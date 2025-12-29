local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local AUTO_SAVE_MODE = "xml"  -- default mode: "xml" or "chap_txt"

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function escape_quotes(str)
    return (str or ""):gsub("'", "''"):gsub('"', '""')
end

local function format_time(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local total_ms = math.floor(seconds * 1000 + 0.5)
    local hours = math.floor(total_ms / 3600000)
    local mins = math.floor((total_ms % 3600000) / 60000)
    local secs = math.floor((total_ms % 60000) / 1000)
    local msecs = total_ms % 1000
    return string.format("%02d:%02d:%02d.%03d", hours, mins, secs, msecs)
end

local function make_uid(chapter)
    local input = (chapter.title or "") .. "|" .. tostring(chapter.time or 0)
    local hash = 0
    for i = 1, #input do
        hash = (hash * 131 + input:byte(i)) % 1000000007
    end
    if hash == 0 then hash = 1 end
    return tostring(hash)
end

-------------------------------------------------
-- AUTO-SAVE MODE TOGGLE
-------------------------------------------------
local function toggle_auto_save_mode()
    if AUTO_SAVE_MODE == "xml" then
        AUTO_SAVE_MODE = "chap_txt"
    else
        AUTO_SAVE_MODE = "xml"
    end
    mp.osd_message("Auto-save mode: "..AUTO_SAVE_MODE:upper(), 2)
end

-------------------------------------------------
-- AUTO-SAVE FUNCTION
-------------------------------------------------
local function auto_save_chapters(count)
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
            mp.osd_message("Auto-saved XML file with renamed chapter.", 4)
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
            mp.osd_message("Auto-saved TXT file with renamed chapter.", 4)
        else
            mp.osd_message("Auto-save failed: cannot write CHAP TXT", 2)
        end
    end
end

-------------------------------------------------
-- CHAPTER RENAME FUNCTION
-------------------------------------------------
local function ask_chapter_name(default_name)
    local res = utils.subprocess({
        args = {
            "powershell", "-NoProfile", "-Command",
            "Add-Type -AssemblyName Microsoft.VisualBasic;" ..
            string.format("[Microsoft.VisualBasic.Interaction]::InputBox('Rename chapter:', 'Rename Chapter', '%s')", escape_quotes(default_name or "Chapter"))
        },
        cancellable = false
    })

    if res.status == 0 then
        return (res.stdout or ""):gsub("[\r\n]+", "")
    end
    return default_name or "Chapter"
end

local function rename_current_chapter()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters to rename.", 2)
        return
    end

    local current_index = nil
    for i, c in ipairs(chapters) do
        if c.time <= time_pos then
            current_index = i
        else
            break
        end
    end

    if not current_index then
        mp.osd_message("No current chapter found.", 2)
        return
    end

    local current_chapter = chapters[current_index]
    local new_name = ask_chapter_name(current_chapter.title)

    if new_name == "" then
        mp.osd_message("Rename canceled.", 2)
        return
    end

    current_chapter.title = new_name
    mp.set_property_native("chapter-list", chapters)
    mp.osd_message("Chapter renamed to '"..new_name.."' ("..AUTO_SAVE_MODE..")", 2)

    auto_save_chapters()  -- auto-save after rename
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
mp.add_key_binding("a", "rename_current_chapter", rename_current_chapter, {repeatable=false})

-- Shift+X → Toggle auto-save mode (keybinding handled by create_chapter.lua)
mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
