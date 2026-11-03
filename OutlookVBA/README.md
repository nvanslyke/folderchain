# FolderChain for Outlook (VBA)

A set of macros for **classic Outlook for Windows**. It treats each email chain as one unit, so you can file it, color it, save it and set up meetings from it. It's plain VBA, so there's nothing to install and no admin rights needed, as long as Outlook lets you run macros.

| Button (macro) | What it does |
|---|---|
| **Save Email + Attachments** (`FC_SaveEmailAndAttachments`) | Saves the selected or open email as a `.msg` file, plus all of its attachments, in one go. |
| **File to Chain** (`FC_FileToChainFolder`) | One click: moves the email into the folder the rest of its chain is filed in. |
| **Move (chain)** (`FC_MoveToFolder`) | Folder picker that **opens on the chain's folder**, not on the last folder you used. Press Enter to accept, or type to find another folder. |
| **Set Folder Color** (`FC_SetFolderColor`) | Picks a color for a folder. Every email in a chain filed there gets that color automatically, including the ones in your Inbox and Sent Items. |
| **Rename Attachment** (`FC_RenameAttachments`) | Renames attachments on the email you're writing, before you send it. |
| **Meeting with Chain** (`FC_ScheduleMeetingWithChain`) | Opens a **new** meeting invite with everyone on the chain. It isn't "Reply with Meeting", so the invite doesn't show up in the chain. |

