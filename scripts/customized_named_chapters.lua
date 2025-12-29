local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local AUTO_SAVE_MODE = "xml" -- "xml" or "chap_txt"
local IGNORED_WORDS = {"Scene"} -- Chapters with this name + numeral will be ignored for count and rename
local ENABLE_CHANGE_TRIGGER = true

-------------------------------------------------
-- SCHEME SETS
-------------------------------------------------
-- Scheme set 1
local schemes1 = {
    label = "", -- Set name is optional
    names_2 = {"Episode", "Credits"},
    names_3 = {"Opening", "Episode", "Credits"},
    names_4 = {"Opening", "Episode", "Credits", "Post-Credits"},
    names_5 = {"Opening", "Previously on...", "Act I", "Act II", "Credits"},
    names_6 = {"Opening", "Previously on...", "Act I", "Act II", "Act III", "Credits"},
    names_7 = {"Opening", "Previously on...", "Act I", "Act II", "Act III", "Act IV", "Credits"},
    names_8 = {"Opening", "Previously on...", "Act I", "Act II", "Act III", "Act IV", "Act V", "Credits"}
}

-- Scheme set 2
local schemes2 = {
    label = "",
    names_2 = {""}, -- Can stay empty if not needed
    names_3 = {"" },
    names_4 = {""},
    names_5 = {"Previously on...", "Opening", "Act I", "Act II", "Credits"},
    names_6 = {"Previously on...", "Opening", "Act I", "Act II", "Act III", "Credits"},
    names_7 = {"Previously on...", "Opening", "Act I", "Act II", "Act III", "Act IV", "Credits"},
    names_8 = {"Previously on...", "Opening", "Act I", "Act II", "Act III", "Act IV", "Act V", "Credits"}
}

-- Add more schemes here if desired
local schemes = { schemes1, schemes2 }

