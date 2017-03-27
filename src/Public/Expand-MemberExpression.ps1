function Expand-MemberExpression {
    <#
    .SYNOPSIS
        Builds the expression for accessing a member through reflection.
    .DESCRIPTION
        Builds the expression for accessing a member through reflection.
    .INPUTS
        None
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> Expand-MemberExpression
        Builds the expression for accessing a member through reflection.
    #>
    [CmdletBinding()]
    param()
    begin {
        function getType ([Parameter(ValueFromPipeline)][string] $TypeName) {
            process {
                $type = $TypeName -as [type]
                # If implicit casting doesn't work then it's probably a non public type.  To get the type
                # without knowing what assembly it came from we have to search all of them.  FYI this is a lot
                # faster then it looks.
                if (-not $type) {
                    $type = [AppDomain]::CurrentDomain.
                        GetAssemblies().
                        GetTypes().
                        Where{ $PSItem.ToString() -match "$typeName$" }[0]
                }
                # TODO: Pull using statements from the ast to catch some edge cases.
                if (-not $type) { throw 'Unable to find type ''{0}''.' -f $typeName }
                $type
            }
        }
        function getTypeExpression ([type] $Type) {
            # If type is not public it can't be called with a type literal expression. The "best" way
            # I know of is to use a type with the same assembly (and preferably a short name), then
            # use that to get the assembly and invoke GetType.

            # TODO: Add support for generic types with nonpublic type arguments. Example case is the
            #       functionFactory parameter on SessionStateScope.SetFunction().  Need to use the
            #       MakeGenericType() method.
            if (-not $Type.IsPublic) {
                $assembly = $Type.Assembly
                $accelerators = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
                $choices = $accelerators.GetEnumerator().
                    Where{ $PSItem.Value.Assembly -eq $assembly }.Key

                if (-not $choices) {
                    $choices = $assembly.GetTypes().ToString()
                }

                $typeName = ($choices | Sort-Object -Property Length)[0]

                return '[{0}].Assembly.GetType(''{1}'')' -f $typeName, $Type.ToString()
            }
            '[{0}]' -f $Type.ToString()
        }
    }
    process {
        $ast = Get-AstAtCursor

        if ($memberExpressionAst = Get-AncestorAst -Ast $ast -TargetAstType ([System.Management.Automation.Language.InvokeMemberExpressionAst])) {
            $isMethodOrConstructor = $true
        } else {
            $memberExpressionAst = Get-AncestorAst -Ast $ast -TargetAstType ([System.Management.Automation.Language.MemberExpressionAst])
        }
        if (-not $memberExpressionAst) { throw 'Unable to find a member expression ast near the current cursor location.' }

        $typeName = $memberExpressionAst.Expression.TypeName.FullName

        # TODO: Add support for different expressions like variables.  Need to create a CompletionContext
        #       to use the GetInferredType method.
        if (-not $typeName) { throw 'Unable to find type name in member expression. The parent expression must be a type literal.' }

        $type = getType -TypeName $typeName

        if ($isMethodOrConstructor) {
            if ($memberExpressionAst.Member.Value -eq 'new') {
                $members = $type.GetConstructors([BindingFlags]'NonPublic,Public,Instance,Static,IgnoreCase')
            } else {
                $methods = $type.GetMethods([BindingFlags]'NonPublic,Public,Instance,Static,IgnoreCase')
                $members = $methods.Where{ $PSItem.Name -eq $memberExpressionAst.Member.Value }
            }

            <#
                Check for overloads based on the following:

                -   If there is one argument and it is a int, check for members with a matching
                    amount of parameters.

                -   If arguments is an array of type objects, check for matching parameter types.

                -   If there are no arguments, check for a member with no parameters, else pick the
                    first result.
            #>
            if ($memberExpressionAst.Arguments) {

                $arguments = $memberExpressionAst.Arguments
                # StaticType comes out as a RuntimeType which doesn't work with -is.
                if ($arguments.Count -eq 1 -and $arguments.StaticType.Name -eq 'Int32') {

                    $member = $members.Where{ $PSItem.GetParameters().Count -eq $arguments.Value }[0]

                } elseif ($arguments.TypeName) {

                    $argumentTypes = ($arguments.TypeName | getType) -as [type[]]
                    $member = $members.Where{-not (
                        Compare-Object -ReferenceObject  $PSItem.GetParameters().ParameterType `
                                       -DifferenceObject $argumentTypes
                    )}
                }
            } else {
                $member = $members.Where{ -not $PSItem.GetParameters().Count }[0]

                if (-not $member) { $member = $members[0] }
            }
        } else {
            $properties = $type.GetProperties([BindingFlags]'NonPublic,Public,Instance,Static,IgnoreCase')
            $member     = $properties.Where{ $PSItem.Name -eq $memberExpressionAst.Member.Value }[0]

            if (-not $member) {
                $fields = $type.GetFields([BindingFlags]'NonPublic,Public,Instance,Static,IgnoreCase')
                $member = $fields.Where{ $PSItem.Name -eq $memberExpressionAst.Member.Value }[0]
            }
        }
        if (-not $member) { throw 'Unable to find member ''{0}''.' -f $memberExpressionAst.Member.Value }

        if ($member.IsStatic) {
            $expression       = [System.Text.StringBuilder]::new("[$typeName].").AppendLine()
            $staticOrInstance = 'Static'
        } else {
            $expression       = [System.Text.StringBuilder]::new('$targetHere.GetType().').AppendLine()
            $staticOrInstance = 'Instance'
        }

        # TODO: Is there a quick way to get editor indent settings?
        $scriptFile   = GetScriptFile
        $line         = $scriptFile.GetLine($memberExpressionAst.Extent.StartLineNumber)
        $indent       = '    '
        $indentOffset = [regex]::Match($line, '^\s*').Value + $indent

        # Add getter method (e.g. GetMethod, GetProperty, etc)
        $expression.
            Append($indentOffset).
            Append('Get').
            Append($member.MemberType).
            AppendLine('(').
            Append($indentOffset + $indent) | Out-Null

        # Only add the name parameter if not a constructor because GetConstructor doesn't have it.
        if ($member.MemberType -ne 'Constructor') {
            $expression.
                Append("<# name: #> '").
                Append($member.Name).
                AppendLine("',").
                Append($indentOffset + $indent) | Out-Null
        }

        # I can't think of why you would use this for public members, but I'd rather not hard code
        # NonPublic in just in case.
        if ($member.IsPublic) {
            $privateOrPublic = 'Public'
        } else {
            $privateOrPublic = 'NonPublic'
        }
        $expression.
            Append("<# bindingAttr: #> [System.Reflection.BindingFlags]'").
            Append($privateOrPublic).
            Append(', ').
            Append($staticOrInstance).
            Append("'") | Out-Null

        if ($isMethodOrConstructor)  {
            $expression.
                AppendLine(',').
                Append($indentOffset + $indent).
                AppendLine('<# binder: #> $null,').
                Append($indentOffset + $indent).
                Append('<# types: #> ') | Out-Null

            # If the method has parameters make a type[] object with the parameter types for
            # the 'types' parameter.
            $parameters = $member.GetParameters()
            if ($parameters) {
                $expression.Append('(') | Out-Null
                for ($i = 0; $i -lt $parameters.Count; $i++) {

                    $expression.Append((getTypeExpression -Type $parameters[$i].ParameterType)) | Out-Null

                    if ($i -eq ($parameters.Count - 1)) {
                        $expression.AppendLine(' -as [type[]]),') | Out-Null
                    } else {
                        $expression.Append(', ') | Out-Null
                    }
                }
            } else {
                $expression.AppendLine('[type[]]::new(0),') | Out-Null
            }
            $expression.
                Append($indentOffset + $indent).
                Append('<# modifiers: #> ').
                AppendLine($member.GetParameters().Count).
                Append($indentOffset).
                Append(').Invoke(') | Out-Null

            # Add the target parameter to invoke if this isn't a constructor.  If static make it null,
            # if instance make it a placeholder variable. Also start the arguments variable with a
            # starting array tag.
            if ($member.MemberType -eq 'Constructor') {
                $expression.Append('@(') | Out-Null
            } else {
                if ($member.IsStatic) {
                    $expression.Append('$null, @(') | Out-Null
                } else {
                    $expression.Append('$targetHere, @(') | Out-Null
                }
            }

            # Add each parameter along with a placeholder $null variable.  If no parameters, then
            # just close the tag.
            if ($parameters) {
                $expression.AppendLine() | Out-Null
                for ($i = 0; $i -lt $parameters.Count; $i++) {
                    $expression.
                        Append($indentOffset + $indent).
                        Append("<# ").
                        Append($parameters[$i].Name).
                        Append(': #> $null') | Out-Null

                    if ($i -eq ($parameters.Count - 1)) {
                        $expression.AppendLine().
                            Append($indentOffset).
                            Append('))') | Out-Null
                    } else {
                        $expression.AppendLine(',') | Out-Null
                    }
                }
            } else {
                $expression.AppendLine('))') | Out-Null
            }

        # TODO: Check if expression is in an assignment and switch GetValue to SetValue if applicable.
        } else { $expression.Append($indentOffset).AppendLine(').GetValue($targetHere)') | Out-Null }

        Set-ExtentText -Extent $memberExpressionAst.Extent -Value ($expression.ToString())
    }
}