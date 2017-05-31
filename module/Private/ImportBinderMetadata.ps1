using namespace System.Management.Automation.Language
using namespace System.Collections.ObjectModel
using namespace System.Management.Automation
using namespace System.Reflection

function ValidateIsAttributeType {
    param($Type)
    if (-not ([System.Attribute].IsAssignableFrom($Type))) {
        throw $Strings.InvalidAttributeType
    }
    $true
}
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
        [ValidateScript({ValidateIsAttributeType $PSItem})]
        [type]
        $Attribute,

        # Specifies the parameter ast to use for additional metadata.
        [Parameter(Position=1, Mandatory)]
        [ParameterAst[]]
        $ParameterAst,

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

            # Ensure we don't try to process imported external commands (e.g. the functions from this module)
            $commands = $functionTable.Values.Where{
                $PSItem.ScriptBlock.Module.Name -eq $SessionState.Module.Name
            }
         } else {
            $commands = $Command
         }

        foreach ($aCommand in $commands) {
            $hasAttribute = $aCommand.ScriptBlock.Attributes.TypeId.Foreach{
                if ($PSItem) {
                    $Attribute.Name -eq $PSItem.Name
                }
            } -contains $true

            if ($hasAttribute) {
                $originalSessionState = $aCommand.ScriptBlock.GetType().
                    GetProperty('SessionStateInternal', [BindingFlags]'Instance, NonPublic').
                    GetValue($aCommand.ScriptBlock)

                $function = $aCommand.ScriptBlock.Ast

                # Sometimes the command's scriptblock is a child of the function definition. Need to
                # look into why that is.
                if ($function -isnot [FunctionDefinitionAst]) {
                    for ($parent = $function; $parent; $parent = $parent.Parent) {
                        if ($parent -is [FunctionDefinitionAst]) {
                            $function = $parent
                            break
                        }
                    }
                }
                $oldParamBlock = $function.Body.ParamBlock

                # Can't just cast oldParamAsts because the command could not have any other parameters.
                $newParams = [Collection[ParameterAst]]::new()
                $oldParamBlock.Parameters.ForEach{ $newParams.Add($PSItem) }

                # Don't override parameters or add duplicates.
                $ParameterAst.
                    Where{
                        $PSItem.Name.VariablePath.UserPath -notin $oldParameters.Name.VariablePath.UserPath
                    }.ForEach{
                        $newParams.Add($PSItem)
                    }
                $newParamBlock = [ParamBlockAst]::new(
                    <# extent:     #> $oldParamBlock.Extent,
                    <# attributes: #> $oldParamBlock.Attributes.ForEach('Copy') -as [AttributeAst[]],
                    <# parameters: #> $newParams.ForEach('Copy') -as [ParameterAst[]])

                $null = [ScriptBlockAst].GetProperty('ParamBlock').
                                         SetMethod.Invoke($function.Body, $newParamBlock)

                $newScriptBlock = $function.Body.GetScriptBlock()

                $null = [scriptblock].GetProperty('SessionStateInternal', [BindingFlags]'Instance, NonPublic').
                                      SetValue($newScriptBlock, $originalSessionState)
                # Replace FunctionInfo's scriptblock with ours. When the function is exported into
                # global FunctionInfo will be recreated from the scriptblock.
                $null = $aCommand.GetType().GetField('_scriptBlock', [BindingFlags]'Instance, NonPublic').
                                            SetValue($aCommand, $newScriptBlock)

                if ($PassThru.IsPresent) {
                    $aCommand
                }
            }
        }
    }
}
