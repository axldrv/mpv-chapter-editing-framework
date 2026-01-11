[← Back to README](/README.md)

# [skip_to_silence.lua](/scripts/skip_to_silence.lua)

Detect and jump to silence segments in **mpv**.

This script uses FFmpeg’s **`silencedetect`** audio filter to rapidly scan through media and jump to the next sufficiently long silence segment. It is designed as a **navigation and timing aid**, not as a chapter generator.

It works especially well **in tandem with [create_chapter.lua](/docs/create_chapter.md) and [offset_timestamps.lua](/docs/offset_timestamps.md)**, where silence points are often used as precise boundaries for creating or adjusting chapters.

---

## Typical use cases:
- Finding quiet sections in audio or video
- Locating natural pauses or gaps in dialogue
- Identifying scene transitions marked by silence
- Assisting manual chapter creation with **[create_chapter.lua](/docs/create_chapter.md)** based on audio breaks
- Pairing with timestamp tools such as **[offset_timestamps.lua](/docs/offset_timestamps.md)**

---

## Core behavior

- Temporarily increases playback speed for fast scanning
- Applies FFmpeg’s `silencedetect` audio filter
- Detects silence longer than a configurable duration
- Automatically seeks to the detected timestamp
- Restores normal playback speed afterward
- Allows manual cancellation without seeking

---

## User configuration

At the top of the script:

```
local silence_threshold     = -40   -- dB
local silence_min_duration  = 1.2   -- seconds
```

### `silence_threshold`

Audio level (in dB) below which audio is considered silence.  
Lower (more negative) values require quieter audio and are stricter.

### `silence_min_duration`

Minimum continuous silence duration required for detection.  
Increase this value to ignore brief pauses or gaps.

---

## How detection works

**1.** Press the activation key  
**2.** Playback speed is temporarily increased  
**3.** The `silencedetect` filter is applied  
**4.** The script polls audio filter metadata:  
   - `lavfi.silence_start`

**5.** When a qualifying silence is detected:  
   - detection stops
   - playback speed is restored
   - mpv seeks precisely to the silence start

If no qualifying silence is detected yet, scanning continues.

---

## Toggle and stop behavior

- Press once → start scanning
- Press again while scanning → **cancel scan (no seek)**

Manual cancellation always:
- removes the audio filter
- restores playback speed
- leaves playback position unchanged

---

## Safety and guarantees

- Audio filters are added and removed cleanly
- Playback speed is always restored
- No chapters are created or modified
- No timestamps are permanently changed
- Seeking uses exact positioning
- No duplicate or repeated seeks occur

---

## Keybindings

| Key | Action |
|-----|--------|
| **N** | Toggle silence scan |

---

## Workflow

This script is intended to help locate **act breaks, pauses, and audio-defined transitions** so that chapters can be placed accurately using tools such as `create_chapter.lua`.

Typical workflow:  
**1.** Use this script to jump to a likely silence or pause  
**2.** Insert a chapter manually at the detected position  
**3.** Adjust or refine chapter placement as needed  
**4.** Merge chapters into the media file  

> If silence detection is insufficient or the transition is primarily visual (e.g. fades or hard cuts), consider using **[skip_to_fade.lua](/docs/skip_to_fade.md)** to locate boundaries via visual analysis instead.

---

## Platform-specific notes

- Fully platform-independent
- Requires FFmpeg support compiled into mpv (standard builds)

---

## Dependencies

- mpv with FFmpeg `lavfi` audio filter support
