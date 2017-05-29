using namespace System.Management.Automation.Language

function Test-ScriptExtent {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [OutputType([bool], ParameterSetName='__AllParameterSets')]
    [OutputType([System.Management.Automation.Language.IScriptExtent], ParameterSetName='PassThru')]
    [CmdletBinding(HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/Test-ScriptExtent.md')]
    param(
        [Parameter(Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent]
        $Extent,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent]
        $Inside,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent]
        $After,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent]
        $Before,

        [Parameter(ParameterSetName='PassThru')]
        [switch]
        $PassThru
    )
    process {
        if (-not $Extent) { return $false }
        $passes = (-not $After  -or  $Extent.StartOffset -gt $After.EndOffset)    -and
                  (-not $Before -or  $Extent.EndOffset   -lt $Before.StartOffset) -and
                  (-not $Inside -or ($Extent.StartOffset -ge $Inside.StartOffset  -and
                                     $Extent.EndOffset   -le $Inside.EndOffset))

        if (-not $PassThru.IsPresent) { return $passes }

        if ($passes) {
            $Extent #yield
        }
    }
}
