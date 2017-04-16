function Start-SymbolFinderWorkaround {
    <#
    .SYNOPSIS
        Once started update file reference list to include all workspace files when a text document
        is opened.
    .DESCRIPTION
        Define a class that replaces the DidOpenTextDocumentNotification event handler in the
        PowerShellEditorServices language server.  The replacement method will update the file
        ReferencedFiles field to include all files in the current workspace and call the original
        method.

        This is mainly intended to be a temporary workaround for cross module intellisense until
        PowerShellEditorServices has better symbol tracking for larger projects.

        This will not be loaded automatically unless placed in the $profile used by the editor.
        However, care should be taken before adding to your profile. This is likely to cause issues
        with debugging.
    .INPUTS
        None
    .OUTPUTS
        None
    .EXAMPLE
        PS C:\> Start-SymbolFinderWorkaround
        Starts workspace wide symbol tracking for the session.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()
    end {
        if ($PSCmdlet.ShouldProcess('Loading proxy language server class.', '', '')) {
            # Get the PowerShellEditorServices assemblies.
            $PSESAssemblies = [AppDomain]::CurrentDomain.GetAssemblies() |
                Where-Object Location -Match 'PowerShell.EditorServices.*.dll' |
                ForEach-Object -MemberName Location

            # Add some C# that essentially lets us add a hook to the event that is called when VSCode opens a file.
            Add-Type -Language CSharp -ReferencedAssemblies $PSESAssemblies -WarningAction SilentlyContinue -TypeDefinition @'
                using Microsoft.PowerShell.EditorServices.Protocol.LanguageServer;
                using Microsoft.PowerShell.EditorServices.Protocol.MessageProtocol;
                using Microsoft.PowerShell.EditorServices.Protocol.Server;
                using Microsoft.PowerShell.EditorServices;
                using System.Management.Automation;
                using System.Threading.Tasks;
                using System.Reflection;

                public class ProxyLanguageServer
                {
                    private LanguageServer languageServer;

                    public ProxyLanguageServer(LanguageServer languageServer)
                    {
                        this.languageServer = languageServer;
                        this.languageServer.SetEventHandler(
                            DidOpenTextDocumentNotification.Type,
                            this.HandleDidOpenTextDocumentNotification,
                            true);
                    }
                    protected Task HandleDidOpenTextDocumentNotification(
                            DidOpenTextDocumentNotification openParams,
                            EventContext eventContext)
                    {
                        EditorSession editorSession = languageServer
                            .GetType()
                            .GetField("editorSession", BindingFlags.NonPublic | BindingFlags.Instance)
                            .GetValue(languageServer) as EditorSession;

                        MethodInfo originalMethod = languageServer
                            .GetType()
                            .GetMethod("HandleDidOpenTextDocumentNotification", BindingFlags.NonPublic | BindingFlags.Instance);

                        originalMethod.Invoke(languageServer, new object[] { openParams, eventContext });

                        var psCommand = new PSCommand();
                        psCommand.AddCommand("Update-FileReferenceList");
                        editorSession.PowerShellContext.ExecuteCommand(psCommand);

                        return Task.FromResult(true);
                    }
                }
'@
        }
        # Create the object that handles updating the cross workspace file reference list.
        if ($PSCmdlet.ShouldProcess('Replacing HandleDidOpenTextDocumentNotification method in the PSES language server.', '', '')) {
            $languageServer = $script:EditorOperations.GetType().
                GetField('messageSender', [System.Reflection.BindingFlags]'Instance, NonPublic').
                GetValue($script:EditorOperations)

            [ProxyLanguageServer]::new($languageServer) | Out-Null
        }
        if ($PSCmdlet.ShouldProcess('Updating file reference list in PSES cache.', '', '')) {
            Update-FileReferenceList
        }
    }
}
