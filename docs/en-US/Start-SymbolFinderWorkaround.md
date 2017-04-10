---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Start-SymbolFinderWorkaround

## SYNOPSIS
Once started update file reference list to include all workspace files when a text document
is opened.

## SYNTAX

```
Start-SymbolFinderWorkaround [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Define a class that replaces the DidOpenTextDocumentNotification event handler in the
PowerShellEditorServices language server. 
The replacement method will update the file
ReferencedFiles field to include all files in the current workspace and call the original
method.

This is mainly intended to be a temporary workaround for cross module intellisense until
PowerShellEditorServices has better symbol tracking for larger projects.

This will not be loaded automatically unless placed in the $profile used by the editor.
However, care should be taken before adding to your profile.
This is likely to cause issues
with debugging.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Start-SymbolFinderWorkaround
```

Starts workspace wide symbol tracking for the session.

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

