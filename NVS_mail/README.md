# NVS_mail

**NVS_mail** is a set of VBA tools for **classic Outlook for Windows**. It treats each email chain as one unit, so you can file it, color it, save it and set up meetings from it. It's plain VBA pasted into Outlook, so there's nothing to install and no admin rights needed, as long as Outlook lets you run macros.

| Button (macro) | What it does |
|---|---|
| **File to Chain** (`NVS_FileToChainFolder`) | One click: moves the email into the folder the rest of its chain is filed in. |
| **Move (chain)** (`NVS_MoveToFolder`) | A compact Move Items window, like Outlook's, that **opens on the chain's folder**. It has a folder tree, a search box and **New...**. |
| **Undo Move** (`NVS_UndoMove`) | Puts back the emails moved by the last File to Chain or Move (chain). Click again to go further back. |
| **Save Email + Attachments** (`NVS_SaveEmailAndAttachments`) | Opens Windows' standard Save As window at that chain's save location. The email (under its usual name) and all its attachments are saved in the folder you pick. |
| **Save Locations** (`NVS_SaveLocations`) | Sets where Save opens: a base folder, plus a folder for any Outlook folder you like. |
| **Set Folder Color** (`NVS_SetFolderColor`) | Picks a color for a folder from real color swatches. Chains filed in that folder **or any of its subfolders** get that color, in your Inbox and Sent Items too. |
| **Folder Colors** (`NVS_ListFolderColors`) | Shows every colored folder with its color, and lets you add, change or remove colors. |
| **Rename Attachments** (`NVS_RenameAttachments`) | One window listing every attachment on the email you're writing. Rename any of them, and the extensions are kept. |
| **Meeting with Chain** (`NVS_ScheduleMeetingWithChain`) | Opens a **new** meeting invite with everyone on the chain. It isn't "Reply with Meeting", so the invite doesn't land in the chain. |
| **Search** (`NVS_Search`) | Finds emails in every folder as you type, newest first, without relying on Windows' search index. Optional, in file 4. |
| **Find a Time** (`NVS_FindTime`) | Everyone on the chain's calendars side by side, the times most of them can make listed first, and the meeting invite for the time you pick. Add people by typing their name, and paste in times someone gave you ("tue 2-4, wed 10-11 ET"). Works entirely from the keyboard. Optional, in file 5. |
| **Ribbon shortcuts** (`NVS_SetRibbonShortcuts`) | Run once: **Alt, X** opens your NVS_mail tab, and one more key presses a button (F File to Chain, M Move, U Undo, S Save, E Search...) instead of Outlook's Y1, Y2... |

