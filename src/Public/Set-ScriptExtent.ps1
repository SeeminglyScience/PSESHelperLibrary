using namespace System.Collections.Generic
using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation.Language

function Set-ScriptExtent {
    <#
    .SYNOPSIS
        Replaces text at a specified ScriptExtent object.
    .DESCRIPTION
        The Set-ScriptExtent function can insert or replace text at a specified position in a file
        open in PowerShell Editor Services.

        You can use the Find-Ast function to easily find the desired extent.
    .INPUTS
        System.Management.Automation.Language.IScriptExtent

        You can pass script extent objects to this function.  You can also pass objects with a property
        named "Extent".
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> Find-Ast { 'gci' -eq $_ } | Set-ScriptExtent -Text 'Get-ChildItem'
        Replaces all instances of 'gci' with 'Get-ChildItem'
    .EXAMPLE
        PS C:\> $manifestAst = Find-Ast { 'FunctionsToExport' -eq $_ } | Find-Ast -First
        PS C:\> $manifestAst | Set-ScriptExtent -Text (gci .\src\Public).BaseName -AsArray
        Replaces the current value of FunctionsToExport in a module manifest with a list of files
        in the Public folder as a string array literal expression.
    .EXAMPLE
        PS C:\> ConvertTo-ScriptExtent -StartOffset 100 -EndOffset 110 | Set-ScriptExtent -Text ''
        Removes existing text between offsets 100 and 110 in the current file.
    #>
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName='__AllParameterSets')]
    param(
        # Specifies the text to insert in place of the extent.  Any object can be specified, but will
        # be converted to a string before being passed to PowerShell Editor Services.
        [Parameter(Position=0, Mandatory)]
        [Alias('Value')]
        [psobject]
        $Text,

        # Specifies to insert as a single quoted string expression.
        [Parameter(Mandatory, ParameterSetName='AsString')]
        [switch]
        $AsString,

        # Specifies to insert as a single quoted string list.  The list is separated by comma and
        # new line, and will be adjusted to a hanging indent.
        [Parameter(Mandatory, ParameterSetName='AsArray')]
        [switch]
        $AsArray,

        # Specifies the extent to replace within the editor.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ElasticExtent]
        $Extent = (Find-Ast -AtCursor).Extent
    )
    begin {
        $extentList = [List[ElasticExtent]]::new()
    }
    process {
        $extentList.Add($Extent)
    }
    end {
        TryGetEditorContext


        switch ($PSCmdlet.ParameterSetName) {
            # Insert text as a single string expression.
            AsString {
                $Text = "'{0}'" -f [CodeGeneration]::EscapeSingleQuotedStringContent($Text)
            }
            # Create a string expression for each line, separated by a comma.
            AsArray {
                # Save the PSMethod info to a variable for a vain attempt at readability.
                $escape = [CodeGeneration]::EscapeSingleQuotedStringContent

                $escapedValue = $escape.Invoke($Text -join [Environment]::NewLine)

                $template = "<lines:{l | '<l>'}; separator={,<\n>}>"
                $Text     = Invoke-StringTemplate -Definition $template -Parameters @{
                    lines = $escapedValue -split '\r?\n'
                }
                if ($escapedValue.Split("`n", [StringSplitOptions]::RemoveEmptyEntries).Count -gt 1) {
                    $needsIndentFix = $true
                }
            }
        }

        foreach ($aExtent in $extentList) {
            $aText = $Text

            if ($needsIndentFix) {
                # I'd rather let PSSA handle this when there are more formatting options.
                $indentOffset = ' ' * $aExtent.StartColumnNumber
                $aText = $aText -split '\r?\n' `
                                -join ([Environment]::NewLine + $indentOffset)
            }
            # This inserts text to replace the extent and updates all other extents in the queue.
            $aExtent.SetValue($Context.CurrentFile, $aText)
        }

        # Need a new factory after every run because the logic currently can't handle
        # a single change that spans multiple segments.  So if, for example, the user
        # ran this function for multiple extents and then hit undo, we couldn't keep track.
        $null = [ElasticHelper]::instances.Remove($Context.CurrentFile.Path)
    }
}
