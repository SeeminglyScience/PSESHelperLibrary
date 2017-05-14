using namespace System.Collections.Generic
using namespace System.Management.Automation.Language

function Expand-MemberExpression {
    <#
    .SYNOPSIS
        Builds an expression for accessing or invoking a member through reflection.
    .DESCRIPTION
        Creates an expression for the closest MemberExpressionAst to the cursor in the current editor
        context. This is mainly to assist with creating expressions to access private members of .NET
        classes through reflection.

        The expression is created using string templates.  There are templates for several ways of
        accessing members including InvokeMember, GetProperty/GetValue, and a more verbose
        GetMethod/Invoke.  If using the GetMethod/Invoke template it will automatically build type
        expressions for the "types" argument including nonpublic and generic types. If a template
        is not specified, this function will attempt to determine the most fitting template.  If you
        have issues invoking a method with the default, try the VerboseInvokeMethod template.

        This function currently works on member expressions attached to the following:

        1. Type literal expressions (including invalid expressions with non public types)

        2. Variable expressions where the variable exists within a currently existing scope.

        3. Any other scenario where standard completion works.

        4. Any number of nested member expressions where one of the above is true at some point in
           the chain. Additionally chains may break if a member returns a type that is too generic
           like System.Object or a vague interface.
    .INPUTS
        None
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> Expand-MemberExpression
        Expands the member expression closest to the cursor in the current editor context using an
        automatically determined template.
    .EXAMPLE
        PS C:\> Expand-MemberExpression -Template VerboseInvokeMethod
        Expands the member expression closest to the cursor in the current editor context using the
        VerboseInvokeMethod template.
    #>
    [PSEditorCommand(DisplayName='Expand Member Expression')]
    [CmdletBinding()]
    param(
        # Specifies the member expression ast (or child of) to expand.
        [Parameter(Position=1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast]
        $Ast = (Find-Ast -AtCursor),

        # Specifies the name of the template to use for building this expression. Templates are stored
        # in the exported variable $PSESHLTemplates. If a template is not chosen one will be determined
        # based on member type at runtime.
        [ArgumentCompleter({ $PSESHLTemplates.MemberExpressions.Keys -like ($args[2] + '*') })]
        [ValidateScript({ $PSItem -in $PSESHLTemplates.MemberExpressions.Keys })]
        [string]
        $TemplateName
    )
    process {
        function toCamelCase ([Parameter(ValueFromPipeline=$true)][string]$String) {
            process {
                if ($String) {
                    $String -replace '^\w', $String.SubString(0,1).ToLower()
                }
            }
        }

        $targetAstType = [MemberExpressionAst]
        $memberExpressionAst = $Ast

        if ($memberExpressionAst -isnot $targetAstType) {

            $memberExpressionAst = $Ast | Find-Ast { $PSItem -is $targetAstType } -Ancestor -First

            if ($memberExpressionAst -isnot $targetAstType) {
                ThrowError -Exception ([InvalidOperationException]::new($Strings.MissingMemberExpressionAst)) `
                           -Id        MissingMemberExpressionAst `
                           -Category  InvalidOperation `
                           -Target    $Ast `
                           -Show
            }
        }
        [Stack[ExtendedMemberExpressionAst]]$expressionAsts = $memberExpressionAst
        if ($memberExpressionAst.Expression -is $targetAstType) {
            for ($nested = $memberExpressionAst.Expression; $nested; $nested = $nested.Expression) {
                try {
                    $expressionAsts.Push($nested)
                } catch { break }
            }
        }
        [List[string]]$expressions = @()
        while ($expressionAsts.Count -and ($current = $expressionAsts.Pop())) {

            # Throw if we couldn't find member information at any point.
            if (-not $current.InferredMember) {
                ThrowError -Exception ([MissingMemberException]::new($current.Expression, $current.Member.Value)) `
                           -Id        MissingMember `
                           -Category  InvalidResult `
                           -Target    $Ast `
                           -Show
            }

            switch ($current.Expression) {
                { $PSItem -is [MemberExpressionAst] } {
                    $variable = $PSItem.InferredMember.Name -replace
                        '^\.ctor$', $PSItem.InferredMember.ReflectedType.Name |
                        toCamelCase
                }
                { $PSItem -is [VariableExpressionAst] } {
                    $variable = $PSItem.VariablePath.UserPath
                }
                { $PSItem -is [TypeExpressionAst] } {
                    $source = [TypeExpressionHelper]::Create($current.InferredMember.ReflectedType)
                    $target = '$null'
                }
            }
            if ($variable) {
                $target = '${0}' -f $variable

                # We don't want to build out reflection expressions for public members so we chain
                # them together in one of the expressions.
                while ($current.IsPublic -and $expressionAsts.Count) {
                    $target += '.{0}' -f $current.InferredMember.Name

                    if ($current.InferredMember.MemberType -eq 'Method') {
                        $target += '({0})' -f $current.Arguments.Extent.Text
                    }
                    $current = $expressionAsts.Pop()
                }
                $source = '{0}.GetType()' -f $target
            }
            # Add the assignment, mainly to facilitate recursive member expression expansion.
            $source = '${0} = {1}' -f ($current.InferredMember.Name -replace
                '^\.ctor$', $current.InferredMember.ReflectedType.Name |
                toCamelCase), $source

            $helper = [MemberTemplateHelper]::Create($current.InferredMember)
            $helper.source = $source
            $helper.target = $target

            $shouldUseParameterless = -not $current.IsOverload      -and
                                      -not $TemplateName            -and
                                      -not $helper.memberArguments  -and
                                      $current.InferredMember.MemberType -in 'Constructor', 'Method'
            if ($shouldUseParameterless) {
                $helper.TemplateName = 'ParameterlessInvoke'
            }
            # Only use the specified template if this is the top level expression.
            if (-not $expressionAsts.Count -and $TemplateName) {
                $helper.TemplateName = $TemplateName
            }

            if ($psEditor) {
                $scriptFile     = GetScriptFile
                $line           = $scriptFile.GetLine($memberExpressionAst.Extent.StartLineNumber)
                $indentOffset   = [regex]::Match($line, '^\s*').Value
            }

            $expression = $helper.ToString() `
                -split '\r?\n' `
                -join ([Environment]::NewLine + $indentOffset) `
                -replace '\t', '    '

            $expressions.Add($expression)
        }
        if ($psEditor) {
            Set-ExtentText -Extent $memberExpressionAst.Extent `
                           -Value  ($expressions -join (,[Environment]::NewLine * 2))
        } else {
            $expressions -join (,[Environment]::NewLine * 2)
        }
    }
}
