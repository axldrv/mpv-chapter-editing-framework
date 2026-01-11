[← Back to README](/README.md)

# [offset_timestamps.lua](/scripts/offset_timestamps.lua)

Offset, snap, and realign chapter timestamps in mpv.

This script provides **precise temporal control** over existing chapters.  
It allows you to shift chapters globally, snap individual chapters to the current playback position, or realign later chapters while preserving order.

It is designed for **post-processing timing corrections** after chapter detection, manual creation, or remuxing, when chapter *names are correct*, but *timestamps are not*.

---

## Core behavior

- Offsets all chapter timestamps by a user-defined amount
- Snaps individual chapters to the current playback position
- Optionally shifts **later chapters** to preserve pacing
- Preserves chapter order and titles
- Protects the 00:00 chapter from accidental movement
- Auto-saves chapter files after operations
- Uses debounced saving to avoid excessive disk writes
- Integrates with the framework-wide auto-save toggle

---

## Customizable parameters

The behavior of this script is controlled by user-editable variables at the top of the file:

- **AUTO_SAVE_MODE**  
  Initial auto-save format (`xml` or `chap_txt`)

- **OFFSET_TIME**  
  Default offset value (in seconds) shown in the offset prompt  
  Can be positive or negative (e.g. `-2`, `+1.5`)

- **SAVE_DEBOUNCE**  
  Delay (in seconds) before auto-saving after a modification  
  Prevents repeated disk writes during rapid adjustments

---

## How timestamp operations work

The script operates in **three distinct modes**, each designed for a different correction scenario.

---

## 1. Global offset (Ctrl+O)

Applies a uniform time offset to **all chapters except the 00:00 chapter**.

Workflow:

**1.** Press **Ctrl+O**  
**2.** Enter a positive or negative number (seconds)  
**3.** All chapter timestamps `> 0` are shifted  
**4.** Negative results are clamped to `≥ 0`  
**5.** Auto-save runs after a short debounce (if enabled)  

Example:

Offset: `-2.0`

- 00:00:00 → 00:00:00 (unchanged)
- 00:05:00 → 00:04:58
- 00:10:00 → 00:09:58

Use case:
- Audio/video delay corrections
- Fixing systematic offsets from detection tools

---

## 2. Snap a single chapter to playback

### Keybindings

- **Ctrl+Alt+Left** → Snap the *next* chapter
- **Ctrl+Alt+Right** → Snap the *previous* chapter

Behavior:

- The target chapter’s timestamp is set exactly to the current playback position
- Chapter order is preserved
- No other chapters are modified
- Chapters at 00:00 are never moved

Use case:
- Fine-tuning a single boundary
- Fixing one mistimed chapter without collateral changes

---

## 3. Snap and shift later chapters

### Keybindings

- **Ctrl+Alt+Up** → Snap the nearest *previous* chapter and all **later** chapters by the same delta
- **Ctrl+Alt+Down** → Snap the nearest *next* chapter and all **later** chapters by the same delta

Behavior:

- Finds the nearest chapter in the selected direction
- Snaps it to the current playback position
- Shifts **all later chapters** by the same delta
- Preserves relative spacing between shifted chapters
- Never moves the 00:00 chapter

Use case:
- Re-aligning an entire section after an edit
- Correcting a boundary while preserving downstream pacing

---

## Ordering and safety guarantees

- Chapters are never reordered
- Chapter titles are never modified
- Chapters at timestamp `00:00` are protected
- Negative timestamps are clamped to zero
- All operations are explicit and deterministic

---

## Auto-save mode

Auto-save runs automatically **after timestamp modifications**, using a short debounce delay.

Supported modes:

- XML (MKVToolNix compatible)
- CHAPTERxx TXT (mp4-compatible)

Auto-save mode is stored **locally per script instance**.

> Auto-save operations are silent by default and do not always display an OSD message.

---

## Auto-save toggle (broadcasted)

This script listens for the shared framework message: `script-message toggle_auto_save_mode`

When received:
- The local auto-save mode switches between XML ↔ CHAPTERxx TXT
- The new mode applies to subsequent operations

This script does **not** emit the toggle message itself.

---

## Dependency on create_chapter.lua

The auto-save toggle is **expected to be emitted by another script**.

In the default framework setup:

- **[create_chapter.lua](/docs/create_chapter.md)** defines the **Shift+X** keybinding
- Pressing **Shift+X** broadcasts `toggle_auto_save_mode`
- `offset_timestamps.lua` reacts to that broadcast

If `create_chapter.lua` is **not loaded**:

- Auto-save mode remains at its initial value
- Timestamp operations still work
- Auto-save cannot be toggled at runtime

This dependency is intentional and keeps scripts loosely coupled.

---

## Export behavior

When auto-save is enabled:

- Chapter files are rewritten after the debounce delay
- Output path is derived from the media filename
- Existing files are overwritten without confirmation

Formats:

### XML
- Matroska chapters (MKVToolNix compatible)
- Uses `os.time()` for `EditionUID`
- Chapter titles are XML-escaped
- ChapterUIDs are generated per chapter index

### CHAPTERxx TXT
- Two-digit chapter numbering (CHAPTER01, CHAPTER02, …)
- Compatible with MP4 and MKV tooling

---

## Platform-specific behavior

- Offset prompt uses a Windows PowerShell InputBox
- On non-Windows systems, prompt-based offset is inert
- All snap-based operations are platform-independent

---

## Typical use cases

- Correcting systematic timestamp drift
- Fixing chapter offsets after remuxing
- Aligning chapters to precise scene cuts
- Adjusting timing without touching titles or order
- Fine-grained chapter authoring workflows

---

## Dependencies

- **[create_chapter.lua](/docs/create_chapter.md)** (for Shift+X auto-save toggle broadcast)
