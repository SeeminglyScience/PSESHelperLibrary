using namespace System.Management.Automation.Language

# Manually create the ParameterAst for the automatic parameter "Context". This is done so we can have
# completely empty extents and the parameter shouldn't interfere with break points.
function NewContextParameterAst {
    # Empty extent that will be used for every element.
    $ee = [PositionUtil]::EmptyExtent

    $typeConstraint = [TypeConstraintAst]::new(
        <# extent:   #> $ee,
        <# typeName: #> [TypeName]::new($ee, 'Microsoft.PowerShell.EditorServices.Extensions.EditorContext'))

    $validator = [AttributeAst]::new(
        <# extent:              #> $ee,
        <# typeName:            #> [TypeName]::new($ee, 'ValidateNotNullOrEmpty'),
        <# positionalArguments: #> [ExpressionAst[]]@(),
        <# namedArguments:      #> [NamedAttributeArgumentAst[]]@())

    # Comes out as $psEditor.ForEach('GetEditorContext') to avoid an exception if $psEditor
    # doesn't exist.
    $getContext = [InvokeMemberExpressionAst]::new(
        <# extent:     #> $ee,
        <# expression: #> [VariableExpressionAst]::new($ee, 'psEditor', $false),
        <# method:     #> [StringConstantExpressionAst]::new($ee, 'ForEach', 'BareWord'),
        <# arguments:  #> [StringConstantExpressionAst]::new($ee, 'GetEditorContext', 'SingleQuoted') -as [ExpressionAst[]],
        <# static:     #> $false)

    # Add index 0 to unwrap (e.g. $psEditor.ForEach('GetEditorContext)[0])
    $unwrappedGetContext = [IndexExpressionAst]::new(
        <# extent: #> $ee,
        <# target: #> $getContext,
        <# index:  #> [ConstantExpressionAst]::new($ee, 0))

    return [ParameterAst]::new(
        <# extent:       #> $ee,
        <# name:         #> [VariableExpressionAst]::new($ee, 'Context', $false),
        <# attributes:   #> ($typeConstraint, $validator) -as [AttributeBaseAst[]],
        <# defaultValue: #> $unwrappedGetContext)
}
