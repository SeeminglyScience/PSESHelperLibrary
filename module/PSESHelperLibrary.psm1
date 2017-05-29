Import-LocalizedData -BindingVariable Strings -FileName Strings

# Define this type here so it's exportable.
[AttributeUsage([AttributeTargets]::Class)]
class PSEditorCommand : Attribute {
    [string] $Name;
    [string] $DisplayName;
    [bool] $SuppressOutput;
    [bool] $SkipRegister;
}

# PSST doesn't load Antlr until first use, and we need them loaded
# to create renderers.
if (-not ('Antlr4.StringTemplate.StringRenderer' -as [type])) {
    if (-not ($psstPath = (Get-Module PSStringTemplate).ModuleBase)) {
        # platyPS doesn't seem to be following RequiredModules, this should only ever run
        # while running platyPS.  Need to look into this more.
        $psstPath = (Get-Module PSStringTemplate -ListAvailable).ModuleBase
    }
    Add-Type -Path $psstPath\Antlr3.Runtime.dll
    Add-Type -Path $psstPath\Antlr4.StringTemplate.dll
}
if ($psEditor) {

    $EditorOperations = $psEditor.GetType().
        GetField('editorOperations', [System.Reflection.BindingFlags]'Instance, NonPublic').
        GetValue($psEditor)

    [System.Diagnostics.CodeAnalysis.SuppressMessage('UseDeclaredVarsMoreThanAssignments', '', Justification='Script variable used throughout the module.')]
    $EditorSession = $EditorOperations.GetType().
        GetField('editorSession', [System.Reflection.BindingFlags]'Instance, NonPublic').
        GetValue($EditorOperations)

# When invoking PSSA the $psEditor variable doesn't get loaded, so without this check we would mock
# these types any time we run Set-RuleSuppression.
} elseif (-not ('Microsoft.PowerShell.EditorServices.Workspace' -as [type])) {

    $typesToMock = 'Microsoft.PowerShell.EditorServices.BufferRange',
                   'Microsoft.PowerShell.EditorServices.BufferPosition',
                   'Microsoft.PowerShell.EditorServices.ScriptFile',
                   'Microsoft.PowerShell.EditorServices.Extensions.FileContext',
                   'Microsoft.PowerShell.EditorServices.Extensions.EditorCommand',
                   'Microsoft.PowerShell.EditorServices.Extensions.EditorContext',
                   'Microsoft.PowerShell.EditorServices.Extensions.EditorSession',
                   'Microsoft.PowerShell.EditorServices.Extensions.EditorObject'

    foreach ($typeName in ($typesToMock)) {
        [ref].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Add($typeName, [int])
    }
}

# Don't reference any files whose FullName match this regex.
[System.Diagnostics.CodeAnalysis.SuppressMessage('UseDeclaredVarsMoreThanAssignments', '', Justification='Exported variable for customization.')]
$PSESHLExcludeFromFileReferences = '\\Release\\|\\\.vscode\\|build.*\.ps1|debugHarness\.ps1'

. "$PSScriptRoot\Classes\Util.ps1"
. "$PSScriptRoot\Classes\Attributes.ps1"
. "$PSScriptRoot\Classes\Expressions.ps1"
. "$PSScriptRoot\Classes\Renderers.ps1"
. "$PSScriptRoot\Classes\Position.ps1"

# This is a temporary workaround for some issues around stale type resolution in PowerShell classes.
[System.Diagnostics.CodeAnalysis.SuppressMessage('UseDeclaredVarsMoreThanAssignments', '', Justification='Script variable used throughout the module.')]
$ImplementingAssemblies = @{
    Main        = [PSEditorCommand].Assembly
    Attributes  = [CommandTransformation].Assembly
    Expressions = [ExtendedMemberExpressionAst].Assembly
    Renderers   = [StringExpressionRenderer].Assembly
}

# Idea from: https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
# but mine works with breakpoints :)
Get-ChildItem $PSScriptRoot\Public, $PSScriptRoot\Private -Filter '*.ps1' | ForEach-Object {
    $ExecutionContext.InvokeCommand.InvokeScript(
        <# useLocalScope: #> $false,
        <# scriptBlock:   #> [System.Management.Automation.Language.Parser]::ParseInput(
            <# input:     #> [IO.File]::ReadAllText($PSItem.FullName),
            <# fileName:  #> $PSItem.FullName,
            <# tokens:    #> [ref]$null,
            <# errors:    #> [ref]$null).GetScriptBlock(),
        <# input:         #> $null,
        <# args:          #> $null)
}

if ($psEditor) {
   Import-EditorCommand -Module $ExecutionContext.SessionState.Module
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-* -Alias * -Variable PSESHLExcludeFromFileReferences
