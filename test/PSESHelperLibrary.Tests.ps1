$moduleName = 'PSESHelperLibrary'
$moduleManifestPath = "$PSScriptRoot\..\src\$moduleName.psd1"

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $moduleManifestPath | should not beNullOrEmpty
    }
}
