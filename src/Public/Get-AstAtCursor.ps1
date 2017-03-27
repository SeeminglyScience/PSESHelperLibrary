# TODO: Rework this entirely into Find-Ast with a -AtCursor switch parameter or default.
# TODO: Use the ScriptFile object to get offset.  Probably also use the GetSmallestStatementAst method.
function Get-AstAtCursor {
    param(
        [Microsoft.PowerShell.EditorServices.Extensions.EditorContext]
        $Context = $psEditor.GetEditorContext(),

        [switch]
        $All
    )

    $ast            = $Context.CurrentFile.Ast
    $cursorLine     = $Context.CursorPosition.Line
    $cursorColumn   = $Context.CursorPosition.Column
    $cursorOffset   = [regex]::Match($ast.Extent.Text, "(.*\r?\n){$($cursorLine-1)}.{$($cursorColumn-1)}").Value.Length

    if (-not ($ast -and $cursorLine -and $cursorColumn -and $cursorOffset)) { return }

    $asts = $ast.FindAll({$cursorOffset -ge $args[0].Extent.StartOffset -and $cursorOffset -le $args[0].Extent.EndOffset},$true)

    if ($All.IsPresent) { return $asts }

    $asts[-1]
}