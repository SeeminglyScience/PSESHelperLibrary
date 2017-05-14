---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Find-Ast

## SYNOPSIS
Search for a ast within an ast.

## SYNTAX

### FilterScript
```
Find-Ast [-Ast <Ast>] [-FilterScript] <ScriptBlock> [-Ancestor] [-First] [<CommonParameters>]
```

### AtCursor
```
Find-Ast [-AtCursor] [<CommonParameters>]
```

## DESCRIPTION
The Find-Ast function can be used to easily find a specific ast from a starting
ast. 
By default children asts will be searched, but ancestor asts can also be
searched by specifying the "Ancestor" switch parameter.

Additionally, you can find the Ast closest to the cursor with the "AtCursor" switch
parameter.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Find-Ast { $PSItem -is [FunctionDefinitionAst] }
```

Returns all function definition asts in the ast of file currently open in the editor.

### -------------------------- EXAMPLE 2 --------------------------
```
Find-Ast {
```

$_ -is \[MemberExpressionAst\] -and
    ($_ | Find-Ast -Ancestor -First { $_ -is \[MemberExpressionAst\] })
}
Returns all nested member expressions in the file currently open in the editor.

## PARAMETERS

### -Ast
Specifies the ast to search in.

```yaml
Type: Ast
Parameter Sets: FilterScript
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -FilterScript
Specifies a ScriptBlock that returns a boolean.
Uses $PSItem and $_ like
like Where-Object.

```yaml
Type: ScriptBlock
Parameter Sets: FilterScript
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Ancestor
Specifies to search ancestors asts instead of children.

```yaml
Type: SwitchParameter
Parameter Sets: FilterScript
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -First
If specified will return only the first result.
This will be the closest
ast that matches.

```yaml
Type: SwitchParameter
Parameter Sets: FilterScript
Aliases: Closest

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AtCursor
If specified, this function will return the smallest ast that the cursor is
within.
Requires PowerShell Editor Services.

```yaml
Type: SwitchParameter
Parameter Sets: AtCursor
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.Language.Ast
You can pass asts to search to this function.

## OUTPUTS

### System.Management.Automation.Language.Ast
Asts that match the criteria will be returned to the pipeline.

## NOTES

## RELATED LINKS

