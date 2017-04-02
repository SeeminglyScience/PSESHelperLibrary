using namespace System.Reflection
# TODO: Comment help.
function Get-AncestorAst {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='Context')]
        [Microsoft.PowerShell.EditorServices.Extensions.EditorContext]
        $Context,

        [Parameter(Mandatory, ParameterSetName='Ast')]
        [System.Management.Automation.Language.Ast]
        $Ast,

        [Parameter(Mandatory)]
        [ValidateScript({[System.Management.Automation.Language.Ast].IsAssignableFrom($PSItem)})]
        [type]
        $TargetAstType
    )
    if ($PSCmdlet.ParameterSetName -eq $Context) {
        $Ast = Get-AstAtCursor -Context $Context
    }
    if (-not $Ast) { return }

    [System.Management.Automation.Language.Ast].
        GetMethod('GetAncestorAst', [BindingFlags]'NonPublic, Static').
        MakeGenericMethod($TargetAstType).
        Invoke($null, $Ast)
}