using namespace System.Reflection

function Import-EditorCommand {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [OutputType([Microsoft.PowerShell.EditorServices.Extensions.EditorCommand])]
    [CmdletBinding(HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/Import-EditorCommand.md')]
    param(
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

        [switch]
        $Force,

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
            Attribute    = $script:ImplementingAssemblies.Main.GetType('PSEditorCommand')
            ParameterAst = NewContextParameterAst
            PassThru     = $true
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
        foreach ($aCommand in $commands) {
            # If we get something back that isn't CommandInfo, then I likely didn't null the output
            # of one of the reflection statements.
            if ($aCommand -isnot [System.Management.Automation.CommandInfo]) {
                ThrowError -Exception ([InvalidOperationException]::new($Strings.InvalidBinderResult)) `
                           -Id        InvalidBinderResult `
                           -Category  InvalidResult `
                           -Target    $aCommand
            }
            # Get the attribute from our command to get name info.
            $details = $aCommand.ScriptBlock.Attributes.Where({
                'PSEditorCommand' -eq $PSItem.TypeId
            }, 'First')[0]

            if (-not $details.SkipRegister -and $details) {
                # Name: Expand-Expression becomes ExpandExpression
                if (-not $details.Name) { $details.Name = $aCommand.Name -replace '-' }

                # DisplayName: Expand-Expression becomes Expand Expression
                if (-not $details.DisplayName) { $details.DisplayName = $aCommand.Name -replace '-', ' ' }

                # If the editor command is already loaded skip unless force is specified.
                if ($editorCommands.ContainsKey($details.Name)) {
                    if ($Force.IsPresent) {
                        $null = $psEditor.UnregisterCommand($details.Name)
                    } else {
                        $PSCmdlet.WriteVerbose($Strings.EditorCommandExists -f $details.Name)
                        continue
                    }
                }
                # Register-EditorCommand passes context as a positional parameter.  We can't rely on
                # position, but we can rely on name.
                $editorCommand = [Microsoft.PowerShell.EditorServices.Extensions.EditorCommand]::new(
                    <# commandName:    #> $details.Name,
                    <# displayName:    #> $details.DisplayName,
                    <# suppressOutput: #> $details.SuppressOutput,
                    <# scriptBlock:    #> [scriptblock]::Create(('{0} -Context $args[0]' -f $aCommand.Name))
                )
                $null = $psEditor.RegisterCommand($editorCommand)

                if ($PassThru.IsPresent -and $editorCommand) {
                    $editorCommand
                }
            }
        }
    }
}
