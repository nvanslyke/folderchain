Attribute VB_Name = "modFCUtil"
'==============================================================================
' FolderChain for Outlook - shared helpers: selection, folder list for the
' picker, email addresses, file names.
'==============================================================================
Option Explicit
Option Private Module

' Folder list used by frmFolderPicker (cached between uses).
Public gFC_FolderCount As Long
Public gFC_FolderID() As String
Public gFC_FolderStoreID() As String
Public gFC_FolderLabel() As String     ' indented name for the tree view
Public gFC_FolderPath() As String      ' "Inbox\Projects\Acme" for filtering
Private mCacheKey As String

'==============================================================================
' Selection
'==============================================================================

Public Function FC_IsMailLike(ByVal obj As Object) As Boolean
    If obj Is Nothing Then Exit Function
    If TypeOf obj Is Outlook.MailItem Then
        FC_IsMailLike = True
    ElseIf TypeOf obj Is Outlook.MeetingItem Then
        FC_IsMailLike = True
    End If
End Function

' The open email (if an email window is active) or the emails selected in
' the main window. If whole conversations are selected (collapsed headers in
' conversation view), their emails in the current folder are included.
Public Function FC_GetSelectedItems() As Collection
    Dim col As New Collection, seen As Object, obj As Object, i As Long, j As Long
    Dim sel As Outlook.Selection, hdrs As Outlook.Selection
    Dim conv As Outlook.Conversation, cur As Outlook.Folder, it As Object
    Dim convItems As Collection

    Set seen = CreateObject("Scripting.Dictionary")
    On Error Resume Next

    If TypeName(Application.ActiveWindow) = "Inspector" Then
        Set obj = Application.ActiveInspector.CurrentItem
        If FC_IsMailLike(obj) Then col.Add obj
        Set FC_GetSelectedItems = col
        Exit Function
    End If

    Set sel = Application.ActiveExplorer.Selection
    If sel Is Nothing Then
        Set FC_GetSelectedItems = col
        Exit Function
    End If

    For i = 1 To sel.Count
        Set obj = Nothing
        Set obj = sel.Item(i)
        If FC_IsMailLike(obj) Then AddUnique col, seen, obj
    Next

    ' Collapsed conversation headers -> their emails in this folder.
    Set hdrs = Nothing
    Set hdrs = sel.GetSelection(olConversationHeaders)
    If Not hdrs Is Nothing Then
        Set cur = Application.ActiveExplorer.CurrentFolder
        For i = 1 To hdrs.Count
            Set conv = Nothing
            Set conv = hdrs.Item(i).GetConversation
            If Not conv Is Nothing And Not cur Is Nothing Then
                Set convItems = New Collection
                For j = 1 To conv.GetRootItems.Count
                    convItems.Add conv.GetRootItems.Item(j)
                Next
                If convItems.Count > 0 Then
                    For Each it In FC_ConversationItems(convItems(1))
                        If FC_IsMailLike(it) Then
                            If FC_SameFolder(it.Parent, cur) Then AddUnique col, seen, it
                        End If
                    Next
                End If
            End If
        Next
    End If

    Set FC_GetSelectedItems = col
End Function

Private Sub AddUnique(ByVal col As Collection, ByVal seen As Object, ByVal it As Object)
    Dim eid As String
    On Error Resume Next
    eid = it.EntryID
    On Error GoTo 0
    If eid = "" Then
        col.Add it
    ElseIf Not seen.Exists(eid) Then
        seen.Add eid, True
        col.Add it
    End If
End Sub

Public Function FC_SameFolder(ByVal a As Object, ByVal b As Object) As Boolean
    On Error Resume Next
    If a Is Nothing Or b Is Nothing Then Exit Function
    FC_SameFolder = Application.Session.CompareEntryIDs(a.EntryID, b.EntryID)
End Function

'==============================================================================
' Folder picker
'==============================================================================

' Shows frmFolderPicker with defaultFolder pre-selected. Nothing = cancelled.
Public Function FC_PickFolder(ByVal title As String, ByVal info As String, _
                              ByVal defaultFolder As Outlook.Folder, _
                              Optional ByVal okCaption As String = "OK") As Outlook.Folder
    Dim frm As frmFolderPicker
    Set frm = New frmFolderPicker
    frm.Prepare title, info, defaultFolder, okCaption
    frm.Show
    If Not frm.Cancelled Then Set FC_PickFolder = frm.SelectedFolder
    Unload frm
End Function

' Builds the folder list for the default mailbox plus any extra stores
' (e.g. the shared mailbox the current email lives in).
Public Sub FC_BuildFolderCache(ByVal extraStores As Collection, ByVal force As Boolean)
    Dim stores As New Collection, st As Object, key As String, v As Variant

    AddStore stores, Application.Session.DefaultStore
    If Not extraStores Is Nothing Then
        For Each v In extraStores
            AddStore stores, v
        Next
    End If

    For Each st In stores
        key = key & "|" & st.StoreID
    Next
    If Not force And key = mCacheKey And gFC_FolderCount > 0 Then Exit Sub

    gFC_FolderCount = 0
    ReDim gFC_FolderID(0 To 255)
    ReDim gFC_FolderStoreID(0 To 255)
    ReDim gFC_FolderLabel(0 To 255)
    ReDim gFC_FolderPath(0 To 255)

    For Each st In stores
        On Error Resume Next
        AddFolderTree st.GetRootFolder, 0, st.StoreID, st.DisplayName, (st.StoreID = Application.Session.DefaultStore.StoreID)
        On Error GoTo 0
    Next
    mCacheKey = key
