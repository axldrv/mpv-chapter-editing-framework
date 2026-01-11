[← Back to README](/README.md)

# [auto_playlist.lua](/scripts/auto_playlist.lua)

Automatically build a playlist from the current folder in mpv.

This script creates a **deterministic, ordered playlist** from media files in the same directory as the currently playing file.  
The playlist starts with the **current file**, continues to the end of the folder, and then wraps around to the beginning.

It is designed for **episodic or sequential viewing** (TV shows, lecture series, multi-part recordings) where files are already named and ordered correctly on disk.

---

## Core behavior

- Scans the current file’s directory for media files
- Builds a playlist **once per session**
- Starts playback from the current file
- Appends remaining files in sorted order
- Does **not** reload or restart the current file
- Can be toggled on and off safely at runtime
- Clears the playlist without interrupting playback when disabled

---

## Supported media types

By default, the script recognizes:

- `.mp4`
- `.mkv`
- `.avi`

Extensions are matched case-insensitively and can be customized in the script.

---

## How the playlist is ordered

Given a folder like:

```
Episode 01.mkv
Episode 02.mkv
Episode 03.mkv
Episode 04.mkv
```

If you open **Episode 03.mkv**, the generated playlist will be:

```
Episode 03.mkv   ← current
Episode 04.mkv
Episode 01.mkv
Episode 02.mkv
```

This ensures continuous playback without losing the current context.

---

## When the playlist is created

- Only when **auto-playlist mode is enabled**
- Only **once per session**
- Triggered on `file-loaded`
- Ignored for non-filesystem sources (URLs, streams)

This prevents repeated rebuilding when switching tracks or chapters.

---

## Toggle behavior

### Enable (Ctrl+Alt+P)

- Clears the existing playlist
- Reloads the current file **without restarting playback**
- Scans the directory
- Builds a new playlist
- Displays an OSD summary with file count

### Disable (Ctrl+Alt+P)

- Removes **all playlist entries except the current one**
- Does **not** reload the file
- Playback continues uninterrupted
- Displays how many files were removed

---

## Safety guarantees

- The current file is never restarted
- Playlist removal does not affect playback position
- No files are modified on disk
- Sorting is stable and case-insensitive
- The script fails silently if no files are found

---

## Keybinding

| Key | Action |
|----|-------|
| **Ctrl+Alt+P** | Toggle auto-playlist on/off |

---

## Typical use cases

- **Batch chapter editing workflows**, where multiple files are loaded in order for:
  - Reviewing chapter structure across episodes
  - Applying consistent chapter naming or numbering
  - Offsetting, cleaning, or replacing chapters in bulk
- Watching TV show episodes sequentially
- Folder-based media libraries
- Temporary playlists without manual curation
- Avoiding mpv’s implicit directory loading behavior

---

## Platform notes

- Fully cross-platform
- Uses mpv’s native filesystem APIs
- No external tools required
