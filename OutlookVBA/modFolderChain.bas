Attribute VB_Name = "modFolderChain"
'==============================================================================
' FolderChain for Outlook - core logic: settings, chains, colors, watchers.
'
' See OutlookVBA/README.md for setup. "Option Private Module" keeps these
' helpers out of the Macros list; the macros you put on the ribbon are in
' modFCCommands and modFCCompose.
'==============================================================================
Option Explicit
Option Private Module

'------------------------------------------------------------------------------
' SETTINGS - change these to taste
'------------------------------------------------------------------------------

' Prefix for the categories FolderChain creates (one per colored folder).
Public Const FC_CATEGORY_PREFIX As String = "Folder: "

' Folder names (semicolon separated, not case sensitive) that never count as
' "the folder a chain is filed in". Inbox, Sent Items, Deleted Items (and its
' subfolders), Drafts, Outbox, Junk, RSS Feeds and the Sync Issues folders are
' always excluded, whatever language Outlook is in.
Public Const FC_EXCLUDED_FOLDER_NAMES As String = "Archive;Conversation History;Snoozed;Scheduled"

' True = color mail automatically when it arrives, is sent, or is filed.
Public Const FC_AUTO_COLOR As Boolean = True

' How many days back "Recolor Inbox" and "color existing mail" look.
Public Const FC_RECOLOR_DAYS_BACK As Long = 180

' Save Email + Attachments: skip pictures embedded in the body (signature
' logos and so on) and only save real attachments.
Public Const FC_SKIP_INLINE_IMAGES As Boolean = True

' Save Email + Attachments: 0 = save straight into the chosen folder,
' 1 = one subfolder per email when several emails are selected, 2 = always.
Public Const FC_SUBFOLDER_MODE As Long = 1

' Schedule Meeting: text put in front of the chain's subject, e.g. "Meeting: ".
Public Const FC_MEETING_SUBJECT_PREFIX As String = ""

' Schedule Meeting: True = people who were only ever on CC become optional.
Public Const FC_CC_AS_OPTIONAL As Boolean = True

'------------------------------------------------------------------------------
' Internals
'------------------------------------------------------------------------------
Public Const FC_APP As String = "FolderChain"
Public Const FC_RULE_PREFIX As String = "FolderChain: "
Public Const PR_SMTP_ADDRESS As String = "http://schemas.microsoft.com/mapi/proptag/0x39FE001E"
Public Const PR_ATTACH_CONTENT_ID As String = "http://schemas.microsoft.com/mapi/proptag/0x3712001F"
Public Const PR_ATTACHMENT_HIDDEN As String = "http://schemas.microsoft.com/mapi/proptag/0x7FFE000B"
Public Const PR_ATTR_HIDDEN As String = "http://schemas.microsoft.com/mapi/proptag/0x10F4000B"

Private Const SEC_FOLDERS As String = "FolderCategory"

' True while FolderChain itself is moving mail, so the folder watchers don't
' repeat the work.
Public gFC_Busy As Boolean

Private mWatchers As Collection
Private mExcluded As Object        ' folder EntryID -> True
Private mStoreDeleted As Object    ' StoreID -> Deleted Items folder path
Private mMappedCats As Object      ' category name -> True (Nothing = reload)

'==============================================================================
' Startup and folder watchers
'==============================================================================

' Called from ThisOutlookSession.Application_Startup.
Public Sub FC_Startup()
    On Error Resume Next
    FC_StartWatchers
End Sub

' (Re)creates one watcher for Sent Items and one per colored folder, so mail
' that lands there is colored by its chain.
Public Sub FC_StartWatchers()
    On Error Resume Next
    Set mWatchers = New Collection
    If Not FC_AUTO_COLOR Then Exit Sub
    If MappedCategories().Count = 0 Then Exit Sub

    AddWatcher Application.Session.GetDefaultFolder(olFolderSentMail)

    Dim s As Variant, i As Long, f As Outlook.Folder
    s = GetAllSettings(FC_APP, SEC_FOLDERS)
    If Not IsArray(s) Then Exit Sub
    For i = LBound(s, 1) To UBound(s, 1)
        Set f = Nothing
        Set f = Application.Session.GetFolderFromID(CStr(s(i, 0)))
        If Not f Is Nothing Then AddWatcher f
    Next
