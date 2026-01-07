[← Back to README](/README.md)

# [create_chapter.lua](/scripts/create_chapter.lua)

Real-time **chapter creation, renaming, and export** for mpv.

This script turns mpv into a live chapter authoring environment.
Chapters can be created during playback, inserted out of order,
auto-numbered, renamed, and exported automatically or manually.

### Customizable parameters

Some behavior is controlled by user-editable variables at the top of the script:

- **Chapter prefix list**
- **Default first chapter names**
- **Duplicate prevention margin** (time window in seconds)
- **Non-numbered prefixes** (e.g. Episode, Credits)
- **Initial auto-save mode** (XML or CHAPTERxx TXT, set in script)

> These values can be adjusted directly in the script to match personal workflows or release conventions.
---

## Core behavior

- Creates chapters at the current playback position
- Prevents duplicate chapters within a fixed time margin
- Ensures a clean chapter at `00:00:000` always exists
- Automatically renumbers chapters sharing the same prefix
- Supports numbered and non-numbered prefixes
- Optional auto-save mode overwrites chapter files on every change

---

## Chapter naming

### Prefix cycling

Predefined prefixes:

- Chapter
- Scene
- Act
- Part
- Episode
- Credits

Prefixes can be cycled at runtime or set manually.

Some prefixes are explicitly excluded from numbering:
- Episode
- Credits

---

### Default first chapter (00:00:000)

The first chapter title can be cycled between:

- Chapter 1
- Cold Open
- Previously on...
- Opening

If no chapter exists at 00:00:000, one is inserted automatically.

---

## Keybindings

| Key         | Action                                                     |
|-------------|------------------------------------------------------------|
| **C**           | Create chapter (auto-numbered)                              |
| **Shift+C**     | Create chapter named by timestamp                           |
| **Shift+D**     | Delete previous chapter                                     |
| **Shift+R**     | Rename and renumber all chapters                            |
| **Shift+M**     | Rename all chapters to timestamps                           |
| **Shift+B**     | Manual export chapters (respects current auto-save mode)    |
| **Shift+T**     | Export human-readable TXT                                   |
| **H**           | Export CHAPTERxx TXT (mp4-compatible)                       |
| **Ctrl+Space**  | Cycle chapter prefix                                        |
| **Shift+P**     | Cycle default 00:00 chapter name                            |
| **Ctrl+Q**      | Set custom chapter prefix (Windows only)                    |
| **Shift+X**     | Toggle auto-save mode (broadcast)                           |

---

## Renumbering behavior

When a chapter is added at a timestamp that is not the last chapter:

- The script scans backwards to find the previous chapter with the same prefix
- Numbering resumes from that chapter
- The inserted chapter and all following chapters using the same prefix are renumbered automatically

This guarantees sequential numbering even when chapters
are inserted retroactively.

### Example

Initial chapters:

```
- 00:00:00  Chapter 1
- 00:05:00  Chapter 2
- 00:10:00  Chapter 3
```

A new chapter is added at `00:07:30`.

Resulting chapters:

```
- 00:00:00  Chapter 1
- 00:05:00  Chapter 2
- 00:07:30  Chapter 3
- 00:10:00  Chapter 4
```

---

## Detailed behavior and edge cases

### Duplicate prevention window

- New chapters are rejected if another chapter exists within 0.5 seconds of the current position
- Prevents accidental double taps and near-duplicates

---

### Near-zero timestamp normalization

- Any timestamp within `±0.05` seconds of zero is normalized to exactly `00:00:000`

Purpose:
- Prevents multiple near-zero chapters
- Guarantees a single canonical first chapter

---

### Automatic 00:00 chapter insertion

If no chapter exists at `00:00:000`:

- A chapter is automatically inserted
- Its title is taken from the current default first-chapter name

Triggered during:
- Chapter creation
- Renaming and rebuilding operations

---

### Prefix-aware numbering

- Numbering is scoped per prefix
- Only chapters sharing the active prefix are renumbered
- Different prefixes can coexist without interference

---

### Non-numbered prefixes

For prefixes marked as non-numbered:

- Chapters are created without a trailing number
- No renumbering occurs
- Only the inserted chapter is affected

Example:

`00:55:00  Credits`

---

### Timestamp-named chapters

When using timestamp-based creation or renaming:

- Titles are formatted as `HH:MM:SS.mmm`
- Duplicate timestamps are filtered
- A `00:00:000` chapter is always enforced

This mode produces a purely time-driven chapter list.

---

### Sorting guarantees

After any operation:

- Chapters are always sorted by timestamp
- Internal order never depends on creation order
- Manual reordering is unnecessary
  
---

## Manual export formats

### XML
- Matroska chapters (MKVToolNix compatible)
- Deterministic ChapterUID generation
- Generated edition is marked as the default edition
- Uses media filename as output base
  
#### ChapterUID generation

- ChapterUID values are generated deterministically
- Derived from chapter title and timestamp
- Identical chapters always produce identical UIDs

Purpose:
- Stable remuxing
- Prevents UID churn across exports

### TXT (human-readable)

`HH:MM:SS.mmm - Chapter Title`

### CHAPTERxx TXT (mp4-compatible)

- `CHAPTER01=00:00:00.000`
- `CHAPTER01NAME=Chapter 1`

---

## Auto-save mode

Auto-save runs after every chapter modification.

Supported modes:

- XML (MKVToolNix compatible)
- CHAPTERxx TXT (mp4-compatible)

Auto-save mode is stored **locally per script instance**.

### Auto-save side effects

When auto-save is enabled:

- Every chapter modification triggers a file write
- Output files are overwritten without confirmation
- Paths are derived from the media filename

Triggered by:
- Creation
- Deletion
- Renaming
- Renumbering

---

## Auto-save toggle (broadcasted)

The auto-save toggle is implemented using an mpv **script-message broadcast**.

Pressing **Shift+X** sends: `script-message toggle_auto_save_mode`

This message is broadcast to **all loaded Lua scripts**.

Each script that registers `mp.register_script_message("toggle_auto_save_mode", ...)` receives the event and updates its own local auto-save state.

### Design intent of broadcast toggle

- One global keybinding controls auto-save behavior
- Scripts remain loosely coupled
- Export format stays synchronized when all scripts opt in
- No direct script-to-script dependencies
- New scripts integrate by registering the same message

### Practical effect

When multiple chapter-related scripts are loaded:

- Pressing **Shift+X** once switches auto-save mode everywhere
- All scripts agree on XML ↔ CHAP TXT output
- Any subsequent chapter change from any script uses the same mode
- Prevents conflicting exports and mixed formats

---

### Platform-specific behavior

- Custom prefix input (Ctrl+Q) uses a Windows PowerShell InputBox
- On non-Windows systems this feature is inert
- All other functionality is platform-independent
