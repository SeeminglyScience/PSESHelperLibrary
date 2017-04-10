---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Update-FileReferenceList

## SYNOPSIS
Adds all files in the current workspace to the list of referenced files for all currently
open script files.

## SYNTAX

```
Update-FileReferenceList [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function is mainly intended to be ran automatically by the Start-SymbolFinderWorkaround
function. 
It can however be ran manually for temporary workspace wide symbol support as an
alternative for those who do not want to override EditorServices private methods.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Update-FileReferenceList
```

Updates the referenced files list for all currently open script files.

## PARAMETERS

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

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

