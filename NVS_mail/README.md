# NVS_mail

**NVS_mail** is a set of VBA tools for **classic Outlook for Windows**. It treats each email chain as one unit, so you can file it, color it, save it and set up meetings from it. It's plain VBA pasted into Outlook, so there's nothing to install and no admin rights needed, as long as Outlook lets you run macros.

| Button (macro) | What it does |
|---|---|
| **Save Email + Attachments** (`NVS_SaveEmailAndAttachments`) | Saves the selected or open email as a `.msg` file, plus all of its attachments, in one go. |
| **File to Chain** (`NVS_FileToChainFolder`) | One click: moves the email into the folder the rest of its chain is filed in. |
| **Move (chain)** (`NVS_MoveToFolder`) | Folder picker that **opens on the chain's folder**, not on the last folder you used. Press Enter to accept, or type to find another folder. |
| **Set Folder Color** (`NVS_SetFolderColor`) | Picks a color for a folder. Every email in a chain filed there gets that color automatically, including the ones in your Inbox and Sent Items. |
| **Rename Attachment** (`NVS_RenameAttachments`) | Renames attachments on the email you're writing, before you send it. |
| **Meeting with Chain** (`NVS_ScheduleMeetingWithChain`) | Opens a **new** meeting invite with everyone on the chain. It isn't "Reply with Meeting", so the invite doesn't show up in the chain. |

