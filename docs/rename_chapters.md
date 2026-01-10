[← Back to README](/README.md)

# [rename_chapters.lua](/scripts/rename_chapters.lua)

Bulk rename and normalize chapter titles in mpv.

This script scans existing chapter titles, matches configurable naming patterns, and renames them into a clean, consistent **sequential “Chapter N” format** (or any other destination prefix you choose).

It is intended for cleanup and normalization after importing, detecting, or merging chapters from mixed sources.

---

## Customizable parameters

The behavior of this script is controlled by user-editable variables at the top of the file:

- **MATCH_WORDS**  
  A list of prefixes that qualify a chapter for renaming (e.g. `Chapter`, `Scene`, `Part`, `Act`, `Episode`)

- **DEST_WORD**  
  The destination prefix applied to renamed chapters (default: `Chapter`).  
  Can be changed to anything else (e.g. `Scene`).

- **AUTO_SAVE_MODE**  
  Initial auto-save format (`xml` or `chap_txt`)

By editing these values, you can adapt the script to:
- Different naming conventions
- Non-English chapter schemes
- Alternative destination labels (e.g. `Scene`, `Part`, `Segment`)

---

## Core behavior

- Renames multiple chapters in one operation
- Matches chapter titles using configurable prefix rules
- Normalizes mixed naming schemes into a single destination prefix
- Supports two modes:
  - Sequential renaming (relative order)
  - Positional renumbering (absolute timeline order)
- Auto-saves chapter files after renaming
- Integrates with the framework-wide auto-save toggle

---

## How chapters are selected

A chapter is eligible for renaming if its title:

- Starts with **any word listed in `MATCH_WORDS`**
- Matching is case-insensitive
- The remainder of the title (after the prefix) is:
  - Empty
  - A number (e.g. `3`)
  - Letters (e.g. `A`, `B`)
  - A valid Roman numeral (e.g. `I`, `IV`, `X`)

Only chapters that satisfy **both** conditions are renamed.

> Note  
> This script **does not generate Roman numeral chapter titles**.
>  
> Roman numerals are only *recognized* for matching purposes (e.g. `Act IV`) and are converted into sequential numeric titles.
>  
> If you want chapters **named using Roman numerals** (e.g. `Chapter I`, `Chapter II`), use **[rename_acts.lua](/docs/rename_acts.md)** instead and set `DEST_WORD` to `"Chapter"`.


### Examples that will be renamed (default configuration)

- `Chapter`
- `Chapter 3`
- `Scene 2`
- `Act III`
- `Part A`
- `episode`

> By default, only the words listed in `MATCH_WORDS` are considered.

---

## Keybindings

| Key | Action |
|-----|--------|
| **Ctrl+Shift+C** | Rename matching chapters sequentially |
| **Ctrl+Alt+Shift+C** | Rename and renumber chapters by timeline position |

> This script does **not** define a keybinding for toggling auto-save mode.

---

## Typical use cases

- Cleaning up chapters imported from different sources
- Normalizing Scene/Act/Part naming into a single scheme
- Fixing inconsistent numbering formats
- Preparing chapters for final export or remuxing
- Standardizing chapters after batch detection or merging

---

## Workflow

### Sequential rename (Ctrl+Shift+C)

- Chapters are scanned in timestamp order
- Each matching chapter is renamed to `DEST_WORD 1`, `DEST_WORD 2`, …
- Numbering increments only when a chapter matches
- Non-matching chapters are left untouched

### Positional renumbering (Ctrl+Alt+Shift+C)

- Chapters are sorted by timestamp
- Matching chapters are renamed using their **absolute position**
- Resulting titles reflect strict playback order

### Example

Input:

- 00:00:00  Intro
- 00:02:00  Chapter 1
- 00:04:00  Opening
- 00:08:00  Chapter 2
- 00:20:00  Credits

Result:

- 00:00:00  Intro
- 00:02:00  Chapter 2
- 00:04:00  Opening
- 00:08:00  Chapter 4
- 00:20:00  Credits

Explanation:
- Only chapters starting with `MATCH_WORDS` are renamed
- Their numbers are set to their timeline index
- Non-matching titles are preserved exactly

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
- `rename_chapters.lua` reacts to that broadcast

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
