@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSESHelperLibrary.psm1'

# Version number of this module.
ModuleVersion = '0.1.0'

# ID used to uniquely identify this module
GUID = '95ad039d-1e7e-49ee-8ec9-dfaa0395d17e'

# Author of this module
Author = 'Patrick Meinecke'

# Copyright statement for this module
Copyright = '(c) 2017 Patrick Meinecke. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module to facilitate easy manipulation of script files and editor features.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = 'PSStringTemplate'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'ConvertFrom-ScriptExtent',
                    'Expand-MemberExpression',
                    'ConvertTo-ScriptExtent',
                    'Import-EditorCommand',
                    'Set-RuleSuppression',
                    'Expand-Expression',
                    'Get-ScriptExtent',
                    'Set-ScriptExtent',
                    'Find-Ast'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = 'PSESHLExcludeFromFileReferences'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# List of all files packaged with this module
FileList = 'Public\ConvertFrom-ScriptExtent.ps1',
           'Public\Expand-MemberExpression.ps1',
           'Public\ConvertTo-ScriptExtent.ps1',
           'Private\ImportBinderMetadata.ps1',
           'Public\Import-EditorCommand.ps1',
           'Public\Set-RuleSuppression.ps1',
           'Templates\MemberExpression.stg',
           'Private\GetInferredMember.ps1',
           'Private\GetWorkspaceFile.ps1',
           'Public\Expand-Expression.ps1',
           'Private\GetInferredType.ps1',
           'Public\Get-ScriptExtent.ps1',
           'Public\Set-ScriptExtent.ps1',
           'Private\GetScriptFile.ps1',
           'Classes\Expressions.ps1',
           'PSESHelperLibrary.psd1',
           'Classes\Attributes.ps1',
           'Private\ThrowError.ps1',
           'PSESHelperLibrary.psm1',
           'Classes\Renderers.ps1',
           'Classes\Position.ps1',
           'Public\Find-Ast.ps1',
           'Private\GetType.ps1',
           'en-US\Strings.psd1'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/SeeminglyScience/PSESHelperLibrary'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
