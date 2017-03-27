# TODO: Finish comment help.
function Set-ExtentText {
    <#
    .SYNOPSIS
        Description
    .DESCRIPTION
        Description
    .INPUTS
        None
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> $psEditor.GetEditorContext().CurrentFile.Tokens |
            Where-Object Text -eq '=' |
            Set-ExtentText -Value '?'

        Changes all equal signs in the current file to question marks for some reason.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.Language.IScriptExtent]
        $Extent = (Get-AstAtCursor).Extent,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Value
    )
    process {
        $bufferRange = ConvertFrom-ScriptExtent -Extent $Extent -BufferRange
        $currentFile = $psEditor.GetEditorContext().CurrentFile

        if ($PSCmdlet.ShouldProcess((
            'Changing ''{0}'' to ''{1}''' -f $currentFile.GetText($bufferRange), $Value
        ))) {
            $psEditor.GetEditorContext().CurrentFile.InsertText($Value, $bufferRange)
        }
    }
}