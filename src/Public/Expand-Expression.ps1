function Expand-Expression {
    <#
    .SYNOPSIS
        Replaces an extent with the return value of it's text.
    .DESCRIPTION
        Replaces an extent with the return value of it's text.
    .INPUTS
        None
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> Expand-Expression
        Replaces an extent with the return value of it's text.
    #>
    [CmdletBinding()]
    param(
        # Specifies the extent to invoke.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Extent')]
        [System.Management.Automation.Language.IScriptExtent[]]
        $InputObject = ($psEditor.GetEditorContext().SelectedRange | ConvertTo-ScriptExtent)
    )
    process {
        foreach ($object in $InputObject) {
            if ([string]::IsNullOrWhiteSpace($object.Text)) {
                throw 'Cannot expand the extent with start offset ''{0}'' for file ''{1}'' because it is empty.' -f $object.StartOffset, $object.File
            }
            $parseErrors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseInput(
                <# input:  #> $object.Text,
                <# tokens: #> [ref]$null,
                <# errors: #> [ref]$parseErrors
            )
            if ($parseErrors) { throw $parseErrors }

            $output = & ([scriptblock]::Create($object.Text)) | Out-String
            # gci
            Set-ExtentText -Extent $object -Value $output
        }
    }
}