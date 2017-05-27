---
Module Name: PSESHelperLibrary
Module Guid: 95ad039d-1e7e-49ee-8ec9-dfaa0395d17e 95ad039d-1e7e-49ee-8ec9-dfaa0395d17e
Download Help Link: {{Please enter FwLink manually}}
Help Version: {{Please enter version of help manually (X.X.X.X) format}}
Locale: en-US
---

# PSESHelperLibrary Module

## Description

Module to facilitate easy manipulation of script files and editor features.

## PSESHelperLibrary Cmdlets

### [ConvertFrom-ScriptExtent](ConvertFrom-ScriptExtent.md)

Translates IScriptExtent object properties into constructors for some common PowerShell EditorServices types.

### [ConvertTo-ScriptExtent](ConvertTo-ScriptExtent.md)

Converts position and range objects from PowerShellEditorServices to ScriptExtent objects.

### [Expand-Expression](Expand-Expression.md)

The Expand-Expression function replaces text at a specified range with it's output in PowerShell. As an editor command it will expand output of selected text.

### [Expand-MemberExpression](Expand-MemberExpression.md)

The Expand-MemberExpression function creates an expression for the closest MemberExpressionAst to the cursor in the current editor context. This is mainly to assist with creating expressions to access private members of .NET classes through reflection.

### [Find-Ast](Find-Ast.md)

The Find-Ast function can be used to easily find a specific ast from a starting ast.  By
default children asts will be searched, but ancestor asts can also be searched by specifying
the "Ancestor" switch parameter.

### [Import-EditorCommand](Import-EditorCommand.md)

The Import-EditorCommand function will search the specified module for functions tagged as editor commands and register them with PowerShell Editor Services. By default, if a module is specified only exported functions will be processed. However, if this function is called from a module, and the module is specified in the "Module" parameter, the function table for the module's script scope will be processed.

Alternatively, you can specify command info objects (like those from the Get-Command cmdlet) to be processed directly.

### [Set-RuleSupression](Set-RuleSupression.md)

The Set-RuleSupression function generates a SuppressMessage attribute and inserts it into a script file. The PSScriptAnalyzer rule will be determined automatically, as well as the best place to insert the Attribute.

As an editor command it will attempt to suppress the Ast closest to the current cursor position.

### [Set-ScriptExtent](Set-ScriptExtent.md)

The Set-ScriptExtent function can insert or replace text at a specified position in a file open in PowerShell Editor Services.

You can use the Find-Ast function to easily find the desired extent.