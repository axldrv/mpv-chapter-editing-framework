local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIG
-------------------------------------------------
local AUTO_SAVE_MODE = "xml"        -- "xml" | "chap_txt"
local AUTO_RENAME_ENABLED = false  -- disabled by default
local DEBOUNCE_DELAY = 1.0          -- seconds

local WORD_MAP = {
    ["Old Title 1"]      = "New Title 1",
    ["Old Title 2"]      = "New Title 2",
}

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function plural(n, singular, plural)
    return n == 1 and singular or plural
end

local function format_time(seconds)
    seconds = tonumber(seconds) or 0
    if seconds < 0 then seconds = 0 end
    local total_ms = math.floor(seconds * 1000 + 0.5)
    local h = math.floor(total_ms / 3600000)
    local m = math.floor((total_ms % 3600000) / 60000)
    local s = math.floor((total_ms % 60000) / 1000)
    local ms = total_ms % 1000
    return string.format("%02d:%02d:%02d.%03d", h, m, s, ms)
end

local function make_uid(chapter)
    local seed = (chapter.title or "") .. "|" .. tostring(chapter.time or 0)
    local hash = 0
    for i = 1, #seed do
        hash = (hash * 131 + seed:byte(i)) % 2147483647
    end
    if hash == 0 then hash = 1 end
    return tostring(hash)
end

local function get_output_paths()
    local path = mp.get_property("path")
    if not path then return nil end
    local dir, name_ext = utils.split_path(path)
    local name = name_ext:gsub("%.%w+$", "")
    return dir, name
end

-------------------------------------------------
-- AUTO-SAVE
-------------------------------------------------
local function auto_save_chapters(show_osd)
    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then return end

    local dir, name = get_output_paths()
    if not dir then return end

    if AUTO_SAVE_MODE == "xml" then
        local euid = mp.get_property_number("estimated-frame-count") or os.time()
        local atoms = {}

        for _, c in ipairs(chapters) do
            table.insert(atoms, string.format(
[[    <ChapterAtom>
  <ChapterDisplay>
    <ChapterString>%s</ChapterString>
    <ChapterLanguage>eng</ChapterLanguage>
  </ChapterDisplay>
  <ChapterUID>%s</ChapterUID>
  <ChapterTimeStart>%s</ChapterTimeStart>
  <ChapterFlagHidden>0</ChapterFlagHidden>
  <ChapterFlagEnabled>1</ChapterFlagEnabled>
    </ChapterAtom>]],
                c.title or "",
                make_uid(c),
                format_time(c.time)
            ))
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
</Chapters>]],
    euid,
    table.concat(atoms, "\n")
)
        local f = io.open(utils.join_path(dir, name .. ".xml"), "w")
        if f then
            f:write(xml)
            f:close()
            if show_osd then mp.osd_message("Auto-saved XML chapters", 2) end
        end
    else
        local lines = {}
        for i, c in ipairs(chapters) do
            local n = string.format("%02d", i)
            lines[#lines+1] = "CHAPTER" .. n .. "=" .. format_time(c.time)
            lines[#lines+1] = "CHAPTER" .. n .. "NAME=" .. (c.title or "")
        end

        local f = io.open(utils.join_path(dir, name .. ".txt"), "w")
        if f then
            f:write(table.concat(lines, "\n"))
            f:close()
            if show_osd then mp.osd_message("Auto-saved TXT chapters", 2) end
        end
    end
end

-------------------------------------------------
-- RENAME VIA WORD MAP (CASE-SENSITIVE, FULL MATCH)
-------------------------------------------------
local function rename_chapters_by_map()
    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters to rename.", 1.5)
        return
    end

    local renamed = 0
    local used = {}
    local used_list = {}

    for _, c in ipairs(chapters) do
        if c.title then
            for from, to in pairs(WORD_MAP) do
                if c.title == from then
                    c.title = to
                    renamed = renamed + 1
                    if not used[from] then
                        used[from] = true
                        table.insert(used_list, from)
                    end
                end
            end
        end
    end

    if renamed > 0 then
        mp.set_property_native("chapter-list", chapters)
        auto_save_chapters(false)
        mp.osd_message(
            string.format(
                "Found & Replaced %d %s (%s)",
                renamed,
                plural(renamed, "chapter", "chapters"),
                table.concat(used_list, ", ")
            ),
            5
        )
    else
        mp.osd_message("No chapters found to replace.", 3)
    end
end

-------------------------------------------------
-- AUTO-RENAME ON FILE LOAD (DEBOUNCED)
-------------------------------------------------
local debounce_timer = nil

local function schedule_auto_rename()
    if not AUTO_RENAME_ENABLED then return end
    if debounce_timer then debounce_timer:kill() end
    debounce_timer = mp.add_timeout(DEBOUNCE_DELAY, function()
        rename_chapters_by_map()
        debounce_timer = nil
    end)
end

mp.register_event("file-loaded", schedule_auto_rename)

-------------------------------------------------
-- TOGGLE
-------------------------------------------------
local function toggle_auto_rename()
    AUTO_RENAME_ENABLED = not AUTO_RENAME_ENABLED
    local state = AUTO_RENAME_ENABLED and "ENABLED" or "DISABLED"
    mp.osd_message("Find & Replace auto-rename: " .. state, 2)

    if AUTO_RENAME_ENABLED then
        schedule_auto_rename()
    else
        if debounce_timer then
            debounce_timer:kill()
            debounce_timer = nil
        end
    end
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
mp.add_key_binding("alt+f", "rename_now", rename_chapters_by_map)
mp.add_key_binding("ctrl+f", "toggle_auto_rename", toggle_auto_rename)

mp.add_key_binding("shift+x", "toggle_save_mode", function()
    mp.commandv("script-message", "toggle_auto_save_mode")
end)

mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
