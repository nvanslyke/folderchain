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

## Setup (about 15 minutes, once)

You need classic Outlook for Windows (Microsoft 365, 2021, 2019 or 2016) and the 7 text files in this folder. Each file has its own "HOW TO ADD" note at the top.

| File | Create this in the VBA editor | Name it (F4 > (Name)) |
|---|---|---|
| `1_NVS_mail_Core.txt` | Insert > **Module** | `NVS_mail_Core` |
| `2_NVS_mail_Util.txt` | Insert > **Module** | `NVS_mail_Util` |
| `3_NVS_mail_Commands.txt` | Insert > **Module** | `NVS_mail_Commands` |
| `4_NVS_mail_Tools.txt` | Insert > **Module** | `NVS_mail_Tools` |
| `5_NVS_mail_FolderWatcher.txt` | Insert > **Class Module** | `NVS_mail_FolderWatcher` |
| `6_NVS_mail_FolderPicker.txt` | Insert > **UserForm** | `NVS_mail_FolderPicker` |
| `7_ThisOutlookSession.txt` | *(already exists)* Microsoft Outlook Objects > **ThisOutlookSession** | - |

The names in the right-hand column must match exactly, because the modules call each other by these names.

### 1. Allow macros

**File > Options > Trust Center > Trust Center Settings... > Macro Settings.**

* Best option: choose **Notifications for digitally signed macros**, then sign the project yourself (step 6).
* Quicker option, if your PC allows it: **Notifications for all macros**. Outlook then asks once each time it starts.

If these options are greyed out, your IT department controls them. Step 6 (self-signing) usually still works.

### 2. Paste in the four modules (files 1-4)

Press **Alt+F11** to open the VBA editor. For each of files 1 to 4:

1. **Insert > Module**.
2. Press **F4**. In the Properties window, change **(Name)** from `Module1` to the name in the table, e.g. `NVS_mail_Core`.
3. Click in the code window. If it already says `Option Explicit`, delete it, since the file has its own and a second copy causes an error.
4. Open the `.txt` file in Notepad, **Ctrl+A**, **Ctrl+C**, then **Ctrl+V** into the code window.

### 3. Paste in the class module (file 5)

Same as step 2, but use **Insert > Class Module** and name it `NVS_mail_FolderWatcher`.

### 4. Create the folder picker UserForm (file 6)

1. **Insert > UserForm**.
2. Press **F4** and change **(Name)** from `UserForm1` to `NVS_mail_FolderPicker`.
3. Right-click the form and choose **View Code**. Delete anything there, then paste in the whole of `6_NVS_mail_FolderPicker.txt`.

Leave the form blank. Don't draw controls on it, because the code adds the filter box, folder list and buttons itself when the form opens. Don't worry that it looks empty in the designer.

### 5. Add the startup code (file 7)

In the project tree, double-click **Project1 > Microsoft Outlook Objects > ThisOutlookSession** and paste in `7_ThisOutlookSession.txt`. If ThisOutlookSession already has an `Application_Startup` or `Application_NewMailEx` from other macros, don't paste a second copy. Add the `NVS_...` line inside your existing one instead.

### 6. Compile, sign and save

1. **Debug > Compile Project1.** Nothing should happen, and no message means success. If a line turns red or yellow, check the module names against the table.
2. *(Recommended)* Sign the code so it keeps running after a restart. In the Windows Start menu, search for **Digital Certificate for VBA Projects** (`SELFCERT.EXE`, installed with Office) and create a certificate named `NVS_mail`. Then, in the VBA editor, choose **Tools > Digital Signature... > Choose** and pick it.
3. Click **Save** (the disk icon) and **restart Outlook**. If asked about macros, choose **Trust all documents from this publisher** (or **Enable Macros**).

If you edit the code later, sign it again (Tools > Digital Signature).

### 7. Add the NVS_mail buttons to the ribbon

**Main window:** **File > Options > Customize Ribbon**. On the right, select the **Home (Mail)** tab and click **New Group**, then **Rename...** it to `NVS_mail`. On the left, set *Choose commands from* to **Macros** and add:

| Macro (listed as `Project1.NVS_...`) | Suggested button name |
|---|---|
| `NVS_FileToChainFolder` | File to Chain |
| `NVS_MoveToFolder` | Move (chain) |
| `NVS_SaveEmailAndAttachments` | Save Email + Attachments |
| `NVS_ScheduleMeetingWithChain` | Meeting with Chain |
| `NVS_SetFolderColor` | Set Folder Color |
| `NVS_RenameAttachments` | Rename Attachment (works while replying in the reading pane) |

Select each one and use **Rename...** to give it a friendly name and an icon. The extras (`NVS_RecolorInbox`, `NVS_ListFolderColors`, ...) can go in the group too, or you can run them from **Alt+F8**.

**Email window** (for Rename Attachment, and Save/Meeting on an open email): open any email or a new message, right-click its ribbon, choose **Customize the Ribbon**, and add the same macros to a new `NVS_mail` group on the **Message** tab.

**Keyboard shortcuts:** macros you add to the **Quick Access Toolbar** get shortcuts. The first button is Alt+1, the second Alt+2, and so on. Putting File to Chain first gives you one-key filing.

### 8. Try it

1. **Set Folder Color**: pick a project folder, choose a color, and answer Yes to color existing mail.
2. Select an Inbox email whose chain already has an email in that folder, and click **File to Chain**.
3. Select another email and click **Move (chain)**. The picker should open on that chain's folder.

### Updating to a new version

Replace the code in a module: click in it, **Ctrl+A**, **Delete**, and paste the new file. Then **Debug > Compile**, sign again, save, and restart Outlook. Your folder colors are kept, since they're stored in the registry rather than in the code.

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
   * When you file a chain into a colored folder (with these buttons, Outlook's Move, or drag and drop), the whole chain changes to that folder's color. A chain only ever has one NVS_mail color, and your other categories are never touched.

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

These are at the top of **modNVS_mail**. Change the value and save.

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

* **"User-defined type not defined" when compiling:** a module, class or form isn't named exactly as in the setup table (for example the form must be `NVS_mail_FolderPicker`, not `UserForm1`).
* **Red line or "Duplicate Option statement" / "Invalid outside procedure" right after pasting:** the module had its own `Option Explicit` (delete the extra one at the top), the file was pasted twice, or it was pasted into the wrong kind of module (the class file must go in a Class Module, the form file in the UserForm's code).
* **Buttons do nothing after restarting Outlook:** macros are disabled. See steps 1 and 6.
* **New mail isn't colored:** the code in ThisOutlookSession (step 5) runs when Outlook starts, so restart Outlook after installing. Also check that the chain is actually filed in a colored folder (`NVS_ListFolderColors`).
* **"isn't filed in a folder yet" for a chain you did file:** filing works within one mailbox. Mail in a different mailbox, PST file or online archive isn't part of the same Outlook conversation. Also check the folder isn't in `NVS_EXCLUDED_FOLDER_NAMES`.
* **Big folders are slow to color the first time:** that's the one-off "color existing mail" pass. Lower `NVS_RECOLOR_DAYS_BACK` if needed.

## Uninstall

In the VBA editor, right-click each NVS_mail module, the class and the form, choose **Remove...** (answer No to exporting), and delete the NVS_ lines from ThisOutlookSession. Delete the registry key above. Optionally delete the `Folder: ...` categories in **Categorize > All Categories**.
