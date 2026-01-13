# mpv-chapter-editing-framework

A carefully developed set of MPV Lua scripts resulting from extensive testing, tweaking, and iterative improvement, designed to handle the entire chapter-editing workflow for **MKV and MP4** files directly inside MPV, thus eliminating the need to resort to external chapter editors during authoring.

The framework is designed around **live playback workflows**: chapters are authored, refined, and deployed **during playback**, not before or after.

This project focuses on **chapter authoring and deployment**; it does not aim to replace full remuxing or encoding tools.

📚 **Full per-script documentation is available in the [docs](/docs/) directory.**

---

## Table of Contents

- [Lua Scripts](#-lua-scripts)
  - [Chapter Creation & Editing](#-chapter-creation--editing)
  - [Structured & Thematic Naming](#-structured--thematic-naming)
  - [Title Formatting Tools](#-title-formatting-tools)
  - [Timestamp Tools](#-timestamp-tools)
  - [Loading & Navigation](#-loading--navigation)
  - [Import/Export Tools](#-importexport-tools)
  - [Scene Detection](#-scene-detection)
  - [Automation](#-automation)
- [Workflow Scenarios](#-workflow-scenarios)
- [Requirements](#requirements)
- [Notes](#-notes)

---

# 📦 Lua Scripts

Below are **collapsible sections**, each containing detailed documentation.

---

## 🧱 Chapter Creation & Editing

**create_chapter.lua** — Core chapter creation tool  
The foundation of the framework.  
This script turns MPV into a live chapter authoring environment during playback.

<details>
<summary><strong><a href="docs/create_chapter.md">create_chapter.lua</a> — Details</strong></summary>

### Features
- Create chapter markers at the exact playback position
- Delete the nearest previous chapter
- Renumber the entire chapter list sequentially
- Export chapters in real time to:
  - Matroska XML (MKVToolNix compatible)
  - CHAPTERxx.txt format  (MP4 compatible)
  - Plain TXT
- Cycle predefined title prefixes
- Enter fully custom prefixes manually
- Optional auto-save mode

### Keybindings
- **C** — Create chapter  
- **Shift+C** — Create chapter (named after respective timestamp)  
- **Shift+D** — Delete previous chapter  
- **Shift+R** — Rename + renumber all chapters  
- **Shift+B** — Export XML  
- **H** — Export CHAPTERxx.txt  
- **Shift+T** — Export TXT  
- **Ctrl+Space** — Cycle prefix  
- **Shift+P** — Cycle first chapter title  
- **Ctrl+Q** — Enter custom prefix  
</details>

---

**rename_singlechapter.lua** — Rename the selected chapter  
Provides a minimal popup interface to rename only the currently selected chapter.

<details>
<summary><strong><a href="docs/rename_singlechapter.md">rename_singlechapter.lua</a> — Details</strong></summary>

### Keybindings
- **A** — Rename current chapter 
</details>

---

## 🎭 Structured & Thematic Naming

**rename_chapters.lua** — Rename all to “Chapter 1, 2, etc.”  
Applies a clean, neutral chapter naming format widely used in MKV releases.

<details>
<summary><strong><a href="docs/rename_chapters.md">rename_chapters.lua</a> — Details</strong></summary>

### Keybindings
- **Ctrl+Shift+C** — Rename matching chapters sequentially  
- **Ctrl+Alt+Shift+C** — Rename and renumber chapters by timeline position  

</details>

---

**rename_acts.lua** — Roman numeral acts (Act I, Act II…)  
Uses Roman numerals for traditional act-based structures.

<details>
<summary><strong><a href="docs/rename_acts.md">rename_acts.lua</a> — Details</strong></summary>

### Keybindings
- **Shift+Ctrl+A** — Rename matching chapters to Roman-numeral acts  

</details>

---

**rename_parts.lua** — Alphabetical parts (Part A, Part B…)  
Applies alphabetical section naming, especially well-suited for anime.

<details>
<summary><strong><a href="docs/rename_parts.md">rename_parts.lua</a> — Details</strong></summary>

### Keybindings
- **Ctrl+Shift+P** — Rename matching chapters to alphabetical parts  

</details>

---

**customized_named_chapters.lua** — TV-style naming 
Applies structured, television-style chapter naming schemes.

<details>
<summary><strong><a href="docs/customized_named_chapters.md">customized_named_chapters.lua</a> — Details</strong></summary>

### Features
- Predefined structures such as:
  - Cold Open
  - Act I/Act II/Act III
  - Credits/Outro
- Automatically adapts to the number of chapters
- Independent naming scheme sets
- Optional auto-rename mode that reacts to chapter changes

### Keybindings
- **Alt+R** — Apply naming scheme  
- **Ctrl+Alt+R** — Toggle auto-rename  
- **Ctrl+Alt+L** — Switch naming set  

</details>

---

**find_&_replace.lua** — Targeted chapter title normalization  
Applies deterministic, rule-based find & replace operations to chapter titles using a predefined word map.

<details>
<summary><strong><a href="docs/find_&_replace.md">find_&_replace.lua</a> — Details</strong></summary>

### Keybindings
- **Alt+F** — Apply find & replace  
- **Ctrl+F** — Toggle auto-rename on file load

</details>

---

## 🔠 Title Formatting Tools

**clean_titles.lua** — Remove messy prefixes  
Strips unwanted numeric or symbolic prefixes from chapter titles.

<details>
<summary><strong><a href="docs/clean_titles.md">clean_titles.lua</a> — Details</strong></summary>

### Examples
- `01 - Intro` → `Intro`  
- `[1] Opening` → `Opening`  
- `(03)_Scene` → `Scene`  

### Keybindings
- **Alt+C** — Clean titles  

</details>

---

**number_titles.lua** — Add numbers to existing titles  
Adds numeric prefixes while preserving existing chapter names.

<details>
<summary><strong><a href="docs/number_titles.md">number_titles.lua</a> — Details</strong></summary>

### Features
- Multiple numbering styles
- Optional two-digit formatting
- Works after other rename scripts
- Auto-save support

### Keybindings
- **Alt+N** — Number titles  
- **Alt+Shift+N** — Cycle numbering styles  
- **Alt+Shift+D** — Toggle two-digit mode  

</details>

---

## 🕒 Timestamp Tools

**offset_timestamps.lua** — Snap & shift timestamps  
Provides precise timestamp correction tools.

<details>
<summary><strong><a href="docs/offset_timestamps.md">offset_timestamps.lua</a> — Details</strong></summary>

### Keybindings
- **Ctrl+Alt+Right** — Snap previous chapter  
- **Ctrl+Alt+Left** — Snap next chapter  
- **Ctrl+Alt+Up** — Snap previous chapter and all later chapters  
- **Ctrl+Alt+Down** — Snap later chapter and all later chapters  
- **Ctrl+O** — Manual offset  

</details>

---

## 📂 Loading & Navigation

**jump_to_chapter.lua** — Chapter navigation

<details>
<summary><strong><a href="docs/jump_to_chapter.md">jump_to_chapter.lua</a> — Details</strong></summary>

### Keybindings
- **Ctrl+Left** — Previous chapter  
- **Ctrl+Right** — Next chapter  

</details>

---

**go_to.lua** — Jump to input timestamp  

<details>
<summary><strong><a href="docs/go_to.md">go_to.lua</a> — Details</strong></summary>

### Keybindings
- **Shift+G** — Open Go To Box

</details>

---

**load_chapters.lua** — Load external XML chapters

<details>
<summary><strong><a href="docs/load_chapters.md">load_chapters.lua</a> — Details</strong></summary>

### Keybindings
- **Ctrl+L** — Toggle XML/embedded chapters  
- **Shift+L** — Enable or disable script  

</details>

---

## 📤 Import/Export Tools

**merge_chapters.lua** — Universal chapter deployment (MKV + MP4)  
Applies external chapter files back into video containers, per-file or in bulk.

<details>
<summary><strong><a href="docs/merge_chapters.md">merge_chapters.lua</a> — Details</strong></summary>

### Keybindings
- **Ctrl+Alt+T** — Toggle replace mode (current video ⇄ all videos in current folder)
- **Ctrl+Alt+M** — Update chapters for the current video or all videos in the current folder (depending on replace mode)
- **Shift+Ctrl+Alt+M** — Update chapters recursively for all videos in the parent folder and all its subfolders
- **Ctrl+Alt+D** — Move all XML/TXT chapter files in the current folder to the Recycle Bin
- **Shift+Ctrl+Alt+D** — Move all XML/TXT chapter files in the parent folder and all subfolders to the Recycle Bin
- **Shift+Ctrl+Delete** — Backup embedded chapters from the current MKV and then clear them from the file


</details>

---

**extract_chapters.lua** — Extract MKV chapters

<details>
<summary><strong><a href="docs/extract_chapters.md">extract_chapters.lua</a> — Details</strong></summary>

### Keybindings
- **Shift+Ctrl+E** — Extract chapters from the currently playing MKV  
- **Shift+Ctrl+Alt+E** — Extract chapters from all MKVs in the current folder  
- **Shift+Ctrl+Alt+U** — Extract chapters from all MKVs in the parent folder (recursive)  
- **Shift+Ctrl+O** — Toggle XML overwrite mode (overwrite vs numeric suffix)  

</details>

---

## 🎧 Scene Detection

**skip_to_fade.lua** — Fade-to-black scene detection

<details>
<summary><strong><a href="docs/skip_to_fade.md">skip_to_fade.lua</a> — Details</strong></summary>

### Keybindings
- **G** — Start/Stop fade detection  

</details>

---

**skip_to_silence.lua** — Silence-based scene detection

<details>
<summary><strong><a href="docs/skip_to_silence.md">skip_to_silence.lua</a> — Details</strong></summary>

### Keybindings
- **N** — Start/Stop silence scan  

</details>

---

## 🔁 Automation

**auto_playlist.lua** — Automatic playlist builder

<details>
<summary><strong><a href="docs/auto_playlist.md">auto_playlist.lua</a> — Details</strong></summary>

### Keybindings
- **Ctrl+Alt+P** — Toggle playlist automation  

</details>

---

# 🎬 Workflow Scenarios

The following scenarios demonstrate common real-world workflows enabled by the framework, showing how individual scripts work together during playback and batch processing.

---

### Scenario 1: Create chapters live while watching
<details>
  
**Situation:**  
You're watching an episode or movie and want to create chapters as you watch.

**Steps:**  
**1.** Open the video in MPV  
**2.** While watching, press **C** at each scene change (creates chapters in real time using `create_chapter.lua`)  
**3.** If needed, fix a title:  
- Navigate to the chapter (`jump_to_chapter.lua`)  
- Press **A** to rename it (`rename_singlechapter.lua`)  

**4.** Chapters are auto-saved to XML as you work  
**5.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)  

**Result:**  
All videos receive clean, consistent chapters authored during playback.
</details>

---

### Scenario 2: Remove numbering from existing chapters
<details>
  
**Situation:**  
You have a file with chapters like:
  
```
01 - Intro
02 - Opening Sequence
03 - Scene 1
...
```
You want to remove the numbering and re-embed clean chapter titles into the MKV.

**Steps:**  
**1.** Open the file in MPV  
**2.** Press **Alt+C** (removes numeric prefixes using `clean_titles.lua`)  
**3.** Chapters are auto-saved to XML immediately  
**4.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)   

**Result:**  
The file now contains clean chapter titles, and no external chapter files remain.
</details>

---

### Scenario 3: Convert messy auto-generated chapters into a clean structure
<details>
  
**Situation:**  
You extracted chapters with messy titles like:
  
```
00:00:00.000
00:03:13.026
00:04:38.028
...
```

**Steps:**  
**1.** Open the file in MPV  
**2.** Press **Shift+R** (discards all existing chapter titles and replaces them with a clean, sequential set using `create_chapter.lua`)  
**3.** Chapters are auto-saved to XML immediately  
**4.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)   

**Result:**  
A clean, professional chapter list replaces the messy originals.
</details>

---

### Scenario 4: Apply a custom chapter naming preset
<details>
  
**Situation:**  
You want to apply a predefined chapter naming preset, such as broadcast-style,
anime-style, or any custom structure you prefer.

Example preset:

```
Cold Open  
Act I  
Act II  
Act III  
Credits  
```

**Steps:**  
**1.** Open **[customized_named_chapters.lua](/scripts/customized_named_chapters.lua)** in a text editor  
**2.** Add the desired chapter names (`names_5 = {"Cold Open", "Act I", "Act II", "Act III", "Credits"}`)  
**3.** Save the lua script  
**4.** Open the file in MPV  
**5.** Press **Alt+R** (apply TV-style naming)  
**6.** Chapters are auto-saved to XML immediately  
**7.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)   

**Result:**  
The episode receives a consistent chapter naming structure based on the selected preset, with all chapters applied in a single operation.
</details>

---

### Scenario 5: Fix chapters that are slightly out of sync
<details>
  
**Situation:**  
Chapters exist but start too early or late.

**Steps:**  
**1.** Open the file in MPV  
**2.** Navigate to the chapter (`jump_to_chapter.lua`)  
**3.** Seek the correct position  
**4.** Press **Ctrl+Alt+Right/Left** (snap desired chapter to playback time using `offset_timestamps.lua`)  
**5.** Repeat as needed  
**6.** Chapters are auto-saved to XML as you work  
**7.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)   

**Result:**  
Chapter boundaries are precisely aligned with scene transitions.
</details>

---

### Scenario 6: Batch update chapters across an entire folder (MKV + MP4)
<details>
  
**Situation:**  
You want to apply chapters across a whole folder of videos.

**Steps:**  
**1.** Ensure chapter XML/TXT files exist for each video  
**2.** Open any file in the folder  
**3.** Press **Ctrl+Alt+T** (enable all-files mode for the folder)  
**4.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)   

**Result:**  
Every episode is updated, and the folder is left clean.
</details>

---

### Scenario 7: Use silence and fade detection to find act breaks
<details>
  
**Situation:**  
You want to place chapters at traditional broadcast-style act breaks, which are usually marked by a fade to black and a period of silence.

**1.** Open the file in MPV  
**2.** Use either detection method to locate a potential chapter boundary:
   - Press **N** to seek silence (`skip_to_silence.lua`)
   - Press **G** to seek a fade to black (`skip_to_fade.lua`)

**3.** When MPV stops at a suitable point, press **C** to create a chapter (`create_chapter.lua`)  
**4.** Alternate between **N** and **G** and repeat as needed  
**5.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)  

**Result:**  
Chapters align naturally with scene transitions.
</details>

---

### Scenario 8: Renumber chapters to reflect their actual position
<details>

**Situation:**  
You have a chapter list such as:

```
Recap
Chapter 1  
Opening  
Chapter 2  
Chapter 3
...
```

**Steps:**  
**1.** Open the file in MPV  
**2.** Press **Ctrl+Shift+Alt+C** (renames and renumbers all chapters so numbering reflects their true position using `rename_chapters.lua`)  
**3.** Chapters are auto-saved to XML immediately  
**4.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)

**Result:**  

```
Recap
Chapter 2  
Opening  
Chapter 4  
Chapter 5
...
```

**Result:**  
Chapter numbering now correctly reflects their position in the chapter list, even when non-numbered entries (Recap, Opening, etc.) are present.
</details>

---
### Scenario 9: Use Roman numerals for chapter numbering

<details>

**Situation:**  
You want chapters labeled using Roman numerals instead of Arabic numbers (**`Chapter I`**, **`Chapter II`**, **`Chapter III`**, etc.).

**Steps:**  
**1.** Open **[rename_acts.lua](/scripts/rename_acts.lua)** in a text editor  
**2.** Change the title prefix from `"Act"` to `"Chapter"`  
**3.** Save the lua script  
**4.** Open the video in MPV  
**5.** Press **Ctrl+Shift+A** to rename all chapters using Roman numerals  
**6.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)

**Result:**  
All chapters are renamed to `Chapter I`, `Chapter II`, `Chapter III`, etc., providing a clean, classical chapter numbering style.

</details>

---

### Scenario 10: Batch find & replace chapter titles across an entire folder
<details>

**Situation:**  
You have a set of video files where chapters contain the title **`End Credits`**.  
You want to standardize this across all files by replacing it with **`Credits`**.  

**Steps:**  
**1.** Open **[find_&_replace.lua](/scripts/find_&_replace.lua)** in a text editor  
**2.** Add or edit the local `WORD_MAP` to include: `End Credits → Credits`  
**3.** Open any file in the target folder in MPV  
**4.** Press **Ctrl+F** (enables auto-rename in `find_&_replace.lua`)  
**5.** Press **Ctrl+Alt+P** (creates a playlist of all files in the folder using `auto_playlist.lua`)  
**6.** Navigate through the playlist normally. As each file loads, auto-rename applies the replacement automatically.  
**7.** Chapters are auto-saved to XML as you work  
**8.** Press **Ctrl+Alt+T** (enable all-files mode for the folder)  
**9.** Press **Ctrl+Alt+M** to embed chapters and **Ctrl+Alt+D** to move chapter files to the recycle bin (`merge_chapters.lua`)

**Result:**  
All files in the set now share consistent chapter naming, achieved with a single find-and-replace definition and automated playback traversal — no manual editing per file required.
</details>

---

# Requirements

Some scripts rely on external tools:

- **MKVToolNix** (`mkvpropedit`, `mkvextract`) for MKV chapter deployment
- **GPAC/MP4Box** for MP4 chapter deployment

These tools are **only required for chapter deployment**.  
All chapter authoring, editing, and formatting features work without them.

---

# 📝 Notes

> **Auto-save mode:** is enabled by default, so every chapter change is immediately exported and overwrites the corresponding file.  
> Manual export is therefore **usually unnecessary** across all scripts that support auto-save.

> **MP4 workflow:**  
> When working with MP4 files, you can press **Shift+X** to switch chapter auto-save to **TXT**.  
> However, it's recommended to keep the default **XML auto-save** while authoring: it acts as an automatic backup if MPV crashes or is closed accidentally.  
> You can instantly resume work by reloading the XML with `load_chapters.lua`, then export the final `CHAPTERxx.TXT` using **H** before merging.


> **Batch merge:**  
> When working with multiple files, press **Ctrl+Alt+T** to enable all-files mode before pressing **Ctrl+Alt+M** to embed chapters into the files. 
