---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Expand-Expression

## SYNOPSIS
Replaces an extent with the return value of it's text as an expression.

## SYNTAX

```
Expand-Expression [[-Context] <EditorContext>] [-InputObject <IScriptExtent[]>] [<CommonParameters>]
```

## DESCRIPTION
Creates and invokes a scriptblock from the text at the specified extent. 
The output is
then converted to a string object using the "Out-String" cmdlet and used to set the text at
the extent.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$psEditor.GetEditorContext().SelectedRange | ConvertTo-ScriptExtent | Expand-Expression
```

Invokes the currently selected text and replaces it with it's output.
This is also the default.

## PARAMETERS

### -Context
Specifies the current editor context.
This parameter is required by PSES to register as
an EditorCommand.

```yaml
Type: EditorContext
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Specifies the extent to invoke.

```yaml
Type: IScriptExtent[]
Parameter Sets: (All)
Aliases: Extent

Required: False
Position: Named
Default value: ($psEditor.GetEditorContext().SelectedRange | ConvertTo-ScriptExtent)
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.Language.IScriptExtent
You can pass extents to invoke from the pipeline.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

