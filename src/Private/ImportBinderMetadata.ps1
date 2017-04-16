using namespace System.Management.Automation.Language
using namespace System.Collections.ObjectModel
using namespace System.Management.Automation
using namespace System.Reflection

function ImportBinderMetadata {
    [OutputType([System.Management.Automation.CommandInfo], ParameterSetName='PassThru')]
    [CmdletBinding()]
    param(
        # Specifies the attribute used to target commands for additional metadata.
        [Parameter(Position=0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            [System.Attribute].IsAssignableFrom($PSItem)
        })]
        [type]
        $Attribute,

        # Specifies the type that contains that metadata to merge.
        [Parameter(Position=1, Mandatory)]
        [ValidateScript({
            $metadata = [System.Management.Automation.ParameterMetadata]::GetParameterMetadata($PSItem)

            if (-not $metadata) { throw 'Specified type must define parameters.' }
            $true
        })]
        [type]
        $ImplementingType,

        # If specified will return the result CommandInfo to the pipeline.
        [Parameter(ParameterSetName='PassThru')]
        [switch]
        $PassThru
    )
    end {
        # Get the function table for the module.
        $internal = $ExecutionContext.SessionState.GetType().
            GetProperty('Internal', [BindingFlags]'Instance, NonPublic').
            GetValue($ExecutionContext.SessionState)

        $functionTable = $internal.GetType().
            GetMethod('GetFunctionTableAtScope', [BindingFlags]'Instance, NonPublic').
            Invoke($internal, @('Script'))


        foreach ($command in $functionTable.Values) {
            $hasAttribute = $command.ScriptBlock.Attributes.TypeId.Foreach{
                if ($PSItem) {
                    $Attribute.IsAssignableFrom($PSItem)
                }
            } -contains $true

            if ($hasAttribute) {
                $function = $command.ScriptBlock.Ast

                $parameters = $function.Body.ParamBlock.Parameters

                $additionalParameters = [AdditionalCommandParameters]::GetParameterAsts($ImplementingType)

                # Don't override parameters or add duplicates.
                foreach ($parameter in $parameters) {
                    $originalName = $parameter.Name.VariablePath.UserPath
                    $null = $additionalParameters.
                            Where{   $PSItem.Name.VariablePath.UserPath -eq $originalName }.
                            ForEach{ $additionalParameters.Remove($PSItem) }
                }

                [ReadOnlyCollection[ParameterAst]]$newParameters = $parameters + $additionalParameters
                # Parameters are cached in a few places, so we need to set it multiple times.
                $null = $function.Body.ParamBlock.GetType().
                    GetMethod('set_Parameters', [BindingFlags]'Instance, NonPublic').
                    Invoke($function.Body.ParamBlock, @(,$newParameters))

                $null = $function.GetType().
                    GetMethod('set_Parameters', [BindingFlags]'Instance, NonPublic').
                    Invoke($function, @(,$newParameters))

                # Create a new scriptblock from the ast.
                $newScriptBlock = [scriptblock].InvokeMember(
                    <# name:       #> '',
                    <# invokeAttr: #> [BindingFlags]'CreateInstance, Instance, NonPublic',
                    <# binder:     #> $null,
                    <# target:     #> $null,
                    <# args:       #> @(
                        <# ast:      #> $function,
                        <# isFilter: #> $false
                    )
                )
                $null = [scriptblock].
                    GetProperty('SessionStateInternal', [BindingFlags]'Instance, NonPublic').
                    SetValue($newScriptBlock, $internal)
                # Replace FunctionInfo's scriptblock with ours. When the function is exported into
                # global FunctionInfo will be recreated from the scriptblock.
                $null = $command.GetType().
                    GetField('_scriptBlock', [BindingFlags]'Instance, NonPublic').
                    SetValue($command, $newScriptBlock)

                if ($PassThru.IsPresent) {
                    $command
                }
            }
        }
    }
}
