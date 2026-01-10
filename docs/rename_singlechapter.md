[← Back to README](/README.md)

# [rename_singlechapter.lua](/scripts/rename_singlechapter.lua)

Rename the currently active chapter in mpv.

This script provides a minimal, focused workflow for renaming **only the current chapter** without affecting timestamps, numbering, or other chapter titles.
It is designed to complement bulk chapter tools by allowing precise, single-edit fixes.

---

## Core behavior

- Renames the chapter active at the current playback position
- Auto-saves chapter files after renaming
- Integrates with the framework-wide auto-save toggle

---

## How the current chapter is determined

- The script selects the **last chapter whose timestamp is ≤ current playback time**
- If playback is between chapters, the previous chapter is considered current
- If no chapters exist, the operation is aborted safely

This matches mpv’s standard “current chapter” semantics.

---

## Keybindings

| Key | Action |
|-----|--------|
| **A** | Rename current chapter |

> This script does **not** define a keybinding for toggling auto-save mode.

---

## Typical use cases

- Fixing typos in a single chapter title
- Renaming one scene without disturbing numbering
- Adjusting chapter names after bulk generation
- Fine-tuning chapter metadata before export

## Rename workflow

**1.** Press **A**  
**2.** A small input dialog appears (Windows only)  
**3.** The current chapter title is pre-filled  
**4.** Enter a new name and confirm  
**5.** The chapter title is updated immediately  

If the dialog is canceled or left empty:
- No changes are applied

---

## Auto-save mode

Auto-save runs automatically **after a successful rename**.

Supported modes:

- XML (MKVToolNix compatible)
- CHAPTERxx TXT (mp4-compatible)

Auto-save mode is stored **locally per script instance**.

---

## Auto-save toggle (broadcasted)

This script listens for the shared framework message: `script-message toggle_auto_save_mode`

When the message is received:
- The local auto-save mode switches between XML ↔ CHAPTERxx TXT
- The new mode applies to subsequent renames

This script does **not** emit the toggle message itself.

---

## Dependency on create_chapter.lua

The auto-save toggle is **expected to be emitted by another script**.

In the default framework setup:
- **[create_chapter.lua.lua](docs/create_chapter.md)** defines the **Shift+X** keybinding
- Pressing **Shift+X** broadcasts `toggle_auto_save_mode`
- `rename_singlechapter.lua` reacts to that broadcast

If `create_chapter.lua` is **not loaded**:
- **Shift+X does nothing**
- Auto-save mode remains at its initial value
- Renaming still works, but auto-save cannot be toggled at runtime

This dependency is **intentional** and keeps scripts loosely coupled.

---

## Design intent of broadcast dependency

- One global keybinding controls auto-save behavior
- No duplicate keybindings across scripts
- No hard script-to-script calls
- Scripts opt in by registering the same message
- Additional scripts can participate without modification

---

## Export behavior

When auto-save is enabled:

- The chapter file is rewritten immediately after renaming
- Output path is derived from the media filename
- Existing files are overwritten without confirmation

Formats:

### XML
- Matroska chapters (MKVToolNix compatible)
- Deterministic ChapterUID generation
- Generated edition is marked as the default edition

### CHAPTERxx TXT
- Two-digit chapter numbering (CHAPTER01, CHAPTER02, …)
- Compatible with MP4 and MKV tooling

---

## Platform-specific behavior

- Chapter rename input uses a Windows PowerShell InputBox
- On non-Windows systems, the rename action is inert
- All non-UI logic remains platform-independent

---

## Dependencies

- **[create_chapter.lua](/docs/create_chapter.md)** (for Shift+X auto-save toggle broadcast)
- Windows PowerShell (optional, for rename dialog UI)
