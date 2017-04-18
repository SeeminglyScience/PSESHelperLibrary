# Define this type here so it's exportable.
[AttributeUsage([AttributeTargets]::Class)]
class PSEditorCommand : Attribute {
    [string] $Name;
    [string] $DisplayName;
    [bool] $SuppressOutput;
    [bool] $SkipRegister;
}

if ($psEditor) {

    $EditorOperations = $psEditor.GetType().
        GetField('editorOperations', [System.Reflection.BindingFlags]'Instance, NonPublic').
        GetValue($psEditor)

    [System.Diagnostics.CodeAnalysis.SuppressMessage('UseDeclaredVarsMoreThanAssignments', '', Justification='Script variable used throughout the module.')]
    $EditorSession = $EditorOperations.GetType().
        GetField('editorSession', [System.Reflection.BindingFlags]'Instance, NonPublic').
        GetValue($EditorOperations)

} else {

    # This is to avoid parsing errors when loaded outside of the integrated console. Primarily to
    # enable build tasks from VSCode's task runner.
    $mockSplat = @{
        MemberDefinition = 'private object mock;'
        IgnoreWarnings   = $true
        WarningAction    = 'SilentlyContinue'
        Namespace        = 'Microsoft.PowerShell.EditorServices'
    }
    'BufferRange', 'BufferPosition' | ForEach-Object {
        Add-Type -Name $PSItem @mockSplat
    }
    $mockSplat.Namespace = 'Microsoft.PowerShell.EditorServices.Extensions'
    'EditorCommand', 'EditorContext' | ForEach-Object {
        Add-Type -Name $PSItem @mockSplat
    }
}

[System.Diagnostics.CodeAnalysis.SuppressMessage('UseDeclaredVarsMoreThanAssignments', '', Justification='Exported variable for customization.')]
$PSESHLTemplates = @{
    MemberExpressions = ConvertFrom-StringData @'
    InvokeMember={0}.InvokeMember(\n\t<# name: #> '{3}',\n\t<# invokeAttr: #> [System.Reflection.BindingFlags]'{4}, {1}',\n\t<# binder: #> $null,\n\t<# target: #> {2},\n\t<# args: #> @({5})\n)
    GetValue={0}.\n\t{4}('{3}', [System.Reflection.BindingFlags]'{1}').\n\tGetValue({2})
    SetValue={0}.\n\t{4}('{3}', [System.Reflection.BindingFlags]'{1}').\n\tSetValue({2}, {8})
    ParameterlessInvoke={0}.\n\tGet{9}('{3}', [System.Reflection.BindingFlags]'{1}').\n\tInvoke({2}, @({8}))
    VerboseInvokeMethod={0}.\n\tGet{9}(\n\t\t<# name: #> '{3}',\n\t\t<# bindingAttr: #> [System.Reflection.BindingFlags]'{1}',\n\t\t<# binder: #> $null,\n\t\t<# types: #> {6},\n\t\t<# modifiers: #> {7}\n\t).Invoke({2}, @({5}))
'@
}

# Don't reference any files whose FullName match this regex.
[System.Diagnostics.CodeAnalysis.SuppressMessage('UseDeclaredVarsMoreThanAssignments', '', Justification='Exported variable for customization.')]
$PSESHLExcludeFromFileReferences = '\\Release\\|\\\.vscode\\|build.*\.ps1|debugHarness\.ps1'

. "$PSScriptRoot\Classes\Attributes.ps1"
. "$PSScriptRoot\Classes\Metadata.ps1"
. "$PSScriptRoot\Classes\Expressions.ps1"

Get-ChildItem $PSScriptRoot\Public, $PSScriptRoot\Private -Filter '*.ps1' |
    ForEach-Object {
        . $PSItem.FullName
    }

if ($psEditor) {
   Import-EditorCommand -Module $ExecutionContext.SessionState.Module
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-* -Alias * -Variable PSESHLExcludeFromFileReferences, PSESHLTemplates
