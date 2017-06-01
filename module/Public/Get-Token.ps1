using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation.Language
using namespace System.Linq

function Get-Token {
    <#
    .EXTERNALHELP PSESHelperLibrary-help.xml
    #>
    [CmdletBinding(DefaultParameterSetName='Extent',
                   HelpUri='https://github.com/SeeminglyScience/PSESHelperLibrary/blob/master/docs/en-US/Get-Token.md')]
    [OutputType([System.Management.Automation.Language.Token])]
    [SuppressMessage('PSUseOutputTypeCorrectly', '', Justification='Issue #676')]
    param(
        # Specifies the extent that a token must be within to be returned.
        [Parameter(Position=0,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ParameterSetName='Extent')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.IScriptExtent]
        $Extent,

        # Specifies the path to a file to get tokens for.
        [Parameter(Position=0, Mandatory, ParameterSetName='Path')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )
    process {
        if ($Path) { return [PositionUtil]::GetFileTokens($Path) }

        if ($Extent) {
            $tokens    = [PositionUtil]::GetFileTokens($Extent.File)
            $predicate = [Func[Token, bool]]{
                param($Token)

               ($Token.Extent.StartOffset -ge $Extent.StartOffset -and
                $Token.Extent.EndOffset   -le $Extent.EndOffset)
            }
            if ($tokens){
                $result = [Enumerable]::Where($tokens, $predicate)
            }
            return $result
        }

        return [PositionUtil]::GetFileTokens([EditorServicesUtil]::GetContext().CurrentFile.Path)
    }
}