Extras: `FC_RemoveFolderColor`, `FC_ListFolderColors`, `FC_RecolorSelected`, `FC_RecolorInbox`, `FC_ApplyRowColorsToView` (see [Colors](#3-color-coding)).

---

## Install (about 10 minutes, once)

You need: classic Outlook for Windows (Microsoft 365, 2021, 2019 or 2016) and the files in this folder.

### 1. Allow macros

**File > Options > Trust Center > Trust Center Settings... > Macro Settings.**

* Best option: choose **Notifications for digitally signed macros**, then sign the project yourself (step 6).
* Quicker option, if your PC allows it: **Notifications for all macros**. Outlook then asks once each time it starts.

If these options are greyed out, your IT department controls them. Step 6 (self-signing) usually still works.

### 2. Import the modules

1. Press **Alt+F11** to open the VBA editor.
2. **File > Import File...** and import these 5 files one at a time:
   `modFolderChain.bas`, `modFCUtil.bas`, `modFCCommands.bas`, `modFCMailTools.bas`, `clsFolderWatcher.cls`

### 3. Create the folder picker form

1. **Insert > UserForm**.
2. Press **F4**. In the Properties window, change **(Name)** from `UserForm1` to `frmFolderPicker`.
3. Right-click the form and choose **View Code**. Delete what's there and paste in the whole of `frmFolderPicker.vba`.

Don't draw anything on the form. The code creates the list, buttons and filter box itself.

### 4. Add the startup code

In the project tree, open **Project1 > Microsoft Outlook Objects > ThisOutlookSession** and paste in the contents of `ThisOutlookSession.vba`. If you already have an `Application_Startup` or `Application_NewMailEx` there, add the `FC_...` line to your existing one instead of pasting a second copy.

### 5. Compile and save

**Debug > Compile Project1.** It should finish without any message. Then click **Save** and **restart Outlook**. The automatic coloring starts when Outlook starts.

### 6. (Recommended) Sign the macros so they always run

1. In the Windows Start menu, search for **Digital Certificate for VBA Projects** (`SELFCERT.EXE`, installed with Office) and create a certificate, for example "FolderChain".
2. In the VBA editor: **Tools > Digital Signature... > Choose**, then pick that certificate.
3. Save and restart Outlook. When asked, choose **Trust all documents from this publisher**.

If you edit the code later, sign it again.

### 7. Add the buttons

**Main window:** **File > Options > Customize Ribbon**. On the right, select the **Home (Mail)** tab and click **New Group** (rename it "FolderChain"). On the left, set *Choose commands from* to **Macros** and add:

| Macro (listed with a `Project1.` prefix) | Suggested button name |
|---|---|
| `FC_FileToChainFolder` | File to Chain |
| `FC_MoveToFolder` | Move (chain) |
| `FC_SaveEmailAndAttachments` | Save Email + Attachments |
| `FC_ScheduleMeetingWithChain` | Meeting with Chain |
| `FC_SetFolderColor` | Set Folder Color |
| `FC_RenameAttachments` | Rename Attachment (shows up while replying in the reading pane) |

Use **Rename...** on each one to choose an icon and a friendly name.

**Email window** (for Rename Attachment, and Save/Meeting on an open email): open any email or a new message, right-click its ribbon, choose **Customize the Ribbon**, and add the same macros to a new group on the **Message** tab.

**Keyboard shortcuts:** macros you add to the **Quick Access Toolbar** get shortcuts. The first button is Alt+1, the second Alt+2, and so on. Putting File to Chain first gives you one-key filing.

---

## How each feature works

### 1. Save Email + Attachments

* Select one or more emails, or open one, and click the button.
* After the first time, it asks: *Save to this folder?* **Yes** saves to the same folder as last time. **No** opens a folder browser.
* Each email is saved as `2026-11-03 0915 - Subject.msg`, with its attachments next to it under their own names. If a file with that name already exists, it becomes `name (2).ext`.
* Pictures embedded in the email body, such as signature logos, are skipped. Set `FC_SKIP_INLINE_IMAGES = False` to save them too.
* When several emails are selected, each one gets its own subfolder. See `FC_SUBFOLDER_MODE`.

### 2. Filing a chain

**The chain's folder** is the folder holding the most recent email of the conversation that sits in a normal folder. Inbox, Sent Items, Deleted Items, Drafts, Outbox, Junk, and anything listed in `FC_EXCLUDED_FOLDER_NAMES` (Archive by default) don't count.

* **File to Chain** moves the selected email(s) there straight away, with no dialog. If the chain hasn't been filed anywhere yet, the folder picker opens instead. If you select several emails from different chains, each goes to its own chain's folder.
* **Move (chain)** opens the folder picker with the chain's folder already selected. Press **Enter** to move there, or start typing part of a folder name to jump to another folder. If the chain isn't filed yet, the picker starts on the last folder you moved something to.
* In conversation view, selecting a collapsed conversation moves all of its emails in the current folder.

> **Why not change Outlook's own Move button?** Outlook only lets compiled COM/VSTO add-ins take over built-in buttons. VBA macros can't. *Move (chain)* is the VBA equivalent. Put it where you'd normally click Move. If you later want the built-in button itself replaced, the same logic can be ported to a C# VSTO add-in.

### 3. Color coding

Colors use Outlook **categories**. Each colored folder gets a category, `Folder: <folder name>` by default, with the color you pick.

1. Click **Set Folder Color**, pick the folder, then type a color number or name (for example `8` or `Blue`). Optionally rename the category.
2. It offers to color the chains already in that folder from the last `FC_RECOLOR_DAYS_BACK` days. Their emails in your Inbox and Sent Items get the color too.
3. From then on, colors update automatically:
   * New mail in your Inbox gets the color of the folder its chain is filed in.
   * Your sent replies get it too.
   * When you file a chain into a colored folder (with these buttons, Outlook's Move, or drag and drop), the whole chain changes to that folder's color. A chain only ever has one FolderChain color, and your other categories are never touched.

You can also change a color later in Outlook's own **Categorize > All Categories** dialog, and the change takes effect everywhere straight away.

**Whole-row colors (optional):** categories appear as a colored tag on each email. If you want the text of the whole row colored, open the Inbox (or any folder) and run `FC_ApplyRowColorsToView`. It adds one Conditional Formatting rule per colored folder to that view. Outlook only has 16 text colors, so it uses the closest one. Run it again after adding new folder colors. You can fine-tune the rules in **View > View Settings > Conditional Formatting**.

Other macros:
* `FC_RecolorSelected` re-checks the selected chain(s).
* `FC_RecolorInbox` re-checks every chain in the Inbox, for example after you've filed mail while Outlook was closed.
* `FC_RemoveFolderColor` stops coloring a folder and can strip its color from existing mail.
* `FC_ListFolderColors` shows all folder colors.

Categories are saved on the emails themselves, so the colors also show in Outlook on the web and on your phone.

### 4. Rename attachments on a draft

Click **Rename Attachment** while writing an email (in its own window or as an inline reply). With one attachment, it asks straight away for the new name. With several, it lists them by number. The original extension is kept automatically, so typing `Q3 Invoice` for `scan0042.pdf` gives `Q3 Invoice.pdf`.

Outlook can't rename attachments in place, so the macro saves a copy under the new name, attaches that copy, and removes the original. The renamed file moves to the end of the attachment list. OneDrive/SharePoint "share link" attachments and pictures in the body can't be renamed.

### 5. Meeting with everyone on the chain

Select or open any email in the chain and click **Meeting with Chain**. A new meeting invite opens with:

* **Required:** everyone who sent an email in the chain or was on its To line.
* **Optional:** people who were only ever on CC (set `FC_CC_AS_OPTIONAL = False` to make them required).
* You are left off, and BCC'd people are never added.
* **Subject:** the chain's subject without RE:/FW:. Add a prefix with `FC_MEETING_SUBJECT_PREFIX`, for example `"Meeting: "`.

Nothing is sent. You pick the time, edit the attendees, and click Send yourself. Because the invite is created fresh rather than as a reply, it doesn't appear inside the email chain.

---

## Settings

These are at the top of **modFolderChain**. Change the value and save.

| Setting | Default | Meaning |
|---|---|---|
| `FC_CATEGORY_PREFIX` | `"Folder: "` | Start of the category names FolderChain creates. |
| `FC_EXCLUDED_FOLDER_NAMES` | `"Archive;Conversation History;Snoozed;Scheduled"` | Folders that never count as a chain's folder. |
| `FC_AUTO_COLOR` | `True` | Color mail automatically as it arrives, is sent or is filed. |
| `FC_RECOLOR_DAYS_BACK` | `180` | How far back the "color existing mail" step and `FC_RecolorInbox` look. |
| `FC_SKIP_INLINE_IMAGES` | `True` | When saving, skip pictures embedded in the body. |
| `FC_SUBFOLDER_MODE` | `1` | 0 = never, 1 = when several emails are selected, 2 = always make a subfolder per email. |
| `FC_MEETING_SUBJECT_PREFIX` | `""` | Text added before the meeting subject. |
| `FC_CC_AS_OPTIONAL` | `True` | People only on CC become optional attendees. |

Folder colors and "last used folder" are stored in the registry under `HKEY_CURRENT_USER\Software\VB and VBA Program Settings\FolderChain`.

---

## Troubleshooting

* **"User-defined type not defined" when compiling:** the form isn't named exactly `frmFolderPicker` (step 3), or `clsFolderWatcher.cls` wasn't imported.
* **Buttons do nothing after restarting Outlook:** macros are disabled. See steps 1 and 6.
* **New mail isn't colored:** the code in ThisOutlookSession (step 4) runs when Outlook starts, so restart Outlook after installing. Also check that the chain is actually filed in a colored folder (`FC_ListFolderColors`).
* **"isn't filed in a folder yet" for a chain you did file:** filing works within one mailbox. Mail in a different mailbox, PST file or online archive isn't part of the same Outlook conversation. Also check the folder isn't in `FC_EXCLUDED_FOLDER_NAMES`.
* **Big folders are slow to color the first time:** that's the one-off "color existing mail" pass. Lower `FC_RECOLOR_DAYS_BACK` if needed.

## Uninstall

Delete the modules, the form and the ThisOutlookSession lines in the VBA editor. Delete the registry key above. Optionally delete the `Folder: ...` categories in **Categorize > All Categories**.
