[AttributeUsage([AttributeTargets]::Class)]
class PSEditorCommand : Attribute {
    [string] $Name;
    [string] $DisplayName;
    [bool] $SuppressOutput;
    [bool] $SkipRegister;
}
