function ConvertTo-ScriptExtent {
    <#
    .SYNOPSIS
        Converts position and range objects from PowerShellEditorServices to ScriptExtent objects.
    .DESCRIPTION
        Converts position and range objects from PowerShellEditorServices to ScriptExtent objects.
    .INPUTS
        None
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> ConvertTo-ScriptExtent
        Converts position and range objects from PowerShellEditorServices to ScriptExtent objects.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseOutputTypeCorrectly', '', Justification='PSSA does not seem to check implemented interfaces.  The current output tag is correct.')]
    [OutputType([System.Management.Automation.Language.IScriptExtent])]
    param(
        # This is here so we can pass script extent objects through without any processing.
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
        [Alias('File')]
        [string]
        $FileName,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByBuffer')]
        [Alias('Start')]
        [Microsoft.PowerShell.EditorServices.BufferPosition]
        $StartBuffer,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByBuffer')]
        [Alias('End')]
        [Microsoft.PowerShell.EditorServices.BufferPosition]
        $EndBuffer
    )
    begin { $flags = [BindingFlags]'NonPublic, Instance' }
    process {
        if ($InputObject -is [System.Management.Automation.Language.IScriptExtent]) { return $InputObject }

        if ($StartBuffer) {
            $StartLineNumber   = $StartBuffer.Line
            $StartColumnNumber = $StartBuffer.Column
            $EndLineNumber     = $EndBuffer.Line
            $EndColumnNumber   = $EndBuffer.Column
        }

        # We use the FileContext from GetEditorContext here as well, but we'd have to create a BufferRange
        # to get line text.
        if (-not $File) { $File = $psEditor.GetEditorContext().CurrentFile.Ast.Extent.File }
        $scriptFile  = GetScriptFile -Path $File
        $startOffset = $scriptFile.GetOffsetAtPosition($StartLineNumber, $StartColumnNumber)
        $endOffset   = $startOffset

        $endIsSame = $EndLineNumber   -eq $StartLineNumber -and
                     $EndColumnNumber -eq $StartColumnNumber

        if (($EndLineNumber -and $EndColumnNumber) -and -not $endIsSame) {
            $endOffset = $scriptFile.GetOffsetAtPosition($EndLineNumber, $EndColumnNumber)
        }

        $positionHelper = $scriptFile.ScriptAst.Extent.GetType().
            GetProperty('PositionHelper', $flags).
            GetValue($scriptFile.ScriptAst.Extent)

        [psobject].Assembly.GetType('System.Management.Automation.Language.InternalScriptExtent').
            GetConstructor(
                <# bindingAttr:     #> $flags,
                <# binder:          #> $null,
                <# types:           #> ($positionHelper.GetType(), [int], [int] -as [type[]]),
                <# modifiers:       #> 3
            ).Invoke(@(
                <# _positionHelper: #> $positionHelper,
                <# startOffset:     #> $startOffset,
                <# endOffset:       #> $endOffset
            ))
    }
}