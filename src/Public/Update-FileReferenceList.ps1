using namespace System.Reflection

function Update-FileReferenceList {
    <#
    .SYNOPSIS
        Adds all files in the current workspace to the list of referenced files for all currently
        open script files.
    .DESCRIPTION
        This function is mainly intended to be ran automatically by the Start-SymbolFinderWorkaround
        function.  It can however be ran manually for temporary workspace wide symbol support as an
        alternative for those who do not want to override EditorServices private methods.
    .INPUTS
        None
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> Update-FileReferenceList
        Updates the referenced files list for all currently open script files.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()
    end {
        # Get the current list of open files.
        $openFiles = $script:EditorSession.Workspace.GetType().
            GetField('workspaceFiles', [BindingFlags]'NonPublic,Instance').
            GetValue($script:EditorSession.Workspace)

        foreach ($openFile in $openFiles.GetEnumerator()) {

            [string[]]$newReferencedFiles = $openfile.Value.ReferencedFiles
            # Ensure all workspace files are in the referenced file list for every file.
            foreach ($workspaceFile in (GetWorkspaceFile).FullName) {
                if (-not $openFile.Value.ReferencedFiles -or -not $openFile.Value.ReferencedFiles.Contains($workspaceFile)) {
                    $newReferencedFiles += $workspaceFile
                }
            }
            if ($PSCmdlet.ShouldProcess($openFile.FilePath)) {
                # Set the private field for referenced files because the property is read only.
                $openFile.Value.GetType().
                    GetField('<ReferencedFiles>k__BackingField', [BindingFlags]'NonPublic,Instance').
                    SetValue($openFile.Value, $newReferencedFiles)
            }
        }
    }
}
