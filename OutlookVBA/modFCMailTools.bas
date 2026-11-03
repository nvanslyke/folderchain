Attribute VB_Name = "modFCMailTools"
'==============================================================================
' FolderChain for Outlook - email tools.
'
'   FC_SaveEmailAndAttachments   save the email (.msg) and all its attachments
'   FC_RenameAttachments         rename attachments on the draft you're writing
'   FC_ScheduleMeetingWithChain  new meeting invite with everyone on the chain
'==============================================================================
Option Explicit

'==============================================================================
' Save email + attachments
'==============================================================================

Public Sub FC_SaveEmailAndAttachments()
    Dim items As Collection, root As String, useSub As Boolean
    Set items = FC_GetSelectedItems()
    If items.Count = 0 Then
        MsgBox "Select or open an email first.", vbInformation, FC_APP
        Exit Sub
    End If

    root = ChooseSaveFolder()
    If root = "" Then Exit Sub
    useSub = (FC_SUBFOLDER_MODE = 2) Or (FC_SUBFOLDER_MODE = 1 And items.Count > 1)

    Dim fso As Object, it As Object, dest As String, baseName As String
    Dim nMsg As Long, nAtt As Long, errs As String
    Set fso = CreateObject("Scripting.FileSystemObject")

    For Each it In items
        baseName = EmailBaseName(it)
        dest = root
        If useSub Then
            dest = FC_UniquePath(root, baseName, "")
            On Error Resume Next
            fso.CreateFolder dest
            On Error GoTo 0
            If Not fso.FolderExists(dest) Then dest = root
        End If

        On Error Resume Next
        Err.Clear
        it.SaveAs FC_UniquePath(dest, baseName, ".msg"), olMSGUnicode
        If Err.Number = 0 Then
            nMsg = nMsg + 1
        Else
            errs = errs & "Email '" & baseName & "': " & Err.Description & vbCrLf
        End If
        On Error GoTo 0

        nAtt = nAtt + SaveAttachments(it, dest, errs)
    Next

    Dim msg As String
    msg = "Saved " & nMsg & IIf(nMsg = 1, " email", " emails") & " and " & nAtt & _
          IIf(nAtt = 1, " attachment", " attachments") & " to:" & vbCrLf & root
    If errs <> "" Then msg = msg & vbCrLf & vbCrLf & "Problems:" & vbCrLf & errs
    If MsgBox(msg & vbCrLf & vbCrLf & "Open the folder?", vbYesNo + _
              IIf(errs = "", vbInformation, vbExclamation), FC_APP) = vbYes Then
        Shell "explorer.exe """ & root & """", vbNormalFocus
    End If
End Sub

Private Function SaveAttachments(ByVal it As Object, ByVal dest As String, ByRef errs As String) As Long
    Dim html As String, i As Long, att As Outlook.Attachment, fn As String
    Dim b As String, ext As String, n As Long

    On Error Resume Next
    html = it.HTMLBody
    On Error GoTo 0

    For i = 1 To it.Attachments.Count
        Set att = it.Attachments.Item(i)
        If FC_SKIP_INLINE_IMAGES And FC_IsInlineAttachment(att, html) Then GoTo NextAtt

        fn = ""
        On Error Resume Next
        fn = att.FileName
        If fn = "" Then fn = att.DisplayName & IIf(att.Type = olEmbeddeditem, ".msg", "")
        On Error GoTo 0
        fn = FC_SafeFileName(fn, 200)
        If fn = "" Then fn = "attachment " & i
        FC_SplitExt fn, b, ext

        On Error Resume Next
        Err.Clear
        att.SaveAsFile FC_UniquePath(dest, b, ext)
        If Err.Number = 0 Then
            n = n + 1
        Else
            errs = errs & "Attachment '" & fn & "': " & Err.Description & vbCrLf
        End If
        On Error GoTo 0
NextAtt:
    Next
    SaveAttachments = n
End Function

' "2026-11-03 0915 - Subject"
Private Function EmailBaseName(ByVal it As Object) As String
    Dim subj As String
    On Error Resume Next
    subj = it.Subject
    On Error GoTo 0
    If Trim$(subj) = "" Then subj = "(no subject)"
    EmailBaseName = Format$(FC_ItemTime(it), "yyyy-mm-dd hhnn") & " - " & FC_SafeFileName(subj, 80)
End Function

' Offers the last folder used; otherwise shows Windows' folder browser.
Private Function ChooseSaveFolder() As String
    Dim fso As Object, last As String, ans As VbMsgBoxResult
    Dim sh As Object, fld As Object, p As String

    Set fso = CreateObject("Scripting.FileSystemObject")
    last = GetSetting(FC_APP, "Save", "LastFolder", "")
    If last <> "" Then
        If fso.FolderExists(last) Then
            ans = MsgBox("Save to this folder?" & vbCrLf & vbCrLf & last & vbCrLf & vbCrLf & _
                         "Yes = save here" & vbCrLf & "No = choose a different folder", _
                         vbYesNoCancel + vbQuestion, FC_APP & " - save email + attachments")
            If ans = vbCancel Then Exit Function
            If ans = vbYes Then ChooseSaveFolder = last: Exit Function
        End If
    End If

    Set sh = CreateObject("Shell.Application")
    ' &H51 = only file system folders + "make new folder" button + path box
    Set fld = sh.BrowseForFolder(0, "Where should the email and its attachments be saved?", &H51)
    If fld Is Nothing Then Exit Function

    On Error Resume Next
    p = fld.Self.Path
    On Error GoTo 0
    If p = "" Or Not fso.FolderExists(p) Then
        MsgBox "Please choose a normal folder on your computer or network drive.", vbExclamation, FC_APP
        Exit Function
    End If

    SaveSetting FC_APP, "Save", "LastFolder", p
    ChooseSaveFolder = p
End Function

'==============================================================================
' Rename attachments on a draft
'==============================================================================

Public Sub FC_RenameAttachments()
    Dim m As Outlook.MailItem, html As String, i As Long, n As Long
    Dim idx() As Long, lst As String, s As String, pick As Long
    Dim att As Outlook.Attachment, oldName As String, newName As String

    Set m = CurrentDraft()
    If m Is Nothing Then
        MsgBox "Open the email you're writing (or start a reply) first." & vbCrLf & _
               "Attachments can only be renamed on emails that haven't been sent.", vbInformation, FC_APP
        Exit Sub
    End If

    Do
        On Error Resume Next
        html = ""
        html = m.HTMLBody
        On Error GoTo 0

        ' List the real file attachments (not pictures in the body).
        n = 0
        lst = ""
        ReDim idx(1 To m.Attachments.Count + 1)
        For i = 1 To m.Attachments.Count
            Set att = m.Attachments.Item(i)
            If att.Type = olByValue And Not FC_IsInlineAttachment(att, html) Then
                n = n + 1
                idx(n) = i
                lst = lst & n & ".   " & att.FileName & vbCrLf
            End If
        Next
        If n = 0 Then
            MsgBox "This email has no file attachments to rename." & vbCrLf & _
                   "(Cloud/OneDrive links and pictures in the body can't be renamed.)", vbInformation, FC_APP
            Exit Sub
        End If

        If n = 1 Then
            pick = 1
        Else
            s = InputBox("Attachments:" & vbCrLf & vbCrLf & lst & vbCrLf & _
                         "Type the number of the one to rename (Cancel when done):", _
                         FC_APP & " - rename attachment", "1")
            If StrPtr(s) = 0 Then Exit Sub
            s = Trim$(s)
            If s = "" Then Exit Sub
            If Not IsNumeric(s) Then GoTo NextRound
            pick = CLng(s)
            If pick < 1 Or pick > n Then GoTo NextRound
        End If

        Set att = m.Attachments.Item(idx(pick))
        oldName = att.FileName
        newName = InputBox("New name for:" & vbCrLf & oldName & vbCrLf & vbCrLf & _
                           "(The extension, e.g. .pdf, is kept automatically.)", _
                           FC_APP & " - rename attachment", oldName)
        If StrPtr(newName) = 0 Then
            If n = 1 Then Exit Sub
            GoTo NextRound
        End If

        newName = CleanNewName(newName, oldName)
        If newName <> "" And newName <> oldName Then
            If Not ReplaceAttachment(m, att, newName) Then Exit Sub
        End If
        If n = 1 Then Exit Sub
NextRound:
    Loop
End Sub

' The unsent email in the active window, the inline reply in the reading
' pane, or a single selected draft.
Private Function CurrentDraft() As Outlook.MailItem
    Dim obj As Object
    On Error Resume Next
    If TypeName(Application.ActiveWindow) = "Inspector" Then
        Set obj = Application.ActiveInspector.CurrentItem
    Else
        Set obj = Application.ActiveExplorer.ActiveInlineResponse
        If obj Is Nothing Then
            If Application.ActiveExplorer.Selection.Count = 1 Then
                Set obj = Application.ActiveExplorer.Selection.Item(1)
            End If
        End If
    End If
    On Error GoTo 0

    If obj Is Nothing Then Exit Function
    If Not TypeOf obj Is Outlook.MailItem Then Exit Function
    If obj.Sent Then Exit Function
    Set CurrentDraft = obj
End Function

' Removes characters Windows can't use and keeps the old extension when the
' user didn't type one.
Private Function CleanNewName(ByVal newName As String, ByVal oldName As String) As String
    Dim ob As String, oe As String, nb As String, ne As String
    newName = FC_SafeFileName(newName, 200)
    If newName = "" Then Exit Function
    FC_SplitExt oldName, ob, oe
    FC_SplitExt newName, nb, ne
    ' Keep the original extension so the file still opens: "Invoice 3.2"
    ' for "scan.pdf" becomes "Invoice 3.2.pdf".
    If oe <> "" And LCase$(ne) <> LCase$(oe) Then newName = newName & oe
    CleanNewName = newName
End Function

' Outlook can't rename an attachment in place, so save it under the new name
' and attach that copy instead of the original.
Private Function ReplaceAttachment(ByVal m As Outlook.MailItem, ByVal att As Outlook.Attachment, _
                                   ByVal newName As String) As Boolean
    Dim fso As Object, tmpDir As String, tmpPath As String, newAtt As Outlook.Attachment

    On Error GoTo Fail
    Set fso = CreateObject("Scripting.FileSystemObject")
    tmpDir = Environ$("TEMP") & "\FolderChain_" & Format$(Now, "yyyymmddhhnnss") & "_" & CLng(Timer * 100)
    fso.CreateFolder tmpDir
    tmpPath = tmpDir & "\" & newName

    att.SaveAsFile tmpPath
    Set newAtt = m.Attachments.Add(tmpPath, olByValue, , newName)
    att.Delete
    ReplaceAttachment = True

Cleanup:
    On Error Resume Next
    If tmpPath <> "" Then fso.DeleteFile tmpPath, True
    If tmpDir <> "" Then fso.DeleteFolder tmpDir, True
    Exit Function
Fail:
    MsgBox "Couldn't rename the attachment: " & Err.Description, vbExclamation, FC_APP
    Resume Cleanup
End Function

'==============================================================================
' Schedule a meeting with everyone on the chain
'==============================================================================

' Opens a brand-new meeting invite (not "Reply with Meeting", so it doesn't
' land in the chain) with everyone who sent or received any email in the
' selected chain(s). You can edit everything before sending.
Public Sub FC_ScheduleMeetingWithChain()
    Dim items As Collection, sel As Object, it As Object
    Dim people As Object, mine As Object, seenConv As Object, cid As String

    Set items = FC_GetSelectedItems()
    If items.Count = 0 Then
        MsgBox "Select or open an email in the chain first.", vbInformation, FC_APP
        Exit Sub
    End If

    Set people = CreateObject("Scripting.Dictionary")
    people.CompareMode = vbTextCompare
    Set seenConv = CreateObject("Scripting.Dictionary")
    Set mine = FC_MyAddresses()

    For Each sel In items
        cid = ""
        On Error Resume Next
        cid = sel.ConversationID
        On Error GoTo 0
        If cid = "" Or Not seenConv.Exists(cid) Then
            If cid <> "" Then seenConv.Add cid, True
            For Each it In FC_ConversationItems(sel)
                CollectPeople it, people, mine
            Next
        End If
    Next

    If people.Count = 0 Then
        MsgBox "Couldn't find anyone else on this chain.", vbInformation, FC_APP
        Exit Sub
    End If

    Dim topic As String
    On Error Resume Next
    topic = items(1).ConversationTopic
    If topic = "" Then topic = items(1).Subject
    On Error GoTo 0

    Dim appt As Outlook.AppointmentItem, k As Variant, r As Outlook.Recipient
    Set appt = Application.CreateItem(olAppointmentItem)
    appt.MeetingStatus = olMeeting
    appt.Subject = FC_MEETING_SUBJECT_PREFIX & topic
    For Each k In people.Keys
        Set r = appt.Recipients.Add(CStr(k))
        r.Type = people(k)
    Next
    appt.Recipients.ResolveAll
    appt.Display
End Sub

Private Sub CollectPeople(ByVal it As Object, ByVal people As Object, ByVal mine As Object)
    Dim i As Long, r As Outlook.Recipient, kind As Long
    If Not FC_IsMailLike(it) Then Exit Sub

    AddPerson people, mine, FC_SenderSmtp(it), olRequired

    On Error Resume Next
    For i = 1 To it.Recipients.Count
        Set r = Nothing
        Set r = it.Recipients.Item(i)
        If Not r Is Nothing Then
            kind = r.Type
            If kind = olTo Then
                AddPerson people, mine, FC_RecipientSmtp(r), olRequired
            ElseIf kind = olCC Then
                AddPerson people, mine, FC_RecipientSmtp(r), IIf(FC_CC_AS_OPTIONAL, olOptional, olRequired)
            End If
            ' BCC is skipped on purpose.
        End If
    Next
End Sub

Private Sub AddPerson(ByVal people As Object, ByVal mine As Object, ByVal addr As String, ByVal kind As Long)
    addr = Trim$(addr)
    If addr = "" Then Exit Sub
    If mine.Exists(addr) Then Exit Sub
    If people.Exists(addr) Then
        If kind = olRequired Then people(addr) = olRequired
    Else
        people.Add addr, kind
    End If
End Sub
