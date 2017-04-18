using namespace System.Management.Automation

class ModuleTransformation : ArgumentTransformationAttribute {
    [object] Transform ([EngineIntrinsics] $engineIntrinsics, [object] $inputData) {

        if ($inputData -is [psmoduleinfo]) {
            if ($engineIntrinsics.SessionState.Module.Name -eq $inputData.Name) {
                return $inputData
            }
        }

        $result = Get-Module $inputData.Name
        if ($result) {
            return $result
        }
        throw 'Unable to find module "{0}" in the current session.' -f $inputData
    }
}
class CommandTransformation : ArgumentTransformationAttribute {
    [object] Transform ([EngineIntrinsics] $engineIntrinsics, [object] $inputData) {
        return Get-Command -ListImported -Name $inputData
    }
}
