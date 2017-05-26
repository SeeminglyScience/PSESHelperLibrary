---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Set-RuleSuppression

## SYNOPSIS
Adds a SuppressMessage attribute to suppress a rule violation.

## SYNTAX

```
Set-RuleSuppression [[-Ast] <Ast[]>]
```

## DESCRIPTION
The Set-RuleSupression function generates a SuppressMessage attribute and inserts it into a
script file.
The PSScriptAnalyzer rule will be determined automatically, as well as the best
place to insert the Attribute.

The default behavior is to attempt to suppress the Ast closest to the current cursor position,
but you can also specify Asts to suppress.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Set-RuleSuppression
```

Adds a SuppressMessage attribute to suppress a rule violation.

### -------------------------- EXAMPLE 2 --------------------------
```
$propBlock = Find-Ast { $_.CommandElements -and $_.GetCommandName() -eq 'Properties' }
```

PS C:\\\> $propBlock | Find-Ast { $_.VariablePath } | Set-RuleSuppression
Finds all variable expressions in a psake Properties block and creates a rule suppression for
any that have a violation.

## PARAMETERS

### -Ast
Specifies the Ast with a rule violation to suppress.

```yaml
Type: Ast[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: (Find-Ast -AtCursor)
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

### System.Management.Automation.Language.Ast

You can pass Asts with violations to this function.

## OUTPUTS

### None

## NOTES
This function does not use existing syntax markers from PowerShell Editor Services, and
instead runs the Invoke-ScriptAnalyzer cmdlet on demand.
This may create duplicate suppression
attributes.

## RELATED LINKS

