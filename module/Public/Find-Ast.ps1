using namespace System.Management.Automation
using namespace System.Collections.Generic

function Find-Ast {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [CmdletBinding(PositionalBinding=$false,
                   DefaultParameterSetName='FilterScript',
                   HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/Find-Ast.md')]
    param(
        [Parameter(Position=0, ParameterSetName='FilterScript')]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $FilterScript = { $true },

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='FilterScript')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast]
        $Ast,

        [Parameter(ParameterSetName='FilterScript')]
        [switch]
        $Before,

        [Parameter(ParameterSetName='FilterScript')]
        [switch]
        $Family,

        [Parameter(ParameterSetName='FilterScript')]
        [Alias('Closest', 'F')]
        [switch]
        $First,

        [Parameter(ParameterSetName='FilterScript')]
        [Alias('Furthest')]
        [switch]
        $Last,

        [Parameter(ParameterSetName='FilterScript')]
        [Alias('Parent')]
        [switch]
        $Ancestor,

        [Parameter(ParameterSetName='FilterScript')]
        [switch]
        $IncludeStartingAst,

        [Parameter(ParameterSetName='AtCursor')]
        [switch]
        $AtCursor
    )
    begin {
        # Get all children or ancestors.
        function GetAllFamily {
            param($Start)

            if ($Before.IsPresent) {
                $parent = $Start
                for ($parent; $parent = $parent.Parent) { $parent }
                return
            }
            return $Start.FindAll({ $true }, $true)
        }
        # Get all asts regardless of structure, in either direction from the starting ast.
        function GetAllAsts {
            param($Start)

            $topParent = Find-Ast -Ast $Start -Ancestor -Last -IncludeStartingAst
            if (-not $topParent) { $topParent = $Start }

            if ($Before.IsPresent) {
                # Need to store and cast so we can reverse the collection.
                $result = $topParent.
                    FindAll({ $true }, $true).
                    Where({ $PSItem -eq $Ast }, 'Until') -as [Language.Ast[]]

                [array]::Reverse($result)
                return $result
            }
            return $topParent.FindAll({ $true }, $true).Where({ $PSItem -eq $Ast }, 'SkipUntil')
        }
    }
    process {
        if ($Ancestor.IsPresent) {
            $Family = $Before = $true
        }
        $context = [EditorServicesUtil]::GetContext()

        if (-not $Ast -and $context) {
            $Ast = $context.CurrentFile.Ast
        }
        switch ($PSCmdlet.ParameterSetName) {
            AtCursor {
                # Need editor context to get cursor location.
                if (-not $context) {
                    ThrowError -Exception ([InvalidOperationException]::new($Strings.MissingEditorContext)) `
                               -Id        MissingEditorContext `
                               -Category  InvalidOperation
                }

                $cursorLine     = $context.CursorPosition.Line
                $cursorColumn   = $context.CursorPosition.Column
                $cursorOffset   = [regex]::Match(
                    $ast.Extent.Text,
                    "(.*\r?\n){$($cursorLine-1)}.{$($cursorColumn-1)}"
                ).Value.Length

                #yield
                Find-Ast -Last {
                    $cursorOffset -ge $PSItem.Extent.StartOffset -and
                    $cursorOffset -le $PSItem.Extent.EndOffset
                }
            }
            FilterScript {
                if (-not $Ast) { return }

                # Check if we're trying to get the top level ancestor when we already are.
                if ($Before.IsPresent -and
                    $Family.IsPresent -and
                    $Last.IsPresent   -and -not
                    $Ast.Parent       -and
                    $Ast -is [Language.ScriptBlockAst])
                    { return $Ast }

                if ($Family.IsPresent) {
                    $asts = GetAllFamily $Ast
                } else {
                    $asts = GetAllAsts $Ast
                }
                # Check the first ast to see if it's our starting ast, unless
                $checkFirstAst = -not $IncludeStartingAst
                foreach ($aAst in $asts) {
                    if ($checkFirstAst) {
                        if ($aAst -eq $Ast) {
                            $checkFirstAst = $false
                            continue
                        }
                    }
                    # Include object in args as well as dollar under incase the user
                    # prefers to treat it like a predicate.
                    $shouldReturn = $FilterScript.InvokeWithContext(
                        <# functionsToDefine: #> $null,
                        <# variablesToDefine: #> [psvariable]::new('_', $aAst) -as [List[psvariable]],
                        <# args:              #> $aAst
                    )

                    if (-not $shouldReturn) { continue }

                    # Return first, last, both, or all depending on the combination of switches.
                    if (-not $Last.IsPresent) {
                        $aAst #yield
                        if ($First.IsPresent) { break }
                    } else {
                        $lastMatch = $aAst
                        if ($First.IsPresent) {
                            $aAst #yield
                            $First = $false
                        }
                    }
                }
                #yield
                if ($Last.IsPresent) { return $lastMatch }
            }
        }
    }
}
