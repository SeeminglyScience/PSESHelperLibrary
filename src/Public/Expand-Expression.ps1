function Expand-Expression {
    <#
    .SYNOPSIS
        Replaces an extent with the return value of it's text as an expression.
    .DESCRIPTION
        Creates and invokes a scriptblock from the text at the specified extent.  The output is
        then converted to a string object using the "Out-String" cmdlet and used to set the text at
        the extent.
    .INPUTS
        System.Management.Automation.Language.IScriptExtent

        You can pass extents to invoke from the pipeline.
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> $psEditor.GetEditorContext().SelectedRange | ConvertTo-ScriptExtent | Expand-Expression
        Invokes the currently selected text and replaces it with it's output. This is also the default.
    #>
    [PSEditorCommand()]
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

            Set-ExtentText -Extent $object -Value $output
        }
    }
}
