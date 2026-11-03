Attribute VB_Name = "modFCCommands"
'==============================================================================
' FolderChain for Outlook - filing and color buttons.
'
' Put these macros on the ribbon (File > Options > Customize Ribbon >
' Choose commands from: Macros). See README.md.
'
'   FC_FileToChainFolder     one click: move email(s) to the chain's folder
'   FC_MoveToFolder          folder picker that starts on the chain's folder
'   FC_SetFolderColor        choose a color for a folder
'   FC_RemoveFolderColor     stop coloring a folder
'   FC_ListFolderColors      show which folders have which colors
'   FC_RecolorSelected       re-check the color of the selected chain(s)
'   FC_RecolorInbox          re-check the colors of everything in the Inbox
'   FC_ApplyRowColorsToView  also color the text of whole rows in this view
'==============================================================================
Option Explicit

'==============================================================================
' Filing
'==============================================================================

' Moves each selected email into the folder the rest of its chain is filed
' in. Emails whose chain isn't filed anywhere yet get a folder picker.
Public Sub FC_FileToChainFolder()
    Dim items As Collection, n As Long, i As Long
    Set items = FC_GetSelectedItems()
    n = items.Count
    If n = 0 Then
        MsgBox "Select one or more emails first.", vbInformation, FC_APP
        Exit Sub
    End If

    ' Work out every target before moving anything.
    Dim targets() As Outlook.Folder, cache As Object, cid As String, it As Object
    ReDim targets(1 To n)
    Set cache = CreateObject("Scripting.Dictionary")
    For i = 1 To n
        Set it = items(i)
        cid = ""
        On Error Resume Next
        cid = it.ConversationID
        On Error GoTo 0
        If cid <> "" And cache.Exists(cid) Then
            If IsObject(cache(cid)) Then Set targets(i) = cache(cid)
        Else
            Set targets(i) = FC_FindChainFolder(it, True)
            If cid <> "" Then
                If targets(i) Is Nothing Then cache.Add cid, Empty Else cache.Add cid, targets(i)
            End If
        End If
    Next

    Dim moved As New Collection, orphans As New Collection, already As Long
    Dim lastTarget As Outlook.Folder, m As Object

    gFC_Busy = True
    For i = 1 To n
        If targets(i) Is Nothing Then
            orphans.Add items(i)
        ElseIf FC_SameFolder(items(i).Parent, targets(i)) Then
            already = already + 1
        Else
            Set m = Nothing
            On Error Resume Next
            Set m = items(i).Move(targets(i))
            On Error GoTo 0
            If Not m Is Nothing Then
                moved.Add m
                Set lastTarget = targets(i)
            End If
        End If
    Next
    gFC_Busy = False

    If orphans.Count > 0 Then
        Dim pick As Outlook.Folder, def As Outlook.Folder
        Set def = FC_GetLastMoveFolder()
        If def Is Nothing Then Set def = Application.ActiveExplorer.CurrentFolder
        Set pick = FC_PickFolder("File to folder", _
            IIf(orphans.Count = 1, "This email's chain", orphans.Count & " of these chains") & _
            " isn't filed in a folder yet. Choose where to file it:", def, "Move here")
        If Not pick Is Nothing Then
            MoveAll orphans, pick, moved
            Set lastTarget = pick
        End If
    End If

    If Not lastTarget Is Nothing Then FC_SetLastMoveFolder lastTarget
    RecolorMoved moved

    If moved.Count = 0 And already > 0 And orphans.Count = 0 Then
        MsgBox IIf(already = 1, "This email is", "These emails are") & _
               " already in the chain's folder.", vbInformation, FC_APP
    End If
End Sub

' Folder picker for moving email that starts on the folder the chain is
' filed in (instead of the last folder you used).
Public Sub FC_MoveToFolder()
    Dim items As Collection, def As Outlook.Folder, info As String, target As Outlook.Folder
    Set items = FC_GetSelectedItems()
    If items.Count = 0 Then
        MsgBox "Select one or more emails first.", vbInformation, FC_APP
        Exit Sub
    End If

    Set def = FC_FindChainFolder(items(1), True)
    If def Is Nothing Then
        info = "This chain isn't filed anywhere yet, so your last-used folder is selected."
        Set def = FC_GetLastMoveFolder()
        If def Is Nothing Then Set def = Application.ActiveExplorer.CurrentFolder
    Else
        info = "Selected: the folder this chain is filed in. Press Enter to move there, or type to find another folder."
    End If

    Set target = FC_PickFolder("Move " & items.Count & IIf(items.Count = 1, " email", " emails") & " to folder", _
                               info, def, "Move here")
    If target Is Nothing Then Exit Sub

    Dim moved As New Collection
    gFC_Busy = True
    MoveAll items, target, moved
    gFC_Busy = False
    FC_SetLastMoveFolder target
    RecolorMoved moved
