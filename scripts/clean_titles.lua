local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local AUTO_SAVE_MODE = "xml"  -- "xml" or "chap_txt"
local AUTO_RENAME_ENABLED = false -- disabled by default
local DEBOUNCE_DELAY = 1.0 -- seconds to wait after file load

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

-------------------------------------------------
-- AUTO-SAVE FUNCTION
-------------------------------------------------
local function auto_save_chapters(cleaned_count)
    local chapters = mp.get_property_native("chapter-list")
    if not chapters or #chapters == 0 then
        mp.osd_message("No chapters to save.", 2)
        return
    end

    local count = cleaned_count or #chapters

    local path = mp.get_property("path")
    if not path then
        mp.osd_message("Cannot autosave: no file path.", 2)
        return
    end

    local dir, name_ext = utils.split_path(path)
    local name = name_ext:gsub("%.%w+$", "")

    -------------------------------------------------
    -- XML
    -------------------------------------------------
    if AUTO_SAVE_MODE == "xml" then
        local euid = mp.get_property_number("estimated-frame-count") or 0
        local xml_data = {}

        for _, c in ipairs(chapters) do
            table.insert(xml_data, string.format(
[[  <ChapterAtom>
    <ChapterDisplay>
      <ChapterString>%s</ChapterString>
      <ChapterLanguage>eng</ChapterLanguage>
    </ChapterDisplay>
    <ChapterUID>%s</ChapterUID>
    <ChapterTimeStart>%s</ChapterTimeStart>
  </ChapterAtom>]],
                c.title, make_uid(c), format_time(c.time)
            ))
        end

        local xml_content = string.format(
[[<?xml version="1.0" encoding="UTF-8"?>
<Chapters>
  <EditionEntry>
    <EditionUID>%s</EditionUID>
%s
  </EditionEntry>
</Chapters>]],
            euid, table.concat(xml_data, "\n")
        )

        local xml_path = utils.join_path(dir, name .. ".xml")
        local f, err = io.open(xml_path, "w")

        if f then
            f:write(xml_content)
            f:close()
            mp.osd_message(
    string.format(
        "Saved %d XML chapters (%d cleaned).",
        #chapters,
        cleaned_count or 0
    ),
    3
)
        else
            mp.osd_message("XML save failed: " .. err, 3)
        end

    -------------------------------------------------
    -- CHAP TXT
    -------------------------------------------------
    else
        local lines = {}

        for i, c in ipairs(chapters) do
            local num = string.format("%02d", i)
            table.insert(lines, "CHAPTER" .. num .. "=" .. format_time(c.time))
            table.insert(lines, "CHAPTER" .. num .. "NAME=" .. c.title)
        end

        local txt_path = utils.join_path(dir, name .. ".txt")
        local f, err = io.open(txt_path, "w")

        if f then
            f:write(table.concat(lines, "\n"))
            f:close()
            mp.osd_message(
    string.format(
        "Saved %d TXT chapters (%d cleaned).",
        #chapters,
        cleaned_count or 0
    ),
    3
)
        else
            mp.osd_message("TXT save failed: " .. err, 3)
        end
    end
end

-------------------------------------------------
-- TOGGLE AUTO-SAVE MODE
-------------------------------------------------
local function toggle_auto_save_mode()
    AUTO_SAVE_MODE = (AUTO_SAVE_MODE == "xml") and "chap_txt" or "xml"
    mp.osd_message("Auto-save mode: " .. AUTO_SAVE_MODE:upper(), 2)
end

-------------------------------------------------
-- CLEANUP FUNCTION
-------------------------------------------------
local function cleanup_chapter_titles()
    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters to clean.", 2)
        return
    end

    local cleaned = 0
    for _, c in ipairs(chapters) do
        local original = c.title or ""
        local new_title = original:gsub("^%s*[%(%[]?%s*%d+[%)]?%s*[%._:–-]*%s*", "")
        if new_title ~= original then
            c.title = new_title
            cleaned = cleaned + 1
        end
    end

    if cleaned > 0 then
        mp.set_property_native("chapter-list", chapters)
        mp.osd_message("Cleaned " .. cleaned .. " chapter names.", 2)
        auto_save_chapters(cleaned)
    else
        mp.osd_message("No cleanup needed.", 2)
    end
end

-------------------------------------------------
-- AUTO-TRIGGER ON FILE LOAD
-------------------------------------------------
local debounce_timer = nil

local function schedule_auto_cleanup()
    if not AUTO_RENAME_ENABLED then return end
    if debounce_timer then debounce_timer:kill() end
    debounce_timer = mp.add_timeout(DEBOUNCE_DELAY, function()
        cleanup_chapter_titles()
        debounce_timer = nil
    end)
end

mp.register_event("file-loaded", function()
    if AUTO_RENAME_ENABLED then
        schedule_auto_cleanup()
    end
end)

local function toggle_auto_rename()
    AUTO_RENAME_ENABLED = not AUTO_RENAME_ENABLED
    local state = AUTO_RENAME_ENABLED and "ENABLED" or "DISABLED"
    mp.osd_message("Auto-cleanup on file load: " .. state, 2)
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
mp.add_key_binding("alt+c", "cleanup_chapter_titles", cleanup_chapter_titles)

-- Shift+X → Toggle auto-save mode (keybinding handled by create_chapter.lua)
mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
