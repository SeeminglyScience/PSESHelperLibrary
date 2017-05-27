using namespace Microsoft.PowerShell.EditorServices

function ConvertFrom-ScriptExtent {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [CmdletBinding(HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/ConvertFrom-ScriptExtent.md')]
    [OutputType([Microsoft.PowerShell.EditorServices.BufferRange],      ParameterSetName='BufferRange')]
    [OutputType([Microsoft.PowerShell.EditorServices.BufferPosition],   ParameterSetName='BufferPosition')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent[]]
        $Extent,

        [Parameter(ParameterSetName='BufferRange')]
        [switch]
        $BufferRange,

        [Parameter(ParameterSetName='BufferPosition')]
        [switch]
        $BufferPosition,

        [Parameter(ParameterSetName='BufferPosition')]
        [switch]
        $Start,

        [Parameter(ParameterSetName='BufferPosition')]
        [switch]
        $End
    )
    process {
        foreach ($aExtent in $Extent) {
            switch ($PSCmdlet.ParameterSetName) {
                BufferRange {
                    [BufferRange]::new(
                        <# startLine:   #> $aExtent.StartLineNumber,
                        <# startColumn: #> $aExtent.StartColumnNumber,
                        <# endLine:     #> $aExtent.EndLineNumber,
                        <# endColumn:   #> $aExtent.EndColumnNumber
                    )
                }
                BufferPosition {
                    if ($End) {
                        $line   = $aExtent.EndLineNumber
                        $column = $aExtent.EndLineNumber
                    } else {
                        $line   = $aExtent.StartLineNumber
                        $column = $aExtent.StartLineNumber
                    }
                    [BufferPosition]::new($line, $column)
                }
            }
        }
    }
}
