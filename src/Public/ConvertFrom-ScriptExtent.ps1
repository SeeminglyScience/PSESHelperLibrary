using namespace Microsoft.PowerShell.EditorServices

function ConvertFrom-ScriptExtent {
    <#
    .SYNOPSIS
        Converts IScriptExtent objects to some common EditorServices types.
    .DESCRIPTION
        Translates IScriptExtent object properties into constructors for some common PowerShell
        EditorServices types.
    .INPUTS
        System.Management.Automation.Language.IScriptExtent

        You can pipe IScriptExtent objects to be converted.
    .OUTPUTS
        Microsoft.PowerShell.EditorServices.BufferRange
        Microsoft.PowerShell.EditorServices.BufferPosition

        This function will return an extent converted to one of the above types depending on switch
        choices.
    .EXAMPLE
        PS C:\> $sb = {
            Get-ChildItem 'Documents'
        }
        $sb.Ast.FindAll({$args[0].Value -eq 'Documents'}, $true) | ConvertFrom-ScriptExtent -BufferRange

        Gets the buffer range of the string expression "Documents".
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.EditorServices.BufferRange],      ParameterSetName='BufferRange')]
    [OutputType([Microsoft.PowerShell.EditorServices.BufferPosition],   ParameterSetName='BufferPosition')]
    param(
        # Specifies the extent to be converted.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent[]]
        $Extent,

        # If specified will convert extents to BufferRange objects.
        [Parameter(ParameterSetName='BufferRange')]
        [switch]
        $BufferRange,

        # If specified will convert extents to BufferPosition objects.
        [Parameter(ParameterSetName='BufferPosition')]
        [switch]
        $BufferPosition,

        # Specifies to use the start of the extent when converting to types with no range. This is
        # the default.
        [Parameter(ParameterSetName='BufferPosition')]
        [switch]
        $Start,

        # Specifies to use the end of the extent when converting to types with no range.
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
