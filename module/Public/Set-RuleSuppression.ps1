using namespace System.Management.Automation.Language
using namespace Microsoft.PowerShell.EditorServices

function Set-RuleSuppression {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [PSEditorCommand(DisplayName='Suppress PSSA Rule Violation')]
    [CmdletBinding(HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/Set-RuleSuppression.md')]
    param(
        [Parameter(Position=0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast[]]
        $Ast = (Find-Ast -AtCursor)
    )
    begin {
        function GetAttributeTarget {
            param(
                [System.Management.Automation.Language.Ast]
                $SubjectAst
            )
            if (-not $Ast) { return }
            $splat = @{
                Ast   = $SubjectAst
                First = $true
            }

            # Attribute can go right on top of variable expressions.
            if ($SubjectAst.VariablePath -or (Find-Ast @splat -Ancestor { $_.VariablePath })) {
                return $SubjectAst
            }

            $splat.FilterScript = { $PSItem.ParamBlock }
            # This isn't a variable expression so we need to find the closest param block.
            if ($scriptBlockAst = Find-Ast @splat -Ancestor) { return $scriptBlockAst.ParamBlock }

            # No param block anywhere in it's ancestry so try to find a physically close param block
            if ($scriptBlockAst = Find-Ast @splat -Before) { return $scriptBlockAst.ParamBlock }

            # Check if part of a method definition in a class.
            $splat.FilterScript = { $PSItem -is [FunctionMemberAst] }
            if ($methodAst = Find-Ast @splat -Ancestor) { return $methodAst }

            # Check if part of a class period.
            $splat.FilterScript = { $_ -is [TypeDefinitionAst] }
            if ($classAst = Find-Ast @splat -Ancestor) { return $classAst}

            # Give up and just create it above the original ast.
            return $SubjectAst
        }
        $astList = [System.Collections.Generic.List[Ast]]::new()
    }
    process {
        if ($Ast) {
            $astList.AddRange($Ast)
        }
    }
    end {
        if (-not $Context) {
            ThrowError -Exception ([InvalidOperationException]::new($Strings.MissingEditorContext)) `
                       -Id        MissingEditorContext `
                       -Category  InvalidOperation
        }
        $scriptFile = [EditorServicesUtil]::GetScriptFile()

        $markers = Invoke-ScriptAnalyzer -Path $Context.CurrentFile.Path

        $extentsToSuppress = [System.Collections.Generic.List[psobject]]::new()
        foreach ($aAst in $astList) {
            # Get the closest valid ast that can be assigned an attribute.
            $target = GetAttributeTarget $aAst

            foreach ($marker in $markers) {
                $isWithinMarker = $aAst.Extent.StartOffset -ge $marker.Extent.StartOffset -and
                                  $aAst.Extent.EndOffset   -le $marker.Extent.EndOffset

                if (-not $isWithinMarker) { continue }

                # FilePosition gives us some nice methods for indent aware navigation.
                $position = [FilePosition]::new($scriptFile, $target.Extent.StartLineNumber, 1)

                # GetLineStart puts us at the first non-whitespace character, which we use to get indent level.
                $indentOffset = ' ' * ($position.GetLineStart().Column - 1)

                $string = '{0}{1}[System.Diagnostics.CodeAnalysis.SuppressMessage(''{2}'', '''')]' -f
                    [Environment]::NewLine, $indentOffset, $marker.RuleName

                # AddOffset is line/column based, and will throw if you try to move to a column where
                # there is no text.
                $extent = $position.AddOffset(-1, ($position.Column - 1) * -1).GetLineEnd() |
                    ConvertTo-ScriptExtent
                $extentsToSuppress.Add([PSCustomObject]@{
                    Extent     = $extent
                    Expression = $string
                })
            }
        }
        # Need to pass extents all at once to Set-ScriptExtent for position tracking.
        $extentsToSuppress | Group-Object -Property Expression | ForEach-Object {
            $PSItem.Group.Extent | Set-ScriptExtent -Text $PSItem.Name
        }
    }
}
