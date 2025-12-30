local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local AUTO_SAVE_MODE = "xml"  -- or "chap_txt"
local numbering_formats = {
    "%s. %s",  -- 1. Title or 01. Title
    "%s) %s",  -- 1) Title or 01) Title
    "%s - %s"  -- 1 - Title or 01 - Title
}

local current_format_index = 1
local two_digit_mode = false  -- false = single-digit, true = double-digit

-------------------------------------------------
-- SKIP CHAPTER RULES
-------------------------------------------------
local SKIP_CHAPTER_PATTERNS = {
    "^[%s%p]*[Cc]hapter%s*%d+",
    "^[%s%p]*[Ss]cene%s*%d+",
    "^[%s%p]*[Pp]art%s*%d+",
    "^[%s%p]*[Aa]ct%s*%d+",
}

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function format_time(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02d:%02d:%06.3f", h, m, s)
end

local function make_uid(chapter)
    return tostring(math.floor(os.clock() * 1000000 + (chapter.time or 0) * 1000))
end

local function current_format_preview()
    local fmt = numbering_formats[current_format_index]
    local sample = two_digit_mode and "01" or "1"
    return fmt:gsub("%%s", sample, 1):gsub("%%s", "Title")
end

local function show_status(message)
    local preview = current_format_preview()
    mp.osd_message(string.format("%s\nFormat: %s | Save: %s",
        message, preview, AUTO_SAVE_MODE:upper()), 3)
end

local function should_skip_chapter(title)
    if not title or title == "" then return false end

    for _, pattern in ipairs(SKIP_CHAPTER_PATTERNS) do
        if title:match(pattern) then
            return true
        end
    end

    return false
end

-------------------------------------------------
-- AUTO-SAVE FUNCTION
-------------------------------------------------
local function auto_save_chapters()
    local all_chapters = mp.get_property_native("chapter-list")
    if not all_chapters or #all_chapters == 0 then return end

    local path = mp.get_property("path")
    if not path then return end
    local dir, name_ext = utils.split_path(path)
    local name = name_ext:gsub("%.%w+$", "")

    if AUTO_SAVE_MODE == "xml" then
        local euid = mp.get_property_number("estimated-frame-count") or 0
        local xml_data = {}
        for _, c in ipairs(all_chapters) do
            local uid = make_uid(c)
            table.insert(xml_data,
                string.format([[<ChapterAtom>
  <ChapterDisplay>
    <ChapterString>%s</ChapterString>
    <ChapterLanguage>eng</ChapterLanguage>
  </ChapterDisplay>
  <ChapterUID>%s</ChapterUID>
  <ChapterTimeStart>%s</ChapterTimeStart>
  <ChapterFlagHidden>0</ChapterFlagHidden>
  <ChapterFlagEnabled>1</ChapterFlagEnabled>
</ChapterAtom>]],
                c.title, uid, format_time(c.time))
            )
        end
        local xml = string.format(
            [[<?xml version="1.0" encoding="UTF-8"?>
<Chapters>
  <EditionEntry>
    <EditionFlagHidden>0</EditionFlagHidden>
    <EditionFlagDefault>1</EditionFlagDefault>
    <EditionUID>%s</EditionUID>
%s
  </EditionEntry>
</Chapters>]], euid, table.concat(xml_data, "\n"))

        local out_path = utils.join_path(dir, name..".xml")
        local file = io.open(out_path, "w")
        if file then
            file:write(xml)
            file:close()
            mp.osd_message("Saved XML chapters: "..out_path, 2)
        else
            mp.osd_message("Auto-save failed: cannot write XML", 2)
        end

    elseif AUTO_SAVE_MODE == "chap_txt" then
        local lines = {}
        for i, c in ipairs(all_chapters) do
            local num = string.format("%02d", i)
            table.insert(lines, "CHAPTER"..num.."="..format_time(c.time))
            table.insert(lines, "CHAPTER"..num.."NAME="..c.title)
        end
        local out_path = utils.join_path(dir, name..".txt")
        local file = io.open(out_path, "w")
        if file then
            file:write(table.concat(lines, "\n"))
            file:close()
            mp.osd_message("Saved CHAP TXT: "..out_path, 2)
        else
            mp.osd_message("Auto-save failed: cannot write CHAP TXT", 2)
        end
    end
end

-------------------------------------------------
-- TOGGLE AUTO-SAVE MODE
-------------------------------------------------
local function toggle_auto_save_mode()
    if AUTO_SAVE_MODE == "xml" then
        AUTO_SAVE_MODE = "chap_txt"
    else
        AUTO_SAVE_MODE = "xml"
    end
    show_status("Toggled auto-save mode")
end

-------------------------------------------------
-- APPLY NUMBERING
-------------------------------------------------
local function apply_numbering()
    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters found.", 2)
        return
    end

    local format = numbering_formats[current_format_index]
    local counter = 0
    local changed_count = 0

    for _, c in ipairs(chapters) do
        local base_title = c.title or ""
        counter = counter + 1

        if should_skip_chapter(base_title) then
            goto continue
        end

        -- Remove existing leading numbering like "1. " or "01) "
        base_title = base_title:gsub("^%s*%d+[%s%p_-]*", "")

        local num = two_digit_mode and string.format("%02d", counter) or tostring(counter)
        c.title = string.format(format, num, base_title)
        changed_count = changed_count + 1

        ::continue::
    end

    mp.set_property_native("chapter-list", chapters)
    auto_save_chapters()

    local skipped = #chapters - changed_count

    show_status(string.format(
        "Chapters numbered: %d changed, %d skipped.",
        changed_count,
        skipped
    ))
end

-------------------------------------------------
-- TOGGLE NUMBER FORMAT
-------------------------------------------------
local function toggle_number_format()
    current_format_index = current_format_index % #numbering_formats + 1
    show_status("Toggled numbering format")
end

-------------------------------------------------
-- TOGGLE TWO-DIGIT MODE
-------------------------------------------------
local function toggle_two_digit_mode()
    two_digit_mode = not two_digit_mode
    show_status("Toggled " .. (two_digit_mode and "two-digit" or "single-digit") .. " mode")
end

-------------------------------------------------
-- MAIN FUNCTION
-------------------------------------------------
local function number_chapters()
    apply_numbering()
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
mp.add_key_binding("alt+n", "number_chapters", number_chapters)
mp.add_key_binding("alt+shift+n", "toggle_number_format", toggle_number_format)
mp.add_key_binding("alt+shift+d", "toggle_two_digit_mode", toggle_two_digit_mode)

-- Shift+X → Toggle auto-save mode (keybinding handled by create_chapter.lua)
mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
