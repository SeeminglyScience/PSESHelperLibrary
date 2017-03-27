using namespace System.Reflection
using namespace Microsoft.PowerShell.EditorServices

$flags              = [System.Reflection.BindingFlags]'NonPublic, Instance'
$editorOperations   = $psEditor.        GetType().GetField('editorOperations',  $flags).GetValue($psEditor)
$extensionService   = $psEditor.        GetType().GetField('extensionService',  $flags).GetValue($psEditor)
$editorSession      = $editorOperations.GetType().GetField('editorSession',     $flags).GetValue($editorOperations)
$languageServer     = $editorOperations.GetType().GetField('messageSender',     $flags).GetValue($editorOperations)

[System.Diagnostics.CodeAnalysis.SuppressMessage('UseDeclaredVarsMoreThanAssignments', '')]
$PSESData = [PSCustomObject]@{
    EditorOperations    = $editorOperations
    ExtensionService    = $extensionService
    EditorSession       = $editorSession
    LanguageServer      = $languageServer
} | Add-Member  -MemberType ScriptProperty `
                -Name       CurrentScriptFile `
                -PassThru `
                -Value {

    $psEditor.GetEditorContext().CurrentFile.GetType().
        GetField('scriptFile', [System.Reflection.BindingFlags]'NonPublic, Instance').
        GetValue($psEditor.GetEditorContext().CurrentFile)
} | Add-Member  -MemberType ScriptMethod `
                -Name       GetWorkspaceFiles `
                -PassThru `
                -Value {

    Get-ChildItem -Path $psEditor.Workspace.Path -Filter '*.ps*1' -Recurse |
            Where-Object FullName -NotMatch $PSESHLExcludeFromFileReferences |
            ForEach-Object -MemberName FullName
}

# Don't reference any files whose FullName match this regex.
$PSESHLExcludeFromFileReferences = '\\Release\\|\\\.vscode\\|build.*\.ps1|debugHarness\.ps1|\.psd1'

# Load all functions.
Get-ChildItem $PSScriptRoot\Public, $PSScriptRoot\Private -Filter '*.ps1' | ForEach-Object {
    . $PSItem.FullName
}


# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-* -Alias * -Variable PSESHLExcludeFromFileReferences
