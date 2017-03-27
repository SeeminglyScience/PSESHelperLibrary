function TestSelection {
    param(
        [Microsoft.PowerShell.EditorServices.BufferRange]
        $SelectedRange
    )
    $SelectedRange.Start -ne $SelectedRange.End
}