End Sub

Private Sub AddWatcher(ByVal f As Outlook.Folder)
    If f Is Nothing Then Exit Sub
    Dim w As clsFolderWatcher
    Set w = New clsFolderWatcher
    w.Attach f
    mWatchers.Add w
End Sub

' Called from ThisOutlookSession.Application_NewMailEx.
Public Sub FC_OnNewMail(ByVal entryIDs As String)
    On Error Resume Next
    If Not FC_AUTO_COLOR Then Exit Sub
    If MappedCategories().Count = 0 Then Exit Sub

    Dim ids() As String, i As Long, it As Object
    ids = Split(entryIDs, ",")
    For i = LBound(ids) To UBound(ids)
        Set it = Nothing
        Set it = Application.Session.GetItemFromID(Trim$(ids(i)))
        If Not it Is Nothing Then
            If TypeOf it Is Outlook.MailItem Then FC_RecolorConversation it
        End If
    Next
End Sub

'==============================================================================
' Folder -> category (color) mapping, stored in the registry under
' HKCU\Software\VB and VBA Program Settings\FolderChain\FolderCategory
'==============================================================================

Public Function FC_GetFolderCategory(ByVal f As Outlook.Folder) As String
    If f Is Nothing Then Exit Function
    FC_GetFolderCategory = GetSetting(FC_APP, SEC_FOLDERS, f.EntryID, "")
End Function

Public Sub FC_SaveFolderCategory(ByVal f As Outlook.Folder, ByVal catName As String)
    SaveSetting FC_APP, SEC_FOLDERS, f.EntryID, catName
    Set mMappedCats = Nothing
End Sub

Public Sub FC_ClearFolderCategory(ByVal f As Outlook.Folder)
    On Error Resume Next
    DeleteSetting FC_APP, SEC_FOLDERS, f.EntryID
    Set mMappedCats = Nothing
End Sub

' 2-D array (row, 0 = folder EntryID / 1 = category) or Empty if none.
Public Function FC_GetMappings() As Variant
    FC_GetMappings = GetAllSettings(FC_APP, SEC_FOLDERS)
End Function

Private Function MappedCategories() As Object
    If mMappedCats Is Nothing Then
        Dim d As Object, s As Variant, i As Long, k As String
        Set d = CreateObject("Scripting.Dictionary")
        d.CompareMode = vbTextCompare
        s = GetAllSettings(FC_APP, SEC_FOLDERS)
        If IsArray(s) Then
            For i = LBound(s, 1) To UBound(s, 1)
                k = CStr(s(i, 1))
                If k <> "" And Not d.Exists(k) Then d.Add k, True
            Next
        End If
        Set mMappedCats = d
    End If
    Set MappedCategories = mMappedCats
End Function

' Is this one of the categories FolderChain manages?
Private Function IsFolderCategory(ByVal catName As String, ByVal alsoStrip As String) As Boolean
    If catName = "" Then Exit Function
    If alsoStrip <> "" Then
        If StrComp(catName, alsoStrip, vbTextCompare) = 0 Then IsFolderCategory = True: Exit Function
    End If
    If MappedCategories().Exists(catName) Then IsFolderCategory = True: Exit Function
    If FC_CATEGORY_PREFIX <> "" Then
        If StrComp(Left$(catName, Len(FC_CATEGORY_PREFIX)), FC_CATEGORY_PREFIX, vbTextCompare) = 0 Then IsFolderCategory = True
    End If
End Function

'==============================================================================
' Categories and colors
'==============================================================================

Public Function FC_ColorNames() As Variant
    ' Index = OlCategoryColor value.
    FC_ColorNames = Array("None", "Red", "Orange", "Peach", "Yellow", "Green", _
        "Teal", "Olive", "Blue", "Purple", "Maroon", "Steel", "Dark Steel", _
        "Gray", "Dark Gray", "Black", "Dark Red", "Dark Orange", "Dark Peach", _
        "Dark Yellow", "Dark Green", "Dark Teal", "Dark Olive", "Dark Blue", _
        "Dark Purple", "Dark Maroon")
End Function

