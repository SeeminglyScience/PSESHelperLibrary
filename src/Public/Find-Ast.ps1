using namespace System.Management.Automation
using namespace System.Collections.Generic

function Find-Ast {
    <#
    .SYNOPSIS
        Search for a ast within an ast.
    .DESCRIPTION
        The Find-Ast function can be used to easily find a specific ast from a starting ast. All
        asts following the inital starting ast will be searched, including those that are not part
        of the same tree.

        The behavior of the search (such as direction) and criteria can be changed with the parameters.

        Alternatively, you can specify the AtCursor parameter to only return the ast closest to the
        cursor in PowerShell Editor Services.
    .INPUTS
        System.Management.Automation.Language.Ast

        You can pass asts to search to this function.
    .OUTPUTS
        System.Management.Automation.Language.Ast

        Asts that match the criteria will be returned to the pipeline.
    .EXAMPLE
        PS C:\> Find-Ast
        Returns all asts in the currently open file in the editor.
    .EXAMPLE
        PS C:\> Find-Ast -First -IncludeStartingAst
        Returns the top level ast in the currently open file in the editor.
    .EXAMPLE
        PS C:\> Find-Ast { $PSItem -is [FunctionDefinitionAst] }
        Returns all function definition asts in the ast of file currently open in the editor.
    .EXAMPLE
        PS C:\> Find-Ast { $_.Member }
        Returns all member expressions in the file currently open in the editor.
    .EXAMPLE
        PS C:\> Find-Ast { $_.InvocationOperator -eq 'Dot' } | Find-Ast -Family { $_.VariablePath }
        Returns all variable expressions used in a dot source expression.
    .EXAMPLE
        PS C:\> Find-Ast { 'PowerShellVersion' -eq $_ } | Find-Ast -First | Set-ExtentText -Value "'4.0'"
        First finds the ast of the PowerShellVersion manifest tag, then finds the first ast after it
        and changes the text to '4.0'. This will not work as is if the field is commented.
    #>
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName='FilterScript')]
    param(
        # Specifies a ScriptBlock that returns $true if an ast should be returned. Uses $PSItem and
        # $_ like Where-Object. If not specified all asts will be returned.
        [Parameter(Position=0, ParameterSetName='FilterScript')]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $FilterScript = { $true },

        # Specifies the starting ast. The default is the ast of the current file in PowerShell
        # Editor Services.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='FilterScript')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast]
        $Ast,

        # If specified the direction of the search will be reversed.
        [Parameter(ParameterSetName='FilterScript')]
        [switch]
        $Before,

        # If specified only children of the starting ast will be searched. If specified with the
        # "Before" parameter then only ancestors will be searched.
        [Parameter(ParameterSetName='FilterScript')]
        [switch]
        $Family,

        # If specified will return only the first result. This will be the closest
        # ast that matches.
        [Parameter(ParameterSetName='FilterScript')]
        [Alias('Closest', 'F')]
        [switch]
        $First,

        # If specified will return only the last result. This will be the furthest
        # ast that matches.
        [Parameter(ParameterSetName='FilterScript')]
        [Alias('Furthest')]
        [switch]
        $Last,

        # If specified will only search ancestors of the starting ast.  This is a convenience
        # parameter that acts the same as the "Family" and "Before" parameters when used together.
        [Parameter(ParameterSetName='FilterScript')]
        [Alias('Parent')]
        [switch]
        $Ancestor,

        # If specified the starting ast will be included if matched.
        [Parameter(ParameterSetName='FilterScript')]
        [switch]
        $IncludeStartingAst,

        # If specified, this function will return the smallest ast that the cursor is
        # within. Requires PowerShell Editor Services.
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
        TryGetEditorContext
        if (-not $Ast -and $Context) {
            $Ast = $Context.CurrentFile.Ast
        }
        switch ($PSCmdlet.ParameterSetName) {
            AtCursor {
                # Need editor context to get cursor location.
                if (-not $Context) {
                    ThrowError -Exception ([InvalidOperationException]::new($Strings.MissingEditorContext)) `
                               -Id        MissingEditorContext `
                               -Category  InvalidOperation
                }

                $cursorLine     = $Context.CursorPosition.Line
                $cursorColumn   = $Context.CursorPosition.Column
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
