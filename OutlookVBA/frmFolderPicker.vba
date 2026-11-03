'==============================================================================
' FolderChain for Outlook - folder picker form code
'
' HOW TO ADD (once):
'   1. In the VBA editor choose Insert > UserForm.
'   2. In the Properties window (F4) change (Name) to:  frmFolderPicker
'   3. Right-click the form > View Code, delete anything there, and paste
'      everything below.
' Don't draw any controls on the form - this code creates them itself.
'
' Keys: type to filter, Up/Down to move, Enter to choose, Esc to cancel.
'==============================================================================
Option Explicit

Private WithEvents txtFilter As MSForms.TextBox
Private WithEvents lstFolders As MSForms.ListBox
Private WithEvents btnOK As MSForms.CommandButton
Private WithEvents btnCancel As MSForms.CommandButton
Private WithEvents btnRefresh As MSForms.CommandButton
Private lblInfo As MSForms.Label
Private lblFilter As MSForms.Label

Private mRows() As Long          ' list row -> index in the folder cache
Private mRowCount As Long
Private mResult As Long          ' chosen folder cache index
Private mCancelled As Boolean
Private mDefaultIndex As Long
Private mStores As Collection

Private Sub UserForm_Initialize()
    mCancelled = True
    mResult = -1
    mDefaultIndex = -1

    Me.Caption = "Choose folder"
    Me.Width = 392
    Me.Height = 466

    Set lblInfo = Me.Controls.Add("Forms.Label.1", "lblInfo")
    With lblInfo
        .Left = 8
        .Top = 6
        .Width = 366
        .Height = 28
        .WordWrap = True
    End With

    Set lblFilter = Me.Controls.Add("Forms.Label.1", "lblFilter")
    With lblFilter
        .Left = 8
        .Top = 38
        .Width = 366
        .Height = 12
        .Caption = "Type part of a folder name to find it:"
    End With

    Set txtFilter = Me.Controls.Add("Forms.TextBox.1", "txtFilter")
    With txtFilter
        .Left = 8
        .Top = 52
        .Width = 366
        .Height = 18
    End With

    Set lstFolders = Me.Controls.Add("Forms.ListBox.1", "lstFolders")
    With lstFolders
        .Left = 8
        .Top = 76
        .Width = 366
        .Height = 318
        .IntegralHeight = False
        .Font.Name = "Segoe UI"
        .Font.Size = 9
    End With

    Set btnRefresh = Me.Controls.Add("Forms.CommandButton.1", "btnRefresh")
    With btnRefresh
        .Left = 8
        .Top = 402
        .Width = 84
        .Height = 24
        .Caption = "Refresh list"
        .TakeFocusOnClick = False
    End With

    Set btnOK = Me.Controls.Add("Forms.CommandButton.1", "btnOK")
    With btnOK
        .Left = 214
        .Top = 402
        .Width = 76
        .Height = 24
        .Caption = "OK"
    End With

    Set btnCancel = Me.Controls.Add("Forms.CommandButton.1", "btnCancel")
    With btnCancel
        .Left = 298
        .Top = 402
        .Width = 76
        .Height = 24
        .Caption = "Cancel"
        .Cancel = True
    End With
End Sub

' Called by FC_PickFolder before the form is shown.
Public Sub Prepare(ByVal title As String, ByVal info As String, _
                   ByVal defaultFolder As Outlook.Folder, ByVal okCaption As String)
    Dim defID As String
    Me.Caption = title
    lblInfo.Caption = info
    btnOK.Caption = okCaption

    Set mStores = New Collection
    If Not defaultFolder Is Nothing Then
        On Error Resume Next
        mStores.Add defaultFolder.Store
        defID = defaultFolder.EntryID
        On Error GoTo 0
    End If

    FC_BuildFolderCache mStores, False
    mDefaultIndex = FC_FolderCacheIndex(defID)
    ApplyFilter
End Sub

Public Property Get Cancelled() As Boolean
    Cancelled = mCancelled
End Property

