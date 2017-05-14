using namespace System.Management.Automation.Language
using namespace System.Management.Automation
using namespace System.Collections.ObjectModel
using namespace System.Reflection

class AdditionalCommandParameters {
    AdditionalCommandParameters () {}

    static [Collection[ParameterAst]] GetParameterAsts ([type] $type) {
        if ([AdditionalCommandParameters].IsAssignableFrom($type)) {
            $instance = $type::new()
            return $instance.GetParameterAsts()
        } else {
            throw $script:Strings.InvalidMetadataType
        }
    }
    [Collection[ParameterAst]] GetParameterAsts () {
        $result   = [Collection[ParameterAst]]::new()
        $metadata = [ParameterMetadata]::GetParameterMetadata($this.GetType())

        foreach ($property in $metadata.GetEnumerator()) {
            $proxyExpression =  'param('
            $proxyExpression += $property.Value.GetType().InvokeMember(
                <# name:       #> 'GetProxyParameterData',
                <# invokeAttr: #> [BindingFlags]'InvokeMethod, Instance, NonPublic',
                <# binder:     #> $null,
                <# target:     #> $property.Value,
                <# args:       #> @(
                    <# prefix:            #> [Environment]::NewLine,
                    <# paramNameOverride: #> $property.Key,
                    <# isProxyForCmdlet:  #> $false
                )
            )
            $proxyExpression += ')'

            $ast = [Parser]::ParseInput($proxyExpression, [ref]$null, [ref]$null).
                Find({ $args[0] -is [ParameterAst] }, $false)

            $result.Add($ast)
        }
        return $result
    }
}
# Initally I had these two classes in separate files but it causes null reference errors for some reason.
class EditorCommandParameters : AdditionalCommandParameters {
    [Parameter(ParameterSetName='__AllParameterSets')]
    [ValidateNotNullOrEmpty()]
    [Microsoft.PowerShell.EditorServices.Extensions.EditorContext]
    $Context;
}
