using namespace System.Reflection

function ConvertTo-ScriptExtent {
    <#
    .SYNOPSIS
        Converts position and range objects from PowerShellEditorServices to ScriptExtent objects.
    .DESCRIPTION
        Converts position and range objects from PowerShellEditorServices to ScriptExtent objects.
    .INPUTS
        System.Object

        You can pass any object with any of the following properties.

        StartLineNumber, StartLine, Line
        EndLineNumber, EndLine
        StartColumnNumber, StartColumn, Column
        EndColumnNumber, EndColumn
        StartOffsetNumber, StartOffset, Offset
        EndOffsetNumber, EndOffset
        StartBuffer, Start
        EndBuffer, End

        Objects of type IScriptExtent will be passed through with no processing.
    .OUTPUTS
        System.Management.Automation.Language.IScriptExtent,
        System.Management.Automation.Language.InternalScriptExtent

        This function will return any IScriptExtent object passed without processing. Objects created
        by this function will be of type InternalScriptExtent.
    .EXAMPLE
        PS C:\> $psEditor.GetEditorContext().SelectedRange | ConvertTo-ScriptExtent
        Returns a InternalScriptExtent object of the currently selected range.
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.IScriptExtent])]
    param(
        # This is here so we can pass script extent objects through without any processing.
        [Parameter(ValueFromPipeline, DontShow, ParameterSetName='ByObject')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent]
        $InputObject,

        # Specifies the starting line number.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Alias('StartLine', 'Line')]
        [int]
        $StartLineNumber,

        # Specifies the starting column number.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Alias('StartColumn', 'Column')]
        [int]
        $StartColumnNumber,

        # Specifies the ending line number.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Alias('EndLine')]
        [int]
        $EndLineNumber,

        # Specifies the ending column number.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Alias('EndColumn')]
        [int]
        $EndColumnNumber,

        # Specifies the starting offset number.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByOffset')]
        [Alias('StartOffset', 'Offset')]
        [int]
        $StartOffsetNumber,

        # Specifies the ending offset number.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByOffset')]
        [Alias('EndOffset')]
        [int]
        $EndOffsetNumber,

        # Specifies the path of the source script file.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByPosition')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByOffset')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByBuffer')]
        [Alias('File', 'FileName')]
        [string]
        $FilePath,

        # Specifies the starting buffer position.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByBuffer')]
        [Alias('Start')]
        [Microsoft.PowerShell.EditorServices.BufferPosition]
        $StartBuffer,

        # Specifies the ending buffer position.
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName='ByBuffer')]
        [Alias('End')]
        [Microsoft.PowerShell.EditorServices.BufferPosition]
        $EndBuffer
    )
    begin {
        $flags = [BindingFlags]'NonPublic, Instance'
        if ($psEditor) { $context = $psEditor.GetEditorContext() }
    }
    process {
        if ($InputObject -is [System.Management.Automation.Language.IScriptExtent]) { return $InputObject }

        if ($StartOffsetNumber) {
            $startOffset = $StartOffsetNumber
            $endOffset   = $EndOffsetNumber

            if (-not $EndOffsetNumber) {
                $endOffset = $startOffset
            }
            $scriptFile = GetScriptFile
        } else {
            if ($StartBuffer) {
                $StartLineNumber   = $StartBuffer.Line
                $StartColumnNumber = $StartBuffer.Column
                $EndLineNumber     = $EndBuffer.Line
                $EndColumnNumber   = $EndBuffer.Column
            }

            # We use the FileContext from GetEditorContext here as well, but we'd have to create a BufferRange
            # to get line text.
            if (-not $FilePath) {
                $FilePath = $context.CurrentFile.Path
            }
            $scriptFile  = GetScriptFile -Path $FilePath
            $startOffset = $scriptFile.GetOffsetAtPosition($StartLineNumber, $StartColumnNumber)
            $endOffset   = $startOffset

            $endIsSame = $EndLineNumber   -eq $StartLineNumber -and
                        $EndColumnNumber -eq $StartColumnNumber

            if (($EndLineNumber -and $EndColumnNumber) -and -not $endIsSame) {
                $endOffset = $scriptFile.GetOffsetAtPosition($EndLineNumber, $EndColumnNumber)
            }
        }

        $positionHelper = $scriptFile.ScriptAst.Extent.GetType().
            GetProperty('PositionHelper', $flags).
            GetValue($scriptFile.ScriptAst.Extent)

        [ref].Assembly.GetType('System.Management.Automation.Language.InternalScriptExtent').
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
