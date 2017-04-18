# PSESHelperLibrary

The PSESHelperLibrary module provides tools to assist in interacting with PowerShell Editor Services along with some
commands for general editing use.

This project is at a very early stage and does not currently have an official release. But feel free to try it out
and let me know needs to change.

## Features

### PSEditorCommand attribute and Import-EditorCommand

Tag functions as editor commands with the PSEditorCommand attribute.  Import them with the Import-EditorCommand
function to automatically add the Context parameter and register them with Editor Services.

```powershell
#requires -Module PSESHelperLibrary
using module PSESHelperLibrary

function Invoke-MyEditorCommand {
    [PSEditorCommand(DisplayName='Invoke my editor command')]
    [CmdletBinding()]
    param()
    if ($Context) {
        $Context.CurrentFile.InsertText('I am an editor command!')
    }
}
Import-EditorCommand -Command Invoke-MyEditorCommand
```

Or import all the editor commands tagged in a module with `Import-EditorCommand -Module MyModule`.

### Expand-MemberExpression

Expand normal member expressions with private members to working reflection statements.

![Expand-MemberExpression](https://cloud.githubusercontent.com/assets/24977523/24843248/fa03ee76-1d6e-11e7-97ad-56e1677ae820.gif)

### Expand-Expression

Replace selected text with it's return value.

### Under Construction

More demos for existing features are coming soon, as well as commands and tools for command creators.

