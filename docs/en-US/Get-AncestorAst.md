---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Get-AncestorAst

## SYNOPSIS
Get a parent ast of a specific ast type.

## SYNTAX

### Context
```
Get-AncestorAst -Context <EditorContext> -TargetAstType <Type> [<CommonParameters>]
```

### Ast
```
Get-AncestorAst -Ast <Ast> -TargetAstType <Type> [<CommonParameters>]
```

## DESCRIPTION
Uses the "GetAncestorAst" method of System.Management.Automation.Language.Ast to find a parent
ast of a specific type.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-AncesterAst -Context $psEditor.GetEditorContext() `
```

-TargetAstType (\[System.Management.Automation.Language.FunctionDefinitionAst\])
Returns the FunctionDefinitionAst of the function that the cursor is currently inside.

## PARAMETERS

### -Context
Specifies the current editor context.
The smallest ast closest to the current cursor
position will be used as a starting point.

```yaml
Type: EditorContext
Parameter Sets: Context
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Ast
Specifies the starting ast.

```yaml
Type: Ast
Parameter Sets: Ast
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetAstType
Specifies the type of ast to search for as an ancestor.

```yaml
Type: Type
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Management.Automation.Language.Ast
The nearest parent ast of the specified type will be returned.

## NOTES

## RELATED LINKS