Extras: `NVS_RemoveFolderColor`, `NVS_RecolorSelected`, `NVS_RecolorInbox` and `NVS_ApplyRowColorsToView` (see [Colors](#3-color-coding)).

---

## Setup (about 10 minutes, once)

You need classic Outlook for Windows (Microsoft 365, 2021, 2019 or 2016) and the 3 text files in this folder. Two more are optional: file 4 for the Search window and file 5 for Find a Time. Each file has a "HOW TO ADD" note at the top.

| File | Where it goes in the VBA editor | Name (F4 > (Name)) |
|---|---|---|
| `1_NVS_mail.txt` | Insert > **Module** | `NVS_mail` |
| `2_NVS_mail_Dialog.txt` | Insert > **UserForm**, then right-click it > **View Code** | `NVS_mail_Dialog` (must match exactly) |
| `3_ThisOutlookSession.txt` | Microsoft Outlook Objects > **ThisOutlookSession** (already there) | - |
| `4_NVS_mail_Search.txt` *(optional)* | Insert > **UserForm**, then right-click it > **View Code** | `NVS_mail_Search` (must match exactly) |
| `5_NVS_mail_FindTime.txt` *(optional)* | Insert > **UserForm**, then right-click it > **View Code** | `NVS_mail_FindTime` (must match exactly) |

Three is the minimum. Outlook keeps code, forms and its own events in three separate places, and each needs its own paste. Files 4 and 5 are optional extras; see [Search](#6-search-optional) and [Find a Time](#7-find-a-time-optional).

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
3. If you already have an `Application_Startup`, `Application_NewMailEx` or `Application_Quit`, move the lines inside NVS_mail's version into yours, then delete NVS_mail's empty copy. Two subs can't have the same name.

### 5. Compile, sign and save

1. **Debug > Compile Project1.** Nothing should happen, and no message means success. If a line turns red or yellow, see [Troubleshooting](#troubleshooting).
2. *(Recommended)* Sign the code so it keeps running after a restart. In the Windows Start menu, search for **Digital Certificate for VBA Projects** (`SELFCERT.EXE`, installed with Office) and create a certificate named `NVS_mail`. Then, in the VBA editor, choose **Tools > Digital Signature... > Choose** and pick it.
3. Click **Save** (the disk icon) and **restart Outlook**. If asked about macros, choose **Trust all documents from this publisher** (or **Enable Macros**).

If you edit the code later, sign it again (Tools > Digital Signature).

### 6. Add the NVS_mail buttons to the ribbon

**Main window:** **File > Options > Customize Ribbon**. On the right, select the **Home (Mail)** tab and click **New Tab**. **Rename...** the new tab to `NVS_mail`, and its *New Group* to something like `Mail`. A tab of its own is what gives the buttons the Alt, X shortcuts below. On the left, set *Choose commands from* to **Macros** and add:

| Macro (listed as `Project1.NVS_...`) | Suggested button name |
|---|---|
| `NVS_FileToChainFolder` | File to Chain |
| `NVS_MoveToFolder` | Move (chain) |
| `NVS_UndoMove` | Undo Move |
| `NVS_SaveEmailAndAttachments` | Save Email + Attachments |
| `NVS_ScheduleMeetingWithChain` | Meeting with Chain |
| `NVS_SetFolderColor` | Set Folder Color |
| `NVS_ListFolderColors` | Folder Colors |
| `NVS_SaveLocations` | Save Locations |
| `NVS_RenameAttachments` | Rename Attachments (works while replying in the reading pane) |
| `NVS_Search` | Search (needs file 4) |
| `NVS_FindTime` | Find a Time (needs file 5) |

Only NVS_mail's own macros appear in that list (16 of them). All the helper code is hidden. Select each one and use **Rename...** to give it a friendly name and an icon. The extras (`NVS_RecolorInbox`, ...) can go on the tab too, or you can run them from **Alt+F8**. `NVS_SetRibbonShortcuts` doesn't need a button, since you run it once (below).

**Email window** (for Rename Attachments, and Save/Meeting on an open email): open any email or a new message, right-click its ribbon, choose **Customize the Ribbon**, and add the same macros to a new `NVS_mail` group on the **Message** tab. To get the Alt, X keys there too, use a new tab instead of a group, the same way as in the main window.

**Shortcut keys (Alt, X):** Outlook names the keys on a tab you make yourself Y1, Y2 and so on, and Customize Ribbon has no way to change them. NVS_mail can:

1. Press **Alt+F8**, pick `NVS_SetRibbonShortcuts` and click **Run**. It lists the keys it set.
2. Close Outlook completely and start it again.

Then **Alt, X** opens the NVS_mail tab, and one more key presses a button. For example, Alt, X, F files the selected email, and Alt, X, U puts it back.

| Key | Button | | Key | Button |
|---|---|---|---|---|
| **F** | File to Chain | | **C** | Set Folder Color |
| **M** | Move (chain) | | **O** | Folder Colors |
| **U** | Undo Move | | **L** | Save Locations |
| **S** | Save Email + Attachments | | **D** | Remove Folder Color |
| **E** | Search (as in Ctrl+E, Outlook's own search key) | | **P** | Recolor Selected |
| **I** | Meeting with Chain (I for invite) | | **B** | Recolor Inbox |
| **R** | Rename Attachments | | **W** | Row colors (`NVS_ApplyRowColorsToView`) |
| **A** | Find a Time | | | |

* Any other macro on the tab, such as one of your own, gets a free letter from its name. Outlook's own commands that you add to the tab keep the keys Outlook gives them.
* To use different keys, change `NVS_RIBBON_TAB_KEY` and `NVS_RIBBON_KEYS` at the top of file 1, then run it again.
* Run it again whenever you change the tab in Customize Ribbon.
* Outlook has no setting for these keys, so `NVS_SetRibbonShortcuts` writes them into the file Outlook keeps your ribbon in, `%LOCALAPPDATA%\Microsoft\Office\olkexplorer.officeUI`. It keeps the old file next to it as `olkexplorer.officeUI.bak`. It also saves a copy on your Desktop that you can import if the keys don't show up (see [Troubleshooting](#troubleshooting)).

**Quick Access Toolbar:** macros you add there get even shorter shortcuts. The first button is Alt+1, the second Alt+2, and so on. Put **File to Chain** first and **Undo Move** second, and Alt+1 files an email while Alt+2 takes it back.

### 7. Try it

1. **Set Folder Color**: pick a project folder and click a color. Its existing chains are colored straight away, with a progress window you can cancel.
2. Select an Inbox email whose chain already has an email in that folder, and click **File to Chain**.
3. Select another email and click **Move (chain)**. The window should open on that chain's folder.
4. **Save Locations**: set your base folder and a folder for a project. Then select an email from that project's chain and click **Save Email + Attachments**.

### Updating to a new version

Replace the code in each place: click in its code window, **Ctrl+A**, **Delete**, and paste the new file. For the form, right-click it and choose View Code first. Then **Debug > Compile**, sign again, save, and restart Outlook. Your folder colors and save locations are kept, since they're stored in the registry rather than in the code.

**Transcribe Call has been taken out.** If you added it, remove it before pasting in the new file 2, or the project won't compile:

1. In the VBA editor, right-click the `NVS_mail_Transcribe` module, choose **Remove...** and answer **No** to exporting.
2. Choose **Tools > References** and untick **UIAutomationClient** (only Transcribe Call used it).
3. Take the Transcribe Call button off your ribbon or Quick Access Toolbar.

The Search window is now file 4 (`4_NVS_mail_Search.txt`) and Find a Time is file 5 (`5_NVS_mail_FindTime.txt`). Only the file names changed; the forms keep their names, so a Search or Find a Time form you've already added doesn't need redoing because of that.

**Coming from the version with the Alt, X ribbon keys:** replace files 1, 2 and 3, plus file 4 (Search) if you use it. Add file 5 for Find a Time, put `NVS_FindTime` on your NVS_mail tab, and run `NVS_SetRibbonShortcuts` again so it gets its key (**A**).

**Coming from the version with the Search window:** replace files 1, 2 and 3, plus file 4 (Search) if you use it, and add file 5 if you want Find a Time. Then, for the Alt, X keys, run `NVS_SetRibbonShortcuts` (see [step 6](#6-add-the-nvs_mail-buttons-to-the-ribbon)).

**Coming from the version with the `NVS_mail_Dialog` form, but no Search window:** replace files 1, 2 and 3. Add file 4 if you want the Search window and file 5 for Find a Time.

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
* The window lists **every file** in each folder, not just emails, so you can see what's already been saved there.
* The cursor starts in the folders rather than the file name box, like pressing Shift+Tab twice, so you can move around with the keyboard straight away. To start in the file name box instead, set `NVS_SAVE_START_IN_FOLDERS = False`.
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
* **Undo Move** puts the emails from the last File to Chain or Move (chain) back where they were, and their colors follow. Click it again to go further back, up to 20 moves.
  * Outlook's own **Ctrl+Z** only undoes moves made with Outlook's own buttons, so use Undo Move for NVS_mail's moves.
  * VBA has no safe way to take over Ctrl+Z, so Undo Move gets its own shortcut instead: see the Quick Access Toolbar tip in [step 6](#6-add-the-nvs_mail-buttons-to-the-ribbon).
  * The undo list lasts until Outlook closes.

**The Move Items window** works like Outlook's own, plus a search box:

* Every folder and subfolder is shown, in the same order as in Outlook, with the chain's folder selected.
* **The keyboard works from the search box.** You don't need to click into the folders first:
  * **Up** / **Down**, **Page Up** / **Page Down** move through the folders.
  * **Right** opens a folder; press it again to go into its first subfolder. **Left** closes it; press it again to go up to its parent. (While you're typing a search, Left and Right move the cursor in your text instead.)
  * **Enter** moves the email there. **Esc** cancels.
* **Tab** goes into the folder list itself, where the same keys work, plus **Home** / **End**, **+** / **-**, **\*** (open everything inside), **Backspace** (go to the parent) and **Insert** or **Ctrl+N** (new folder). Typing a letter there starts a search.
* **Search** finds a folder anywhere in your mailbox as you type. Folders whose name starts with what you typed come first, then ones with a word starting with it, then ones inside a folder that matches. Each result shows where it is. Clear the search and you're back in the tree, on the folder you found.
* **Mouse:** click an arrow to open or close a folder, **double-click** a folder to move there, and scroll with the **mouse wheel**.
* **New...** (Alt+N) creates a folder inside the selected one.
* It opens in the middle of the Outlook window you're working in, on the same screen and in front of Outlook. Drag its edge to resize it, and it remembers the size. If that size doesn't fit the screen you're on now, such as a laptop screen, it's shrunk to fit.

In conversation view, selecting a collapsed conversation moves all of its emails in the current folder.

> **Why not change Outlook's own Move button?** Outlook only lets compiled COM/VSTO add-ins take over built-in buttons. VBA macros can't. *Move (chain)* is the VBA equivalent. Put it where you'd normally click Move.

### 3. Color coding

Colors use Outlook **categories**. Each colored folder gets a category, `Folder: <folder name>` by default, with the color you pick.

1. Click **Set Folder Color** and pick the folder.
2. Click a color in the swatch grid. Hovering shows each color's name, and the bar underneath previews how the category tag will look. You can rename the category in the box.
3. Click **OK**. If the folder is new to NVS_mail, its existing chains are colored straight away (last `NVS_RECOLOR_DAYS_BACK` days). This covers the folder and its subfolders, plus the chains' emails in your Inbox and Sent Items. A progress window shows how far along it is, Outlook keeps responding, and **Cancel** stops it at any point.
4. **Changing only the color** of a folder that already has one is instant. Outlook repaints every email with that category by itself.

**Subfolders:** a color covers the folder and every folder inside it. If a subfolder has a color of its own, that one wins for it and its own subfolders. Emails filed outside the colored folder never get its color.

From then on, colors update automatically:

* **Filed emails** always show the color of the folder they're in, or of the colored folder above it.
* **Emails in your Inbox and Sent Items** show the color of the folder their chain was most recently filed in. New replies and the replies you send arrive already colored.
* When you move an email to another folder (with these buttons, Outlook's Move button, drag and drop, or a Quick Step), it takes its new folder's color, and the chain's Inbox and Sent Items emails follow it. Emails already filed somewhere else keep their own folder's color. This works for moves out of the Inbox and out of whichever folder you're looking at.
* NVS_mail only ever gives an email one folder color, and never touches your other categories.

**Folder Colors** (`NVS_ListFolderColors`) shows every colored folder with its color swatch, plus **Add...**, **Change...** (or double-click a row) and **Remove**. From the keyboard: **Up** / **Down** pick a row, **Enter** changes it, **Delete** removes it and **Insert** adds one. Save Locations works the same way.

In the color window, the **arrow keys** move between the colors and **Enter** picks one. **Tab** goes to the category name.

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

### 6. Search (optional)

**Search** (`NVS_Search`, file 4) is a search window built to fix the usual complaints about Outlook's own search.

| Outlook's search | NVS_mail's Search |
|---|---|
| Relies on Windows' search index, which is often incomplete, so emails go missing | Reads every email's subject, people, date and folder straight from your mail folders, so nothing on your PC is left out |
| Shows 250 results unless you change a setting | No cap. Lists the newest 500, and **Show more** lists the rest |
| Only matches the start of a word: `1234` won't find `PO1234` | Matches anywhere in a word |
| Often searches just the current folder | Every folder, unless you choose one in **Folder** |
| "Top results" can bury recent mail | Always newest first |
| Deleted and junk mail mixed in | Left out unless you tick the box |
| Doesn't show where a result is filed | A Folder column, and **Go to folder** |
| You type, press Enter and wait | Results appear as you type |

**One-time setup**

1. In the VBA editor, choose **Insert > UserForm**. Press **F4** and change **(Name)** to `NVS_mail_Search`.
2. Right-click the form, choose **View Code**, delete anything there, and paste in `4_NVS_mail_Search.txt`. Leave the form blank.
3. Choose **Debug > Compile**, then save.
4. Add `NVS_Search` to your ribbon group. On the Quick Access Toolbar it also gets an Alt+number shortcut.

**Using it**

* Click **Search**. The first time in each Outlook session it reads your mail, which takes a few seconds for a typical mailbox. Progress shows at the bottom left, and you can start typing straight away.
* Before you type anything, it lists your most recent mail from every folder.
* **Type words.** An email matches when every word appears somewhere in its subject, the sender's name or email address, or the names on its To and Cc lines. The order doesn't matter, and a word can match in the middle of a longer one.
  * `acme budget` finds emails with both words.
  * `"site visit"` finds that exact phrase.
  * `-draft` leaves out emails with that word.
  * A company name also finds everyone who wrote from an address at that company.
* **Narrow it down** with the boxes underneath:
  * **From** and **To** take part of a name. To also covers Cc.
  * **When** has ready-made periods, plus custom dates.
  * **Folder** lets you pick a folder or type part of a folder's name. Subfolders are included.
  * **Has attachments** counts real attachments only, not pictures in a signature.
  * **One per chain** lists just the newest email of each chain, with the number of emails in it.
* **The preview** under the list shows the selected email's text, starting at the first place your words appear.
* **Whole chain** lists every email in the selected email's chain, wherever each one is filed. **Back** returns to your search.
* **Search text** (Alt+T) also looks inside the emails' text and adds what it finds to the list. If nothing matched by subject or people, pressing Enter does this for you.
* **In Outlook** runs the same search with Outlook's own search across all folders. Use it for mail that isn't on your PC and for words inside attachments.

| Key | What it does |
|---|---|
| **Up / Down**, **Page Up / Down** | Move through the results, even while typing |
| **Enter** | Open the selected email |
| **Ctrl+Enter** | Show it in its folder in Outlook |
| **Esc** | Close the window. Your search is still there next time |
| **F5** | Read all your mail again |

**Staying up to date:** the window re-reads only folders whose mail has changed. That covers new mail, mail you send, and mail you move or delete. It checks each time you open it and when you type. **F5** reads everything again from scratch.

**Limits**

* **Only mail that's on your PC.** Outlook keeps a set period of mail offline. To check it, go to **File > Account Settings > Account Settings**, double-click your account, and look at **Download email for the past**. Older mail lives only on the server, so use **In Outlook** for it, or move that slider to **All**.
* **Message text goes through Windows' index.** The text inside emails isn't in the window's own list, so **Search text** uses the same index Outlook does. It matches the start of words, and it can miss emails if that index is incomplete. Searching by subject and people doesn't have that problem.
* **Memory.** The list is kept in memory while Outlook is open, roughly 60 to 70 MB for every 100,000 emails. It's rebuilt each time Outlook starts.
* **Shared mailboxes.** One is included when you open Search while looking at one of its folders. Search text covers your own mailbox only.
* **Sender addresses.** If reading them turns out to be slow on your PC, the window leaves them out and says so in its status line. Names still match.

The Search window has its own settings at the top of file 4:

| Setting | Default | Meaning |
|---|---|---|
| `SEARCH_SHOW_ROWS` | `500` | Results listed at first. **Show more** lists four times as many. |
| `SEARCH_MONTHS_BACK` | `0` | `0` reads all the mail on your PC. `24` reads only the last two years, which opens faster and uses less memory. |
| `SEARCH_SENDER_ADDRESS` | `True` | Also match the sender's email address. |
| `SEARCH_MAX_EMAILS` | `400000` | Stop reading beyond this many emails. |
| `TEXT_MAX_RESULTS` | `3000` | Most message-text matches taken for one search. |

### 7. Find a Time (optional)

**Find a Time** (`NVS_FindTime`, file 5) shows the calendars of everyone on a chain side by side, lists the times most of them can make, and opens Outlook's meeting invite for the time you pick. Nothing is ever sent: you check the invite, add a Teams link if you want one, and press Send yourself.

**One-time setup**

1. In the VBA editor, choose **Insert > UserForm**. Press **F4** and change **(Name)** to `NVS_mail_FindTime`.
2. Right-click the form, choose **View Code**, delete anything there, and paste in `5_NVS_mail_FindTime.txt`. Leave the form blank.
3. Choose **Debug > Compile**, sign again (Tools > Digital Signature) and save.
4. Add `NVS_FindTime` to your NVS_mail tab, then run `NVS_SetRibbonShortcuts` again. **Alt, X, A** then opens it.

**The quickest way through it**

1. Select (or open) an email in the chain and press **Alt, X, A**.
2. Everyone on the chain is listed and their calendars are read. You're always included. People only ever on Cc are optional (`NVS_CC_AS_OPTIONAL`).
3. **Best times** fills in, with the times the most people can make at the top, soonest first. Use **Up** / **Down** to look at them; the people list shows who's free, busy or tentative at the selected time.
4. Press **Enter**. The meeting invite opens with everyone on it, the chain's subject, and that time and length.

**Adding people:** just type a name. Wherever you are in the window, typing a letter starts it. Suggestions come from people you've emailed recently, the ones you email most first. **Down** / **Up** pick one; **Enter** adds them as required, **Shift+Enter** as optional. Anyone else is looked up in the address book as you'd type them in an email ("Smith, Jane", an alias, or an email address). **Ctrl+K** opens the address book itself, with Required and Optional boxes.

**Someone sent the times that work for them?** Press **Alt+O** and type them the way they wrote them. The line under the box shows how they were read, in your time. From then on, only those times are suggested.

| You type | It looks at |
|---|---|
| `tue 2-4pm` | Tuesday 2:00 to 4:00 PM |
| `Tuesday 2-4, Wednesday 10-11:30` | both |
| `tue 10-11, 2-4` | both, on Tuesday |
| `mon or tue 2-4` | 2:00 to 4:00 PM on both days |
| `thu after 3`, `fri before 11` | Thursday from 3 PM to the end of your hours; Friday from the start of your hours to 11 AM |
| `tomorrow morning`, `wed afternoon` | the morning (until noon) or afternoon (from noon) |
| `11/30 9am-12`, `dec 2 1:30-3`, `the 30th 4-5` | those dates |
| `next tue 2-3` | Tuesday of next week |
| `tue 2-4 PT`, `wed 10-11 ET`, `thu 3-5 London` | converted to your time, summer time included (ET, CT, MT, PT, London/UK, CET, HK, Singapore, Tokyo) |
| `2-3` | 2:00 to 3:00 PM on every day shown |

Times without am/pm are read as working hours: 7 to 11 are mornings, 12 is noon, 1 to 6 are afternoons. Clear the box to look at every time again.

**The grid** (**Alt+G**) shows each working day for the next two weeks, from 7 AM to 8 PM. Each box is a meeting **starting** then, checked for its whole length. **Green** means everyone's free; **light green** means only optional people are busy; **yellow**, **orange** and **red** mean one, two, or three or more required people can't make it, with the number in the box. Pale boxes are outside your hours, or not among the times you picked. Grey means it's past or too late in the day. The black box is the selected time.

* **Arrows** move. **Home** / **End** go to the start and end of your hours. **Page Up** / **Page Down** show earlier or later days, if they don't all fit.
* **Space** marks a time to look at, in blue (or right-click it). **Shift+arrows** mark as you go, and **Delete** clears the marks. Marked times work like Only at: only they're suggested.
* **Enter** opens the invite for the selected time. Hover over a time to see who can't make it.

**Other keys**

| Key | What it does |
|---|---|
| **Alt+P** | The people list. **Space** switches someone between required, optional and not invited ("off"). **Delete** removes them. |
| **Alt+L** | Meeting length: pick one or type minutes (`45`) or hours (`1.5h`). |
| **Alt+H** | The hours best times are looked for in, such as `8am-6pm` or `7:30-19`. |
| **Alt+T** | Whether tentative meetings count as busy. |
| **Alt+S** | The invite's subject. |
| **Alt+B** | Best times. **Enter** in any box takes you here too. |
| **Enter** / **Ctrl+Enter** | Open the invite for the selected time (Ctrl+Enter works from anywhere). |
| **F5** | Read everyone's calendar again. Calendars are otherwise kept for 10 minutes. |
| **Esc** | Close the window. It keeps everything for next time. |

The window stays open while you work in Outlook, so you can go back to the email to read someone's times. Running Find a Time on another chain starts over with that chain's people.

**Limits**

* **Calendars from your own company only.** People outside it show `?`: they're still invited, but they don't count toward the best times. If they sent their times, type them in Only at.
* **Times start on the hour or half hour.**
* **Up to a month ahead.** Outlook gives free/busy for about a month, so later days typed in Only at are left out.

Find a Time's settings are at the top of file 5:

| Setting | Default | Meaning |
|---|---|---|
| `FT_DAYS` | `10` | Working days shown, starting today. |
| `FT_GRID_FROM` / `FT_GRID_TO` | `7` / `20` | Hours the grid covers (24-hour clock). |
| `FT_HOURS` | `"8am-6pm"` | The hours to look in when it opens. |
| `FT_LENGTH` | `30` | Meeting length when it first opens, in minutes. It then keeps the last one you used. |
| `FT_TENTATIVE_BUSY` | `True` | Tentative counts as busy. |
| `FT_WEEKENDS` | `False` | Show Saturdays and Sundays too. |

---

## Settings

These are at the top of the **NVS_mail** module (file 1). Change the value, then save and restart Outlook.

| Setting | Default | Meaning |
|---|---|---|
| `NVS_CATEGORY_PREFIX` | `"Folder: "` | Start of the category names NVS_mail creates. |
| `NVS_EXCLUDED_FOLDER_NAMES` | `"Archive;Conversation History;Snoozed;Scheduled"` | Folders that never count as a chain's folder. |
| `NVS_AUTO_COLOR` | `True` | Color mail automatically as it arrives, is sent or is filed. |
| `NVS_NEW_MAIL_DELAY` | `2` | Seconds new mail waits before it's colored, so your Outlook rules get to it first. |
| `NVS_RECOLOR_DAYS_BACK` | `180` | How far back coloring existing mail and `NVS_RecolorInbox` look. `0` means all mail. |
| `NVS_SKIP_INLINE_IMAGES` | `True` | When saving, skip pictures embedded in the body. |
| `NVS_SAVE_START_IN_FOLDERS` | `True` | When the Save As window opens, put the cursor in the folders instead of the file name box. |
| `NVS_SUBFOLDER_PER_EMAIL` | `True` | When saving several emails at once, give each one its own subfolder. |
| `NVS_MEETING_SUBJECT_PREFIX` | `""` | Text added before the meeting subject. |
| `NVS_CC_AS_OPTIONAL` | `True` | People only on CC become optional attendees. |
| `NVS_RIBBON_TAB_KEY` | `"X"` | The key after Alt that opens your NVS_mail tab. Run `NVS_SetRibbonShortcuts` again after changing it. `""` gives the tab Outlook's own keys back. |
| `NVS_RIBBON_KEYS` | `"NVS_FileToChainFolder=F;..."` | The key for each button on that tab, one to three letters or digits each. Run `NVS_SetRibbonShortcuts` again after changing it. |
| `NVS_MOUSE_WHEEL` | `True` | Let the mouse wheel scroll NVS_mail's windows. Outlook's VBA windows ignore the wheel on their own, so this uses a small Windows hook while one of them is open. |
| `NVS_LOG` | `True` | Keep a short log of what NVS_mail does, in `NVS_mail.log` in your TEMP folder. |

The Search window's and Find a Time's settings are in their own sections, [Search](#6-search-optional) and [Find a Time](#7-find-a-time-optional).

Folder colors, save locations, recent searches and the last folder you moved mail to are stored in the registry under `HKEY_CURRENT_USER\Software\VB and VBA Program Settings\NVS_mail`.

---

## Troubleshooting

* **"User-defined type not defined" when compiling:** the form isn't named exactly `NVS_mail_Dialog`. It's probably still `UserForm1` or `NVS_mail_FolderPicker`, or the name has a typo.
* **Red line, or "Duplicate Option statement", "Invalid outside procedure" or "Only comments may appear after End Sub" right after pasting:** there's an extra `Option Explicit` (keep only the first one), a file was pasted twice, or a file went in the wrong place. File 1 goes in a Module, file 2 in the UserForm's code window, and file 3 in ThisOutlookSession. If ThisOutlookSession has your own code too, see step 4.
* **Buttons do nothing after restarting Outlook:** macros are disabled. See steps 1 and 5.
* **Outlook seems frozen and you can't click anything:** usually an NVS_mail or Outlook window is waiting for you somewhere you can't see it: behind Outlook, or on a screen that's no longer connected. Press **Alt+Tab** to find it, or **Esc** to cancel it. NVS_mail's windows and messages now always open in front of Outlook, on the screen you're working on.
  * If Outlook really does hang, open `%TEMP%\NVS_mail.log` in Notepad (type that into the File Explorer address bar). Its last lines show what NVS_mail was doing and how long each step took. Send them to whoever looks after your NVS_mail.
  * NVS_mail colors big batches of new mail a few at a time, so Outlook stays usable, and it gives up on a single giant chain after a few seconds. Outlook can put thousands of automated emails with the same subject into one chain.
* **Outlook says it couldn't apply your rules:** this happened when an Outlook rule tried to move an email in the moment NVS_mail was coloring it. New mail is now colored 2 seconds after it arrives, once your rules have run. If you still see it, make `NVS_NEW_MAIL_DELAY` longer, such as `4`. If that doesn't help, turn off coloring new mail with `NVS_AUTO_COLOR = False`.
* **The mouse wheel doesn't scroll, or the pointer acts oddly while an NVS_mail window is open:** set `NVS_MOUSE_WHEEL = False` at the top of file 1. The arrow and Page keys and the scroll bars still work.
* **"An error occurred while attempting to verify the VBA project's signature" when Outlook starts:** the code changed after it was signed, which usually happens after pasting in an update. In the VBA editor choose **Debug > Compile**, then **Tools > Digital Signature > Remove**, then **Choose...** and pick your certificate. Click **Save**, close Outlook completely and start it again. If it keeps happening, make a new certificate with **Digital Certificate for VBA Projects** and sign with that one.
* **The NVS_mail tab still shows Y1, Y2... after running `NVS_SetRibbonShortcuts`:** close Outlook completely (check Task Manager) and start it again. If the keys still aren't there, import the copy it saved on your Desktop: **File > Options > Customize Ribbon > Import/Export > Import customization file**, pick `NVS_mail ribbon (main window).exportedUI` and click **Yes**. The copy holds all your current ribbon and Quick Access Toolbar changes, plus the keys.
* **Only the tab shows a Y-number, and its buttons have their letters:** something else already uses X, often an Add-ins tab. Set `NVS_RIBBON_TAB_KEY` to another letter, such as `"N"`, and run `NVS_SetRibbonShortcuts` again.
* **Your ribbon changes disappeared after running `NVS_SetRibbonShortcuts`:** close Outlook and open `%LOCALAPPDATA%\Microsoft\Office` in File Explorer. Delete `olkexplorer.officeUI`, rename `olkexplorer.officeUI.bak` to `olkexplorer.officeUI`, and start Outlook again.
* **New mail isn't colored:** the code in ThisOutlookSession (step 4) starts when Outlook starts, so restart Outlook after installing. Also check that the chain is actually filed in a colored folder, using Folder Colors.
* **"isn't filed anywhere yet" for a chain you did file:** filing works within one mailbox. Mail in a different mailbox, PST file or online archive isn't part of the same Outlook conversation. Also check the folder isn't in `NVS_EXCLUDED_FOLDER_NAMES`.
* **Unrelated emails share a color:** Outlook sometimes puts emails with the same subject into one conversation, which is common with automated emails. NVS_mail goes by Outlook's conversation, so they count as one chain.
* **NVS_mail's windows look the wrong size, or blurry, on one of your screens:** this happens when two screens use different scaling. In Outlook, go to **File > Options > General**, set **When using multiple displays** to **Optimize for compatibility**, and restart Outlook. You can also resize the Move Items window by dragging its edge, and it keeps the size you choose.
* **The Save As window doesn't appear:** NVS_mail falls back to Windows' simpler folder browser. Pick the folder there and click OK.

* **Search says it "isn't set up yet":** add file 4. The form must be named exactly `NVS_mail_Search`.
* **Search takes a long time to read your mail the first time:** set `SEARCH_MONTHS_BACK` at the top of file 4 to `24` (or fewer) so it reads only recent mail, or set `SEARCH_SENDER_ADDRESS` to `False`.
* **Search shows an email in the wrong folder, or says it has moved:** press **F5** in the Search window to read your mail again.
* **Find a Time says it "isn't set up yet":** add file 5. The form must be named exactly `NVS_mail_FindTime`.
* **Someone shows `?` in Find a Time:** their calendar can't be read. They're outside your company, or their calendar isn't shared. They're still invited. If they sent their times, type them in **Only at**.
* **The line under Only at says "Couldn't read" part of what you typed:** write it as a day and a time, like `tue 2-4`, `11/30 9-11` or `thu after 3`, with commas between separate times.

## Uninstall

In the VBA editor, right-click the `NVS_mail` module, the `NVS_mail_Dialog` form and (if you added them) `NVS_mail_Search` and `NVS_mail_FindTime`, choose **Remove...** (answer No to exporting), and delete the NVS_mail code (everything with `nvs` or `NVS_` in it) from ThisOutlookSession. Delete the registry key above. Optionally delete the `Folder: ...` categories in **Categorize > All Categories**.
