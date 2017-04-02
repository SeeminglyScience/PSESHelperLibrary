function Expand-MemberExpression {
    <#
    .SYNOPSIS
        Builds an expression for accessing or invoking a member through reflection.
    .DESCRIPTION
        Creates an expression for the closest MemberExpressionAst to the cursor in the current editor
        context. This is mainly to assist with creating expressions to access private members of
        .NET classes through reflection.

        The expression is created using string templates.  There are templates for several ways of
        accessing members including InvokeMember, GetProperty/GetValue, and a more verbose
        GetMethod/Invoke.  If using the GetMethod/Invoke template it will automatically build type
        expressions for the "types" argument including nonpublic and generic types. If a template
        is not specified, this function will attempt to determine the most fitting template.  If you
        have issues invoking a method with the default, try the VerboseInvokeMethod template.

        Currently this only works with expressions on type literals (i.e. [string]) and will not work
        with variables.  Even if a type cannot typically be resolved with a type literal, this function
        will still work (e.g. [System.Management.Automation.SessionStateScope].SetFunction() will
        still resolve)
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
    [CmdletBinding()]
    param(
        # Specifies the current editor context.
        [Parameter(Position=0)]
        [Microsoft.PowerShell.EditorServices.Extensions.EditorContext]
        $Context,

        # Specifies the name of the template to use for building this expression. Templates are stored
        # in the exported variable $PSESHLTemplates. If a template is not chosen one will be determined
        # based on member type at runtime.
        [ArgumentCompleter({ $PSESHLTemplates.MemberExpressions.Keys -like ($args[2] + '*') })]
        [ValidateScript({ $PSItem -in $PSESHLTemplates.MemberExpressions.Keys })]
        [string]
        $TemplateName
    )
    process {
        $ast = Get-AstAtCursor

        $memberExpressionAst = Get-AncestorAst -Ast $ast -TargetAstType ([System.Management.Automation.Language.MemberExpressionAst])
        if (-not $memberExpressionAst) { throw 'Unable to find a member expression ast near the current cursor location.' }

        # TODO: Add support for different expressions like variables.  Need to check if there is a
        #       method in editor services to call, or if we need to enumerate scopes.
        $typeName = $memberExpressionAst.Expression.TypeName.FullName

        if (-not $typeName) { throw 'Unable to find type name in member expression. The parent expression must be a type literal.' }

        $type       = GetType -TypeName $typeName
        $memberName = $memberExpressionAst.Member.Value -replace '^new$', '.ctor'

        # TODO: Add a better way to select an overload.

        # Returns true if member name and parameter count match.
        $predicate = {
            param($Member, $Criteria)

            $nameFilter, $argCountFilter = $Criteria

            $Member.Name -eq $nameFilter -and
            (-not $argCountFilter -or $Member.GetParameters().Count -eq $argCountFilter)
        }

        $member = $type.FindMembers(
            <# memberType:     #> 'All',
            <# bindingAttr:    #> [BindingFlags]'NonPublic, Public, Instance, Static, IgnoreCase',
            <# filter:         #> $predicate,
            <# filterCriteria: #> @($memberName, $memberExpressionAst.Arguments.Count)

            # Prioritize properties over fields and methods with smaller parameter counts.
        ) | Sort-Object -Property `
            @{Expression = { $PSItem.MemberType }; Ascending = $false},
            @{Expression = {
                if ($PSItem -is [MethodBase]) { $PSItem.GetParameters().Count }
                else { 0 }
            }}

        if ($member.Count -gt 1) { $member = $member[0] }

        if (-not $member) { throw 'Unable to find member ''{0}''.' -f $memberExpressionAst.Member.Value }

        # TODO: Is there a quick way to get editor indent settings?
        $scriptFile     = GetScriptFile
        $line           = $scriptFile.GetLine($memberExpressionAst.Extent.StartLineNumber)
        $indentOffset   = [regex]::Match($line, '^\s*').Value

        if ($TemplateName) {
            $helper = [MemberTemplateHelper]::Create($member, $TemplateName)
        } else {
            $helper = [MemberTemplateHelper]::Create($member)
        }

        $template = $PSESHLTemplates.MemberExpressions.($helper.TemplateName)

        $expression = $template -f $helper.TemplateArguments `
            -split '\r?\n' `
            -join ([Environment]::NewLine + $indentOffset)

        Set-ExtentText -Extent $memberExpressionAst.Extent -Value $expression
    }
}