function ConvertTo-SubExpression {
    param(
        [Microsoft.PowerShell.EditorServices.Extensions.EditorContext]
        $Context
    )
    $ast = Get-AstAtCursor -Context $Context

    if ($ast.Parent -is [System.Management.Automation.Language.CommandAst]) {
        $commandElements    = $ast.Parent.CommandElements
        $parameters         = $commandElements | Where-Object {$PSItem.ParameterName -and $PSItem.ParameterName -ne 'f'}
        $lastParameter      = $parameters[-1]

        $startExtent = $commandElements | ForEach-Object {
            if ($lastElement -eq $lastParameter) {
                $PSItem
            }
            $lastElement = $PSItem
        }

        $startExtent    = $startExtent.Extent
        $endExtent      = $commandElements[-1].Extent

        $context.CurrentFile.InsertText('(', $startExtent.StartLineNumber, $startExtent.StartColumnNumber)
        $context.CurrentFile.InsertText(')', $endExtent.EndLineNumber, $endExtent.EndColumnNumber+1)
    }
}