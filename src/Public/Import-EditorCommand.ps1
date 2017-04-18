function Import-EditorCommand {
    <#
    .SYNOPSIS
        Imports commands with the PSEditorCommand attribute into PowerShell Editor Services.
    .DESCRIPTION
        This function will search the specified module for functions tagged as editor commands and
        register them with PowerShell Editor Services.  By default, if a module is specified only
        exported functions will be processed. However, if this function is called from a module, and
        the module is specified in the "Module" parameter, the function table for the module's script
        scope will be processed.

        Alternatively, you can specify command info objects (like those from the Get-Command cmdlet)
        to be processed directly.
    .INPUTS
        System.Management.Automation.CommandInfo

        You can pass commands to register as editor commands.
    .OUTPUTS
        Microsoft.PowerShell.EditorServices.Extensions.EditorCommand

        If the "PassThru" parameter is specified editor commands that were successfully registered
        will be returned.  This function does not output to the pipeline otherwise.
    .EXAMPLE
        PS C:\> Import-EditorCommand -Module PSESHelperLibrary
        Registers all editor commands in the module PSESHelperLibrary.
    .EXAMPLE
        PS C:\> Get-Command *Editor* | Import-EditorCommand -PassThru
        Registers all editor commands that contain "Editor" in the name and return all successful imports.
    #>
    [OutputType([Microsoft.PowerShell.EditorServices.Extensions.EditorCommand])]
    [CmdletBinding()]
    param(
        # Specifies the module to search for exportable editor commands.
        [Parameter(Position=0,
                   Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ParameterSetName='ByModule')]
        [ArgumentCompleter({ (Get-Module).Name -like ($args[2] + '*') })]
        [ValidateNotNullOrEmpty()]
        [ModuleTransformation()]
        [System.Management.Automation.PSModuleInfo[]]
        $Module,

        # Specifies the functions to register as editor commands. If the function does not have the
        # PSEditorCommand attribute it will be ignored.
        [Parameter(Position=0,
                   Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ParameterSetName='ByCommand')]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ (Get-Command -ListImported).Name -like ($args[2] + '*') })]
        [CommandTransformation()]
        [System.Management.Automation.CommandInfo[]]
        $Command,

        # If specified will replace existing editor commands.
        [switch]
        $Force,

        # If specified will return an EditorCommand object for each imported command.
        [switch]
        $PassThru
    )
    begin {
        $extensionService = $psEditor.GetType().
            GetField('extensionService', [BindingFlags]'Instance, NonPublic').
            GetValue($psEditor)
        $editorCommands = $extensionService.GetType().
            GetField('editorCommands', [BindingFlags]'Instance, NonPublic').
            GetValue($extensionService)
    }
    process {
        $importMetadataSplat = @{
            Attribute        = ([PSEditorCommand])
            ImplementingType = ([EditorCommandParameters])
            PassThru         = $true
        }
        if ($PSCmdlet.ParameterSetName -eq 'ByModule') {
            # If called from a module during it's initialization we can't rely on ExportedFunctions.
            # Instead we need to grab the FunctionTable at the module's script scope.
            $caller = (Get-PSCallStack)[1]
            foreach ($aModule in $Module) {
                if ($caller.InvocationInfo.MyCommand.ScriptBlock.Module.Name -eq $aModule.Name) {
                    $commands = ImportBinderMetadata -SessionState $aModule.SessionState @importMetadataSplat
                } else {
                    $Command = $aModule.ExportedFunctions.Values
                }
            }
        }
        if ($Command) {
            $commands = ImportBinderMetadata -Command $Command @importMetadataSplat
        }
        foreach ($command in $commands) {
            # If we get something back that isn't CommandInfo, then I likely didn't null the output
            # of one of the reflection statements.
            if ($command -isnot [System.Management.Automation.CommandInfo]) {
                throw 'Internal module error: Received binder result is not a command info object.  Please file an issue on GitHub.'
            }
            # Get the attribute from our command to get name info.
            $details = $command.ScriptBlock.Attributes.Where{
                $PSItem -is [PSEditorCommand]
            }[0]

            if (-not $details.SkipRegister) {
                # Name: Expand-Expression becomes ExpandExpression
                if (-not $details.Name) { $details.Name = $command.Name -replace '-' }
                # DisplayName: Expand-Expression becomes Expand Expression
                if (-not $details.DisplayName) { $details.DisplayName = $command.Name -replace '-', ' ' }

                # If the editor command is already loaded skip unless force is specified.
                if ($editorCommands.ContainsKey($details.Name)) {
                    if ($Force.IsPresent) {
                        $null = $psEditor.UnregisterCommand($details.Name)
                    } else {
                        Write-Verbose ('Editor command "{0}" already exists, skipping.' -f $details.Name)
                        continue
                    }
                }
                # Register-EditorCommand passes context as a positional parameter.  We can't rely on
                # position, but we can rely on name.
                $editorCommand = [Microsoft.PowerShell.EditorServices.Extensions.EditorCommand]::new(
                    <# commandName:    #> $details.Name,
                    <# displayName:    #> $details.DisplayName,
                    <# suppressOutput: #> $details.SuppressOutput,
                    <# scriptBlock:    #> [scriptblock]::Create(('{0} -Context $args[0]' -f $command.Name))
                )
                $null = $psEditor.RegisterCommand($editorCommand)

                if ($PassThru.IsPresent -and $editorCommand) {
                    $editorCommand
                }
            }
        }
    }
}
