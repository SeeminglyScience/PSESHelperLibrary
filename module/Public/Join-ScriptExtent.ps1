using namespace System.Collections.Generic
using namespace System.Management.Automation.Language
using namespace System.Linq

function Join-ScriptExtent {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [CmdletBinding(HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/Join-ScriptExtent.md')]
    [OutputType([System.Management.Automation.Language.IScriptExtent])]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.Language.IScriptExtent[]]
        $Extent
    )
    begin {
        $extentList = [List[IScriptExtent]]::new()
    }
    process {
        if ($Extent) {
            $extentList.AddRange($Extent)
        }
    }
    end {
        if (-not $extentList) { return }

        $start = [Enumerable]::Min($extentList.StartOffset -as [int[]])
        $end   = [Enumerable]::Max($extentList.EndOffset -as [int[]])

        return [PositionUtil]::CreateExtent([Enumerable]::FirstOrDefault($extentList), $start, $end)
    }
}
