# This module is meant to be an example of how you can easily use PSESHL and PSES to tailor the editor
# to how you work.
# These may not work for every workflow or project stucture.

#requires -module PSESHelperLibrary
using module PSESHelperLibrary
using namespace System.Management.Automation.Language
using namespace System.Collections.Generic

# Remove semicolons that aren't part of a property definition and have a new line afterwards.
function Remove-Semicolon {
    [CmdletBinding()]
    [PSEditorCommand()]
    param()
    end {
        $propertyDefinitions = Find-Ast { $PSItem -is [PropertyMemberAst] }
        $tokens = (Get-Token).Where{ $PSItem.Extent.StartOffset + 1 -notin $propertyDefinitions.Extent.EndOffset }

        $extentsToRemove = [List[IScriptExtent]]::new()

        for ($i = 0; $i -lt $tokens.Count; $i++) {
            if ($tokens[$i].Kind -ne [TokenKind]::Semi) { continue }

            if ($tokens[$i+1].Kind -eq [TokenKind]::NewLine) {
                $extentsToRemove.Add($tokens[$i].Extent)
            }
        }
        [Linq.Enumerable]::Distinct($extentsToRemove) | Set-ScriptExtent -Text ''
    }
}

# Adds the function your cursor is currently within to FunctionsToExport and FileList.
# This is cool and I use it all the time, but it only works if you edit it for your project structure.
# This would also feel a lot more smooth if there was a way to save.
function Add-CommandToManifest {
    [CmdletBinding()]
    [PSEditorCommand(DisplayName='Add Closest Function To Manifest')]
    param()

    $commandAst = Find-Ast -AtCursor |
        Find-Ast -Ancestor -First -IncludeStartingAst { $PSItem.Name -and $PSItem.Name -match '\w+-\w+'}

    $functionName = $commandAst.Name

    $filePath = $psEditor.GetEditorContext().CurrentFile.Path

    $fileListEntry = $filePath -replace [regex]::Escape((Join-Path $psEditor.Workspace.Path 'module\'))

    [string]$manifestFile = Resolve-Path (Join-Path $psEditor.Workspace.Path 'module\*.psd1')

    $psEditor.Workspace.OpenFile($manifestFile)

    $loops = 0
    while ($psEditor.GetEditorContext().CurrentFile.Path -ne $manifestFile) {
        Start-Sleep -Milliseconds 200
        $loops++
        if ($loops -gt 10) { throw "$($psEditor.GetEditorContext().CurrentFile.Path) -ne $manifestFile" }
    }

    function GetManifestField ([string]$Name) {
        $field = Find-Ast -First { $PSItem.Value -eq $Name } | Find-Ast -First
        # This transforms a literal string array expression into it's output without invoking.
        $valueString = $field.ToString() -split   '[,\n\s]' `
                                         -replace '['',\s]' `
                                         -match   '.' `
                                         -as      [List[string]]
        # yield
        [PSCustomObject]@{
            Ast    = $field
            Extent = $field.Extent
            Value  = $valueString
        }
    }

    $functions = GetManifestField -Name FunctionsToExport
    $functions.Value.Add($functionName)
    $functions.Value.Sort({ $args[0].CompareTo($args[1]) })
    $functions.Extent | Set-ScriptExtent -Text ([Linq.Enumerable]::Distinct($functions.Value)) -AsArray

    $fileList = GetManifestField -Name FileList

    $fileList.Value.Add($fileListEntry)
    $fileList.Value.Sort({ $args[0].CompareTo($args[1]) })
    $fileList.Extent | Set-ScriptExtent -Text ([Linq.Enumerable]::Distinct($fileList.Value)) -AsArray

    $psEditor.Workspace.OpenFile($filePath)

    $loops = 0
    while ($psEditor.GetEditorContext().CurrentFile.Path -ne $filePath) {
        Start-Sleep -Milliseconds 200
        $loops++
        if ($loops -gt 10) { throw "$($psEditor.GetEditorContext().CurrentFile.Path) -ne $filePath" }
    }
}

# I'd like to put this in a pack of PS classes themed commands. Not sure how many people really use
# them though.  Also it uses Expand-MemberExpression's type resolution so it builds Assembly.GetType
# expressions even though you can't use them for type constraints.
function Expand-TypeImplementation {
    [PSEditorCommand(DisplayName='Implement Closest Type')]
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [type[]]
        $Type
    )
    begin {
        $renderer = (Get-Module PSESHelperLibrary).Invoke({ [TypeRenderer] })::new()
        $group = @'
class(FullName, Name, DeclaredMethods) ::= <<
class New<Name> : <FullName> {
    <DeclaredMethods:methods(); separator={<\n><\n>}>
}

>>
methods(m) ::= <<
<m.ReturnType> <if(m.IsStatic)>static <endif><m.Name> (<m.Parameters:params(); separator=", ">) {
    throw [NotImplementedException]::new()
}
>>
params(p) ::= "<p.ParameterType> $<p.Name>"
'@
        $group    = New-StringTemplateGroup -Definition $group
        $instance = $group.GetType().GetProperty('Instance', 60).GetValue($group)

        $instance.RegisterRenderer([type], $renderer)
    }
    process {
        $typeList
        if ($Type) {
            $targetExtent = $psEditor.GetEditorContext().CursorPosition | ConvertTo-ScriptExtent
        } else {
            $ast = Find-Ast -AtCursor |
                Find-Ast -Family -First -IncludeStartingAst { $PSItem.TypeName }

            $targetExtent = $ast.Extent

            $resolvedType = $ast.TypeName -as [type]

            if (-not $resolvedType) {
                Find-Ast {  }
            }
        }
        foreach ($aType in $Type) {
            $result = Invoke-StringTemplate -Group $group -Name class -Parameters ($Type)
        }
        Set-ExtentText -Extent $ast.Extent -Value $result
    }
}
# Orders using statements by type (assembly > module > namespace) then alphabetically
function Set-UsingStatementOrder {
    [CmdletBinding()]
    [PSEditorCommand(DisplayName='Sort Using Statements')]
    param()
    end {
        $statements = Find-Ast { $PSItem -is [UsingStatementAst] }

        $groups = $statements | Group-Object UsingStatementKind -AsHashTable -AsString

        $sorted = & {
            if ($groups.Assembly)  { $groups.Assembly  | Sort-Object Name }
            if ($groups.Module)    { $groups.Module    | Sort-Object Name }
            if ($groups.Namespace) { $groups.Namespace | Sort-Object Name }
        } | ForEach-Object -MemberName ToString

        $statements | Join-ScriptExtent | Set-ScriptExtent -Text ($sorted -join [Environment]::NewLine)
    }
}

# Doesn't check for tags so it can mess up the name there, and might also need to grab parts of the
# script that are outside all describe blocks.
function Invoke-DescribeBlock {
    [PSEditorCommand(DisplayName='Invoke Closest Describe Block')]
    [CmdletBinding()]
    param()
    end {
        $currentFile = $Context.CurrentFile.Path
        $describeBlock = Find-Ast { $PSItem -is [CommandAst] -and $PSItem.GetCommandName() -eq 'Describe' }
        $describeBlock.CommandElements.
            Where{ $PSItem.StaticType -ne ([scriptblock]) -and $PSItem.Value -ne 'Describe' }[0].
            ForEach{ Invoke-Pester -Script $currentFile -TestName $PSItem.Value }
    }
}
# Yeah replace all would do the same, but this won't touch strings or comments!
function Rename-DollarUnder {
    [CmdletBinding()]
    [PSEditorCommand(DisplayName='Replace $_ with $PSItem')]
    param()
    end {
        Find-Ast { $PSItem.VariablePath.UserPath -eq '_' } | Set-ScriptExtent -Text '$PSItem'
    }
}

Import-EditorCommand -Module $ExecutionContext.SessionState.Module

Export-ModuleMember -Function Remove-Semicolon,
                              Add-CommandToManifest,
                              Expand-TypeImplementation,
                              Set-UsingStatementOrder,
                              Invoke-DescribeBlock,
                              Rename-DollarUnder