Public Function FC_ColorName(ByVal colorValue As Long) As String
    Dim names As Variant
    names = FC_ColorNames()
    If colorValue >= 0 And colorValue <= UBound(names) Then
        FC_ColorName = names(colorValue)
    Else
        FC_ColorName = "?"
    End If
End Function

' Asks for a color (number or name). Returns -1 if the user cancels.
Public Function FC_AskColor(ByVal folderName As String, ByVal current As Long) As Long
    Dim names As Variant, prompt As String, i As Long, s As String
    names = FC_ColorNames()
    For i = 1 To 25
        prompt = prompt & i & " " & names(i)
        If i Mod 3 = 0 Then prompt = prompt & vbCrLf Else prompt = prompt & "      "
    Next

    Do
        s = InputBox("Color for '" & folderName & "':" & vbCrLf & vbCrLf & prompt & _
                     vbCrLf & vbCrLf & "Type a number or a color name:", _
                     FC_APP & " - folder color", IIf(current > 0, CStr(current), ""))
        If StrPtr(s) = 0 Then FC_AskColor = -1: Exit Function
        s = Trim$(s)
        If IsNumeric(s) Then
            i = CLng(s)
            If i >= 1 And i <= 25 Then FC_AskColor = i: Exit Function
        ElseIf s <> "" Then
            For i = 1 To 25
                If StrComp(names(i), s, vbTextCompare) = 0 Then FC_AskColor = i: Exit Function
            Next
        End If
        MsgBox "Please type a number from 1 to 25 or one of the color names.", vbExclamation, FC_APP
    Loop
End Function

' Creates the category in Outlook's master list, or updates its color.
Public Sub FC_EnsureCategory(ByVal catName As String, ByVal colorValue As Long)
    Dim c As Outlook.Category
    For Each c In Application.Session.Categories
        If StrComp(c.Name, catName, vbTextCompare) = 0 Then
            c.Color = colorValue
            Exit Sub
        End If
    Next
    Application.Session.Categories.Add catName, colorValue
End Sub

' Returns the category's OlCategoryColor, or -1 if it doesn't exist.
Public Function FC_CategoryColor(ByVal catName As String) As Long
    Dim c As Outlook.Category
    FC_CategoryColor = -1
    If catName = "" Then Exit Function
    For Each c In Application.Session.Categories
        If StrComp(c.Name, catName, vbTextCompare) = 0 Then
            FC_CategoryColor = c.Color
            Exit Function
        End If
    Next
End Function

' Windows list separator, which Outlook uses between categories.
Private Function ListSep() As String
    Static sep As String
    If sep = "" Then
        On Error Resume Next
        sep = CreateObject("WScript.Shell").RegRead("HKCU\Control Panel\International\sList")
        On Error GoTo 0
        If sep = "" Then sep = ","
    End If
    ListSep = sep
End Function

' Gives the item exactly one FolderChain category (or none if catName = "").
' Other categories the item has are left alone. Saves only when something
' changed.
Public Sub FC_SetItemFolderCategory(ByVal it As Object, ByVal catName As String, _
                                    Optional ByVal alsoStrip As String = "")
    On Error GoTo Done
    Dim cur As String, parts() As String, i As Long, p As String
    Dim result As String, hasCat As Boolean, changed As Boolean, sep As String

    sep = ListSep()
    cur = it.Categories
    cur = Replace(Replace(cur, ";", ","), sep, ",")
    parts = Split(cur, ",")

    For i = LBound(parts) To UBound(parts)
        p = Trim$(parts(i))
        If p <> "" Then
            If catName <> "" And StrComp(p, catName, vbTextCompare) = 0 Then
                If Not hasCat Then
                    hasCat = True
                    result = AppendCat(result, p, sep)
                End If
            ElseIf IsFolderCategory(p, alsoStrip) Then
                changed = True            ' drop the stale folder category
            Else
                result = AppendCat(result, p, sep)
            End If
        End If
    Next

    If catName <> "" And Not hasCat Then
        result = AppendCat(result, catName, sep)
        changed = True
    End If

    If changed Then
        it.Categories = result
        it.Save
    End If
Done:
End Sub

