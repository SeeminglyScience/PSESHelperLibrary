# Since this is just a workaround and any fixes PSES makes will be significantly better, I don't think
# this function/class will be updated.  If anything I would generalize this to add hooks into all of
# the events and requests, assuming that isn't added as well.
function Start-SymbolFinderWorkaround {

    # Get the PowerShellEditorServices assemblies.
    $PSESAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies() |
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
    # Create the object that handles updating the cross workspace file reference list.
    [ProxyLanguageServer]::new($script:PSESData.LanguageServer) | Out-Null

    Update-FileReferenceList
}