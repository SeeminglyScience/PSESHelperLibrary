---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Set-ExtentText

## SYNOPSIS
Replaces text at a specified IScriptExtent object.

## SYNTAX

```
Set-ExtentText [[-Extent] <IScriptExtent>] [-Value] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
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
    Set-ExtentText -Value 'Get-ChildItem'

Replaces all instances of 'get-childitem' with 'Get-ChildItem'

## PARAMETERS

### -Extent
{{Fill Extent Description}}

```yaml
Type: IScriptExtent
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: (Get-AstAtCursor).Extent
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Value
{{Fill Value Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
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

