using namespace System.Reflection
function Get-ScriptExtent {
    <#
    .SYNOPSIS
        Combine script extents.
    .DESCRIPTION
        Get the collective extent of any number of IScriptExtent objects.
    .INPUTS
        System.Management.Automation.Language.IScriptExtent

        You can pass script extent objects to this function.  You can also pass objects with a property
        named "Extent".
    .OUTPUTS
        System.Management.Automation.Language.IScriptExtent

        The combined extent is outputted.
    .EXAMPLE
        PS C:\> $sb = {
                'This is a scriptblock'
                'With two extents'
            }
            $sb.Ast.FindAll({$args[0].Value}, $true) | Get-ScriptExtent

        Returns the combined extent of the two string expressions.
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.IScriptExtent])]
    param(
        # Specifies the extents to combine. If a single extent is passed, it will be returned as is.
        # If no extents are passed nothing will be returned.  Extents passed from the pipeline are
        # processed after pipeline input completes.
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