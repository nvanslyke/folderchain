VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "clsFolderWatcher"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'==============================================================================
' FolderChain for Outlook - watches one folder (Sent Items or a colored
' folder) and colors the chain of any email that lands in it.
'==============================================================================
Option Explicit

Private WithEvents mItems As Outlook.Items
Attribute mItems.VB_VarHelpID = -1

Public Sub Attach(ByVal f As Outlook.Folder)
    Set mItems = f.Items
End Sub

Private Sub mItems_ItemAdd(ByVal Item As Object)
    On Error Resume Next
    If gFC_Busy Then Exit Sub
    If TypeOf Item Is Outlook.MailItem Then FC_RecolorConversation Item
End Sub
