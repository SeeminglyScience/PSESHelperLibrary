function GetScriptFile {
    <#
    .SYNOPSIS
        Get a ScriptFile object for a file.
    .DESCRIPTION
        Uses the GetFile() method from Microsoft.PowerShell.EditorServices.Workspace to retrieve
        a ScriptFile object.  This function will also add the retrieved object to the cache of currently
        opened files within PSES if it is not already loaded.
    .INPUTS
        System.String

        You can pass file paths to this function. You can also pass objects with a property named
        "Path" or "FullName".
    .OUTPUTS
        Microsoft.PowerShell.EditorServices.ScriptFile

        A ScriptFile object will be returned if a valid path is supplied.
    .EXAMPLE
        PS C:\> GetScriptFile -Path .\src\Public\*.ps1
        Returns ScriptFile objects for all .ps1 files in the public folder.
    .EXAMPLE
        PS C:\> Get-ChildItem .\*.ps1 -Recurse | GetScriptFile
        Returns ScriptFile objects for all .ps1 files recursively from the current working directory.
    #>
    [CmdletBinding()]
    param(
        # Specifies the file path to open.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
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
