[← Back to README](/README.md)

# [clean_titles.lua](/scripts/clean_titles.lua)

Clean numeric prefixes from chapter titles in mpv.

This script removes **leading numbers and symbols** from existing chapter titles (e.g. `01 - Intro`, `[3] Scene`, `(02)_Opening`) while preserving timestamps and chapter order.

It is designed as a **post-processing cleanup tool** after importing, detecting, or batch-renaming chapters. Some commercial chapter sources include numeric prefixes in titles by default, which this script can remove for a cleaner presentation.

> This script intentionally does the **opposite** of **[number_titles.lua](/docs/number_titles.md)**.  
> While some users prefer explicit numeric ordering, others find numeric prefixes visually noisy or redundant.  
> This script exists to remove numbering and restore clean, semantic chapter titles.

---

## Customizable parameters

The behavior of this script is controlled by user-editable variables at the top of the file:

- **AUTO_SAVE_MODE**  
  Initial auto-save format (`xml` or `chap_txt`)

- **AUTO_RENAME_ENABLED**  
  Enables automatic cleanup on file load (disabled by default)

- **DEBOUNCE_DELAY**  
  Delay (in seconds) before auto-cleanup runs after file load  
  Prevents premature cleanup while chapters are still being populated

---

## Core behavior

- Removes leading numeric clutter from chapter titles
- Preserves timestamps and chapter order
- Leaves non-matching titles untouched
- Can be triggered manually or automatically
- Auto-saves chapter files after cleanup

---

## What gets cleaned

The script strips **only leading patterns** such as:

- Numbers
- Parentheses or brackets around numbers
- Common separators (`-`, `_`, `.`, `:`)

### Examples

Before → After:

- `01 - Intro` → `Intro`
- `[2] Opening` → `Opening`
- `(03)_Scene` → `Scene`
- `  4: Credits` → `Credits`

Only the **prefix** is affected. The remainder of the title is preserved exactly.

---

## What is NOT changed

- Chapter timestamps
- Chapter order
- Titles without a matching numeric prefix
- Embedded numbers later in the title  
  (e.g. `Chapter 2` is untouched)

---

## Keybindings

| Key | Action |
|-----|--------|
| **Alt+C** | Clean chapter titles |

> This script does **not** define a keybinding for toggling auto-save mode.

---

## Typical use cases

- Cleaning chapters imported from external tools
- Removing numbering after detection-based workflows
- Normalizing titles before applying structured renaming
- Preparing chapters for final export or remuxing

---

## Workflow

### Manual cleanup

**1.** Ensure chapters are present  
**2.** Press **Alt+C**  
**3.** Matching numeric prefixes are removed  
**4.** Auto-save runs (if enabled)  

### Automatic cleanup (optional)

When enabled, cleanup runs automatically:

- After file load
- Once, after a debounce delay

This avoids interfering with scripts that populate chapters asynchronously.

---

## Auto-cleanup behavior

- Disabled by default
- When enabled, runs only on file load
- Uses a debounce timer to prevent repeated execution
- Safe to combine with chapter-detection scripts

---

## Auto-save mode

Auto-save runs automatically **after a successful cleanup**.

Supported modes:

- XML (MKVToolNix compatible)
- CHAPTERxx TXT (mp4-compatible)

Auto-save mode is stored **locally per script instance**.

---

## Auto-save toggle (broadcasted)

This script listens for the shared framework message: `script-message toggle_auto_save_mode`

When received:
- The local auto-save mode switches between XML ↔ CHAPTERxx TXT
- The new mode applies to subsequent cleanup operations

This script does **not** emit the toggle message itself.

---

## Dependency on create_chapter.lua

The auto-save toggle is **expected to be emitted by another script**.

In the default framework setup:

- **[create_chapter.lua](/docs/create_chapter.md)** defines the **Shift+X** keybinding
- Pressing **Shift+X** broadcasts `toggle_auto_save_mode`
- `clean_titles.lua` reacts to that broadcast

If `create_chapter.lua` is **not loaded**:

- Auto-save mode remains at its initial value
- Cleanup still works
- Auto-save cannot be toggled at runtime

This dependency is intentional and keeps scripts loosely coupled.

---

## Export behavior

When auto-save is enabled:

- Chapter files are rewritten immediately after cleanup
- Output path is derived from the media filename
- Existing files are overwritten without confirmation

Formats:

### XML
- Matroska chapters (MKVToolNix compatible)

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