-- Active scheme
local current_scheme_index = 1
local current_schemes = schemes[current_scheme_index]

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function format_time(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local total_ms = math.floor(seconds * 1000 + 0.5)
    local hours = math.floor(total_ms / 3600000)
    local mins  = math.floor((total_ms % 3600000) / 60000)
    local secs  = math.floor((total_ms % 60000) / 1000)
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

local function is_ignored_chapter(title)
    for _, w in ipairs(IGNORED_WORDS) do
        if title:match("^" .. w .. "%s*%d+$") then return true end
    end
    return false
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
    mp.osd_message("Auto-save mode: " .. AUTO_SAVE_MODE:upper(), 2)
end

-------------------------------------------------
-- AUTO-SAVE FUNCTION
-------------------------------------------------
local function auto_save_chapters(count)
    local chapters = mp.get_property_native("chapter-list")
    if not chapters or #chapters == 0 then
        return "No chapters."
    end

    local path = mp.get_property("path")
    if not path then
        return "No file path."
    end

    local dir, name_ext = utils.split_path(path)
    local name = name_ext:gsub("%.%w+$", "")

    if AUTO_SAVE_MODE == "xml" then
        local euid = mp.get_property_number("estimated-frame-count") or os.time()
        local atoms = {}

        for _, c in ipairs(chapters) do
            table.insert(atoms, string.format([[
    <ChapterAtom>
      <ChapterDisplay>
        <ChapterString>%s</ChapterString>
        <ChapterLanguage>eng</ChapterLanguage>
      </ChapterDisplay>
      <ChapterUID>%s</ChapterUID>
      <ChapterTimeStart>%s</ChapterTimeStart>
    </ChapterAtom>]],
                c.title or "",
                make_uid(c),
                format_time(c.time)
            ))
        end

        local xml = string.format([[
<?xml version="1.0" encoding="UTF-8"?>
<Chapters>
  <EditionEntry>
    <EditionFlagHidden>0</EditionFlagHidden>
    <EditionFlagDefault>1</EditionFlagDefault>
    <EditionUID>%s</EditionUID>
%s
  </EditionEntry>
</Chapters>]],
            euid,
            table.concat(atoms, "\n")
        )

        local f, err = io.open(utils.join_path(dir, name .. ".xml"), "w")
        if not f then
            return "XML save failed: " .. (err or "unknown error")
        end

        f:write(xml)
        f:close()
        return count .. " Chapters (XML)"

    else
        local lines = {}
        for i, c in ipairs(chapters) do
            local n = string.format("%02d", i)
            lines[#lines + 1] = "CHAPTER" .. n .. "=" .. format_time(c.time)
            lines[#lines + 1] = "CHAPTER" .. n .. "NAME=" .. (c.title or "")
        end

        local f, err = io.open(utils.join_path(dir, name .. ".txt"), "w")
        if not f then
            return "TXT save failed: " .. (err or "unknown error")
        end

        f:write(table.concat(lines, "\n"))
        f:close()
        return count .. " Chapters (TXT)"
    end
end

-------------------------------------------------
-- RENAME CHAPTERS
-------------------------------------------------
local function rename_show_chapters()
    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then mp.osd_message("No chapters to rename.", 1.5); return end

    table.sort(chapters, function(a,b) return a.time < b.time end)

    local to_rename = {}
    local ignored_count = 0

    for _, c in ipairs(chapters) do
        if is_ignored_chapter(c.title) then
            ignored_count = ignored_count + 1
        else
            to_rename[#to_rename+1] = c
        end
    end

    local count = #to_rename
    if count == 0 then mp.osd_message("No non-ignored chapters to rename.", 2); return end

    local key = "names_" .. count
    local names = current_schemes[key]

    if not names or #names == 0 then
        mp.osd_message("Scheme for " .. count .. " chapters is empty. Skipping.", 5)
        return
    end

    local idx = 1
    for _, c in ipairs(chapters) do
        if not is_ignored_chapter(c.title) then
            c.title = names[idx] or c.title
            idx = idx + 1
        end
    end

    mp.set_property_native("chapter-list", chapters)
    local save_status = auto_save_chapters(count)

    mp.osd_message(
        string.format("Renamed %d custom chapters. Saved %s.\nSkipped %d ignored chapters.",
            count, save_status, ignored_count),
        6
    )
end

-------------------------------------------------
-- AUTO-RENAME
-------------------------------------------------
local debounce_timer
local AUTO_RENAME_ENABLED = false

function schedule_auto_rename()
    if not AUTO_RENAME_ENABLED then return end
    if debounce_timer then debounce_timer:kill() end
    debounce_timer = mp.add_timeout(1.0, function()
        rename_show_chapters()
        debounce_timer = nil
    end)
end

local function toggle_auto_rename()
    AUTO_RENAME_ENABLED = not AUTO_RENAME_ENABLED
    local state = AUTO_RENAME_ENABLED and "ENABLED" or "DISABLED"
    mp.osd_message("Auto-rename (file load & chapter change): " .. state, 2)

    if AUTO_RENAME_ENABLED and ENABLE_CHANGE_TRIGGER then
        mp.observe_property("chapter-list", "native", function()
            if AUTO_RENAME_ENABLED then schedule_auto_rename() end
        end)
    end
end

-------------------------------------------------
-- SCHEME TOGGLE (cycles through all schemes)
-------------------------------------------------
local function toggle_scheme_set()
    current_scheme_index = current_scheme_index + 1
    if current_scheme_index > #schemes then current_scheme_index = 1 end

    current_schemes = schemes[current_scheme_index]

    mp.osd_message(
        "Using scheme set " .. current_scheme_index ..
        (current_schemes.label and current_schemes.label ~= "" and (" (" .. current_schemes.label .. ")") or ""),
        2
    )

    if AUTO_RENAME_ENABLED then schedule_auto_rename() end
end

-------------------------------------------------
-- EVENTS
-------------------------------------------------
mp.register_event("file-loaded", function()
    if AUTO_RENAME_ENABLED then schedule_auto_rename() end
end)

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
mp.add_key_binding("alt+r", "rename_show_chapters", rename_show_chapters)
mp.add_key_binding("ctrl+alt+r", "toggle_auto_rename", toggle_auto_rename)
mp.add_key_binding("ctrl+alt+l", "toggle_scheme_set", toggle_scheme_set)

-- Shift+X → Toggle auto-save mode (keybinding handled by create_chapter.lua)
mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
