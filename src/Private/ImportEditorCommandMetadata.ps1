function ImportEditorCommandMetadata {
    [CmdletBinding()]
    param()
    end {
        $commands = ImportBinderMetadata -Attribute        ([PSEditorCommand]) `
                                         -ImplementingType ([EditorCommandParameters]) `
                                         -PassThru

        foreach ($command in $commands) {
            # Get the attribute from our command to get name info.
            $details = $command.ScriptBlock.Attributes.Where{
                $PSItem -is [PSEditorCommand]
            }[0]

            if (-not $details.SkipRegister) {
                if (-not $details.Name) { $details.Name = $command.Name -replace '-' }
                if (-not $details.DisplayName) { $details.DisplayName = $command.Name -replace '-', ' ' }
                $editorCommand = [Microsoft.PowerShell.EditorServices.Extensions.EditorCommand]::new(
                    <# commandName:    #> $details.Name,
                    <# displayName:    #> $details.DisplayName,
                    <# suppressOutput: #> $details.SuppressOutput,
                    <# scriptBlock:    #> [scriptblock]::Create(('{0} -Context $args[0]' -f $command.Name))
                )
                $psEditor.RegisterCommand($editorCommand)
            }
        }
    }
}
