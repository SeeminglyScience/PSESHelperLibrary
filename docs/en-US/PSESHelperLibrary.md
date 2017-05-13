---
Module Name: PSESHelperLibrary
Module Guid: 95ad039d-1e7e-49ee-8ec9-dfaa0395d17e 95ad039d-1e7e-49ee-8ec9-dfaa0395d17e
Download Help Link: {{Please enter FwLink manually}}
Help Version: {{Please enter version of help manually (X.X.X.X) format}}
Locale: en-US
---

# PSESHelperLibrary Module
## Description
{{Manually Enter Description Here}}

## PSESHelperLibrary Cmdlets
### [ConvertFrom-ScriptExtent](ConvertFrom-ScriptExtent.md)
Translates IScriptExtent object properties into constructors for some common PowerShell
EditorServices types.

### [ConvertTo-ScriptExtent](ConvertTo-ScriptExtent.md)
Converts position and range objects from PowerShellEditorServices to ScriptExtent objects.

### [Expand-Expression](Expand-Expression.md)
Creates and invokes a scriptblock from the text at the specified extent.
The output is
then converted to a string object using the "Out-String" cmdlet and used to set the text at
the extent.

### [Expand-MemberExpression](Expand-MemberExpression.md)
Creates an expression for the closest MemberExpressionAst to the cursor in the current editor
context.
This is mainly to assist with creating expressions to access private members of .NET
classes through reflection.

The expression is created using string templates.
There are templates for several ways of
accessing members including InvokeMember, GetProperty/GetValue, and a more verbose
GetMethod/Invoke.
If using the GetMethod/Invoke template it will automatically build type
expressions for the "types" argument including nonpublic and generic types.
If a template
is not specified, this function will attempt to determine the most fitting template.
If you
have issues invoking a method with the default, try the VerboseInvokeMethod template.

Currently this only works with expressions on type literals (i.e.
\[string\]) and will not work
with variables.
Even if a type cannot typically be resolved with a type literal, this function
will still work (e.g.
\[System.Management.Automation.SessionStateScope\].SetFunction() will
still resolve)

### [Find-Ast](Find-Ast.md)
The Find-Ast function can be used to easily find a specific ast from a starting ast.  By
default children asts will be searched, but ancestor asts can also be searched by specifying
the "Ancestor" switch parameter.

### [Import-WorkspaceFunctionSet](Import-WorkspaceFunctionSet.md)
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

### [Set-ExtentText](Set-ExtentText.md)
Uses the PowerShell EditorServices API to replace text an extent.
ScriptExtent objects can
be found as a property on any object inherited from System.Management.Automation.Language.Ast.

### [Start-SymbolFinderWorkaround](Start-SymbolFinderWorkaround.md)
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

### [Update-FileReferenceList](Update-FileReferenceList.md)
This function is mainly intended to be ran automatically by the Start-SymbolFinderWorkaround
function.
It can however be ran manually for temporary workspace wide symbol support as an
alternative for those who do not want to override EditorServices private methods.

