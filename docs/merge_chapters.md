[← Back to README](/README.md)

# [merge_chapters.lua](/scripts/merge_chapters.lua)

Manage, replace, and clean chapter files for MKV and MP4 media in mpv.

This script provides **batch-safe, file-level chapter management** using external tools (**MKVToolNix** and **MP4Box**) to apply, replace, back up, or remove chapters across single files, folders, or entire directory trees.

It is designed for users who maintain chapters **outside the container**, typically as
`.xml` (MKV) or `.txt` (MP4) files, and want reliable propagation into media files.

---

## Core behavior

- Replaces embedded chapters using external chapter files
- Supports **MKV (XML)** and **MP4 (CHAP TXT)** formats
- Can operate on:
  - Current file only
  - All videos in the current folder
  - Entire directory trees (recursive, starting from parent folder of current file)
- Automatically detects required external tools
- Validates XML chapter files before applying
- Supports safe deletion (Recycle Bin) of chapter files
- Can back up and clear embedded chapters from MKV files
- Provides detailed OSD progress and summaries

---

## Supported external tools

This script relies on external binaries (auto-detected on Windows):

### MKV
- `mkvpropedit.exe` (required)
- `mkvextract.exe` (optional, for backups)

### MP4
- `MP4Box.exe` (optional; disables MP4 support if missing)

If a tool is missing:
- The relevant feature is disabled
- Clear OSD and log messages explain what is unavailable

---

## Chapter file matching rules

For each video file:

### MKV
```
video.mkv
video.xml
```

- XML must contain a valid `<Chapters>` root
- Invalid XML is skipped safely

### MP4
```
video.mp4
video.txt
```

- TXT files are assumed to be CHAPTERxx format (MP4 compatible)

Only matching chapter files are applied.

---

## Replace modes

The script supports two replace scopes:

### Current video only
- Default mode: imports chapters to the currently loaded file

### All videos in folder
- Imports chapters to all MKV/MP4 files in the same folder
- Controlled by replace mode toggle

Recursive replacement across subfolders is also supported.  
>**Note:** Recursive operations start from the parent folder of the currently loaded video file.

---

## Keybindings

### Replace operations

| Key | Action |
|----|-------|
| **Ctrl+Alt+T** | Toggle replace mode (current file ↔ all files in folder) |
| **Ctrl+Alt+M** | Replace chapters (current folder or current file) |
| **Shift+Ctrl+Alt+M** | Replace chapters recursively (parent folder → all subfolders) |

---

## Recursive replace behavior

- Scans all `.mkv` and `.mp4` files starting from the **parent folder** of the currently loaded video
- Matches local chapter files per video
- Shows per-file progress
- Displays final summary:
  - Files updated
  - Files scanned
  - Folders affected

This is intended for season-level or library-wide updates.

---

## Chapter file cleanup (safe delete)

Chapter files are moved to the **Recycle Bin**, not permanently deleted.

Supported extensions:
- `.xml`
- `.txt`

### Keybindings

| Key | Action |
|----|-------|
| **Ctrl+Alt+D** | Recycle XML/TXT files in current folder |
| **Shift+Ctrl+Alt+D** | Recycle XML/TXT files recursively (parent folder → all subfolders) |

OSD output reports:
- Number of XML files
- Number of TXT files
- Affected folders

---

## Backup and clear embedded chapters (MKV only)

Safely back up and remove chapters embedded inside an MKV file.

Behavior:

**1.** Extracts chapters to: `video.chapters.backup.xml`  
**2.** Clears embedded chapters from the MKV container  
**3.** Updates mpv’s in-memory chapter list  

Safeguards:
- MKV-only
- Refuses to overwrite existing backups
- Aborts if required tools are missing

### Keybinding

| Key | Action |
|----|-------|
| **Shift+Ctrl+Del** | Back up and clear chapters from current MKV |

---

## Progress and OSD feedback

- Per-file progress percentages
- Clear success/failure messages
- Folder-level summaries
- Duration scales with output size

> **Performance note (MP4 files)**  
> Applying chapters to large MP4 files may take significantly longer than MKV files.  
> This is a limitation of how `MP4Box` rewrites MP4 containers and involves heavier disk I/O.  
> Progress OSD remains active during long operations.

---

## Safety guarantees

- Chapters are never modified implicitly
- XML files are validated before use
- Deletions go to the Recycle Bin
- Backups are created before destructive operations
- Unsupported formats fail safely
- Partial failures do not abort batch jobs

---

## Platform-specific behavior

- Windows-only
- Uses PowerShell for:
- Recursive scanning
- Safe deletion
- External tool execution
- UTF-8 safe for paths and output

---

## Works well with other chapter tools

Typical workflow:

**1.** Author, correct, or adjust chapters  
**2.** Validate chapters in mpv  
**3.** Apply chapters into containers using this script  
**4.** Optionally clean up external chapter files  

---

## Dependencies

- MKVToolNix (`mkvpropedit.exe`, `mkvextract.exe`)
- GPAC (`MP4Box.exe`) for MP4 support
- Windows PowerShell
