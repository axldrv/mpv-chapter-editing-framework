[← Back to README](/README.md)

# [find_&_replace.lua](/scripts/find_&_replace.lua)

Find and replace exact chapter titles in mpv.

This script scans existing chapter titles and replaces them using an **explicit, user-defined mapping**.
Only **full, case-sensitive matches** are modified. It is designed for **controlled normalization** of chapter names.

The script does **not** guess, partially match, or infer intent. If no exact match is found, nothing is changed.

---

## Customizable parameters

The behavior of this script is controlled by user-editable variables at the top of the file:

- **WORD_MAP**  
  A table defining exact `find → replace` pairs.

  Example:
  ```
  ["Intro"]     = "Opening"
  ["Credits"]   = "End credits"
  ```

  Rules:
  - Matching is **full-title only**
  - Matching is **case-sensitive**
  - Partial matches are ignored

- **AUTO_SAVE_MODE**  
  Initial auto-save format (`xml` or `chap_txt`)

- **AUTO_RENAME_ENABLED**  
  Whether replacements run automatically on file load (disabled by default)  

- **DEBOUNCE_DELAY**  
  Delay (in seconds) before auto-renaming executes on file load
  Debounce does not affect manual runs

By editing `WORD_MAP`, you can adapt the script to:
- Different naming conventions
- Streaming-service labels
- Personal or library-wide standards

---

## Core behavior

- Renames chapters using an explicit **find → replace map**
- Applies only **exact, case-sensitive matches**
- Renames multiple chapters in one pass
- Preserves chapter order
- Preserves chapter timestamps
- Leaves non-matching chapters untouched
- Auto-saves chapter files after renaming
- Integrates with the framework-wide auto-save toggle

---

## How chapters are selected

A chapter is eligible for renaming if:

- Its title exactly matches a key in `WORD_MAP`
- Case must match exactly
- The entire title must match (no substrings)

Examples (default configuration):

| Original title | Result |
|---------------|--------|
| `Intro` | `Opening` |
| `intro` | unchanged |
| `Intro Scene` | unchanged |
| `Credits` | `End credits` |
| `credits` | unchanged |

This strict behavior avoids unintended renaming.

---

## Workflow

**1.** The current chapter list is read  
**2.** Each chapter title is compared against `WORD_MAP`  
**3.** Matching titles are replaced  
**4.** All replacements occur in one operation  
**5.** Chapters are auto-saved  

If no matches are found, the script exits without changes.

---

## On-screen display (OSD)

When replacements occur, the OSD shows:

- Number of chapters renamed
- Which original titles were matched

Example:
```
Found & Replaced 3 chapters (Intro, Credits)
```

If no matches are found:
```
No chapters found to replace.
```

---

## Keybindings

| Key | Action |
|-----|--------|
| **Alt+F** | Apply find & replace immediately |
| **Ctrl+F** | Toggle auto-rename on file load |

> This script does **not** define a keybinding for toggling auto-save mode.

---

## Typical use cases

- Normalizing inconsistent chapter names
- Fixing capitalization differences
- Renaming service-specific labels
- Cleaning up chapters after detection
- Enforcing preferred wording across a library

---

## Auto-save mode

Auto-save runs automatically **after a successful rename operation**.

Supported modes:

- XML (MKVToolNix compatible)
- CHAPTERxx TXT (mp4-compatible)

Auto-save mode is stored **locally per script instance**.

---

## Auto-save toggle (broadcasted)

This script listens for the shared framework message: `script-message toggle_auto_save_mode`

When received:
- The local auto-save mode switches between XML ↔ CHAPTERxx TXT
- The new mode applies to subsequent rename operations

This script does **not** emit the toggle message itself.

---

## Dependency on create_chapter.lua

The auto-save toggle is **expected to be emitted by another script**.

In the default framework setup:
- **[create_chapter.lua](/docs/create_chapter.md)** defines the **Shift+X** keybinding
- Pressing **Shift+X** broadcasts `toggle_auto_save_mode`
- `find_&_replace.lua` reacts to that broadcast

If `create_chapter.lua` is **not loaded**:
- Auto-save mode remains at its initial value
- Renaming still works
- Auto-save cannot be toggled at runtime

This dependency is intentional and keeps scripts loosely coupled.

---

## Export behavior

When auto-save is enabled:

- Chapter files are rewritten immediately after renaming
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

- Fully platform-independent
- No UI dialogs or OS-specific features are used

---

## Dependencies

- **[create_chapter.lua](/docs/create_chapter.md)** (for Shift+X auto-save toggle broadcast)
