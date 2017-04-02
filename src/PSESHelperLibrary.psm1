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

$PSESHLTemplates = @{
    MemberExpressions = ConvertFrom-StringData @'
    InvokeMember={0}.InvokeMember(\n\t<# name: #> '{3}',\n\t<# invokeAttr: #> [System.Reflection.BindingFlags]'{4}, {1}',\n\t<# binder: #> $null,\n\t<# target: #> {2},\n\t<# args: #> @({5})\n)
    GetValue={0}.\n\t{4}('{3}', [System.Reflection.BindingFlags]'{1}').\n\tGetValue({2})
    SetValue={0}.\n\t{4}('{3}', [System.Reflection.BindingFlags]'{2}').\n\tSetValue({3}, {8})
    VerboseInvokeMethod={0}.\n\tGetMethod(\n\t\t<# name: #> '{3}',\n\t\t<# bindingAttr: #> [System.Reflection.BindingFlags]'{1}',\n\t\t<# binder: #> $null,\n\t\t<# types: #> {6},\n\t\t<# modifiers: #> {7}\n\t).Invoke({2}, @({5}))
'@
}

# Don't reference any files whose FullName match this regex.
$PSESHLExcludeFromFileReferences = '\\Release\\|\\\.vscode\\|build.*\.ps1|debugHarness\.ps1|\.psd1'

# Load all functions and classes.
Get-ChildItem $PSScriptRoot\Classes, $PSScriptRoot\Public, $PSScriptRoot\Private -Filter '*.ps1' |
    ForEach-Object {
        . $PSItem.FullName
    }

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-* -Alias * -Variable PSESHLExcludeFromFileReferences, PSESHLTemplates
