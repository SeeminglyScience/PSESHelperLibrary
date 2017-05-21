using namespace System.Collections.Generic
using namespace System.Management.Automation.Language
using namespace System.Reflection
using namespace Antlr4.StringTemplate.Compiler

function Expand-MemberExpression {
    <#
    .SYNOPSIS
        Builds an expression for accessing or invoking a member through reflection.
    .DESCRIPTION
        Creates an expression for the closest MemberExpressionAst to the cursor in the current editor
        context. This is mainly to assist with creating expressions to access private members of .NET
        classes through reflection, but can also be used to generate parameter name comments for public
        methods.

        The expression is created using string templates.  There are templates for several ways of
        accessing members including InvokeMember, GetProperty/GetValue, and a more verbose
        GetMethod/Invoke.  If using the GetMethod/Invoke template it will automatically build type
        expressions for the "types" argument including nonpublic and generic types. If a template
        is not specified, this function will attempt to determine the most fitting template.  If you
        have issues invoking a method with the default, try the VerboseGetMethod template.

        This function currently works on member expressions attached to the following:

        1. Type literal expressions (including invalid expressions with non public types)

        2. Variable expressions where the variable exists within a currently existing scope.

        3. Any other scenario where standard completion works.

        4. Any number of nested member expressions where one of the above is true at some point in
           the chain. Additionally chains may break if a member returns a type that is too generic
           like System.Object or a vague interface.
    .INPUTS
        System.Management.Automation.Language.Ast

        You can past MemberExpressionAsts or asts close to member expressions to this function.
    .OUTPUTS
        System.String

        This function will return the fully expanded expression as a string if used outside of
        PowerShell Editor Services.  Otherwise this function does not return output.
    .EXAMPLE
        PS C:\> Expand-MemberExpression
        Expands the member expression closest to the cursor in the current editor context using an
        automatically determined template.
    .EXAMPLE
        PS C:\> Expand-MemberExpression -Template VerboseGetMethod
        Expands the member expression closest to the cursor in the current editor context using the
        VerboseInvokeMethod template.
    .EXAMPLE
        PS C:\> Find-Ast -First { $_.Member -and -not $_.Parent.Member } | Expand-MemberExpression
        Gets the ast of the last member of the first member expression in the current file and then
        expands it.
    #>
    [PSEditorCommand(DisplayName='Expand Member Expression')]
    [CmdletBinding()]
    param(
        # Specifies the member expression ast (or child of) to expand.
        [Parameter(Position=1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast]
        $Ast = (Find-Ast -AtCursor),

        # A template is automatically chosen based on member type and visibility.  You can use
        # this parameter to force the use of a specific template.
        [ValidateSet('GetMethod', 'InvokeMember', 'VerboseGetMethod', 'GetValue', 'SetValue')]
        [string]
        $TemplateName,

        # By default expanded methods will have a comment with the parameter name on each line.
        # (e.g. <# paramName: #> $paramName,) If you specify this parameter it will be omitted.
        [switch]
        $NoParameterNameComments
    )
    begin {
        try {
            $groupSource = Get-Content -Raw $PSScriptRoot\..\Templates\MemberExpression.stg
            $group = New-StringTemplateGroup -Definition $groupSource -ErrorAction Stop

            $instance = $group.GetType().
                GetProperty('Instance', [BindingFlags]'Instance, NonPublic').
                GetValue($group)

            $renderer = [MemberExpressionRenderer]::new()
            $instance.RegisterRenderer([string], $renderer)
            $instance.RegisterRenderer([type], [TypeRenderer]::new())
        } catch {
            ThrowError -Exception ([TemplateException]::new($Strings.TemplateGroupCompileError, $null)) `
                       -Id        TemplateGroupCompileError `
                       -Category  InvalidData `
                       -Target    $PSItem
        }
}
    process {
        $memberExpressionAst = $Ast

        if ($memberExpressionAst -isnot [MemberExpressionAst]) {

            $memberExpressionAst = $Ast | Find-Ast { $PSItem -is [MemberExpressionAst] } -Ancestor -First

            if ($memberExpressionAst -isnot [MemberExpressionAst]) {
                ThrowError -Exception ([InvalidOperationException]::new($Strings.MissingMemberExpressionAst)) `
                           -Id        MissingMemberExpressionAst `
                           -Category  InvalidOperation `
                           -Target    $Ast `
                           -Show
            }
        }
        [Stack[ExtendedMemberExpressionAst]]$expressionAsts = $memberExpressionAst
        if ($memberExpressionAst.Expression -is [MemberExpressionAst]) {
            for ($nested = $memberExpressionAst.Expression; $nested; $nested = $nested.Expression) {
                if ($nested -is [MemberExpressionAst]) {
                    $expressionAsts.Push($nested)
                } else { break }
            }
        }
        [List[string]]$expressions = @()
        while ($expressionAsts.Count -and ($current = $expressionAsts.Pop())) {

            # Throw if we couldn't find member information at any point.
            if (-not ($current.InferredMember)) {
                ThrowError -Exception ([MissingMemberException]::new($current.Expression, $current.Member.Value)) `
                           -Id        MissingMember `
                           -Category  InvalidResult `
                           -Target    $Ast `
                           -Show
            }

            switch ($current.Expression) {
                { $PSItem -is [MemberExpressionAst] } {
                    $variable = $renderer.TransformMemberName($PSItem.InferredMember.Name)
                }
                { $PSItem -is [VariableExpressionAst] } {
                    $variable = $PSItem.VariablePath.UserPath
                }
                { $PSItem -is [TypeExpressionAst] } {
                    $source = $current.InferredMember.ReflectedType
                }
            }
            if ($variable) {
                $source = '${0}' -f $variable

                # We don't want to build out reflection expressions for public members so we chain
                # them together in one of the expressions.
                while (($current.InferredMember.IsPublic            -or
                        $current.InferredMember.GetMethod.IsPublic) -and
                        $expressionAsts.Count) {
                    $source += '.{0}' -f $current.InferredMember.Name

                    if ($current.InferredMember.MemberType -eq 'Method') {
                        $source += '({0})' -f $current.Arguments.Extent.Text
                    }
                    $current = $expressionAsts.Pop()
                }
            }

            if ($psEditor) {
                $scriptFile     = GetScriptFile
                $line           = $scriptFile.GetLine($memberExpressionAst.Extent.StartLineNumber)
                $indentOffset   = [regex]::Match($line, '^\s*').Value
            }

            $templateParameters = @{
                ast                  = $current
                source               = $source
                includeParamComments = -not $NoParameterNameComments
            }
            $member = $current.InferredMember

            # Automatically use the more explicit VerboseGetMethod template if building a reflection
            # statement for a method with multiple overloads with the same parameter count.
            $needsVerbose = $member -is [MethodInfo] -and -not
                            $member.IsPublic -and
                            $member.ReflectedType.GetMethods(60).Where{
                                $PSItem.Name -eq $current.InferredMember.Name -and
                                $PSItem.GetParameters().Count -eq $member.GetParameters().Count }.
                                Count -gt 1

            if ($TemplateName -and -not $expressionAsts.Count) {
                $templateParameters.template = $TemplateName
            } elseif ($needsVerbose) {
                $templateParameters.template = 'VerboseGetMethod'
            }
            $expression = Invoke-StringTemplate -Group $group -Name Main -Parameters $templateParameters
            $expressions.Add($expression)
        }

        $result = $expressions -join (,[Environment]::NewLine * 2) `
                               -split '\r?\n' `
                               -join ([Environment]::NewLine + $indentOffset)
        if ($psEditor) {
            Set-ExtentText -Extent $memberExpressionAst.Extent `
                           -Value  $result
        } else {
            $result
        }
    }
}
