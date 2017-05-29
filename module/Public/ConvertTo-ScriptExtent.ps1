using namespace System.Management.Automation.Language

function ConvertTo-ScriptExtent {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [CmdletBinding(HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/ConvertTo-ScriptExtent.md')]
    [OutputType([System.Management.Automation.Language.IScriptExtent])]
    param(
        [Parameter(ValueFromPipeline, DontShow, ParameterSetName='ByObject')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Alias('StartLine', 'Line')]
        [int]
        $StartLineNumber,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Alias('StartColumn', 'Column')]
        [int]
        $StartColumnNumber,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Alias('EndLine')]
        [int]
        $EndLineNumber,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Alias('EndColumn')]
        [int]
        $EndColumnNumber,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByOffset')]
        [Alias('StartOffset', 'Offset')]
        [int]
        $StartOffsetNumber,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByOffset')]
        [Alias('EndOffset')]
        [int]
        $EndOffsetNumber,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByOffset')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByBuffer')]
        [Alias('File', 'FileName')]
        [string]
        $FilePath = [EditorServicesUtil]::GetContext().CurrentFile.Path,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByBuffer')]
        [Alias('Start')]
        [Microsoft.PowerShell.EditorServices.BufferPosition]
        $StartBuffer,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByBuffer')]
        [Alias('End')]
        [Microsoft.PowerShell.EditorServices.BufferPosition]
        $EndBuffer
    )
    process {
        # Already an InternalScriptExtent or is empty.
        $returnAsIs = $InputObject -is [IScriptExtent] -and
                     (0 -ne $InputObject.StartOffset   -or
                      0 -ne $InputObject.EndOffset     -or
                      $InputObject -eq [PositionUtil]::EmptyExtent)

        if ($returnAsIs) { return $InputObject }

        if ($StartOffsetNumber -and $InputObject -isnot [IScriptExtent]) {
            $startOffset = $StartOffsetNumber
            $endOffset   = $EndOffsetNumber

            # Allow creating a single position extent with just the offset parameter.
            if (-not $EndOffsetNumber) {
                $endOffset = $startOffset
            }

            $helperSource = [PositionUtil]::GetFileAst($FilePath).Extent
        } else {
            if ($StartBuffer) {
                $StartLineNumber   = $StartBuffer.Line
                $StartColumnNumber = $StartBuffer.Column
                $EndLineNumber     = $EndBuffer.Line
                $EndColumnNumber   = $EndBuffer.Column
            }
            # If we have PSES context we can get offsets from ScriptFile. Otherwise, we need to make
            # a line start -> offset map.
            $scriptFile   = [EditorServicesUtil]::GetScriptFile($FilePath)
            $helperSource = $scriptFile.ScriptAst.Extent
            $mapSource    = $scriptFile

            if (-not $helperSource -or -not $mapSource) {
                $helperSource = [PositionUtil]::GetFileAst($FilePath).Extent
                $mapSource    = [PositionUtil]::GetLineMap($helperSource.Text)
            }

            $startOffset = [PositionUtil]::GetOffsetFromPosition($mapSource, $StartLineNumber, $StartColumnNumber)
            $endOffset   = [PositionUtil]::GetOffsetFromPosition($mapSource, $EndLineNumber, $EndColumnNumber)
        }
        return [PositionUtil]::CreateExtent($helperSource, $startOffset, $endOffset)
    }
}
