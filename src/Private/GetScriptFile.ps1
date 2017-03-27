function GetScriptFile {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]
        $Path = ($psEditor.GetEditorContext().CurrentFile.Path)
    )
    process {
        foreach ($file in $Path) {
            [string]$file = Resolve-Path $file -ErrorAction Stop

            # If case doesn't match it'll add a second entry to workspaceFiles.
            $script:PSESData.EditorSession.Workspace.GetFile($file.ToLower())
        }
    }
}