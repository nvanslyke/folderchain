# NVS_mail

**NVS_mail** is a set of VBA tools for **classic Outlook for Windows**. It treats each email chain as one unit, so you can file it, color it, save it and set up meetings from it. It's plain VBA pasted into Outlook, so there's nothing to install and no admin rights needed, as long as Outlook lets you run macros.

| Button (macro) | What it does |
|---|---|
| **File to Chain** (`NVS_FileToChainFolder`) | One click: moves the email into the folder the rest of its chain is filed in. |
| **Move (chain)** (`NVS_MoveToFolder`) | A compact Move Items window, like Outlook's, that **opens on the chain's folder**. It has a folder tree, a search box and **New...**. |
| **Save Email + Attachments** (`NVS_SaveEmailAndAttachments`) | Opens Windows' standard Save As window at that chain's save location. The email (under its usual name) and all its attachments are saved in the folder you pick. |
| **Save Locations** (`NVS_SaveLocations`) | Sets where Save opens: a base folder, plus a folder for any Outlook folder you like. |
| **Set Folder Color** (`NVS_SetFolderColor`) | Picks a color for a folder from real color swatches. Chains filed in that folder **or any of its subfolders** get that color, in your Inbox and Sent Items too. |
| **Folder Colors** (`NVS_ListFolderColors`) | Shows every colored folder with its color, and lets you add, change or remove colors. |
| **Rename Attachments** (`NVS_RenameAttachments`) | One window listing every attachment on the email you're writing. Rename any of them, and the extensions are kept. |
| **Meeting with Chain** (`NVS_ScheduleMeetingWithChain`) | Opens a **new** meeting invite with everyone on the chain. It isn't "Reply with Meeting", so the invite doesn't land in the chain. |

