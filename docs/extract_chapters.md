[← Back to README](/README.md)

# [extract_chapters.lua](/scripts/extract_chapters.lua)

Extract embedded chapter data from MKV files into external XML files using MKVToolNix.

This script allows you to **export chapters from MKV containers** into standalone `.xml` files, either for the currently loaded file, all MKVs in a folder, or recursively across parent directories.

It is intended for workflows where chapters are **edited, renamed, offset, or reused externally** before being reapplied with other tools in this framework.

---

## Core behavior

- Extracts embedded MKV chapters to XML files
- Supports:
  - Current video only
  - All MKVs in the current folder
  - All MKVs in the parent folder (recursive)
- Automatically detects `mkvextract.exe`
- Avoids overwriting existing XML files by default
- Provides progress feedback via OSD
- Designed to be batch-safe

---

## Supported formats

- **Input:** MKV only  
- **Output:** XML (Matroska chapter format)

>MP4 is intentionally not supported here, as MP4 chapters are not embedded in the same way.

---

## File naming and overwrite behavior

By default, extracted XML files are written as:

```
video.mkv
video.xml
```

If `video.xml` already exists, a numeric suffix is added:

```
video (1).xml
video (2).xml
```

### Overwrite mode

You can toggle overwrite behavior at runtime (**Shift+Ctrl+O**):

- **Overwrite disabled (default):** add numeric suffix
- **Overwrite enabled:** replace existing XML files

The current mode is shown via OSD.

---

## Extraction modes

### 1. Current video only

Extracts chapters from the currently playing MKV (**Shift+Ctrl+E**).

Use case:
- Quick export for editing, inspection or storage

---

### 2. Current folder

Extracts chapters from **all MKV files in the same folder** as the current video (**Shift+Ctrl+Alt+E**).

Use case:
- Episode-level batch processing
- Season folders

---

### 3. Parent folder (recursive)

Extracts chapters from **all MKV files in the parent directory and all subfolders** (**Shift+Ctrl+Alt+U**).

Use case:
- Full library or season-wide extraction
- Preparing external chapter sets in bulk

---

## Progress and OSD feedback

- Shows percentage and current filename during extraction
- Displays the current filename being processed
- Reports final extraction counts

Operations scale with:
- Number of MKV files
- Size of embedded chapter data

---

## Keybindings

| Key | Action |
|----|-------|
| **Shift+Ctrl+E** | Extract chapters from current MKV |
| **Shift+Ctrl+Alt+E** | Extract chapters from all MKVs in current folder |
| **Shift+Ctrl+Alt+U** | Extract chapters recursively from parent folder |
| **Shift+Ctrl+O** | Toggle overwrite mode (overwrite ↔ numeric suffix) |

---

## Typical use cases

- Backing up embedded chapters before editing
- Converting container-embedded chapters into editable XML
- Library-wide chapter extraction workflows

---

## Safety guarantees

- Never deletes or modifies MKV files
- Never overwrites XML files unless explicitly enabled
- Batch failures do not abort the entire operation
- Missing tools fail safely with clear OSD messages

---

## Platform-specific behavior

- Windows-only
- Uses PowerShell for folder scanning and execution
- Requires MKVToolNix installation

---

## Dependencies

- **MKVToolNix**
  - `mkvextract.exe` (required)
  - `mkvpropedit.exe` (not used here, but part of the broader framework)
