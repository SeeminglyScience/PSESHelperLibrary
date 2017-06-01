using namespace System.Collections.Generic
using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation.Language

function Set-ScriptExtent {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [CmdletBinding(PositionalBinding=$false,
                   DefaultParameterSetName='__AllParameterSets',
                   HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/.md')]
    param(
        [Parameter(Position=0, Mandatory)]
        [Alias('Value')]
        [psobject]
        $Text,

        [Parameter(Mandatory, ParameterSetName='AsString')]
        [switch]
        $AsString,

        [Parameter(Mandatory, ParameterSetName='AsArray')]
        [switch]
        $AsArray,

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
        $context = [EditorServicesUtil]::GetContext()

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
                $indentOffset = ' ' * ($aExtent.StartColumnNumber - 1)
                $aText = $aText -split '\r?\n' `
                                -join ([Environment]::NewLine + $indentOffset)
            }
            # This inserts text to replace the extent and updates all other extents in the queue.
            $aExtent.SetValue($context.CurrentFile, $aText)
        }

        # Need a new factory after every run because the logic currently can't handle
        # a single change that spans multiple segments.  So if, for example, the user
        # ran this function for multiple extents and then hit undo, we couldn't keep track.
        $null = [ElasticHelper]::instances.Remove($context.CurrentFile.Path)
    }
}