Extras: `NVS_RemoveFolderColor`, `NVS_ListFolderColors`, `NVS_RecolorSelected`, `NVS_RecolorInbox`, `NVS_ApplyRowColorsToView` (see [Colors](#3-color-coding)).

---

## Setup (about 10 minutes, once)

You need classic Outlook for Windows (Microsoft 365, 2021, 2019 or 2016) and the 3 text files in this folder. Each file has a "HOW TO ADD" note at the top.

| File | Where it goes in the VBA editor | Name (F4 > (Name)) |
|---|---|---|
| `1_NVS_mail.txt` | Insert > **Module** | `NVS_mail` |
| `2_NVS_mail_FolderPicker.txt` | Insert > **UserForm**, then right-click it > **View Code** | `NVS_mail_FolderPicker` (must match exactly) |
| `3_ThisOutlookSession.txt` | Microsoft Outlook Objects > **ThisOutlookSession** (already there) | - |

Three is the minimum. Outlook keeps code, forms and its own events in three separate places, and each needs its own paste.

### 1. Allow macros

**File > Options > Trust Center > Trust Center Settings... > Macro Settings.**

* Best option: choose **Notifications for digitally signed macros**, then sign the project yourself (step 5).
* Quicker option, if your PC allows it: **Notifications for all macros**. Outlook then asks once each time it starts.

If these options are greyed out, your IT department controls them. Step 5 (self-signing) usually still works.

### 2. Paste in the NVS_mail module (file 1)

Press **Alt+F11** to open the VBA editor.

1. **Insert > Module**.
2. Press **F4**. In the Properties window, change **(Name)** from `Module1` to `NVS_mail`.
3. Click in the code window. If it already says `Option Explicit`, delete it, since the file has its own and a second copy causes an error.
4. Open `1_NVS_mail.txt` in Notepad, **Ctrl+A**, **Ctrl+C**, then **Ctrl+V** into the code window.

### 3. Create the folder picker UserForm (file 2)

1. **Insert > UserForm**.
2. Press **F4** and change **(Name)** from `UserForm1` to `NVS_mail_FolderPicker`. This name must match exactly, because the code opens the form by name.
3. Right-click the form and choose **View Code**. Delete anything there, then paste in the whole of `2_NVS_mail_FolderPicker.txt`.

Leave the form blank. Don't draw controls on it, because the code adds the filter box, folder list and buttons itself when the form opens. Don't worry that it looks empty in the designer.

### 4. Add the event code to ThisOutlookSession (file 3)

In the project tree, double-click **Project1 > Microsoft Outlook Objects > ThisOutlookSession** and paste in `3_ThisOutlookSession.txt`. This is what makes coloring automatic: it tells NVS_mail when Outlook starts, when new mail arrives, when you send a reply and when you move an email.

**If ThisOutlookSession already has code of your own:**

1. Paste the file at the bottom of your code and delete its `Option Explicit` line, since there can only be one.
2. Move the six lines that start with `Private WithEvents nvs...` and `Private nvsMovedToID` up to the top, above your first `Sub`. VBA needs all declarations at the top.
3. If you already have an `Application_Startup` or `Application_NewMailEx`, move the lines inside NVS_mail's version into yours, then delete NVS_mail's empty copy. Two subs can't have the same name.

### 5. Compile, sign and save

1. **Debug > Compile Project1.** Nothing should happen, and no message means success. If a line turns red or yellow, see [Troubleshooting](#troubleshooting).
2. *(Recommended)* Sign the code so it keeps running after a restart. In the Windows Start menu, search for **Digital Certificate for VBA Projects** (`SELFCERT.EXE`, installed with Office) and create a certificate named `NVS_mail`. Then, in the VBA editor, choose **Tools > Digital Signature... > Choose** and pick it.
3. Click **Save** (the disk icon) and **restart Outlook**. If asked about macros, choose **Trust all documents from this publisher** (or **Enable Macros**).

If you edit the code later, sign it again (Tools > Digital Signature).

### 6. Add the NVS_mail buttons to the ribbon

**Main window:** **File > Options > Customize Ribbon**. On the right, select the **Home (Mail)** tab and click **New Group**, then **Rename...** it to `NVS_mail`. On the left, set *Choose commands from* to **Macros** and add:

| Macro (listed as `Project1.NVS_...`) | Suggested button name |
|---|---|
| `NVS_FileToChainFolder` | File to Chain |
| `NVS_MoveToFolder` | Move (chain) |
| `NVS_SaveEmailAndAttachments` | Save Email + Attachments |
| `NVS_ScheduleMeetingWithChain` | Meeting with Chain |
| `NVS_SetFolderColor` | Set Folder Color |
| `NVS_RenameAttachments` | Rename Attachment (works while replying in the reading pane) |

Only NVS_mail's 11 button macros appear in that list. All the helper code is hidden. Select each one and use **Rename...** to give it a friendly name and an icon. The extras (`NVS_RecolorInbox`, `NVS_ListFolderColors`, ...) can go in the group too, or you can run them from **Alt+F8**.

**Email window** (for Rename Attachment, and Save/Meeting on an open email): open any email or a new message, right-click its ribbon, choose **Customize the Ribbon**, and add the same macros to a new `NVS_mail` group on the **Message** tab.

**Keyboard shortcuts:** macros you add to the **Quick Access Toolbar** get shortcuts. The first button is Alt+1, the second Alt+2, and so on. Putting File to Chain first gives you one-key filing.

### 7. Try it

1. **Set Folder Color**: pick a project folder, choose a color, and answer Yes to color existing mail.
2. Select an Inbox email whose chain already has an email in that folder, and click **File to Chain**.
3. Select another email and click **Move (chain)**. The picker should open on that chain's folder.

### Updating to a new version

Replace the code in each place: click in its code window, **Ctrl+A**, **Delete**, and paste the new file. For the form, right-click it and choose View Code first. Then **Debug > Compile**, sign again, save, and restart Outlook. Your folder colors are kept, since they're stored in the registry rather than in the code.

**Already installed the earlier 7-file version?**

1. Right-click `NVS_mail_Core`, `NVS_mail_Util`, `NVS_mail_Commands`, `NVS_mail_Tools` and `NVS_mail_FolderWatcher`, choose **Remove...**, and answer **No** to exporting.
2. Do step 2 above.
3. Replace ThisOutlookSession's NVS_mail code with file 3.

Keep your `NVS_mail_FolderPicker` form, since its code hasn't changed. The ribbon buttons call the same macro names. If one stops working, remove it and add it again.

---

## How each feature works

### 1. Save Email + Attachments

* Select one or more emails, or open one, and click the button.
* After the first time, it asks: *Save to this folder?* **Yes** saves to the same folder as last time. **No** opens a folder browser.
* Each email is saved as `2026-11-03 0915 - Subject.msg`, with its attachments next to it under their own names. If a file with that name already exists, it becomes `name (2).ext`.
* Pictures embedded in the email body, such as signature logos, are skipped. Set `NVS_SKIP_INLINE_IMAGES = False` to save them too.
* When several emails are selected, each one gets its own subfolder. See `NVS_SUBFOLDER_MODE`.

### 2. Filing a chain

**The chain's folder** is the folder holding the most recent email of the conversation that sits in a normal folder. Inbox, Sent Items, Deleted Items, Drafts, Outbox, Junk, and anything listed in `NVS_EXCLUDED_FOLDER_NAMES` (Archive by default) don't count.

* **File to Chain** moves the selected email(s) there straight away, with no dialog. If the chain hasn't been filed anywhere yet, the folder picker opens instead. If you select several emails from different chains, each goes to its own chain's folder.
* **Move (chain)** opens the folder picker with the chain's folder already selected. Press **Enter** to move there, or start typing part of a folder name to jump to another folder. If the chain isn't filed yet, the picker starts on the last folder you moved something to.
* In conversation view, selecting a collapsed conversation moves all of its emails in the current folder.

> **Why not change Outlook's own Move button?** Outlook only lets compiled COM/VSTO add-ins take over built-in buttons. VBA macros can't. *Move (chain)* is the VBA equivalent. Put it where you'd normally click Move. If you later want the built-in button itself replaced, the same logic can be ported to a C# VSTO add-in.

### 3. Color coding

Colors use Outlook **categories**. Each colored folder gets a category, `Folder: <folder name>` by default, with the color you pick.

1. Click **Set Folder Color**, pick the folder, then type a color number or name (for example `8` or `Blue`). Optionally rename the category.
2. It offers to color the chains already in that folder from the last `NVS_RECOLOR_DAYS_BACK` days. Their emails in your Inbox and Sent Items get the color too.
3. From then on, colors update automatically:
   * New mail in your Inbox gets the color of the folder its chain is filed in.
   * Your sent replies get it too.
   * When you move an email to another folder (with these buttons, Outlook's Move button, drag and drop, or a Quick Step), its whole chain is recolored to match the folder it went to. Moving it into a folder without a color takes the color off. This works for moves out of the Inbox and out of whichever folder you're looking at.
   * A chain only ever has one NVS_mail color, and your other categories are never touched.

You can also change a color later in Outlook's own **Categorize > All Categories** dialog, and the change takes effect everywhere straight away.

**Whole-row colors (optional):** categories appear as a colored tag on each email. If you want the text of the whole row colored, open the Inbox (or any folder) and run `NVS_ApplyRowColorsToView`. It adds one Conditional Formatting rule per colored folder to that view. Outlook only has 16 text colors, so it uses the closest one. Run it again after adding new folder colors. You can fine-tune the rules in **View > View Settings > Conditional Formatting**.

Other macros:
* `NVS_RecolorSelected` re-checks the selected chain(s).
* `NVS_RecolorInbox` re-checks every chain in the Inbox, for example after you've filed mail while Outlook was closed.
* `NVS_RemoveFolderColor` stops coloring a folder and can strip its color from existing mail.
* `NVS_ListFolderColors` shows all folder colors.

Categories are saved on the emails themselves, so the colors also show in Outlook on the web and on your phone.

### 4. Rename attachments on a draft

Click **Rename Attachment** while writing an email (in its own window or as an inline reply). With one attachment, it asks straight away for the new name. With several, it lists them by number. The original extension is kept automatically, so typing `Q3 Invoice` for `scan0042.pdf` gives `Q3 Invoice.pdf`.

Outlook can't rename attachments in place, so the macro saves a copy under the new name, attaches that copy, and removes the original. The renamed file moves to the end of the attachment list. OneDrive/SharePoint "share link" attachments and pictures in the body can't be renamed.

### 5. Meeting with everyone on the chain

Select or open any email in the chain and click **Meeting with Chain**. A new meeting invite opens with:

* **Required:** everyone who sent an email in the chain or was on its To line.
* **Optional:** people who were only ever on CC (set `NVS_CC_AS_OPTIONAL = False` to make them required).
* You are left off, and BCC'd people are never added.
* **Subject:** the chain's subject without RE:/FW:. Add a prefix with `NVS_MEETING_SUBJECT_PREFIX`, for example `"Meeting: "`.

Nothing is sent. You pick the time, edit the attendees, and click Send yourself. Because the invite is created fresh rather than as a reply, it doesn't appear inside the email chain.

---

## Settings

These are at the top of the **NVS_mail** module (file 1). Change the value, then save and restart Outlook.

| Setting | Default | Meaning |
|---|---|---|
| `NVS_CATEGORY_PREFIX` | `"Folder: "` | Start of the category names NVS_mail creates. |
| `NVS_EXCLUDED_FOLDER_NAMES` | `"Archive;Conversation History;Snoozed;Scheduled"` | Folders that never count as a chain's folder. |
| `NVS_AUTO_COLOR` | `True` | Color mail automatically as it arrives, is sent or is filed. |
| `NVS_RECOLOR_DAYS_BACK` | `180` | How far back the "color existing mail" step and `NVS_RecolorInbox` look. |
| `NVS_SKIP_INLINE_IMAGES` | `True` | When saving, skip pictures embedded in the body. |
| `NVS_SUBFOLDER_MODE` | `1` | 0 = never, 1 = when several emails are selected, 2 = always make a subfolder per email. |
| `NVS_MEETING_SUBJECT_PREFIX` | `""` | Text added before the meeting subject. |
| `NVS_CC_AS_OPTIONAL` | `True` | People only on CC become optional attendees. |

Folder colors and "last used folder" are stored in the registry under `HKEY_CURRENT_USER\Software\VB and VBA Program Settings\NVS_mail`.

---

## Troubleshooting

* **"User-defined type not defined" when compiling:** the form isn't named exactly `NVS_mail_FolderPicker`. It's probably still `UserForm1`, or the name has a typo.
* **Red line, or "Duplicate Option statement", "Invalid outside procedure" or "Only comments may appear after End Sub" right after pasting:** there's an extra `Option Explicit` (keep only the first one), a file was pasted twice, or a file went in the wrong place. File 1 goes in a Module, file 2 in the UserForm's code window, and file 3 in ThisOutlookSession. If ThisOutlookSession has your own code too, see step 4.
* **Buttons do nothing after restarting Outlook:** macros are disabled. See steps 1 and 5.
* **New mail isn't colored:** the code in ThisOutlookSession (step 4) starts when Outlook starts, so restart Outlook after installing. Also check that the chain is actually filed in a colored folder (`NVS_ListFolderColors`).
* **"isn't filed in a folder yet" for a chain you did file:** filing works within one mailbox. Mail in a different mailbox, PST file or online archive isn't part of the same Outlook conversation. Also check the folder isn't in `NVS_EXCLUDED_FOLDER_NAMES`.
* **Big folders are slow to color the first time:** that's the one-off "color existing mail" pass. Lower `NVS_RECOLOR_DAYS_BACK` if needed.

## Uninstall

In the VBA editor, right-click the `NVS_mail` module and the `NVS_mail_FolderPicker` form, choose **Remove...** (answer No to exporting), and delete the NVS_mail code (everything with `nvs` or `NVS_` in it) from ThisOutlookSession. Delete the registry key above. Optionally delete the `Folder: ...` categories in **Categorize > All Categories**.
