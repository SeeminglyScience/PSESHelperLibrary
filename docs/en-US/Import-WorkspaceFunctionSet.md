---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Import-WorkspaceFunctionSet

## SYNOPSIS
Loads all modules, functions and type definitions from all files in the workspace into the
top level session state.

## SYNTAX

```
Import-WorkspaceFunctionSet [<CommonParameters>]
```

## DESCRIPTION
Recursively searches all files in the current workspace for FunctionDefinitionAst's,
TypeDefinitionAst's, and psd1 files (with exported commands) and loads them into the top
level session state.

The variable $PSESHLExcludeFromFileReferences can be used to exclude files.

This is mainly intended to be a temporary workaround for cross module intellisense until
PowerShellEditorServices has better symbol tracking for larger projects.

This will not be loaded automatically unless placed in the $profile used by the editor.
However, care should be taken before adding to your profile.
This is *very likely* to cause
issues with debugging.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Import-WorkspaceFunctionSet
```

Loads all commands in the current workspace.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS

