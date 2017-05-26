using namespace System.Management.Automation.Language
using namespace Microsoft.PowerShell.EditorServices

function Set-RuleSuppression {
    <#
    .SYNOPSIS
        Adds a SuppressMessage attribute to suppress a rule violation.
    .DESCRIPTION
        The Set-RuleSupression function generates a SuppressMessage attribute and inserts it into a
        script file. The PSScriptAnalyzer rule will be determined automatically, as well as the best
        place to insert the Attribute.

        The default behavior is to attempt to suppress the Ast closest to the current cursor position,
        but you can also specify Asts to suppress.
    .INPUTS
        System.Management.Automation.Language.Ast

        You can pass Asts with violations to this function.
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> Set-RuleSuppression
        Adds a SuppressMessage attribute to suppress a rule violation.
    .EXAMPLE
        PS C:\> $propBlock = Find-Ast { $_.CommandElements -and $_.GetCommandName() -eq 'Properties' }
        PS C:\> $propBlock | Find-Ast { $_.VariablePath } | Set-RuleSuppression
        Finds all variable expressions in a psake Properties block and creates a rule suppression for
        any that have a violation.
    .NOTES
        This function does not use existing syntax markers from PowerShell Editor Services, and
        instead runs the Invoke-ScriptAnalyzer cmdlet on demand. This may create duplicate suppression
        attributes.
    #>
    [PSEditorCommand(DisplayName='Suppress PSSA Rule Violation')]
    [CmdletBinding()]
    param(
        # Specifies the Ast with a rule violation to suppress.
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
        $scriptFile = GetScriptFile $Context.CurrentFile.Path

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
