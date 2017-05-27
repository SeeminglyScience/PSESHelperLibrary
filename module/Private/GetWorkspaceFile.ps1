 function GetWorkspaceFile {
     [OutputType([System.IO.FileSystemInfo])]
     [CmdletBinding()]
     param()
     process {
        Get-ChildItem -Path $psEditor.Workspace.Path -Filter '*.ps*1' -Recurse |
            Where-Object FullName -NotMatch $PSESHLExcludeFromFileReferences
     }
 }