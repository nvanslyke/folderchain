'==============================================================================
' FolderChain for Outlook - ThisOutlookSession code
'
' HOW TO ADD: in the VBA editor (Alt+F11), open Project1 > Microsoft Outlook
' Objects > ThisOutlookSession and paste everything below into it.
'
' If ThisOutlookSession already has an Application_Startup or
' Application_NewMailEx, don't paste a second copy: just add the FC_ line
' to your existing one.
'==============================================================================
Option Explicit

Private Sub Application_Startup()
    FC_Startup
End Sub

Private Sub Application_NewMailEx(ByVal EntryIDCollection As String)
    FC_OnNewMail EntryIDCollection
End Sub
