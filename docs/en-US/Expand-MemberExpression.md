---
external help file: PSESHelperLibrary-help.xml
online version: 
schema: 2.0.0
---

# Expand-MemberExpression

## SYNOPSIS
Builds an expression for accessing or invoking a member through reflection.

## SYNTAX

```
Expand-MemberExpression [[-Context] <EditorContext>] [[-Ast] <Ast>] [-TemplateName <String>]
```

## DESCRIPTION
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

This function currently works on member expressions attached to the following:

1.
Type literal expressions (including invalid expressions with non public types)

2.
Variable expressions where the variable exists within a currently existing scope.

3.
Any other scenario where standard completion works.

4.
Any number of nested member expressions where one of the above is true at some point in
   the chain.
Additionally chains may break if a member returns a type that is too generic
   like System.Object or a vague interface.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Expand-MemberExpression
```

Expands the member expression closest to the cursor in the current editor context using an
automatically determined template.

### -------------------------- EXAMPLE 2 --------------------------
```
Expand-MemberExpression -Template VerboseInvokeMethod
```

Expands the member expression closest to the cursor in the current editor context using the
VerboseInvokeMethod template.

## PARAMETERS

### -Context
Specifies the current editor context.

```yaml
Type: EditorContext
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: $psEditor.GetEditorContext()
Accept pipeline input: False
Accept wildcard characters: False
```

### -Ast
Specifies the member expression ast (or child of) to expand.

```yaml
Type: Ast
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: (Get-AstAtCursor)
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -TemplateName
Specifies the name of the template to use for building this expression.
Templates are stored
in the exported variable $PSESHLTemplates.
If a template is not chosen one will be determined
based on member type at runtime.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

## OUTPUTS

### None

## NOTES

## RELATED LINKS