Public Property Get SelectedFolder() As Outlook.Folder
    If mResult >= 0 Then Set SelectedFolder = FC_FolderFromCache(mResult)
End Property

Private Sub UserForm_Activate()
    On Error Resume Next
    txtFilter.SetFocus
End Sub

Private Sub ApplyFilter()
    Dim f As String, i As Long, keepIdx As Long, sel As Long

    f = Trim$(txtFilter.Text)
    If lstFolders.ListIndex >= 0 Then
        keepIdx = mRows(lstFolders.ListIndex)
    Else
        keepIdx = mDefaultIndex
    End If

    lstFolders.Clear
    mRowCount = 0
    ReDim mRows(0 To gFC_FolderCount)
    sel = -1

    For i = 0 To gFC_FolderCount - 1
        If f = "" Then
            lstFolders.AddItem gFC_FolderLabel(i)
        ElseIf InStr(1, gFC_FolderPath(i), f, vbTextCompare) > 0 Then
            lstFolders.AddItem gFC_FolderPath(i)
        Else
            GoTo NextFolder
        End If
        mRows(mRowCount) = i
        If i = keepIdx Then sel = mRowCount
        mRowCount = mRowCount + 1
NextFolder:
    Next

    If sel < 0 And mRowCount > 0 And f <> "" Then sel = 0
    If sel >= 0 Then
        lstFolders.ListIndex = sel
        If sel > 6 Then lstFolders.TopIndex = sel - 6 Else lstFolders.TopIndex = 0
    End If
End Sub

Private Sub ChooseCurrent()
    If lstFolders.ListIndex < 0 Then
        Beep
        Exit Sub
    End If
    mResult = mRows(lstFolders.ListIndex)
    mCancelled = False
    Me.Hide
End Sub

Private Sub MoveSelection(ByVal delta As Long)
    Dim n As Long
    If mRowCount = 0 Then Exit Sub
    n = lstFolders.ListIndex + delta
    If n < 0 Then n = 0
    If n > mRowCount - 1 Then n = mRowCount - 1
    lstFolders.ListIndex = n
End Sub

Private Sub txtFilter_Change()
    ApplyFilter
End Sub

Private Sub txtFilter_KeyDown(ByVal KeyCode As MSForms.ReturnInteger, ByVal Shift As Integer)
    Select Case KeyCode
        Case vbKeyReturn
            KeyCode = 0
            ChooseCurrent
        Case vbKeyDown
            KeyCode = 0
            MoveSelection 1
        Case vbKeyUp
            KeyCode = 0
            MoveSelection -1
        Case vbKeyPageDown
            KeyCode = 0
            MoveSelection 15
        Case vbKeyPageUp
            KeyCode = 0
            MoveSelection -15
    End Select
End Sub

Private Sub lstFolders_KeyDown(ByVal KeyCode As MSForms.ReturnInteger, ByVal Shift As Integer)
    If KeyCode = vbKeyReturn Then
        KeyCode = 0
        ChooseCurrent
    End If
End Sub

Private Sub lstFolders_DblClick(ByVal Cancel As MSForms.ReturnBoolean)
    ChooseCurrent
End Sub

Private Sub btnOK_Click()
    ChooseCurrent
End Sub

Private Sub btnCancel_Click()
    mCancelled = True
    Me.Hide
End Sub

Private Sub btnRefresh_Click()
    Dim keep As Long
    If lstFolders.ListIndex >= 0 Then keep = mRows(lstFolders.ListIndex) Else keep = mDefaultIndex
    Dim keepID As String
    If keep >= 0 And keep < gFC_FolderCount Then keepID = gFC_FolderID(keep)
    FC_BuildFolderCache mStores, True
    mDefaultIndex = FC_FolderCacheIndex(keepID)
    lstFolders.ListIndex = -1
    ApplyFilter
End Sub

Private Sub UserForm_QueryClose(Cancel As Integer, CloseMode As Integer)
    If CloseMode = vbFormControlMenu Then
        Cancel = True
        mCancelled = True
        Me.Hide
    End If
End Sub
