function Set-ExtentText {
    <#
    .SYNOPSIS
        Replaces text at a specified IScriptExtent object.
    .DESCRIPTION
        Uses the PowerShell EditorServices API to replace text an extent. ScriptExtent objects can
        be found as a property on any object inherited from System.Management.Automation.Language.Ast.
    .INPUTS
        System.Management.Automation.Language.IScriptExtent

        You can pass script extent objects to this function.  You can also pass objects with a property
        named "Extent".
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> $psEditor.GetEditorContext().CurrentFile.Tokens |
            Where-Object Text -ceq 'get-childitem' |
            Set-ExtentText -Value 'Get-ChildItem'

        Replaces all instances of 'get-childitem' with 'Get-ChildItem'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.Language.IScriptExtent]
        $Extent = (Find-Ast -AtCursor).Extent,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Value
    )
    process {
        TryGetEditorContext
        $bufferRange = ConvertFrom-ScriptExtent -Extent $Extent -BufferRange
        $currentFile = $Context.CurrentFile

        $shouldProcess = $PSCmdlet.ShouldProcess(
            ($Strings.WhatIfSetExtent -f $currentFile.GetText($bufferRange), $Value),
             $Strings.ConfirmTitle,
            ($Strings.ConfirmSetExtent -f $currentFile.GetText($bufferRange), $Value)
        )
        if ($shouldProcess) {
            $currentFile.InsertText($Value, $bufferRange)
        }
    }
}