Private Function AppendCat(ByVal list As String, ByVal catName As String, ByVal sep As String) As String
    If list = "" Then AppendCat = catName Else AppendCat = list & sep & " " & catName
End Function

'==============================================================================
' Chains (Outlook conversations)
'==============================================================================

' Every item in the item's conversation (all folders of that mailbox,
' including Sent Items). Falls back to just the item itself when the mailbox
' doesn't support conversations.
Public Function FC_ConversationItems(ByVal item As Object) As Collection
    Dim col As New Collection, conv As Outlook.Conversation
    Dim roots As Outlook.SimpleItems, i As Long

    On Error Resume Next
    Set conv = item.GetConversation
    On Error GoTo 0

    If Not conv Is Nothing Then
        On Error Resume Next
        Set roots = conv.GetRootItems
        On Error GoTo 0
        If Not roots Is Nothing Then
            For i = 1 To roots.Count
                AddBranch conv, roots.Item(i), col, 0
            Next
        End If
    End If

    If col.Count = 0 Then col.Add item
    Set FC_ConversationItems = col
End Function

Private Sub AddBranch(ByVal conv As Outlook.Conversation, ByVal it As Object, _
                      ByVal col As Collection, ByVal depth As Long)
    Dim kids As Outlook.SimpleItems, i As Long
    If depth > 500 Then Exit Sub
    col.Add it
    On Error Resume Next
    Set kids = conv.GetChildren(it)
    On Error GoTo 0
    If kids Is Nothing Then Exit Sub
    For i = 1 To kids.Count
        AddBranch conv, kids.Item(i), col, depth + 1
    Next
End Sub

' True for a normal mail folder that mail gets filed in (not Inbox, Sent
' Items, Deleted Items, Drafts, Junk, an excluded name, a calendar, ...).
Public Function FC_IsFilingFolder(ByVal f As Outlook.Folder) As Boolean
    On Error GoTo Nope
    If f Is Nothing Then Exit Function
    If f.DefaultItemType <> olMailItem Then Exit Function

    Dim st As Outlook.Store, delPath As String
    Set st = f.Store
    LoadExclusions st
    If mExcluded.Exists(f.EntryID) Then Exit Function

    delPath = mStoreDeleted(st.StoreID)
    If delPath <> "" Then
        If StrComp(Left$(f.FolderPath, Len(delPath) + 1), delPath & "\", vbTextCompare) = 0 Then Exit Function
    End If

    If InStr(1, ";" & FC_EXCLUDED_FOLDER_NAMES & ";", ";" & f.Name & ";", vbTextCompare) > 0 Then Exit Function

    ' The mailbox root itself isn't a filing folder.
    If f.EntryID = st.GetRootFolder.EntryID Then Exit Function

    FC_IsFilingFolder = True
Nope:
End Function

Private Sub LoadExclusions(ByVal st As Outlook.Store)
    If mExcluded Is Nothing Then
        Set mExcluded = CreateObject("Scripting.Dictionary")
        Set mStoreDeleted = CreateObject("Scripting.Dictionary")
    End If

    Dim sid As String
    sid = st.StoreID
    If mStoreDeleted.Exists(sid) Then Exit Sub

    Dim ids As Variant, i As Long, f As Outlook.Folder, delPath As String
    ids = Array(olFolderInbox, olFolderSentMail, olFolderDeletedItems, olFolderDrafts, _
                olFolderOutbox, olFolderJunk, olFolderConflicts, olFolderLocalFailures, _
                olFolderServerFailures, olFolderSyncIssues, olFolderRssFeeds)
    For i = LBound(ids) To UBound(ids)
        Set f = Nothing
        On Error Resume Next
        Set f = st.GetDefaultFolder(ids(i))
        On Error GoTo 0
        If Not f Is Nothing Then
            mExcluded(f.EntryID) = True
            If ids(i) = olFolderDeletedItems Then delPath = f.FolderPath
        End If
    Next
    mStoreDeleted(sid) = delPath
End Sub

' Received time for mail, sent time for sent mail, else creation time.
Public Function FC_ItemTime(ByVal it As Object) As Date
    Dim t As Date
    On Error Resume Next
    t = it.ReceivedTime
    If t = 0 Or Year(t) >= 4000 Then t = it.SentOn
    If t = 0 Or Year(t) >= 4000 Then t = it.CreationTime
    FC_ItemTime = t
End Function

' The folder holding the most recent item of the chain that is in a filing
' folder. Ignores the item whose EntryID is excludeEntryID (use that when
' working out where to file that item). Nothing if the chain isn't filed.
Public Function FC_ChainFolderFromItems(ByVal items As Collection, _
                                        Optional ByVal excludeEntryID As String = "") As Outlook.Folder
    Dim it As Object, f As Outlook.Folder, best As Outlook.Folder
    Dim bestT As Date, t As Date, eid As String

    For Each it In items
        eid = ""
        Set f = Nothing
        On Error Resume Next
        eid = it.EntryID
        Set f = it.Parent
        On Error GoTo 0

        If Not f Is Nothing Then
            If excludeEntryID = "" Or eid <> excludeEntryID Then
                If FC_IsFilingFolder(f) Then
                    t = FC_ItemTime(it)
                    If best Is Nothing Or t > bestT Then
                        Set best = f
                        bestT = t
                    End If
                End If
            End If
        End If
    Next
    Set FC_ChainFolderFromItems = best
End Function

Public Function FC_FindChainFolder(ByVal item As Object, ByVal excludeSelf As Boolean) As Outlook.Folder
    Dim excl As String
    If excludeSelf Then
        On Error Resume Next
        excl = item.EntryID
        On Error GoTo 0
    End If
    Set FC_FindChainFolder = FC_ChainFolderFromItems(FC_ConversationItems(item), excl)
End Function

'==============================================================================
' Coloring
'==============================================================================

' Colors every email in the item's chain with the category of the folder the
' chain is filed in. Returns True if a color was applied.
'   force     - run even when no folder has a color yet (used when removing).
'   alsoStrip - an extra category to remove (a color that was just removed).
Public Function FC_RecolorConversation(ByVal item As Object, _
                                       Optional ByVal force As Boolean = False, _
                                       Optional ByVal alsoStrip As String = "") As Boolean
    On Error GoTo Done
    If Not force Then
        If MappedCategories().Count = 0 Then Exit Function
    End If

    Dim items As Collection, chain As Outlook.Folder, cat As String, it As Object
    Set items = FC_ConversationItems(item)
    Set chain = FC_ChainFolderFromItems(items)
    If chain Is Nothing Then
        If alsoStrip = "" Then Exit Function   ' chain not filed: leave as is
    Else
        cat = FC_GetFolderCategory(chain)
    End If

    For Each it In items
        FC_SetItemFolderCategory it, cat, alsoStrip
    Next
    FC_RecolorConversation = (cat <> "")
Done:
End Function

' Recolors the chains of the mail in a folder (one pass per conversation).
' Returns the number of conversations that got a color.
Public Function FC_RecolorFolder(ByVal f As Outlook.Folder, ByVal daysBack As Long, _
                                 Optional ByVal alsoStrip As String = "") As Long
    Dim its As Outlook.Items, it As Object, seen As Object
    Dim cid As String, n As Long, i As Long, total As Long, since As String

    On Error GoTo Fail
    Set seen = CreateObject("Scripting.Dictionary")
    Set its = f.Items
    If daysBack > 0 Then
        since = Format$(DateAdd("d", -daysBack, Date), "ddddd h:nn AMPM")
        Set its = its.Restrict("[ReceivedTime] >= '" & since & "'")
    End If

    gFC_Busy = True
    total = its.Count
    For i = 1 To total
        Set it = Nothing
        cid = ""
        On Error Resume Next
        Set it = its.Item(i)
        cid = it.ConversationID
        On Error GoTo Fail

        If Not it Is Nothing Then
            If cid = "" Then
                If FC_RecolorConversation(it, True, alsoStrip) Then n = n + 1
            ElseIf Not seen.Exists(cid) Then
                seen.Add cid, True
                If FC_RecolorConversation(it, True, alsoStrip) Then n = n + 1
            End If
        End If
        If i Mod 20 = 0 Then DoEvents
    Next
Fail:
    gFC_Busy = False
    FC_RecolorFolder = n
End Function
