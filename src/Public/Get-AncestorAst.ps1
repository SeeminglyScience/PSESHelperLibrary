using namespace System.Reflection

function Get-AncestorAst {
    <#
    .SYNOPSIS
        Get a parent ast of a specific ast type.
    .DESCRIPTION
        Uses the "GetAncestorAst" method of System.Management.Automation.Language.Ast to find a parent
        ast of a specific type.
    .INPUTS
        None
    .OUTPUTS
        System.Management.Automation.Language.Ast

        The nearest parent ast of the specified type will be returned.
    .EXAMPLE
        PS C:\> Get-AncesterAst -Context $psEditor.GetEditorContext() `
                                -TargetAstType ([System.Management.Automation.Language.FunctionDefinitionAst])
        Returns the FunctionDefinitionAst of the function that the cursor is currently inside.
    #>
    [PSEditorCommand(SkipRegister)]
    [CmdletBinding()]
    param(
        # Specifies the starting ast.
        [System.Management.Automation.Language.Ast]
        $Ast,

        # Specifies the type of ast to search for as an ancestor.
        [Parameter(Mandatory)]
        [ValidateScript({[System.Management.Automation.Language.Ast].IsAssignableFrom($PSItem)})]
        [type]
        $TargetAstType
    )
    end {
        if (-not $Ast) {
            TryGetEditorContext
            $Ast = Get-AstAtCursor -Context $Context
        }
        if (-not $Ast) { return }

        [System.Management.Automation.Language.Ast].
            GetMethod('GetAncestorAst', [BindingFlags]'NonPublic, Static').
            MakeGenericMethod($TargetAstType).
            Invoke($null, $Ast)
    }
}
