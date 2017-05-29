using namespace System.Management.Automation.Language
using namespace System.Collections.Generic
using namespace Microsoft.PowerShell.EditorServices
using namespace Microsoft.PowerShell.EditorServices.Extensions

# Updates ElasticExtent objects when a file changes.
class ElasticHelper {
    hidden static [Dictionary[string, ElasticHelper]] $instances;

    hidden [string] $snapshot;
    hidden [ScriptFile] $scriptFile;
    hidden [List[ElasticExtent]] $children;

    ElasticHelper() {
        $this.children = [List[ElasticExtent]]::new()
    }

    static ElasticHelper() {
        [ElasticHelper]::instances = [Dictionary[string, ElasticHelper]]::new([StringComparer]::OrdinalIgnoreCase)
    }

    static [ElasticHelper] Create([IScriptExtent] $extent) {
        $fileName = $extent.File
        $instance = $null

        if ([ElasticHelper]::instances.TryGetValue($fileName, [ref]$instance)) {
            $instance.children.Add($extent)
            return $instance
        }

        $file     = [EditorServicesUtil]::GetScriptFile($fileName)
        $instance = [ElasticHelper]@{
            scriptFile = $file[0]
            snapshot   = $file.Contents
        }
        [ElasticHelper]::instances.Add($fileName, $instance)
        $instance.children.Add($extent)
        return $instance
    }

    # Check if the change has taken effect in PSES.
    [bool] HasChanged() {
        return -not $this.snapshot.Equals($this.scriptFile.Contents) -and
                    $this.snapshot.Length -ne $this.scriptFile.Contents.Length
    }

    # Automatically detect a changed segment of text and update child extents. This doesn't work
    # properly at the moment because of how FileContext.InsertText works. If InsertText is in the
    # process of inserting but hasn't updated the ScriptFile then the extents will get out of sync.
    [void] AddChanges() {
        $this.AddChanges($this.GetChangeExtent().StartOffset,
                         $this.scriptFile.Contents.Length - $this.snapshot.Length)
    }

    [void] AddChanges([int]$changeStart, [int] $changeLength) {
        foreach ($child in $this.children) {
            if ($child.extentInternal.StartOffset -ge $changeStart) {
                $child.ProcessChange($changeLength)
            }
        }
        $this.snapshot = $this.scriptFile.Contents
    }

    # Get the extent of a changed segment. This is very simple and only works if one segment has changed.
    [IScriptExtent] GetChangeExtent() {
        $old      = $this.snapshot
        $new      = $this.scriptFile.Contents

        $start    = $this.GetFirstChangeOffset($old, $new)
        $oldArray = $old.ToCharArray()
        $newArray = $new.ToCharArray()

        [array]::reverse($oldArray)
        [array]::reverse($newArray)

        $end = $new.Length - $this.GetFirstChangeOffset($oldArray, $newArray)

        return ConvertTo-ScriptExtent -StartOffsetNumber $start -EndOffsetNumber $end
    }

    # Find the first char that doesn't match.
    [int] GetFirstChangeOffset([IEnumerable[char]]$reference, [IEnumerable[char]]$difference) {
        $length = [math]::Min($reference.Length, $difference.Length)
        for ($i = 0; $i -lt $length; $i++) {
            if (-not $reference[$i].Equals($difference[$i])) { break }
        }
        return $i
    }
}

class ElasticExtent : IScriptExtent {
    hidden [IScriptExtent] $extentInternal;
    hidden [ElasticHelper] $parent;

    ElasticExtent([IScriptExtent] $extent) {
        $this.extentInternal = $extent
        $this.parent = [ElasticHelper]::Create($this)
    }

    static [ElasticExtent] op_Implicit([IScriptExtent] $valueToConvert) {
        return [ElasticExtent]::new($valueToConvert)
    }

    # "Set" the value of an extent (insert at it's position to replace it) and wait for changes
    # to occur before moving on. Only safe way I've found to change multiple segments sequentially
    # without losing position.
    [void] SetValue([FileContext] $context, [string] $newValue) {
        $this.Check()
        $bufferRange = [BufferRange]::new(
            <# startLine:   #> $this.extentInternal.StartLineNumber,
            <# startColumn: #> $this.extentInternal.StartColumnNumber,
            <# endLine:     #> $this.extentInternal.EndLineNumber,
            <# endColumn:   #> $this.extentInternal.EndColumnNumber
        )
        $context.InsertText($newValue, $bufferRange)
        if ($this.extentInternal.Text.Length -ne $newValue.Length) {
            while (-not $this.parent.HasChanged()) {
                Start-Sleep -Milliseconds 30
            }
            $this.parent.AddChanges($this.extentInternal.StartOffset,
                                    $newValue.Length - $this.extentInternal.Text.Length)
        }
    }

    # Correct our pointer extent.
    [void] ProcessChange([int] $changeLength) {
        if (-not $changeLength) { return }

        $newStart    = $this.extentInternal.StartOffset + $changeLength
        $newEnd      = $this.extentInternal.EndOffset + $changeLength
        $this.extentInternal = ConvertTo-ScriptExtent -StartOffsetNumber $newStart -EndOffsetNumber $newEnd
    }

    # Check for changes that could mean this extent is no longer valid.
    [void] Check() {
        if ($this.parent -and $this.parent.HasChanged()) {
            $this.parent.AddChanges()
        }
    }
    # IScriptExtent accessors. All just point to a hidden extent and check for changes.
    [string] get_File()                         { $this.Check(); return $this.extentInternal.File }
    [int] get_StartLineNumber()                 { $this.Check(); return $this.extentInternal.StartLineNumber }
    [int] get_StartColumnNumber()               { $this.Check(); return $this.extentInternal.StartColumnNumber }
    [int] get_StartOffset()                     { $this.Check(); return $this.extentInternal.StartOffset }
    [int] get_EndOffset()                       { $this.Check(); return $this.extentInternal.EndOffset }
    [IScriptPosition] get_StartScriptPosition() { $this.Check(); return $this.extentInternal.StartScriptPosition }
    [IScriptPosition] get_EndScriptPosition()   { $this.Check(); return $this.extentInternal.EndScriptPosition }
    [int] get_EndLineNumber()                   { $this.Check(); return $this.extentInternal.EndLineNumber }
    [int] get_EndColumnNumber()                 { $this.Check(); return $this.extentInternal.EndColumnNumber }
    [string] get_Text()                         { $this.Check(); return $this.extentInternal.Text }
}
