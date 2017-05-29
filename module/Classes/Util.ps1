using namespace System.Management.Automation.Language
using namespace System.Management.Automation
using namespace System.Diagnostics.CodeAnalysis
using namespace Microsoft.PowerShell.EditorServices.Extensions
using namespace Microsoft.PowerShell.EditorServices

# Methods to retrieve positions and position related objects.
class PositionUtil {
    static [IScriptPosition] $EmptyPosition = [Language.ScriptPosition]::new('', 0, 0, '')
    static [IScriptExtent] $EmptyExtent = [Language.ScriptExtent]::new([PositionUtil]::EmptyPosition,
                                                                       [PositionUtil]::EmptyPosition);

    # Get an Ast either from PSES or the parser.
    static [Ast] GetFileAst([string] $filePath) {
        $filePath = [ContextUtil]::ResolvePath($filePath)

        if (-not $filePath) { return $null }

        if ([EditorServicesUtil]::IsAvailable()) {
            return [EditorServicesUtil]::GetScriptFile($filePath).ScriptAst
        }

        return [Parser]::ParseInput([IO.File]::ReadAllText($filePath), $filePath, [ref]$null, [ref]$null)
    }

    # Get parser tokens either from PSES or the parser.
    static [Token[]] GetFileTokens([string] $filePath) {
        $filePath = [ContextUtil]::ResolvePath($filePath)

        if (-not $filePath) { return $null }

        if ([EditorServicesUtil]::IsAvailable()) {
            return [EditorServicesUtil]::GetScriptFile($filePath).ScriptTokens
        }
        $tokens = $null
        [Parser]::ParseInput([IO.File]::ReadAllText($filePath), $filePath, [ref]$tokens, [ref]$null)

        return $tokens
    }

    # Create a InternalScriptPosition object from a script extent.
    static [IScriptExtent] CreateExtent([IScriptExtent] $helperSource, [int] $start, [int] $end) {
        $helper = $helperSource.GetType().GetProperty('PositionHelper', 60).
                                          GetValue($helperSource)

        return [ref].Assembly.GetType('System.Management.Automation.Language.InternalScriptExtent').InvokeMember(
            <# name:       #> '',
            <# invokeAttr: #> [System.Reflection.BindingFlags]'CreateInstance, Instance, NonPublic',
            <# binder:     #> $null,
            <# target:     #> $null,
            <# args:       #> @(
                <# _positionHelper: #> $helper,
                <# startOffset:     #> $start,
                <# endOffset:       #> $end))
    }

    # Get a line start -> char offset map from a string.
    static [int[]] GetLineMap([string] $text) {
        $newLine = "`n" -as [char]
        $lineMap = for ($i = $text.IndexOf($newLine)
                        $i -gt -1
                        $i = $text.IndexOf($newLine, $i + 1))
                        { $i }
        return $lineMap
    }

    # Get offset using ScriptFile.GetOffsetAtPosition().
    static [int] GetOffsetFromPosition([ScriptFile] $scriptFile, [int] $line, [int] $column) {
        return $scriptFile.GetOffsetAtPosition($line, $column)
    }

    # Get an offset from a string.
    static [int] GetOffsetFromPosition([string] $text, [int] $line, [int] $column) {
        $lineMap = [PositionUtil]::GetLineMap($text)
        return [PositionUtil]::GetOffsetFromPosition($lineMap, $line, $column)
    }

    # Get an offset from a line map. This avoids generating more line maps then needed.
    static [int] GetOffsetFromPosition([int[]] $lineMap, [int] $line, [int] $column) {
        if (-not $lineMap) { return $null }

        return $lineMap[$line - 2] + $column
    }
}

# Methods to retrieve context information from PSES.
[SuppressMessage('PSAvoidGlobalVars', '')]
class EditorServicesUtil {
    static [EditorObject] $EditorObject   = $global:psEditor;
    static [EditorSession] $EditorSession = $script:EditorSession;

    # Returns true if PSES is running.
    static [bool] IsAvailable() {
        return [EditorServicesUtil]::EditorObject
    }

    # Get the current EditorContext.  Returns null if unable.
    static [EditorContext] GetContext() {
        try {
            return [EditorServicesUtil]::EditorObject.GetEditorContext()
        } catch {
            return $null
        }
    }

    # Get ScriptFile from editor context.  Returns null if unable.
    static [ScriptFile] GetScriptFile() {
        if (-not [EditorServicesUtil]::IsAvailable()) { return $null }

        $path =  [EditorServicesUtil]::GetContext().CurrentFile.Path

        return   [EditorServicesUtil]::GetScriptFile($path)
    }

    # Get ScriptFile from a file path.  Returns null if unable.
    static [ScriptFile] GetScriptFile([string] $filePath) {
        $filePath = [ContextUtil]::ResolvePath($filePath)
        try {
            return [EditorServicesUtil]::EditorSession.Workspace.GetFile($filePath)
        } catch {
            return $null
        }
    }
}

# Methods to interact with automatic global variables.  This is to avoid having to use global everywhere.
class ContextUtil {
    static [EngineIntrinsics] $Engine = $global:ExecutionContext;

    # Resolve to a absolute path. Returns null if unable.
    static [string] ResolvePath([string]$filePath) {
        try {
            return [ContextUtil]::Engine.SessionState.Path.GetResolvedPSPathFromPSPath($filePath)
        } catch {
            return $null
        }
    }
}
