# Temporary workaround for populating the Context parameter until I can get default values working
# with the PSEditorCommand attribute.
function TryGetEditorContext {
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [CmdletBinding()]
    param()
    end {
        $context = Get-Variable -Scope 1 -Name Context -ValueOnly -ErrorAction Ignore
        if (-not $context) {
            try {
                if (-not $psEditor) { throw }
                $context = $psEditor.GetEditorContext()
                Set-Variable -Scope 1 -Name Context -Value $context -ErrorAction Stop
            } catch {
                $PSCmdlet.WriteVerbose($Strings.SkippingEditorContext)
            }
        }
    }
}
