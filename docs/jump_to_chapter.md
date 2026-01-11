[← Back to README](/README.md)

# [jump_to_chapter.lua](/scripts/jump_to_chapter.lua)

Navigate between chapters with precision tolerance in mpv.

This script provides **reliable previous/next chapter navigation** that is resilient to floating-point imprecision and tightly spaced chapter boundaries.  
It jumps cleanly to the intended chapter while displaying clear on-screen feedback.

It is designed for **reviewing, validating, and fine-tuning chapter placement**, not for editing chapter data.

---

## Core behavior

- Jump to the **previous** or **next** chapter
- Uses a configurable time margin to avoid accidental re-jumps
- Displays the chapter title after each jump
- Never modifies chapters, timestamps, or files
- Safe, read-only navigation

---

## Keybindings

| Key | Action |
|-----|--------|
| **Ctrl+Left** | Jump to previous chapter |
| **Ctrl+Right** | Jump to next chapter |

An OSD message shows the destination chapter title after each jump.

---

## Precision margin

mpv chapter timestamps are floating-point values.  
When playback is very close to a chapter boundary, naïve navigation can:

- Re-jump to the same chapter
- Skip the intended chapter
- Oscillate between boundaries

This script uses a **margin tolerance** (`MARGIN`, default: `1.5` seconds):

- Previous chapter → must be **earlier than (current time − margin)**
- Next chapter → must be **later than (current time + margin)**

This ensures stable, predictable navigation.

---

## OSD behavior

After each successful jump, the script displays:

```Jumped to previous chapter: <Chapter Name>```

or

```Jumped to next chapter: <Chapter Name>```

If:
- No chapters exist → `No chapters available`
- You are already at the boundary → `Already at first/last chapter`

---

## Workflow

This script pairs naturally with **[offset_timestamps.lua](/docs/offset_timestamps.md)**:

- Use `jump_to_chapter.lua` to navigate and verify chapter boundaries
- Use `offset_timestamps.lua` to correct or realign timestamps
- Jump → inspect → adjust → jump again

Together, they form a tight feedback loop for **chapter timing correction and validation**.

---

## Typical use cases

- Reviewing detected chapters
- Verifying chapter alignment after offsets
- Navigating tightly spaced chapters
- Quality control during chapter authoring
- Checking boundaries before snapping or shifting
