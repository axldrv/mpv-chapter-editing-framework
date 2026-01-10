[← Back to README](/README.md)

# [number titles.lua](/scripts/number_titles.lua)

Add or normalize numeric prefixes in chapter titles in mpv.

This script applies **explicit numeric ordering** to chapter titles (e.g. `1. Intro`, `01 - Opening`, `3) Scene`) while preserving timestamps and chapter order.

It is designed for users who **prefer visible numbering** for readability, navigation, or compatibility with external tools and workflows.

> This script intentionally does the **opposite** of **[clean_titles.lua](/docs/clean_titles.md)**.  
> While some sources include numbers that users may want to remove, other users prefer clear numeric structure.  
> This script exists to support that preference.

---

## Core behavior

- Adds numeric prefixes to chapter titles
- Preserves existing chapter order and timestamps
- Detects semantic chapters using pattern-based matching (e.g. `Chapter 1`, `Scene 2`)
- Supports multiple numbering formats
- Supports single-digit and two-digit numbering
- Auto-saves chapter files after renaming

---

## Customizable parameters

The behavior of this script is controlled by user-editable variables at the top of the file:

- **AUTO_SAVE_MODE**  
  Initial auto-save format (`xml` or `chap_txt`)

- **numbering_formats**  
  A list of numeric prefix formats.  
  Each format uses two `%s` placeholders:
  - first for the number
  - second for the chapter title

  Default examples:
  - `1. Title`
  - `1) Title`
  - `1 - Title`

- **two_digit_mode**  
  Controls whether numbers are rendered as:
  - `1, 2, 3` (single-digit)
  - `01, 02, 03` (two-digit)

### Advanced: semantic skip rules

- **SKIP_CHAPTER_PATTERNS**  
  A list of Lua patterns used to detect *semantic chapter titles* that should **not** be renumbered.

  Default patterns skip titles starting with:
  - `Chapter <number>`
  - `Scene <number>`
  - `Part <number>`
  - `Act <number>`

  Patterns are evaluated against the **start of the title**, allowing optional leading punctuation or whitespace.

  Default configuration:

  ```lua
  local SKIP_CHAPTER_PATTERNS = {
      "^[%s%p]*[Cc]hapter%s*%d+",
      "^[%s%p]*[Ss]cene%s*%d+",
      "^[%s%p]*[Pp]art%s*%d+",
      "^[%s%p]*[Aa]ct%s*%d+",
  }
  ```

  You may extend this list to support additional schemes, for example:
  - `Episode 3`
  - `Book 2`
  - `Volume 1`

  Example addition:

  ```lua
  "^[%s%p]*[Ee]pisode%s*%d+"
  ```

  > Note  
  > These are **Lua patterns**, not full regular expressions.  
  > Incorrect patterns may cause unintended chapters to be skipped.

---

## How numbering is applied

**1.** Chapters are processed in their existing order  
**2.** A running counter is incremented for **every chapter**  
**3.** Titles matching `SKIP_CHAPTER_PATTERNS` are skipped  
**4.** Existing leading numeric prefixes (digits + punctuation) are removed  
**5.** The selected numbering format is applied  
**6.** Chapters are auto-saved

### Mixed numbered and semantic chapters

Chapters that already contain **semantic numbering** (e.g. `Chapter 2`, `Scene 4`) are **left unchanged**.

However, they **still advance the internal counter** so that sequential numbering remains consistent.

Example input:

```
Intro
Chapter 2
Opening
Chapter 4
Credits
```

Result after numbering:

```
1. Intro
Chapter 2
3. Opening
Chapter 4
5. Credits
```

Explanation:
- `Chapter 2` and `Chapter 4` are detected and skipped
- The numbering counter continues advancing internally
- No renumbering gaps or reflow are introduced

---

## Numbering formats

You can cycle between predefined formats at runtime.

Examples:

- `1. Intro`
- `01) Opening`
- `3 - Credits`

After numbering, the OSD reports:
- How many chapters were changed
- How many chapters were skipped

---

## Two-digit mode

When enabled:
- Numbers are zero-padded (`01`, `02`, `03`)

When disabled:
- Numbers are rendered normally (`1`, `2`, `3`)

This is useful for:
- Long chapter lists
- Consistent visual alignment
- External tooling expectations

---

## Keybindings

| Key | Action |
|-----|--------|
| **Alt+N** | Apply numbering to chapters |
| **Alt+Shift+N** | Cycle numbering format |
| **Alt+Shift+D** | Toggle single-digit/two-digit mode |

> This script does **not** define a keybinding for toggling auto-save mode.

---

## Typical use cases

- Adding visible order to chapters without semantic labels
- Restoring numbering after cleanup
- Improving chapter list readability
- Preparing chapters for export or remuxing
- Personal preference for numbered navigation

---

## Auto-save mode

Auto-save runs automatically **after numbering is applied**.

Supported modes:

- XML (MKVToolNix compatible)
- CHAPTERxx TXT (mp4-compatible)

Auto-save mode is stored **locally per script instance**.

---

## Auto-save toggle (broadcasted)

This script listens for the shared framework message: `script-message toggle_auto_save_mode`

When received:
- The local auto-save mode switches between XML ↔ CHAPTERxx TXT
- The new mode applies to subsequent numbering operations

This script does **not** emit the toggle message itself.

---

## Dependency on create_chapter.lua

The auto-save toggle is **expected to be emitted by another script**.

In the default framework setup:

- **[create_chapter.lua](/docs/create_chapter.md)** defines the **Shift+X** keybinding
- Pressing **Shift+X** broadcasts `toggle_auto_save_mode`
- `number_chapters.lua` reacts to that broadcast

If `create_chapter.lua` is **not loaded**:

- Auto-save mode remains at its initial value
- Numbering still works
- Auto-save cannot be toggled at runtime

This dependency is intentional and keeps scripts loosely coupled.

---

## Export behavior

When auto-save is enabled:

- Chapter files are rewritten immediately after numbering
- Output path is derived from the media filename
- Existing files are overwritten without confirmation

Formats:

### XML
- Matroska chapters (MKVToolNix compatible)
- Uses `estimated-frame-count` as `EditionUID`
- Uses `os.clock()`-based `ChapterUID` generation (non-deterministic across runs)

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
