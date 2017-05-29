---
external help file: PSESHelperLibrary-help.xml
online version:
schema: 2.0.0
---

# Get-Token

## SYNOPSIS

Get parser tokens from a script position.

## SYNTAX

### Extent (Default)

```powershell
Get-Token [[-Extent] <IScriptExtent>]
```

### Path

```powershell
Get-Token [-Path] <String>
```

## DESCRIPTION

The Get-Token function can retrieve tokens from a file location, current editor context, or from a ScriptExtent object. You can then use the ScriptExtent functions to manipulate the text at it's location.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
using namespace System.Management.Automation.Language
Find-Ast { $_ -is [IfStatementAst] } -First | Get-Token
```

Gets all tokens from the first IfStatementAst.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-Token | Where-Object { $_.Kind -eq 'Comment' }
```

Gets all comment tokens.

## PARAMETERS

### -Extent

Specifies the extent that a token must be within to be returned.

```yaml
Type: IScriptExtent
Parameter Sets: Extent
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Path

Specifies the path to a file to get tokens for.

```yaml
Type: String
Parameter Sets: Path
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.Management.Automation.Language.IScriptExtent

You can pass extents to get tokens from to this function. You can also pass objects that with a property named "Extent", like Ast objects from the Find-Ast function.

## OUTPUTS

### System.Management.Automation.Language.Token

## NOTES

## RELATED LINKS
