using namespace System.Reflection

class TypeExpressionHelper {
    [type] $Type;

    hidden [bool] $encloseWithBrackets;
    hidden [bool] $needsProxy;

    TypeExpressionHelper ([type] $type) {
        $this.Type = $Type
    }
    static [string] Create ([type] $type) {
        return [TypeExpressionHelper]::Create($type, $true)
    }
    static [string] Create ([type] $type, [bool] $encloseWithBrackets) {
        $helper = [TypeExpressionHelper]::new($type)
        $helper.encloseWithBrackets = $encloseWithBrackets
        return $helper.Create()
    }
   [string] Create () {
        # Non public types can't be retrieved with a type literal expression and need to be retrieved
        # from their assembly directly. The easiest way is to get a type from the same assembly and
        # get the assembly from that. The goal here is to build it as short as possible, hopefully
        # retaining some semblance of readability.
        if (-not $this.Type.IsPublic -or $this.Type.GenericTypeArguments.IsPublic -contains $false) {
            $this.needsProxy = $true
            return $this.CreateProxy()
        }
        else {
            return $this.CreateLiteral()
        }
    }
    hidden [string] CreateProxy () {
        $builder = [System.Text.StringBuilder]::new('[')
        $assembly = $this.Type.Assembly

        # First check if there are any type accelerators in the same assembly.
        $choices = $this.GetAccelerators().GetEnumerator().Where{ $PSItem.Value.Assembly -eq $assembly }.Key

        if (-not $choices) {
            # Then as a last resort pull every type from the assembly. This takes a extra second or
            # two the first time.
            $choices = $assembly.GetTypes().ToString
        }

        $builder.
            Append(($choices | Sort-Object Length)[0]).
            Append('].Assembly.GetType(''')

        if ($this.Type.GenericTypeArguments) {
            # Using the GetType method on the full name doesn't work for every type/combination, so
            # we use the MakeGenericType method.
            return $builder.AppendFormat('{0}.{1}'').MakeGenericType(', $this.Type.Namespace, $this.Type.Name).
                Append($this.GetGenericArguments()).
                Append(')').
                ToString()
        }
        else {
            return $builder.
                AppendFormat('{0}'')', $this.Type.ToString()).
                ToString()
        }
    }
    hidden [string] CreateLiteral () {
        $builder = [System.Text.StringBuilder]::new()
        # If we are building the type name as a generic type argument in a type literal we don't want
        # to enclose it with brackets.
        if ($this.encloseWithBrackets) { $builder.Append('[') }

        if ($this.Type.GenericTypeArguments) {
            $builder.
                AppendFormat('{0}.{1}', $this.Type.Namespace, $this.Type.Name).
                Append('[').
                Append($this.GetGenericArguments()).
                Append(']')
        }
        else {
            $name = $this.GetAccelerators().
                GetEnumerator().
                Where{ $PSItem.Value -eq $this.Type }.
                Key |
                Sort-Object Length

            if (-not $name) { $name = ($this.Type.Name -as [type]).Name }
            if (-not $name) { $name = $this.Type.ToString() }

            if ($name.Count -gt 1) { $name = $name[0] }

            $builder.Append($name)
        }

        if ($this.encloseWithBrackets) { $builder.Append(']') }

        return $builder.ToString()
    }
    hidden [string] GetGenericArguments () {
        $typeArguments = $this.Type.GenericTypeArguments

        $enclose = $false
        if ($this.needsProxy) { $enclose = $true }

        return $typeArguments.ForEach{
            [TypeExpressionHelper]::Create($PSItem, $enclose)
        } -join ', '
    }
    hidden [System.Collections.Generic.Dictionary[string, type]] GetAccelerators () {
       return [ref].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
    }
}

class MemberTemplateHelper {
    [string[]] $TemplateArguments;
    [string] $TemplateName;

    hidden [string] $source;
    hidden [string] $target;
    hidden [hashtable] $valueMap;
    hidden [System.Reflection.MemberInfo] $member;
    hidden [string] $indent = '    ';

