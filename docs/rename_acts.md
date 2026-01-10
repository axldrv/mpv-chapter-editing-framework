[← Back to README](/README.md)

# [rename_acts.lua](/scripts/rename_acts.lua)

Rename chapters into Roman-numeral act format in mpv.

This script scans existing chapter titles, matches configurable naming patterns,
and renames them into a structured **Act I, Act II, Act III…** format using
Roman numerals.

It is intended for content with traditional act-based structure
(films, plays, long-form narratives, TV episodes).

---

## Customizable parameters

The behavior of this script is controlled by user-editable variables at the top of the file:

- **MATCH_WORDS**  
  A list of prefixes that qualify a chapter for renaming (e.g. `Chapter`, `Scene`, `Part`, `Act`, `Episode`)

- **DEST_WORD**  
  The destination prefix applied to renamed chapters (default: `Act`).  
  Can be changed to anything else (e.g. `Part`, `Chapter`).

- **AUTO_SAVE_MODE**  
  Initial auto-save format (`xml` or `chap_txt`)

By editing these values, you can adapt the script to:
- Different structural conventions
- Alternative destination labels (e.g. `Part`, `Chapter`)
- Non-English workflows

---

## Core behavior

- Renames multiple chapters in one operation
- Matches chapter titles using configurable prefix rules
- Converts numeric ordering into Roman numerals
- Preserves chapter timestamps
- Leaves non-matching chapters untouched
- Auto-saves chapter files after renaming
- Integrates with the framework-wide auto-save toggle

---

## How chapters are selected

A chapter is eligible for renaming if its title:

- Starts with **any word listed in `MATCH_WORDS`**
- Matching is case-sensitive (as implemented)
- The remainder of the title (after the prefix) is:
  - Empty
  - A number (e.g. `3`)
  - Letters (e.g. `A`, `B`)
  - A valid Roman numeral (e.g. `I`, `IV`, `X`)

Only chapters that satisfy these conditions are renamed.

### Examples that will be renamed (default configuration)

- `Chapter 1`
- `Scene 2`
- `Act III`
- `Episode 4`
- `Part A`

Examples that will be ignored:

- `Intro`
- `Opening Credits`
- `Behind the Scenes`


> Note  
> This script **does not generate Arabic numeric chapter titles**.
>
> Existing numbers are only *recognized* for matching purposes (e.g. `Chapter 1`, `Scene 2`, `Act 3`).
>
> All renamed chapters are output using **Roman numerals** (e.g. `Act I`, `Act II`, `Act III`).
>
> If you want chapters named using **Arabic numbers** (e.g. `Act 1`, `Act 2`),  use **[rename_chapters.lua](/docs/rename_chapters.md)** instead and set `DEST_WORD` to `"Act"`.

---

## Keybindings

| Key | Action |
|-----|--------|
| **Ctrl+Shift+A** | Rename matching chapters to Roman-numeral acts |

> This script does **not** define a keybinding for toggling auto-save mode.

---

## Typical use cases

- Converting numbered chapters into Act I/Act II structures
- Normalizing mixed chapter naming into classical acts
- Preparing films or narrative content for final release
- Cleaning up chapters imported from heterogeneous sources

---

## Workflow

**1.** Chapters are sorted by timestamp  
**2.** Matching chapters are assigned sequential numeric order  
**3.** Numeric order is converted to Roman numerals  
**4.** Chapter titles are rewritten as `DEST_WORD <Roman>`  
**5.** Chapters are auto-saved  

### Example

Input:

- 00:00:00  Intro
- 00:05:00  Chapter 1
- 00:20:00  Scene 2
- 00:45:00  Chapter 3

Result:

- 00:00:00  Intro
- 00:05:00  Act I
- 00:20:00  Act II
- 00:45:00  Act III

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
- **create_chapter.lua** defines the **Shift+X** keybinding
- Pressing **Shift+X** broadcasts `toggle_auto_save_mode`
- `rename_acts.lua` reacts to that broadcast

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
