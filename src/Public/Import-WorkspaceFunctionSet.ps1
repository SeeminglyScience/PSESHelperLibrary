# Another one that will go away as soon as workspace symbol tracking is fixed.
function Import-WorkspaceFunctionSet {
    # Load all workspace functions into intellisense.  If you use using statements make sure to specify the
    # full type name in anything that generates metadata (e.g. OutputType, parameter type constraints, etc)
    # If you don't, PowerShell will crash when it tries to pull up intellisense.
    $script:PSESHLExcludeFromFileReferences | ForEach-Object {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($PSItem, [ref]$null, [ref]$null)

        $functionDefinitions = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]},$true)
        . ([scriptblock]::Create($functionDefinitions.Extent.Text))
    }
}