ConvertFrom-StringData @'
EditorCommandExists=Editor command '{0}' already exists, skipping.
GettingImportedModules=Getting imported modules in the workspace.
CheckingDefaultScope=No modules found, checking default scope instead.
EnumeratingScopesForMember=Enumerating scopes to find a matching member.
VariableFound=Found variable with type '{0}'.
SkippingEditorContext=PowerShell Editor Services API not available, skipping.
InferringFromCompletion=Checking for type using standard command completion.

WhatIfSetExtent=Changing '{0}' to '{1}'
ConfirmSetExtent=Continuing will change the the text of extent '{0}' to '{1}'. Are you sure you want to continue?
ConfirmTitle=Confirm

MissingEditorContext=Unable to obtain editor context. Make sure PowerShell Editor Services is running and then try the command again.
ExpandEmptyExtent=Cannot expand the extent with start offset '{0}' for file '{1}' because it is empty.
MissingMemberExpressionAst=Unable to find a member expression ast near the current cursor location.
InvalidBinderResult=Internal module error: Received binder result is not a command info object.  Please file an issue on GitHub.
CannotInferType=Unable to infer type for expression '{0}'.
TypeNotFound=Unable to find type [{0}].
InvalidMetadataType=Type must be inherited from the class 'AdditionalCommandParameters'
MissingParameterMetadata=Specified type must define parameters.
CannotFindModule=Unable to find the module '{0}' in the current session.
InvalidAttributeType=Type must be inherited from the class 'System.Attribute'
'@