End Sub

Private Sub MoveAll(ByVal items As Collection, ByVal target As Outlook.Folder, ByVal moved As Collection)
    Dim it As Object, m As Object
    For Each it In items
        If Not FC_SameFolder(it.Parent, target) Then
            Set m = Nothing
            On Error Resume Next
            Set m = it.Move(target)
            On Error GoTo 0
            If Not m Is Nothing Then moved.Add m
        End If
    Next
End Sub

Private Sub RecolorMoved(ByVal moved As Collection)
    If Not FC_AUTO_COLOR Then Exit Sub
    Dim it As Object, seen As Object, cid As String
    Set seen = CreateObject("Scripting.Dictionary")
    For Each it In moved
        cid = ""
        On Error Resume Next
        cid = it.ConversationID
        On Error GoTo 0
        If cid = "" Then
            FC_RecolorConversation it
        ElseIf Not seen.Exists(cid) Then
            seen.Add cid, True
            FC_RecolorConversation it
        End If
    Next
End Sub

'==============================================================================
' Colors
'==============================================================================

Public Sub FC_SetFolderColor()
    Dim f As Outlook.Folder, oldCat As String, catName As String, col As Long, n As Long

    Set f = FC_PickFolder("Set folder color", _
        "Choose the folder whose email chains should be color coded:", _
        Application.ActiveExplorer.CurrentFolder, "Next")
    If f Is Nothing Then Exit Sub

    If Not FC_IsFilingFolder(f) Then
        MsgBox "'" & f.Name & "' is a system folder (Inbox, Sent Items, Archive, ...)." & vbCrLf & _
               "Colors follow the folder a chain is filed in, so pick the folder you file mail into.", _
               vbExclamation, FC_APP
        Exit Sub
    End If

    oldCat = FC_GetFolderCategory(f)
    col = FC_AskColor(f.Name, FC_CategoryColor(oldCat))
    If col < 0 Then Exit Sub

    catName = oldCat
    If catName = "" Then catName = FC_CATEGORY_PREFIX & f.Name
    catName = InputBox("Name of the category that shows this color:", FC_APP & " - category name", catName)
    If StrPtr(catName) = 0 Then Exit Sub
    catName = Trim$(Replace(Replace(catName, ",", " "), ";", " "))
    If catName = "" Then Exit Sub

    FC_EnsureCategory catName, col
    FC_SaveFolderCategory f, catName
    FC_StartWatchers

    If MsgBox("'" & f.Name & "' is now " & FC_ColorName(col) & "." & vbCrLf & vbCrLf & _
              "New and filed email in its chains will be colored from now on." & vbCrLf & vbCrLf & _
              "Color the email chains already in this folder too (last " & FC_RECOLOR_DAYS_BACK & _
              " days)? Their emails in your Inbox and Sent Items are included. " & _
              "This can take a minute for big folders.", vbYesNo + vbQuestion, FC_APP) = vbYes Then
        n = FC_RecolorFolder(f, FC_RECOLOR_DAYS_BACK, IIf(oldCat <> catName, oldCat, ""))
        MsgBox "Done: " & n & " chain(s) colored.", vbInformation, FC_APP
    End If
End Sub

Public Sub FC_RemoveFolderColor()
    Dim f As Outlook.Folder, catName As String, n As Long
    Set f = FC_PickFolder("Remove folder color", "Choose the folder to stop color coding:", _
                          Application.ActiveExplorer.CurrentFolder, "Remove")
    If f Is Nothing Then Exit Sub

    catName = FC_GetFolderCategory(f)
    If catName = "" Then
        MsgBox "'" & f.Name & "' doesn't have a color.", vbInformation, FC_APP
        Exit Sub
    End If

    FC_ClearFolderCategory f
    FC_StartWatchers

    If MsgBox("'" & f.Name & "' will no longer be colored." & vbCrLf & vbCrLf & _
              "Also take the '" & catName & "' color off the email chains in it now (last " & _
              FC_RECOLOR_DAYS_BACK & " days)?", vbYesNo + vbQuestion, FC_APP) = vbYes Then
        FC_RecolorFolder f, FC_RECOLOR_DAYS_BACK, catName
        MsgBox "Done.", vbInformation, FC_APP
    End If
End Sub

