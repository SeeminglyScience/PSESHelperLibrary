using namespace System.Management.Automation.Language
using namespace System.Collections.ObjectModel
using namespace System.Management.Automation
using namespace System.Reflection

function ImportBinderMetadata {
    [OutputType([System.Management.Automation.CommandInfo])]
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName='BySessionState')]
    param(
        # Specifies the session state to process functions from.
        [Parameter(ParameterSetName='BySessionState')]
        [ValidateNotNullOrEmpty()]
        [SessionState]
        $SessionState = $ExecutionContext.SessionState,

        # Specifies the command info objects to process.
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ParameterSetName='ByCommand')]
        [ValidateNotNullOrEmpty()]
        [CommandInfo[]]
        $Command,

        # Specifies the attribute used to target commands for additional metadata.
        [Parameter(Position=0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not ([System.Attribute].IsAssignableFrom($PSItem))) {
                throw $Strings.InvalidAttributeType
            }
            $true
        })]
        [type]
        $Attribute,

        # Specifies the type that contains that metadata to merge.
        [Parameter(Position=1, Mandatory)]
        [ValidateScript({
            $metadata = [System.Management.Automation.ParameterMetadata]::GetParameterMetadata($PSItem)

            if (-not $metadata.Count) { throw $Strings.MissingParameterMetadata }
            $true
        })]
        [type]
        $ImplementingType,

        # If specified will return the result CommandInfo to the pipeline.
        [switch]
        $PassThru
    )
    end {
        if ($PSCmdlet.ParameterSetName -eq 'BySessionState') {
            # Get the function table for the module.
            $internal = $SessionState.GetType().
                GetProperty('Internal', [BindingFlags]'Instance, NonPublic').
                GetValue($SessionState)

            $functionTable = $internal.GetType().
                GetMethod('GetFunctionTableAtScope', [BindingFlags]'Instance, NonPublic').
                Invoke($internal, @('Script'))

            $Command = $functionTable.Values
        }

        foreach ($aCommand in $Command) {
            $hasAttribute = $aCommand.ScriptBlock.Attributes.TypeId.Foreach{
                if ($PSItem) {
                    $Attribute.IsAssignableFrom($PSItem)
                }
            } -contains $true

            if ($hasAttribute) {
                $originalSessionState = $aCommand.ScriptBlock.GetType().
                    GetProperty('SessionStateInternal', [BindingFlags]'Instance, NonPublic').
                    GetValue($aCommand.ScriptBlock)

                $function = $aCommand.ScriptBlock.Ast

                $parameters = $function.Body.ParamBlock.Parameters

                $additionalParameters = $script:ImplementingAssemblies.Metadata.
                    GetType('AdditionalCommandParameters')
                $additionalParameters = $additionalParameters::GetParameterAsts($ImplementingType)

                # Don't override parameters or add duplicates.
                foreach ($parameter in $parameters) {
                    $originalName = $parameter.Name.VariablePath.UserPath
                    $null = $additionalParameters.
                            Where{   $PSItem.Name.VariablePath.UserPath -eq $originalName }.
                            ForEach{ $additionalParameters.Remove($PSItem) }
                }
                if ($parameters) {
                    [ReadOnlyCollection[ParameterAst]]$newParameters = $parameters + $additionalParameters
                } else {
                    [ReadOnlyCollection[ParameterAst]]$newParameters = $additionalParameters
                }
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
                    SetValue($newScriptBlock, $originalSessionState)
                # Replace FunctionInfo's scriptblock with ours. When the function is exported into
                # global FunctionInfo will be recreated from the scriptblock.
                $null = $aCommand.GetType().
                    GetField('_scriptBlock', [BindingFlags]'Instance, NonPublic').
                    SetValue($aCommand, $newScriptBlock)

                if ($PassThru.IsPresent) {
                    $aCommand
                }
            }
        }
    }
}
