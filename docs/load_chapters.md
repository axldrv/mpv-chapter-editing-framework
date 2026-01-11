[← Back to README](/README.md)

# [load_chapters.lua](/scripts/load_chapters.lua)

Automatically load and toggle external XML chapters in mpv.

This script enables **switching between embedded chapters and external XML chapter files** that share the same basename as the media file.

It is designed for workflows where chapters are **authored, edited, or refined externally**, while still allowing you to fall back to the media’s embedded chapters at any time.

---

## Core behavior

- Automatically loads external `.xml` chapters on file load (if present)
- Falls back to embedded chapters when no XML file exists
- Allows manual toggling between XML and embedded chapters
- Detects XML file changes via modification time
- Parses Matroska XML chapters (including multiline atoms)
- Never writes or modifies chapter files (read-only)

---

## Intent

This script treats **external XML chapters as the preferred source when present**, without discarding embedded chapters.

It does not merge, infer, or modify chapters; it only switches the active chapter source.

---

## XML file discovery

On file load, the script looks for an XML file with the same basename as the media.

If found:
- XML chapters are parsed and applied immediately
- An on-screen indicator confirms that XML chapters are active

If not found:
- Embedded chapters remain active
- No warnings are shown

---

## XML parsing behavior

- Parses `<ChapterAtom>` blocks across newlines
- Reads:
  - `<ChapterTimeStart>`
  - `<ChapterString>` (defaults to `Untitled` if missing)
- Supports fractional seconds up to nanosecond precision (truncated to milliseconds)
- Converts all timestamps to seconds

If the XML file changes on disk:
- The script reloads it automatically when you toggle chapters (or on next file load)

---

## Automatic behavior (on file load)

When a file is loaded:

1. Embedded chapters are cached  
2. The script checks for a matching XML file  
3. If found:  
   - XML chapters are applied  
   - Embedded chapters are preserved in memory  
4. If not found:  
   - Embedded chapters remain active  

A small on-screen label indicates which chapter source is active.

---

## Manual toggling

### Keybindings

| Key | Action |
|-----|--------|
| **Ctrl+L** | Toggle between XML and embedded chapters |
| **Shift+L** | Enable/disable the XML chapter loader |

### Toggle logic

- If XML chapters are active → switch back to embedded chapters
- If embedded chapters are active and XML exists → apply XML chapters
- If no XML file exists → nothing changes

---

## Enable/disable behavior

When disabled:
- Embedded chapters are restored immediately
- XML chapters are ignored
- Automatic loading on file load is suspended

When re-enabled:
- XML chapters are re-evaluated and applied if present

---

## On-screen indicators

The script provides visual feedback:

- `📘 XML Chapters Active`
- `🎬 Embedded Chapters Active`
- `🟢 XML Chapter Loader Enabled`
- `❌ XML Chapter Loader Disabled`

These are shown briefly in the top-right corner.

---

## Works well with external chapter editing

This script pairs naturally with tools that generate or update XML chapters, including:

- Framework scripts that auto-save XML chapters
- MKVToolNix chapter editing
- Timestamp correction tools like **[offset_timestamps.lua](/docs/offset_timestamps.md)**

Typical workflow:

**1.** Load media → XML chapters auto-apply (if present)  
**2.** Validate chapter timing and names  
**3.** Edit XML externally  
**4.** Toggle chapters to refresh the loaded XML  

---

## Safety guarantees

- Chapter order is never changed implicitly
- Titles are never modified
- Embedded chapters are never lost (cached and restorable)
- No files are written or overwritten
- XML parsing failures fail safely (no crash; embedded chapters remain usable)

---

## Platform-specific behavior

- Fully platform-independent
- No external dialogs or OS dependencies
- Uses standard Lua file I/O

---

## Dependencies

- External Matroska XML chapter files
