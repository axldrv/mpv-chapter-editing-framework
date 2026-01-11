[← Back to README](/README.md)

# [skip_to_fade.lua](/scripts/skip_to_fade.lua)

Detect and jump to black frames (scene boundaries) in **mpv**.

This script uses FFmpeg’s **blackdetect** filter to rapidly scan a video for black frames and automatically seek to the detected position. It is intended as a **navigation and authoring aid**, not a chapter generator.

---

## Typical use cases:
- Finding clean cut points
- Locating fades to black
- Identifying act or segment boundaries
- Assisting manual chapter creation with **[create_chapter.lua](/docs/create_chapter.md)**
- Pairing with timestamp tools such as **[offset_timestamps.lua](/docs/offset_timestamps.md)**

---

## Core behavior

- Temporarily increases playback speed for fast scanning
- Applies FFmpeg’s `blackdetect` video filter
- Detects black segments longer than a configurable duration
- Automatically seeks to the detected timestamp
- Restores normal playback speed afterward
- Can be manually cancelled without seeking

---

## User configuration

At the top of the script:

```
local duration  = 1.5   -- minimum black duration in seconds
local threshold = 1.0   -- how dark a frame must be (0.0–1.0)
```

### `duration`

Minimum length (in seconds) a black segment must last to be detected.  
Increase this value to ignore brief flashes or hard cuts.

### `threshold`

Brightness threshold:
- `1.0` → full black only
- lower values → allow near-black detection (fades, dark scenes)

---

## How detection works

**1.** Press the activation key  
**2.** Playback speed is temporarily increased 
**3.** The `blackdetect` filter is applied  
**4.** The script polls filter metadata:  
   - looks for `lavfi.black_start`
     
**5.** When a black segment is detected:  
   - detection stops  
   - playback speed is restored  
   - mpv seeks precisely to the detected timestamp  

If no black frame is detected yet, scanning continues.

---

## Toggle behavior

- Press once → start scanning
- Press again while scanning → **cancel scan (no seek)**

Detection always stops cleanly:
- the filter is removed
- playback speed is restored
- no state is left behind

---

## Safety and guarantees

- Filters are added and removed cleanly
- Playback speed is always restored
- No chapters are created or modified
- No timestamps are permanently changed
- Seeking uses exact positioning

---

## Keybinding

| Key | Action |
|-----|--------|
| **G** | Toggle black-frame detection and seek |

---

## Workflow

This script is designed to help locate **fade-outs, hard cuts, and transition points** so that chapters can be placed accurately using tools such as `create_chapter.lua`.

Typical workflow:  
**1.** Use this script to jump to a likely transition point  
**2.** Insert a chapter manually at the detected position  
**3.** Adjust or refine chapter placement as needed  
**4.** Merge chapters into the media file  

> If visual detection is insufficient or the transition is audio-based, consider using **[skip_to_silence.lua](/docs/skip_to_silence.md)** to locate act breaks via silence detection instead.

---

## Platform-specific notes

- Fully platform-independent
- Requires FFmpeg support compiled into mpv (standard builds)

---

## Dependencies

- mpv with FFmpeg `lavfi` filter support
