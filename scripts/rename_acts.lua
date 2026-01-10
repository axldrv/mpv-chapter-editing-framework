local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local MATCH_WORDS = { "Chapter", "Scene", "Part", "Act", "Episode" }
local DEST_WORD = "Act"
local AUTO_SAVE_MODE = "xml" -- "xml" or "chap_txt"

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function to_roman(num)
    if type(num) ~= "number" or num <= 0 or num > 3999 then
        return tostring(num)
    end
    local romans = {
        {1000, "M"}, {900, "CM"}, {500, "D"}, {400, "CD"},
        {100, "C"}, {90, "XC"}, {50, "L"}, {40, "XL"},
        {10, "X"}, {9, "IX"}, {5, "V"}, {4, "IV"}, {1, "I"}
    }
    local result = ""
    for _, pair in ipairs(romans) do
        local value, symbol = pair[1], pair[2]
        while num >= value do
            result = result .. symbol
            num = num - value
        end
    end
    return result
end

local function is_roman(str)
    if type(str) ~= "string" then return false end
    return str:match(
        "^(M{0,3})(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$"
    ) ~= nil
end

local function format_time(seconds)
    local total_ms = math.floor((seconds or 0) * 1000 + 0.5)
    local h = math.floor(total_ms / 3600000)
    local m = math.floor((total_ms % 3600000) / 60000)
    local s = math.floor((total_ms % 60000) / 1000)
    local ms = total_ms % 1000
    return string.format("%02d:%02d:%02d.%03d", h, m, s, ms)
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
    AUTO_SAVE_MODE = (AUTO_SAVE_MODE == "xml") and "chap_txt" or "xml"
    mp.osd_message("Auto-save mode: " .. AUTO_SAVE_MODE:upper(), 2)
end

-------------------------------------------------
-- AUTO-SAVE FUNCTION
-------------------------------------------------
local function auto_save_chapters()
    local chapters = mp.get_property_native("chapter-list")
    if not chapters or #chapters == 0 then return false end

    local path = mp.get_property("path")
    if not path then return false end
    local dir, name_ext = utils.split_path(path)
    local name = name_ext:gsub("%.%w+$", "")

    if AUTO_SAVE_MODE == "xml" then
        local euid = mp.get_property_number("estimated-frame-count") or 0
        local xml_data = {}

        for _, c in ipairs(chapters) do
            table.insert(xml_data, string.format([[<ChapterAtom>
  <ChapterDisplay>
    <ChapterString>%s</ChapterString>
    <ChapterLanguage>eng</ChapterLanguage>
  </ChapterDisplay>
  <ChapterUID>%s</ChapterUID>
  <ChapterTimeStart>%s</ChapterTimeStart>
  <ChapterFlagHidden>0</ChapterFlagHidden>
  <ChapterFlagEnabled>1</ChapterFlagEnabled>
</ChapterAtom>]],
                c.title,
                make_uid(c),
                format_time(c.time)
            ))
        end

        local xml = string.format([[<?xml version="1.0" encoding="UTF-8"?>
<Chapters>
  <EditionEntry>
    <EditionFlagHidden>0</EditionFlagHidden>
    <EditionFlagDefault>1</EditionFlagDefault>
    <EditionUID>%s</EditionUID>
%s
  </EditionEntry>
</Chapters>]], euid, table.concat(xml_data, "\n"))

        local f = io.open(utils.join_path(dir, name .. ".xml"), "w")
        if not f then return false end
        f:write(xml)
        f:close()
        return true
    else
        local lines = {}
        for i, c in ipairs(chapters) do
            local n = string.format("%02d", i)
            table.insert(lines, "CHAPTER" .. n .. "=" .. format_time(c.time))
            table.insert(lines, "CHAPTER" .. n .. "NAME=" .. c.title)
        end
        local f = io.open(utils.join_path(dir, name .. ".txt"), "w")
        if not f then return false end
        f:write(table.concat(lines, "\n"))
        f:close()
        return true
    end
end

-------------------------------------------------
-- MAIN FUNCTION
-------------------------------------------------
local function rename_chapters_to_roman()
    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No " .. DEST_WORD .. "s found.", 2)
        return
    end

    table.sort(chapters, function(a, b) return a.time < b.time end)

    local count = 0
    for _, c in ipairs(chapters) do
        if c.title then
            for _, word in ipairs(MATCH_WORDS) do
                local after = c.title:match("^" .. word .. "%s*(.*)$")
                if after then
                    after = after:gsub("%s+", "")
                    if after == "" or after:match("^%d+$")
                       or after:match("^[A-Za-z]+$") or is_roman(after) then
                        count = count + 1
                        c.title = DEST_WORD .. " " .. count
                        break
                    end
                end
            end
        end
    end

    if count == 0 then
        mp.osd_message("No matching " .. DEST_WORD .. "s found.", 2)
        return
    end

    for _, c in ipairs(chapters) do
        local num = c.title:match("^" .. DEST_WORD .. "%s+(%d+)$")
        if num then
            c.title = DEST_WORD .. " " .. to_roman(tonumber(num))
        end
    end

    mp.set_property_native("chapter-list", chapters)

    local saved = auto_save_chapters()
    local save_status =
        saved and (" and autosaved (" .. AUTO_SAVE_MODE:upper() .. ")")
              or " (auto-save failed)"

    mp.osd_message(
        "Renamed " .. count .. " chapters to " ..
        DEST_WORD .. " I-" .. to_roman(count) .. save_status,
        4
    )
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
mp.add_key_binding("shift+ctrl+a", "rename_chapters_to_roman", rename_chapters_to_roman)

-- Shift+X → Toggle auto-save mode (keybinding handled by create_chapter.lua)
mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