End Sub

Private Sub AddStore(ByVal stores As Collection, ByVal st As Object)
    Dim s As Object
    If st Is Nothing Then Exit Sub
    For Each s In stores
        If s.StoreID = st.StoreID Then Exit Sub
    Next
    stores.Add st
End Sub

Private Sub AddFolderTree(ByVal f As Outlook.Folder, ByVal depth As Long, ByVal storeID As String, _
                          ByVal storeName As String, ByVal isDefaultStore As Boolean)
    Dim subs As Outlook.Folders, i As Long, rel As String, p As Long
    On Error GoTo Done

    If depth > 0 Then
        If f.DefaultItemType <> olMailItem Then Exit Sub
        If IsHiddenFolder(f) Then Exit Sub
    End If

    ' "\\mailbox\Inbox\Projects" -> "Inbox\Projects"
    rel = Mid$(f.FolderPath, 3)
    p = InStr(rel, "\")
    If p > 0 Then rel = Mid$(rel, p + 1) Else rel = storeName
    If Not isDefaultStore And depth > 0 Then rel = rel & "   [" & storeName & "]"

    If gFC_FolderCount > UBound(gFC_FolderID) Then
        ReDim Preserve gFC_FolderID(0 To gFC_FolderCount * 2)
        ReDim Preserve gFC_FolderStoreID(0 To gFC_FolderCount * 2)
        ReDim Preserve gFC_FolderLabel(0 To gFC_FolderCount * 2)
        ReDim Preserve gFC_FolderPath(0 To gFC_FolderCount * 2)
    End If
    gFC_FolderID(gFC_FolderCount) = f.EntryID
    gFC_FolderStoreID(gFC_FolderCount) = storeID
    If depth = 0 Then
        gFC_FolderLabel(gFC_FolderCount) = storeName
    Else
        gFC_FolderLabel(gFC_FolderCount) = String$(depth * 4, " ") & f.Name
    End If
    gFC_FolderPath(gFC_FolderCount) = rel
    gFC_FolderCount = gFC_FolderCount + 1

    Set subs = f.Folders
    For i = 1 To subs.Count
        AddFolderTree subs.Item(i), depth + 1, storeID, storeName, isDefaultStore
    Next
Done:
End Sub

Private Function IsHiddenFolder(ByVal f As Outlook.Folder) As Boolean
    On Error Resume Next
    IsHiddenFolder = CBool(f.PropertyAccessor.GetProperty(PR_ATTR_HIDDEN))
End Function

Public Function FC_FolderCacheIndex(ByVal entryID As String) As Long
    Dim i As Long
    FC_FolderCacheIndex = -1
    If entryID = "" Then Exit Function
    For i = 0 To gFC_FolderCount - 1
        If gFC_FolderID(i) = entryID Then
            FC_FolderCacheIndex = i
            Exit Function
        End If
    Next
End Function

Public Function FC_FolderFromCache(ByVal index As Long) As Outlook.Folder
    On Error Resume Next
    If index < 0 Or index >= gFC_FolderCount Then Exit Function
    Set FC_FolderFromCache = Application.Session.GetFolderFromID(gFC_FolderID(index), gFC_FolderStoreID(index))
End Function

' Remembers / recalls the last folder mail was moved to with FolderChain.
Public Sub FC_SetLastMoveFolder(ByVal f As Outlook.Folder)
    On Error Resume Next
    SaveSetting FC_APP, "Move", "LastFolderID", f.EntryID
    SaveSetting FC_APP, "Move", "LastStoreID", f.StoreID
End Sub

Public Function FC_GetLastMoveFolder() As Outlook.Folder
    Dim eid As String, sid As String
    eid = GetSetting(FC_APP, "Move", "LastFolderID", "")
    sid = GetSetting(FC_APP, "Move", "LastStoreID", "")
    If eid = "" Then Exit Function
    On Error Resume Next
    Set FC_GetLastMoveFolder = Application.Session.GetFolderFromID(eid, sid)
End Function

'==============================================================================
' Email addresses
'==============================================================================

Public Function FC_AddressEntrySmtp(ByVal ae As Outlook.AddressEntry) As String
    Dim s As String
    On Error Resume Next
    If ae Is Nothing Then Exit Function
    Select Case ae.AddressEntryUserType
        Case olExchangeUserAddressEntry, olExchangeRemoteUserAddressEntry
            s = ae.GetExchangeUser.PrimarySmtpAddress
        Case olExchangeDistributionListAddressEntry
            s = ae.GetExchangeDistributionList.PrimarySmtpAddress
    End Select
    If s = "" Then s = ae.PropertyAccessor.GetProperty(PR_SMTP_ADDRESS)
    If s = "" And InStr(ae.Address, "@") > 0 Then s = ae.Address
    FC_AddressEntrySmtp = s
End Function

Public Function FC_RecipientSmtp(ByVal r As Outlook.Recipient) As String
    Dim s As String
    On Error Resume Next
    s = r.PropertyAccessor.GetProperty(PR_SMTP_ADDRESS)
    If s = "" Then s = FC_AddressEntrySmtp(r.AddressEntry)
    If s = "" And InStr(r.Address, "@") > 0 Then s = r.Address
    If s = "" Then s = r.Name
    FC_RecipientSmtp = s
End Function

Public Function FC_SenderSmtp(ByVal it As Object) As String
    Dim s As String, ae As Outlook.AddressEntry
    On Error Resume Next
    If it.SenderEmailType = "SMTP" Then s = it.SenderEmailAddress
    If s = "" Then
        Set ae = it.Sender
        If Not ae Is Nothing Then s = FC_AddressEntrySmtp(ae)
    End If
    If s = "" And InStr(it.SenderEmailAddress, "@") > 0 Then s = it.SenderEmailAddress
    FC_SenderSmtp = s
End Function

' Your own addresses (all accounts), so they can be left off invites.
Public Function FC_MyAddresses() As Object
    Dim d As Object, i As Long, s As String
    Set d = CreateObject("Scripting.Dictionary")
    d.CompareMode = vbTextCompare
    On Error Resume Next
    For i = 1 To Application.Session.Accounts.Count
        s = ""
        s = Application.Session.Accounts.Item(i).SmtpAddress
        If s <> "" And Not d.Exists(s) Then d.Add s, True
    Next
    s = ""
    s = FC_AddressEntrySmtp(Application.Session.CurrentUser.AddressEntry)
    If s <> "" And Not d.Exists(s) Then d.Add s, True
    s = ""
    s = Application.Session.CurrentUser.Name
    If s <> "" And Not d.Exists(s) Then d.Add s, True
    Set FC_MyAddresses = d
End Function

'==============================================================================
' Files
'==============================================================================

' Replaces characters Windows doesn't allow in file names.
Public Function FC_SafeFileName(ByVal s As String, Optional ByVal maxLen As Long = 120) As String
    Dim bad As Variant, i As Long
    bad = Array("\", "/", ":", "*", "?", """", "<", ">", "|")
    For i = LBound(bad) To UBound(bad)
        s = Replace(s, bad(i), "_")
    Next
    For i = 0 To 31
        s = Replace(s, Chr$(i), " ")
    Next
    s = Trim$(s)
    If Len(s) > maxLen Then s = Trim$(Left$(s, maxLen))
    Do While Len(s) > 0 And (Right$(s, 1) = "." Or Right$(s, 1) = " ")
        s = Left$(s, Len(s) - 1)
    Loop
    FC_SafeFileName = s
End Function

Public Sub FC_SplitExt(ByVal fileName As String, ByRef baseName As String, ByRef ext As String)
    Dim p As Long
    p = InStrRev(fileName, ".")
    If p > 1 Then
        baseName = Left$(fileName, p - 1)
        ext = Mid$(fileName, p)
    Else
        baseName = fileName
        ext = ""
    End If
End Sub

' folder\base.ext, or folder\base (2).ext etc. if that already exists.
' Keeps the full path under Windows' 260 character limit.
Public Function FC_UniquePath(ByVal folder As String, ByVal baseName As String, ByVal ext As String) As String
    Dim fso As Object, candidate As String, n As Long, room As Long
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Right$(folder, 1) = "\" Then folder = Left$(folder, Len(folder) - 1)

    room = 250 - Len(folder) - 1 - Len(ext) - 5
    If room < 10 Then room = 10
    If Len(baseName) > room Then baseName = Trim$(Left$(baseName, room))
    If baseName = "" Then baseName = "file"

    candidate = folder & "\" & baseName & ext
    n = 1
    Do While fso.FileExists(candidate) Or fso.FolderExists(candidate)
        n = n + 1
        candidate = folder & "\" & baseName & " (" & n & ")" & ext
    Loop
    FC_UniquePath = candidate
End Function

' True for pictures embedded in the body (signature logos etc.).
Public Function FC_IsInlineAttachment(ByVal att As Outlook.Attachment, ByVal htmlBody As String) As Boolean
    Dim cid As String, hidden As Boolean
    On Error Resume Next
    hidden = att.PropertyAccessor.GetProperty(PR_ATTACHMENT_HIDDEN)
    If hidden Then FC_IsInlineAttachment = True: Exit Function
    cid = att.PropertyAccessor.GetProperty(PR_ATTACH_CONTENT_ID)
    If cid <> "" And htmlBody <> "" Then
        If InStr(1, htmlBody, "cid:" & cid, vbTextCompare) > 0 Then FC_IsInlineAttachment = True
    End If
End Function
