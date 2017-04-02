using namespace System.Reflection

function Import-WorkspaceFunctionSet {
    <#
    .SYNOPSIS
        Loads all modules, functions and type definitions from all files in the workspace into the
        top level session state.
    .DESCRIPTION
        Recursively searches all files in the current workspace for FunctionDefinitionAst's,
        TypeDefinitionAst's, and psd1 files (with exported commands) and loads them into the top
        level session state.

        The variable $PSESHLExcludeFromFileReferences can be used to exclude files.

        This is mainly intended to be a temporary workaround for cross module intellisense until
        PowerShellEditorServices has better symbol tracking for larger projects.

        This will not be loaded automatically unless placed in the $profile used by the editor.
        However, care should be taken before adding to your profile. This is *very likely* to cause
        issues with debugging.
    .INPUTS
        None
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> Import-WorkspaceFunctionSet
        Loads all commands in the current workspace.
    #>
    [CmdletBinding()]
    param()

    $files = $script:PSESData.GetWorkspaceFiles()

    $testManifestSplat = @{
        ErrorAction   = 'Ignore'
        WarningAction = 'SilentlyContinue'
    }
    $files | Where-Object {
        $PSItem -match '.psd1$' -and
        # The match operator is added because ExportedCommands counts as not empty in if statements
        # when empty.
        (Test-ModuleManifest $PSItem @testManifestSplat).ExportedCommands.Keys -match '.'

    } | ForEach-Object { Import-Module $PSItem -Force }

    # Get the top level sesison state from execution context so we can invoke the function and type
    # definitions in the global scope.
    $context = $ExecutionContext.GetType().
        GetField('_context', [BindingFlags]'Instance, NonPublic').
        GetValue($ExecutionContext)

    $topLevelState = $context.GetType().
        GetProperty('TopLevelSessionState', [BindingFlags]'Instance, NonPublic').
        GetValue($context)

    $internal = [scriptblock].GetProperty('SessionStateInternal', [BindingFlags]'Instance, NonPublic')

    $files | ForEach-Object {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($PSItem, [ref]$null, [ref]$null)

        $predicate = {
            param ($Ast)
            # Get type and function definitions. Skip FunctionDefinitionAst's in member definitions.
            $Ast -is [System.Management.Automation.Language.TypeDefinitionAst] -or
            ($Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])
        }

        $functionDefinitions = $ast.FindAll($predicate, $true)

        if ($functionDefinitions) {
            $scriptblock = [scriptblock]::Create($functionDefinitions.Extent.Text)

            $internal.SetValue($scriptblock, $topLevelState)

            . $scriptblock
        }
    }
}
