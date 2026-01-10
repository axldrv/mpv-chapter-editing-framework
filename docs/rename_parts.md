[← Back to README](/README.md)

# [rename_parts.lua](/scripts/rename_parts.lua)

Rename chapters into alphabetical part format in mpv.

This script scans existing chapter titles, matches configurable naming patterns, and renames them into an **alphabetical Part format**:

Part A, Part B, … Part Z, Part AA, Part AB, …

It is intended for content structured into sections or parts rather than numeric chapters or acts.

---

## Customizable parameters

The behavior of this script is controlled by user-editable variables at the top of the file:

- **MATCH_WORDS**  
  A list of prefixes that qualify a chapter for renaming  
  (e.g. `Chapter`, `Scene`, `Part`, `Act`, `Episode`)

- **DEST_WORD**  
  The destination prefix applied to renamed chapters  
  (default: `Part`)  
  Can be changed to any label (e.g. `Section`, `Segment`).

- **AUTO_SAVE_MODE**  
  Initial auto-save format (`xml` or `chap_txt`)

By editing these values, you can adapt the script to:
- Different naming conventions
- Alternative destination labels
- Non-English workflows

---

## Core behavior

- Renames multiple chapters in one operation
- Matches chapter titles using configurable prefix rules
- Converts numeric or symbolic suffixes into alphabetical indices
- Uses Excel-style lettering (A–Z, AA, AB, …)
- Preserves chapter timestamps
- Leaves non-matching chapters untouched
- Auto-saves chapter files after renaming
- Integrates with the framework-wide auto-save toggle

---

## How chapters are selected

A chapter is eligible for renaming if its title:

- Starts with **any word listed in `MATCH_WORDS`**
- Matching is case-sensitive (as implemented)
- The remainder of the title consists only of:
  - Digits
  - Letters
  - Or nothing at all

Examples that will be renamed (default configuration):

- `Chapter 1`
- `Scene 2`
- `Part A`
- `Act III`
- `Episode`

> Note  
> This script is especially well-suited for **anime and episodic content** where sections are commonly labeled as **Part A / Part B / Part C** rather than numbered chapters.
>
> If you want chapters named using **Arabic numerals** (e.g. `Part 1`, `Part 2`), use **[rename_chapters.lua](/docs/rename_chapters.md)** instead and set `DEST_WORD` to `"Part"`.
>
> If you want chapters named using **Roman numerals** (e.g. `Part I`, `Part II`, `Part III`), use **[rename_acts.lua](/docs/rename_acts.md)** instead and set `DEST_WORD` to `"Part"`.

---

## Keybindings

| Key | Action |
|-----|--------|
| **Ctrl+Shift+P** | Rename matching chapters to alphabetical parts |

> This script does **not** define a keybinding for toggling auto-save mode.

---

## Typical use cases

- Structuring long content into labeled parts
- Replacing numeric chapters with alphabetical sections
- Normalizing mixed chapter schemes into Part A/Part B
- Preparing educational or documentary content
- Cleaning up chapters after import or detection

---

## Workflow

1. Chapters are sorted by timestamp
2. Matching chapters are counted sequentially
3. Each matching chapter is assigned a letter index:
   - A–Z for the first 26
   - AA, AB, … for higher counts
4. Chapter titles are rewritten as `DEST_WORD <Letter>`
5. Chapters are auto-saved

### Example

Input:

- 00:00:00  Intro
- 00:03:00  Chapter 1
- 00:07:00  Scene 2
- 00:12:00  Part III

Result:

- 00:00:00  Intro
- 00:03:00  Part A
- 00:07:00  Part B
- 00:12:00  Part C

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
- `rename_parts.lua` reacts to that broadcast

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
