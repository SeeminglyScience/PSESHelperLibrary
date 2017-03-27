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
Description = 'Helper functions for PowerShell Editor Services.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Start-SymbolFinderWorkaround',
                    'Import-WorkspaceFunctionSet',
                    'Update-FileReferenceList',
                    'ConvertFrom-ScriptExtent',
                    'ConvertTo-SubExpression',
                    'Expand-MemberExpression',
                    'ConvertTo-ScriptExtent',
                    'Expand-Expression',
                    'Get-ScriptExtent',
                    'Get-AncestorAst',
                    'Set-ExtentText'


# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = 'PSESHLExcludeFromFileReferences'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# List of all files packaged with this module
FileList =  'Public\Start-SymbolFinderWorkaround.ps1',
            'Public\Import-WorkspaceFunctionSet.ps1',
            'Public\Update-FileReferenceList.ps1',
            'Public\ConvertFrom-ScriptExtent.ps1',
            'Public\ConvertTo-SubExpression.ps1',
            'Public\Expand-MemberExpression.ps1',
            'Public\ConvertTo-ScriptExtent.ps1',
            'Public\Expand-Expression.ps1',
            'Public\Get-ScriptExtent.ps1',
            'Public\Get-AncestorAst.ps1',
            'Public\Set-ExtentText.ps1',
            'Private\GetScriptFile.ps1',
            'Private\TestSelection.ps1'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

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


