using namespace System.Management.Automation

class ModuleTransformation : ArgumentTransformationAttribute {
    [object] Transform ([EngineIntrinsics] $engineIntrinsics, [object] $inputData) {

        if ($inputData -is [psmoduleinfo]) {
            if ($engineIntrinsics.SessionState.Module.Name -eq $inputData.Name) {
                return $inputData
            } elseif ($result = Get-Module $inputData.Name) {
                return $result
            }
        }
        if ($result = Get-Module $inputData) {
            return $result
        }
        throw $script:Strings.CannotFindModule -f $inputData
    }
}
class CommandTransformation : ArgumentTransformationAttribute {
    [object] Transform ([EngineIntrinsics] $engineIntrinsics, [object] $inputData) {
        return Get-Command -ListImported -Name $inputData
    }
}
