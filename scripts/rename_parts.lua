local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local MATCH_WORDS = { "Chapter", "Scene", "Part", "Act", "Episode" }
local DEST_WORD = "Part"
local AUTO_SAVE_MODE = "xml" -- "xml" or "chap_txt"

-------------------------------------------------
-- HELPER: Get letter from index (1 → A, 2 → B, ..., 27 → AA)
-------------------------------------------------
local function index_to_letter(index)
    local letters = ""
    while index > 0 do
        local remainder = (index - 1) % 26
        letters = string.char(65 + remainder) .. letters
        index = math.floor((index - 1) / 26)
    end
    return letters
end

-------------------------------------------------
-- HELPERS
-------------------------------------------------
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

local function is_roman(str)
    return str:match("^(M{0,3})(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$") ~= nil
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
            mp.osd_message("Renamed and autosaved " .. count .. " " .. DEST_WORD .. "(s) (XML).", 2)
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
            mp.osd_message("Renamed and autosaved " .. count .. " " .. DEST_WORD .. "(s) (TXT).", 2)
        else
            mp.osd_message("Auto-save failed: cannot write CHAP TXT", 2)
        end
    end
end

-------------------------------------------------
-- MAIN FUNCTION
-------------------------------------------------
local function rename_chapters_to_parts()
    local chapters = mp.get_property_native("chapter-list") or {}
    if not chapters or #chapters == 0 then
        mp.osd_message("No " .. DEST_WORD .. "s found.", 2)
        return
    end

    table.sort(chapters, function(a,b) return a.time < b.time end)

    local count = 0
    for i, c in ipairs(chapters) do
        if c.title then
            for _, word in ipairs(MATCH_WORDS) do
                local pattern = "^" .. word .. "%s*[%dA-Za-z]*$"
                if c.title:match(pattern) then
                    count = count + 1
                    local letter = index_to_letter(count)
                    c.title = DEST_WORD .. " " .. letter
                    break
                end
            end
        end
    end

    if count > 0 then
        mp.set_property_native("chapter-list", chapters)
        mp.osd_message("Renamed " .. count .. " chapters to " .. DEST_WORD .. " A.." .. index_to_letter(count), 3)
        auto_save_chapters(count)
    else
        mp.osd_message("No matching " .. DEST_WORD .. "s found.", 2)
    end
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
mp.add_key_binding("ctrl+shift+p", "rename_chapters_to_parts", rename_chapters_to_parts)

-- Shift+X → Toggle auto-save mode (keybinding handled by create_chapter.lua)
mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
