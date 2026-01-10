[← Back to README](/README.md)

# [customized_named_chapters.lua](/scripts/customized_named_chapters.lua)

Apply predefined chapter naming schemes in mpv.

This script applies a **fixed, semantic chapter structure** based on predefined schemes. The active scheme is selected solely by the **number of chapters** present (i.e. total chapters minus those matching `IGNORED_WORDS`).

It is designed for episodic content with a **known narrative structure** (e.g. `Cold Open`, `Act I-III`, `Credits`), where chapter titles represent **meaning**, not order.

The script does not infer or guess structure. If no matching scheme exists, it intentionally does nothing.

---

## Customizable parameters

The behavior of this script is controlled by user-editable variables at the top of the file:

- **AUTO_SAVE_MODE**  
  Initial auto-save format (`xml` or `chap_txt`)

- **IGNORED_WORDS**  
  A list of chapter prefixes that should be **excluded from counting/renaming** (default: `{"Scene"}`)

  Chapters matching patterns like:
  - `Scene 1`
  - `Scene 2`

  are skipped and preserved as-is.

- **ENABLE_CHANGE_TRIGGER**  
  If enabled, chapter renaming can be triggered automatically when the chapter list changes.

- **Scheme set labels**

Each scheme set may define an optional name:

- `label = "TV show's name"`

---

## Scheme sets

The script supports **multiple scheme sets**, each defining chapter title lists based on the **number of (non-ignored) chapters**.

Each scheme set contains entries like:

- `names_2`
- `names_3`
- `names_4`
- …
- `names_8`

Each entry defines the **exact titles** to assign when that many chapters exist.

### Example (scheme set 1)

For 5 chapters:

```
names_5 = {"Opening", "Act I", "Act II", "Act III", "Credits"}
```

For 6 chapters:

```
names_6 = {"Previously on...", "Opening", "Act I", "Act II", "Act III", "Credits"}

```

---

## Scheme cycling

Multiple scheme sets can coexist.

- The active scheme set can be cycled at runtime
- Each scheme set may optionally define a name (`label`)
- Auto-renaming respects the currently active scheme

---

## Core behavior

- Renames chapters using **scheme-defined titles**
- Scheme selection is based on the **count of (non-ignored) chapters**
- Ignored chapters are skipped but preserved
- Chapters are processed in timestamp order
- Timestamps are never modified
- Auto-saves chapter files after renaming
- Supports both manual and automatic renaming
- Integrates with the framework-wide auto-save toggle

---

## How chapters are selected

**1.** All chapters are sorted by timestamp  
**2.** Chapters matching `IGNORED_WORDS` are skipped  
**3.** The remaining chapters are counted  
**4.** A scheme whose size exactly matches that count is selected  
**5.** The scheme’s titles are applied sequentially to the remaining chapters  

If:
- No scheme exists for a specific number of chapters, no changes are made
- The scheme exists but is empty, renaming is skipped with a warning

---

## Ignored chapters

Ignored chapters:

- Are detected using prefix + numeric suffix (e.g. `Scene 1`, `Scene 2`)
- Are excluded from renaming
- Retain their original titles
- Do **not** consume scheme slots

This allows mixing:
- Detection chapters (`Scene 3`)
- With structured naming (`Opening`, `Act I`, `Credits`)

---

## Keybindings

| Key | Action |
|-----|--------|
| **Alt+R** | Rename chapters using the active scheme |
| **Ctrl+Alt+R** | Toggle automatic renaming |
| **Ctrl+Alt+L** | Cycle through scheme sets |

> This script does **not** define a keybinding for toggling auto-save mode.

---

## Typical use cases

- Applying a consistent structure across episodic content
- Enforcing predefined titles for a known chapter count
- Running automatic renaming after importing or detecting chapters
- Keeping ignored-chapters untouched while naming key segments

---

## Workflow

### Manual rename

**1.** Ensure your chapter list is present  
**2.** Optionally add detection chapters you want ignored (e.g. `Scene 1`, `Scene 2`)  
**3.** Press **Alt+R**  
**4.** The active `names_N` scheme is applied, where `N` is the count of non-ignored chapters  
**5.** Auto-save runs  

### Auto-rename

When enabled, the same logic runs automatically on:
- File load
- Chapter list change (if `ENABLE_CHANGE_TRIGGER` is true)

Renaming is debounced to avoid rapid repeated execution.

---

## OSD behavior explanation

### What the script actually outputs via OSD

The script uses OSD for **four distinct purposes**:

**1.** Rename results  
**2.** Ignored chapter counts  
**3.** Scheme switching feedback  
**4.** Auto-rename / auto-save state changes  

---

## On-screen display (OSD) messages

### Rename result

After a successful rename:

- Number of renamed chapters
- Save result and format
- Number of ignored chapters

Example:
```
Renamed 6 custom chapters. Saved 6 Chapters (XML).  
Skipped 2 ignored chapters.
```
---

### Empty or missing scheme

If no scheme exists for the detected chapter count:
```
Scheme for 5 chapters is empty. Skipping.

No changes are applied.
```
---

### Scheme switching

When cycling scheme sets:
```
Using scheme set 2 (TV Episode)
```
If no label is defined:
```
Using scheme set 2
```
---

### Auto-rename state

When toggling automatic renaming:
```
Auto-rename (file load & chapter change): ENABLED  
Auto-rename (file load & chapter change): DISABLED
```
---

### Auto-save mode

When receiving the broadcast toggle:
```
Auto-save mode: XML  
Auto-save mode: CHAP_TXT
```
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
- The new mode applies to subsequent renames

This script does **not** emit the toggle message itself.

---

## Dependency on create_chapter.lua

The auto-save toggle is **expected to be emitted by another script**.

In the default framework setup:

- **[create_chapter.lua](/docs/create_chapter.md)** defines the **Shift+X** keybinding
- Pressing **Shift+X** broadcasts `toggle_auto_save_mode`
- `customized_named_chapters.lua` reacts to that broadcast

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
