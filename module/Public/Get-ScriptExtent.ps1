using namespace System.Reflection

function Get-ScriptExtent {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [CmdletBinding(HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/Get-ScriptExtent.md')]
    [OutputType([System.Management.Automation.Language.IScriptExtent])]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.Language.IScriptExtent[]]
        $Extent
    )
    end {
        if (-not $Extent) { return }
        $start  = ($Extent | Sort-Object StartOffset)[0]
        $end    = ($Extent | Sort-Object EndOffset -Descending)[0]
        $iScriptExtentType = [System.Management.Automation.Language.IScriptExtent]
        [System.Management.Automation.Language.Parser].
            GetMethod(
                <# name:        #> 'ExtentOf',
                <# bindingAttr: #> [BindingFlags]'NonPublic, Static',
                <# binder:      #> $null,
                <# types:       #> ($iScriptExtentType, $iScriptExtentType -as [type[]]),
                <# modifiers:   #> 2
            ).Invoke($null, @($start, $end))
    }
}
