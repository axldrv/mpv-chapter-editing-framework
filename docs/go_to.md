[← Back to README](/README.md)

# [go_to.lua](/scripts/go_to.lua)

Jump to an exact timestamp in mpv via prompt.

This script provides a **precise “Go To Time” dialog** that lets you jump to any position in the file using flexible time formats.  
It is designed for **manual navigation, verification, and chapter authoring workflows** where frame-accurate seeking matters.

Unlike relative seeking or chapter jumps, this script allows **explicit absolute positioning**.

---

## Core behavior

- Prompts the user for a timestamp
- Accepts multiple time formats
- Jumps playback to the exact specified position
- Does not modify chapters, metadata, or files
- Safe, read-only navigation

---

## Supported time formats

The input box accepts the following formats:

- **HH:MM:SS.mmm**  
  Example: `01:23:45.678`

- **MM:SS.mmm**  
  Example: `12:34.5`

- **Seconds (integer or decimal)**  
  Example: `83`, `83.25`

Additional behavior:
- Commas are accepted as decimal separators (`12,5`)
- Whitespace and line breaks are ignored

Invalid input is rejected safely.

---

## Workflow

**1.** Press **Shift+G**
**2.** Enter a timestamp in any supported format
**3.** Confirm
**4.** Playback jumps immediately to that position

If:
- The dialog is canceled → nothing happens
- The input cannot be parsed → an error message is shown

---

## Keybinding

| Key | Action |
|-----|--------|
| **Shift+G** | Open “Go To Time” prompt |

---

## Design intent

- Fast absolute seeking without calculating offsets
- Useful when comparing timestamps with external tools
- Ideal companion for chapter editing and verification
- Keeps navigation separate from chapter manipulation

This script intentionally does **not**:
- Snap to chapters
- Create or modify chapters
- Perform relative seeking

It does one thing: **go to an exact time**.

---

## Platform-specific behavior

- Uses a Windows PowerShell InputBox
- On non-Windows systems, the prompt is inert
- No fallback UI is provided

---

## Typical use cases

- Jumping to an exact cut point
- Verifying chapter timestamps
- Matching external timestamps (e.g. from logs or editors)
- Manual QC and navigation during chapter authoring

---

## Dependencies

- Windows PowerShell (for the input dialog)