Extras: `NVS_RemoveFolderColor`, `NVS_RecolorSelected`, `NVS_RecolorInbox` and `NVS_ApplyRowColorsToView` (see [Colors](#3-color-coding)).

---

## Setup (about 10 minutes, once)

You need classic Outlook for Windows (Microsoft 365, 2021, 2019 or 2016) and the 3 text files in this folder. Each file has a "HOW TO ADD" note at the top.

| File | Where it goes in the VBA editor | Name (F4 > (Name)) |
|---|---|---|
| `1_NVS_mail.txt` | Insert > **Module** | `NVS_mail` |
| `2_NVS_mail_Dialog.txt` | Insert > **UserForm**, then right-click it > **View Code** | `NVS_mail_Dialog` (must match exactly) |
| `3_ThisOutlookSession.txt` | Microsoft Outlook Objects > **ThisOutlookSession** (already there) | - |

Three is the minimum. Outlook keeps code, forms and its own events in three separate places, and each needs its own paste.

**Already set up an earlier version?** See [Updating](#updating-to-a-new-version) instead.

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

### 3. Create the NVS_mail_Dialog UserForm (file 2)

1. **Insert > UserForm**.
2. Press **F4** and change **(Name)** from `UserForm1` to `NVS_mail_Dialog`. This name must match exactly, because the code opens the form by name.
3. Right-click the form and choose **View Code**. Delete anything there, then paste in the whole of `2_NVS_mail_Dialog.txt`.

Leave the form blank and don't draw controls on it. The code builds every window itself when it opens: Move Items, Folder Color, the lists, Rename Attachments and the progress window. Don't worry that it looks empty in the designer.

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
| `NVS_ListFolderColors` | Folder Colors |
| `NVS_SaveLocations` | Save Locations |
| `NVS_RenameAttachments` | Rename Attachments (works while replying in the reading pane) |

Only NVS_mail's 12 button macros appear in that list. All the helper code is hidden. Select each one and use **Rename...** to give it a friendly name and an icon. The extras (`NVS_RecolorInbox`, ...) can go in the group too, or you can run them from **Alt+F8**.

**Email window** (for Rename Attachments, and Save/Meeting on an open email): open any email or a new message, right-click its ribbon, choose **Customize the Ribbon**, and add the same macros to a new `NVS_mail` group on the **Message** tab.

**Keyboard shortcuts:** macros you add to the **Quick Access Toolbar** get shortcuts. The first button is Alt+1, the second Alt+2, and so on. Putting File to Chain first gives you one-key filing.

### 7. Try it

1. **Set Folder Color**: pick a project folder and click a color. Its existing chains are colored straight away, with a progress window you can cancel.
2. Select an Inbox email whose chain already has an email in that folder, and click **File to Chain**.
3. Select another email and click **Move (chain)**. The window should open on that chain's folder.
4. **Save Locations**: set your base folder and a folder for a project. Then select an email from that project's chain and click **Save Email + Attachments**.

### Updating to a new version

Replace the code in each place: click in its code window, **Ctrl+A**, **Delete**, and paste the new file. For the form, right-click it and choose View Code first. Then **Debug > Compile**, sign again, save, and restart Outlook. Your folder colors and save locations are kept, since they're stored in the registry rather than in the code.

**Coming from the version with the `NVS_mail_FolderPicker` form:**

1. Click the form `NVS_mail_FolderPicker`, press **F4**, and change its **(Name)** to `NVS_mail_Dialog`.
2. Replace its code with file 2.
3. Replace the module's code with file 1. ThisOutlookSession (file 3) hasn't changed.
4. Add the new **Save Locations** and **Folder Colors** buttons.

**Coming from the 7-file version:**

1. Right-click `NVS_mail_Core`, `NVS_mail_Util`, `NVS_mail_Commands`, `NVS_mail_Tools` and `NVS_mail_FolderWatcher`, choose **Remove...**, and answer **No** to exporting.
2. Do steps 2 to 4 above.
3. Remove the old `NVS_mail_FolderPicker` form the same way.

---

## How each feature works

### 1. Save Email + Attachments

* Select an email, or open one, and click the button. Windows' standard **Save As** window opens, with your pinned folders on the left as usual. It opens at:
  1. the **save location of the chain's Outlook folder**, or of the nearest folder above it that has one; otherwise
  2. your **base folder**.
* Go into the exact subfolder you want and click **Save**. The email is saved there as a `.msg` file under the same name Outlook would give it (its subject), with all its attachments next to it under their own names. There are no other questions.
* If a file with that name is already there, Windows asks whether to replace it. If you say yes, matching attachments are replaced too. Otherwise attachments get `(2)` added to their names rather than overwriting anything.
* Pictures embedded in the email body, such as signature logos, are skipped. Set `NVS_SKIP_INLINE_IMAGES = False` to save them too.
* With several emails selected, they all go into the folder you pick, each under its own name. By default each email also gets its own subfolder (`NVS_SUBFOLDER_PER_EMAIL`).

**Save Locations** (`NVS_SaveLocations`) is where you set these up:

* **Base folder**: used for emails whose chain isn't in an Outlook folder with a save location. The first time you use Save, it asks for this once.
* **Add...**: choose an Outlook folder, then the Windows folder where its emails should start. Its subfolders use the same location unless they have their own.
* **Change...** / **Remove**: edit the selected row.

To choose a Windows folder, the same Save As window opens. Go into the folder you want and click **Save**. The name in the file box is ignored.

### 2. Filing a chain

**The chain's folder** is the folder holding the most recent email of the conversation that sits in a normal folder. Inbox, Sent Items, Deleted Items, Drafts, Outbox, Junk, and anything listed in `NVS_EXCLUDED_FOLDER_NAMES` (Archive by default) don't count.

* **File to Chain** moves the selected email(s) there straight away, with no dialog. If the chain hasn't been filed anywhere yet, the Move Items window opens instead. If you select several emails from different chains, each goes to its own chain's folder.
* **Move (chain)** opens the Move Items window with the chain's folder already selected. Press **Enter** (or click OK) to move there.

**The Move Items window** works like Outlook's own, plus a search box:

* **Click the arrow** next to a folder, or press **Right** / **Left**, to open or close it. Folders you open stay open next time.
* **Search** finds a folder anywhere in your mailbox as you type. **Up** / **Down** pick from the results.
* **Double-click** a folder, or press **Enter**, to move there.
* **New...** creates a folder inside the selected one.

In conversation view, selecting a collapsed conversation moves all of its emails in the current folder.

> **Why not change Outlook's own Move button?** Outlook only lets compiled COM/VSTO add-ins take over built-in buttons. VBA macros can't. *Move (chain)* is the VBA equivalent. Put it where you'd normally click Move.

### 3. Color coding

Colors use Outlook **categories**. Each colored folder gets a category, `Folder: <folder name>` by default, with the color you pick.

1. Click **Set Folder Color** and pick the folder.
2. Click a color in the swatch grid. Hovering shows each color's name, and the bar underneath previews how the category tag will look. You can rename the category in the box.
3. Click **OK**. If the folder is new to NVS_mail, its existing chains are colored straight away (last `NVS_RECOLOR_DAYS_BACK` days). This covers the folder and its subfolders, plus the chains' emails in your Inbox and Sent Items. A progress window shows how far along it is, Outlook keeps responding, and **Cancel** stops it at any point.
4. **Changing only the color** of a folder that already has one is instant. Outlook repaints every email with that category by itself.

**Subfolders:** a color covers the folder and every folder inside it. If a subfolder has a color of its own, that one wins for it and its own subfolders. Chains filed outside the colored folder are never given its color.

From then on, colors update automatically:

* New mail in your Inbox gets the color of the folder its chain is filed in.
* Your sent replies get it too.
* When you move an email to another folder (with these buttons, Outlook's Move button, drag and drop, or a Quick Step), its whole chain is recolored to match the folder it went to. Moving it into a folder without a color takes the color off. This works for moves out of the Inbox and out of whichever folder you're looking at.
* A chain only ever has one NVS_mail color, and your other categories are never touched.

**Folder Colors** (`NVS_ListFolderColors`) shows every colored folder with its color swatch, plus **Add...**, **Change...** (or double-click a row) and **Remove**.

The color names match current Outlook, so what you pick is what you see. Two colors were renamed in newer Outlook: **Peach** is now **Brown**, and **Maroon** is now **Cranberry**, which looks pink.

**Whole-row colors (optional):** categories appear as a colored tag on each email. If you want the text of the whole row colored, open the Inbox (or any folder) and run `NVS_ApplyRowColorsToView`. It adds one Conditional Formatting rule per colored folder to that view. Outlook only has 16 text colors, so it uses the closest one. Run it again after adding new folder colors. You can fine-tune the rules in **View > View Settings > Conditional Formatting**.

Other macros:
* `NVS_RecolorSelected` re-checks the selected chain(s).
* `NVS_RecolorInbox` re-checks every chain in the Inbox, for example after filing mail while Outlook was closed.
* `NVS_RemoveFolderColor` stops coloring a folder and takes its color off its chains.

Categories are saved on the emails themselves, so the colors also show in Outlook on the web and on your phone.

### 4. Rename attachments on a draft

Click **Rename Attachments** while writing an email, in its own window or as an inline reply. A window lists every attached file, one box per file, with its extension shown alongside.

* Type over any of the names. **Tab** moves to the next one, and **Enter** (or **Rename**) applies them all. Files you don't touch stay as they are.
* The extension is kept, so typing `Q3 Invoice` for `scan0042.pdf` gives `Q3 Invoice.pdf`.
* The attachments stay in the same order. If anything goes wrong partway through, the email is left unchanged.

OneDrive/SharePoint "share link" attachments and pictures in the body can't be renamed, so they aren't listed.

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
| `NVS_RECOLOR_DAYS_BACK` | `180` | How far back coloring existing mail and `NVS_RecolorInbox` look. `0` means all mail. |
| `NVS_SKIP_INLINE_IMAGES` | `True` | When saving, skip pictures embedded in the body. |
| `NVS_SUBFOLDER_PER_EMAIL` | `True` | When saving several emails at once, give each one its own subfolder. |
| `NVS_MEETING_SUBJECT_PREFIX` | `""` | Text added before the meeting subject. |
| `NVS_CC_AS_OPTIONAL` | `True` | People only on CC become optional attendees. |

Folder colors, save locations and the last folder you moved mail to are stored in the registry under `HKEY_CURRENT_USER\Software\VB and VBA Program Settings\NVS_mail`.

---

## Troubleshooting

* **"User-defined type not defined" when compiling:** the form isn't named exactly `NVS_mail_Dialog`. It's probably still `UserForm1` or `NVS_mail_FolderPicker`, or the name has a typo.
* **Red line, or "Duplicate Option statement", "Invalid outside procedure" or "Only comments may appear after End Sub" right after pasting:** there's an extra `Option Explicit` (keep only the first one), a file was pasted twice, or a file went in the wrong place. File 1 goes in a Module, file 2 in the UserForm's code window, and file 3 in ThisOutlookSession. If ThisOutlookSession has your own code too, see step 4.
* **Buttons do nothing after restarting Outlook:** macros are disabled. See steps 1 and 5.
* **New mail isn't colored:** the code in ThisOutlookSession (step 4) starts when Outlook starts, so restart Outlook after installing. Also check that the chain is actually filed in a colored folder, using Folder Colors.
* **"isn't filed anywhere yet" for a chain you did file:** filing works within one mailbox. Mail in a different mailbox, PST file or online archive isn't part of the same Outlook conversation. Also check the folder isn't in `NVS_EXCLUDED_FOLDER_NAMES`.
* **Unrelated emails share a color:** Outlook sometimes puts emails with the same subject into one conversation, which is common with automated emails. NVS_mail goes by Outlook's conversation, so they count as one chain.
* **The Save As window doesn't appear:** NVS_mail falls back to Windows' simpler folder browser. Pick the folder there and click OK.

## Uninstall

In the VBA editor, right-click the `NVS_mail` module and the `NVS_mail_Dialog` form, choose **Remove...** (answer No to exporting), and delete the NVS_mail code (everything with `nvs` or `NVS_` in it) from ThisOutlookSession. Delete the registry key above. Optionally delete the `Folder: ...` categories in **Categorize > All Categories**.
