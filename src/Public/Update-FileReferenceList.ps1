using namespace System.Reflection
# TODO: Add comment help, use event args or editor context to load only the current file.
function Update-FileReferenceList {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param()
    # Get the current list of open files.
    $openFiles = $script:PSESData.EditorSession.Workspace.GetType().
        GetField('workspaceFiles', [BindingFlags]'NonPublic,Instance').
        GetValue($script:PSESData.EditorSession.Workspace)

    foreach ($openFile in $openFiles.GetEnumerator()) {

        [string[]]$newReferencedFiles = $openfile.Value.ReferencedFiles
        # Ensure all workspace files are in the referenced file list for every file.
        foreach ($workspaceFile in ($script:PSESData.GetWorkspaceFiles())) {
            if (-not $openFile.Value.ReferencedFiles -or -not $openFile.Value.ReferencedFiles.Contains($workspaceFile)) {
                $newReferencedFiles += $workspaceFile
            }
        }
        # Set the private field for referenced files because the property is read only.
        $openFile.Value.GetType().
            GetField('<ReferencedFiles>k__BackingField', [BindingFlags]'NonPublic,Instance').
            SetValue($openFile.Value, $newReferencedFiles)
    }
}