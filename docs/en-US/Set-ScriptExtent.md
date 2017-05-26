---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Set-ScriptExtent

## SYNOPSIS
Replaces text at a specified IScriptExtent object.

## SYNTAX

### __AllParameterSets (Default)
```
Set-ScriptExtent [-Text] <PSObject> [-Extent <ElasticExtent>] [<CommonParameters>]
```

### AsString
```
Set-ScriptExtent [-Text] <PSObject> [-AsString] [-Extent <ElasticExtent>] [<CommonParameters>]
```

### AsArray
```
Set-ScriptExtent [-Text] <PSObject> [-AsArray] [-Extent <ElasticExtent>] [<CommonParameters>]
```

## DESCRIPTION
Uses the PowerShell EditorServices API to replace text an extent.
ScriptExtent objects can
be found as a property on any object inherited from System.Management.Automation.Language.Ast.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$psEditor.GetEditorContext().CurrentFile.Tokens |
```

Where-Object Text -ceq 'get-childitem' |
    Set-ScriptExtent -Text 'Get-ChildItem'

Replaces all instances of 'get-childitem' with 'Get-ChildItem'

## PARAMETERS

### -Text
Specifies the text to insert in place of the extent.  Any object can be specified, but will
be converted to a string before being passed to PowerShell Editor Services.```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: Value

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsString
Specifies to insert as a single quoted string expression.```yaml
Type: SwitchParameter
Parameter Sets: AsString
Aliases: 

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsArray
Specifies to insert as a single quoted string list.  The list is separated by comma and
new line, and will be adjusted to a hanging indent.```yaml
Type: SwitchParameter
Parameter Sets: AsArray
Aliases: 

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Extent
{{Fill Extent Description}}

```yaml
Type: ElasticExtent
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: (Find-Ast -AtCursor).Extent
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.Language.IScriptExtent
You can pass script extent objects to this function.  You can also pass objects with a property
named "Extent".

## OUTPUTS

### None

## NOTES

## RELATED LINKS