    MemberTemplateHelper ([MemberInfo] $member) {
        $this.member = $member
        $this.TemplateName = $this.GetTemplateName()
        $this.Initialize()
    }
    MemberTemplateHelper ([MemberInfo] $member, [string] $templateName) {
        $this.member = $member
        $this.TemplateName = $templateName

        if (-not $this.TemplateName) {
            $this.TemplateName = $this.GetTemplateName()
        }

        $this.Initialize()
    }
    [void] Initialize () {
        if ($this.member.IsStatic) {
            $this.source = [TypeExpressionHelper]::Create($this.member.ReflectedType)
            $this.target  = '$null'
        } else {
            $this.source = '$targetHere.GetType()'
            $this.target = '$targetHere'
        }
        $this.TemplateArguments = @(
            $this.source
            $this.GetBindingFlags()
            $this.target
            $this.GetMemberName()
            $this.GetInvokeAttribute()
            $this.GetArguments()
            $this.GetTypes()
            $this.GetArgumentCount()
            $this.GetSingleArgument()
        )
    }

    [string] GetTemplateName    () { return 'GetValue' }
    [string] GetSource          () { return '$target.GetType()' }
    [string] GetMemberName      () { return $this.member.Name }
    [string] GetInvokeAttribute () { return 'Get{0}' -f $this.member.MemberType }
    [string] GetArguments       () { return '' }
    [string] GetTypes           () { return '@()' }
    [string] GetArgumentCount   () { return '0' }
    [string] GetSingleArgument  () { return '$null' }
    [string] GetBindingFlags    () {
        return $this.member.GetType().
            GetProperty('BindingFlags', [BindingFlags]'Instance, NonPublic').
            GetValue($this.member).
            ToString()
    }

    static        [MemberTemplateHelper] Create ([MemberInfo] $member) { return [MemberTemplateHelper]::new($member) }
    hidden static [MemberTemplateHelper] Create ([MethodInfo] $member) { return [MethodTemplateHelper]::new($member) }
    hidden static [MemberTemplateHelper] Create ([ConstructorInfo] $member) { return [ConstructorTemplateHelper]::new($member) }
    static        [MemberTemplateHelper] Create ([MemberInfo] $member, [string] $templateName) { return [MemberTemplateHelper]::new($member, $templateName) }
    hidden static [MemberTemplateHelper] Create ([MethodInfo] $member, [string] $templateName) { return [MethodTemplateHelper]::new($member, $templateName) }
    hidden static [MemberTemplateHelper] Create ([ConstructorInfo] $member, [string] $templateName) { return [ConstructorTemplateHelper]::new($member, $templateName) }
}

class MethodTemplateHelper : MemberTemplateHelper {
    hidden [object[]] $arguments;

    MethodTemplateHelper ([MethodInfo] $member) : base ($member) {}
    MethodTemplateHelper ([MethodInfo] $member, [string] $templateName) : base ($member, $templateName) {}

    [string] GetInvokeAttribute () { return 'InvokeMethod' }

    [string] GetArguments () {
        $this.arguments = $this.member.GetParameters()
        $builder = [System.Text.StringBuilder]::new()

        if ($this.arguments) {
            foreach ($argument in $this.arguments) {
                $builder.
                    AppendLine().
                    Append($this.indent * 2).
                    AppendFormat('<# {0}: #> ${0},', $argument.Name)
            }
            $builder.Remove($builder.Length-1, 1).AppendLine().Append($this.indent)
        }
        return $builder.ToString()
    }
    [string] GetTypes () {
        if ($this.arguments) {
            $builder = [System.Text.StringBuilder]::new('(')
            foreach ($argument in $this.arguments) {
                $builder.
                    Append([TypeExpressionHelper]::Create($argument.ParameterType)).
                    Append(', ')
            }
            return $builder.
                Remove($builder.Length-2, 1).
                Append('-as [type[]])').ToString()
        } else {
            return '@()'
        }
    }
    [string] GetNames () { return "@('" + $this.arguments.Name -join "', '" + "')" }
    [string] GetArgumentCount () { return $this.member.GetParameters().Count }
    [string] GetTemplateName  () { return 'InvokeMember' }
}

class ConstructorTemplateHelper : MethodTemplateHelper {

    ConstructorTemplateHelper ([ConstructorInfo] $member) : base ($member) {}
    ConstructorTemplateHelper ([ConstructorInfo] $member, [string] $templateName) : base ($member, $templateName) {}

    [string] GetInvokeAttribute () { return 'CreateInstance' }
    [string] GetMemberName      () { return "''" }
}