Public Sub FC_ListFolderColors()
    Dim s As Variant, i As Long, f As Outlook.Folder, msg As String, nm As String
    s = FC_GetMappings()
    If Not IsArray(s) Then
        MsgBox "No folders have a color yet. Use 'Set Folder Color' to add one.", vbInformation, FC_APP
        Exit Sub
    End If

    For i = LBound(s, 1) To UBound(s, 1)
        Set f = Nothing
        On Error Resume Next
        Set f = Application.Session.GetFolderFromID(CStr(s(i, 0)))
        On Error GoTo 0
        If f Is Nothing Then nm = "(folder not found)" Else nm = Mid$(f.FolderPath, 3)
        msg = msg & FC_ColorName(FC_CategoryColor(CStr(s(i, 1)))) & "  -  " & nm & _
              "   [" & s(i, 1) & "]" & vbCrLf
    Next
    MsgBox msg, vbInformation, FC_APP & " - folder colors"
End Sub

Public Sub FC_RecolorSelected()
    Dim items As Collection, it As Object, n As Long, colored As Long
    Set items = FC_GetSelectedItems()
    If items.Count = 0 Then
        MsgBox "Select one or more emails first.", vbInformation, FC_APP
        Exit Sub
    End If
    For Each it In items
        If FC_RecolorConversation(it, True) Then colored = colored + 1
    Next
    If colored = 0 Then
        MsgBox "No color applied: the chain isn't filed in a folder that has a color.", vbInformation, FC_APP
    End If
End Sub

Public Sub FC_RecolorInbox()
    Dim n As Long
    If MsgBox("Check the colors of every chain in your Inbox from the last " & FC_RECOLOR_DAYS_BACK & _
              " days? This can take a minute.", vbOKCancel + vbQuestion, FC_APP) <> vbOK Then Exit Sub
    n = FC_RecolorFolder(Application.Session.GetDefaultFolder(olFolderInbox), FC_RECOLOR_DAYS_BACK)
    MsgBox "Done: " & n & " chain(s) colored.", vbInformation, FC_APP
End Sub

' Categories show as a colored tag. This adds Conditional Formatting rules to
' the current view so the whole row's text takes the folder's color too.
' Run it once in each folder view you want (e.g. Inbox), and again after
' adding colors. Outlook only has 16 text colors, so it picks the closest.
Public Sub FC_ApplyRowColorsToView()
    Dim v As Outlook.View, tv As Outlook.TableView, rules As Outlook.AutoFormatRules
    Dim r As Outlook.AutoFormatRule, s As Variant, i As Long, catName As String
    Dim done As Object, added As Long

    On Error GoTo Fail
    Set v = Application.ActiveExplorer.CurrentView
    If v.ViewType <> olTableView Then
        MsgBox "Switch this folder to a list view (View > Change View > Compact or Single) first.", _
               vbExclamation, FC_APP
        Exit Sub
    End If
    Set tv = v
    Set rules = tv.AutoFormatRules

    For i = rules.Count To 1 Step -1
        If Left$(rules.Item(i).Name, Len(FC_RULE_PREFIX)) = FC_RULE_PREFIX Then rules.Remove i
    Next

    s = FC_GetMappings()
    Set done = CreateObject("Scripting.Dictionary")
    done.CompareMode = vbTextCompare
    If IsArray(s) Then
        For i = LBound(s, 1) To UBound(s, 1)
            catName = CStr(s(i, 1))
            If catName <> "" And Not done.Exists(catName) Then
                done.Add catName, True
                Set r = rules.Add(FC_RULE_PREFIX & catName)
                r.Filter = """urn:schemas-microsoft-com:office:office#Keywords"" LIKE '%" & _
                           Replace(catName, "'", "''") & "%'"
                r.Font.Color = TextColorFor(FC_CategoryColor(catName))
                r.Enabled = True
                added = added + 1
            End If
        Next
    End If

    rules.Save
    tv.Save
    tv.Apply
    MsgBox added & " row color rule(s) set on this view." & vbCrLf & _
           "To change their order or look: View > View Settings > Conditional Formatting.", _
           vbInformation, FC_APP
    Exit Sub
Fail:
    MsgBox "Couldn't change this view: " & Err.Description, vbExclamation, FC_APP
End Sub

' Closest of Outlook's 16 text colors (OlColor) to a category color.
Private Function TextColorFor(ByVal catColor As Long) As Long
    Dim map As Variant
    '            0  1   2  3   4  5  6  7  8   9  10 11 12 13 14 15 16 17 18  19 20 21 22 23 24 25
    map = Array(0, 10, 2, 14, 4, 3, 7, 4, 13, 6, 2, 8, 8, 8, 8, 1, 2, 2, 14, 4, 3, 7, 4, 5, 6, 2)
    If catColor >= 0 And catColor <= UBound(map) Then TextColorFor = map(catColor)
End Function
