# mpv-chapter-editing-framework

A carefully developed set of MPV Lua scripts resulting from extensive testing, tweaking, and iterative improvement, designed to handle the entire chapter-editing workflow for **MKV and MP4** files directly inside MPV, thus eliminating the need to resort to external chapter editors during authoring.

The framework is designed around **live playback workflows**: chapters are authored, refined, and deployed **during playback**, not before or after.

This project focuses on **chapter authoring and deployment**; it does not aim to replace full remuxing or encoding tools.

📚 **Full per-script documentation is available in the [docs](/docs/) directory.**

---

## Table of Contents

- [Chapter Creation & Editing](#-chapter-creation--editing)
- [Structured & Thematic Naming](#-structured--thematic-naming)
- [Title Formatting Tools](#-title-formatting-tools)
- [Timestamp Tools](#-timestamp-tools)
- [Loading & Navigation](#-loading--navigation)
- [Import/Export Tools](#-importexport-tools)
- [Scene Detection](#-scene-detection)
- [Automation](#-automation)
- [Requirements](#requirements)

---

# 📦 Lua Scripts

Below are **collapsible sections**, each containing detailed documentation.

> **Note**  
> **Auto-save mode** is enabled by default, so every chapter change is immediately exported and overwrites the corresponding file.  
> Manual export is therefore **usually unnecessary** across all scripts that support auto-save.

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

## Requirements

Some scripts rely on external tools:

- **MKVToolNix** (`mkvpropedit`, `mkvextract`) for MKV chapter deployment
- **GPAC/MP4Box** for MP4 chapter deployment

These tools are **only required for chapter deployment**.  
All chapter authoring, editing, and formatting features work without them.
