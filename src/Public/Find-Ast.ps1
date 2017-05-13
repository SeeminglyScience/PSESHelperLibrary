using namespace System.Management.Automation
using namespace System.Collections.Generic

function Find-Ast {
    <#
    .SYNOPSIS
        Search for a ast within an ast.
    .DESCRIPTION
        The Find-Ast function can be used to easily find a specific ast from a starting
        ast.  By default children asts will be searched, but ancestor asts can also be
        searched by specifying the "Ancestor" switch parameter.

        Additionally, you can find the Ast closest to the cursor with the "AtCursor" switch
        parameter.
    .INPUTS
        System.Management.Automation.Language.Ast

        You can pass asts to search to this function.
    .OUTPUTS
        System.Management.Automation.Language.Ast

        Asts that match the criteria will be returned to the pipeline.
    .EXAMPLE
        PS C:\> Find-Ast { $PSItem -is [FunctionDefinitionAst] }
        Returns all function definition asts in the ast of file currently open in the editor.
    .EXAMPLE
        PS C:\> Find-Ast {
            $_ -is [MemberExpressionAst] -and
            ($_ | Find-Ast -Ancestor -First { $_ -is [MemberExpressionAst] })
        }
        Returns all nested member expressions in the file currently open in the editor.
    #>
    [CmdletBinding()]
    param(
        # Specifies the ast to search in.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='FilterScript')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast]
        $Ast,

        # Specifies a ScriptBlock that returns a boolean. Uses $PSItem and $_ like
        # like Where-Object.
        [Parameter(Position=0, Mandatory, ParameterSetName='FilterScript')]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $FilterScript,

        # Specifies to search ancestors asts instead of children.
        [Parameter(ParameterSetName='FilterScript')]
        [switch]
        $Ancestor,

        # If specified will return only the first result. This will be the closest
        # ast that matches.
        [Parameter(ParameterSetName='FilterScript')]
        [Alias('Closest')]
        [switch]
        $First,

        # If specified, this function will return the smallest ast that the cursor is
        # within. Requires PowerShell Editor Services.
        [Parameter(ParameterSetName='AtCursor')]
        [switch]
        $AtCursor
    )
    process {
        TryGetEditorContext
        if (-not $Ast -and $Context) {
            $Ast = $Context.CurrentFile.Ast
        }
        switch ($PSCmdlet.ParameterSetName) {
            AtCursor {
                # Need editor context to get cursor location.
                if (-not $Context) {
                    $PSCmdlet.ThrowTerminatingError([ErrorRecord]::new(
                        <# exception:     #> [InvalidOperationException]::new($Strings.MissingEditorContext),
                        <# errorId:       #> 'MissingEditorContext',
                        <# errorCategory: #> [ErrorCategory]::InvalidOperation,
                        <# targetObject:  #> $null
                    ))
                }

                $cursorLine     = $Context.CursorPosition.Line
                $cursorColumn   = $Context.CursorPosition.Column
                $cursorOffset   = [regex]::Match(
                    $ast.Extent.Text,
                    "(.*\r?\n){$($cursorLine-1)}.{$($cursorColumn-1)}"
                ).Value.Length

                #yield
                $Ast.FindAll({
                    $cursorOffset -ge $args[0].Extent.StartOffset -and
                    $cursorOffset -le $args[0].Extent.EndOffset
                }, $true)[-1]
            }
            FilterScript {
                if (-not $Ast) { return }

                if ($Ancestor.IsPresent) {
                    $parent = $Ast
                    $Asts = for ($parent; $parent = $parent.Parent) { $parent }
                } else {
                    # Grab all children so we can handle ancestors the same as children.
                    $Asts = $Ast.FindAll({$true}, $true)
                }
                foreach ($aAst in $Asts) {
                    $variables = [List[psvariable]]@(
                        [psvariable]::new('_', $aAst),
                        [psvariable]::new('PSItem', $aAst)
                    )
                    # Include ast in args as well as dollar under incase the user
                    # prefers to treat it like a predicate.
                    $shouldReturn = $FilterScript.InvokeWithContext(
                        <# functionsToDefine: #> $null,
                        <# variablesToDefine: #> $variables,
                        <# args:              #> $aAst
                    )
                    if ($shouldReturn) {
                        #yield
                        $aAst
                        if ($First.IsPresent) { break }
                    }
                }
            }
        }
    }
}
