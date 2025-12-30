local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local AUTO_SAVE_MODE = "xml"   -- "xml" or "chap_txt"
local OFFSET_TIME   = -2       -- Default offset time (in seconds) for the prompt
local SAVE_DEBOUNCE = 0.3      -- Seconds

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function format_time(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02d:%02d:%06.3f", h, m, s)
end

local function make_uid(index)
    return tostring(os.time() * 1000 + index)
end

-------------------------------------------------
-- AUTO-SAVE MODE TOGGLE
-------------------------------------------------
local function toggle_auto_save_mode()
    AUTO_SAVE_MODE = (AUTO_SAVE_MODE == "xml") and "chap_txt" or "xml"
    mp.osd_message("Auto-save mode: " .. AUTO_SAVE_MODE:upper(), 2)
end

-------------------------------------------------
-- AUTO-SAVE (DEBOUNCED)
-------------------------------------------------
local save_timer

local function auto_save_chapters()
    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then return end

    local path = mp.get_property("path")
    if not path then return end

    local dir, name_ext = utils.split_path(path)
    local name = name_ext:gsub("%.%w+$", "")

    if AUTO_SAVE_MODE == "xml" then
        local xml_atoms = {}

        for i, c in ipairs(chapters) do
            table.insert(xml_atoms, string.format([[
  <ChapterAtom>
    <ChapterDisplay>
      <ChapterString>%s</ChapterString>
      <ChapterLanguage>eng</ChapterLanguage>
    </ChapterDisplay>
    <ChapterUID>%s</ChapterUID>
    <ChapterTimeStart>%s</ChapterTimeStart>
  </ChapterAtom>]],
                c.title or "",
                make_uid(i),
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
            os.time(),
            table.concat(xml_atoms, "\n")
        )

        local out_path = utils.join_path(dir, name .. ".xml")
        local file, err = io.open(out_path, "w")
        if not file then
            mp.osd_message("XML save failed: " .. (err or "unknown error"), 2)
            return
        end

        file:write(xml)
        file:close()


    else
        local lines = {}
        for i, c in ipairs(chapters) do
            local num = string.format("%02d", i)
            table.insert(lines, "CHAPTER" .. num .. "=" .. format_time(c.time))
            table.insert(lines, "CHAPTER" .. num .. "NAME=" .. (c.title or ""))
        end

        local out_path = utils.join_path(dir, name .. ".txt")
        local file, err = io.open(out_path, "w")
        if not file then
            mp.osd_message("TXT save failed: " .. (err or "unknown error"), 2)
            return
        end

        file:write(table.concat(lines, "\n"))
        file:close()

    end
end

local function auto_save_chapters_debounced()
    if save_timer then
        save_timer:kill()
    end
    save_timer = mp.add_timeout(SAVE_DEBOUNCE, auto_save_chapters)
end

-------------------------------------------------
-- SNAP CHAPTER TO CURRENT PLAYBACK
-------------------------------------------------
local function snap_chapter_to_playback(direction)
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters found.", 2)
        return
    end

    local current_index
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

    local target_index =
        (direction == "prev") and current_index or
        (direction == "next") and (current_index + 1)

    local target = chapters[target_index]
    if not target or target.time == 0 then
        mp.osd_message("No chapter to snap.", 2)
        return
    end

    target.time = time_pos
    mp.set_property_native("chapter-list", chapters)
    auto_save_chapters_debounced()

    mp.osd_message(
        string.format("Snapped '%s' to %s",
            target.title or "Untitled",
            format_time(time_pos)),
        3
    )
end

-------------------------------------------------
-- SNAP AND SHIFT CHAPTERS
-------------------------------------------------
local function snap_and_shift_chapters(direction)
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters found.", 2)
        return
    end

    local target_index

    if direction == "up" then
        for i = #chapters, 1, -1 do
            if chapters[i].time < time_pos and chapters[i].time ~= 0 then
                target_index = i
                break
            end
        end
    else
        -- nearest NEXT chapter
        for i, c in ipairs(chapters) do
            if c.time > time_pos and c.time ~= 0 then
                target_index = i
                break
            end
        end
    end

    if not target_index then
        mp.osd_message("No chapter found.", 2)
        return
    end

    local target = chapters[target_index]
    local delta = time_pos - target.time
    target.time = time_pos

    for i = target_index + 1, #chapters do
        chapters[i].time = math.max(0, chapters[i].time + delta)
    end

    mp.set_property_native("chapter-list", chapters)
    auto_save_chapters_debounced()

    mp.osd_message(
        string.format("Snapped '%s' and shifted later chapters by %.3f s",
            target.title or "Untitled",
            delta),
        3
    )
end

-------------------------------------------------
-- OFFSET VIA PROMPT (WINDOWS ONLY)
-------------------------------------------------
local function offset_chapters_prompt()
    local res = utils.subprocess({
        args = {
            "powershell", "-NoProfile", "-Command",
            "Add-Type -AssemblyName Microsoft.VisualBasic;" ..
            "[Microsoft.VisualBasic.Interaction]::InputBox('Enter offset in seconds (+/-):','Offset Chapters'," ..
            OFFSET_TIME .. ")"
        }
    })

    if res.status ~= 0 or not res.stdout then
        mp.osd_message("Offset canceled.", 2)
        return
    end

    local offset = tonumber(res.stdout:match("%-?%d+%.?%d*"))
    if not offset then
        mp.osd_message("Invalid number.", 2)
        return
    end

    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters.", 2)
        return
    end

    local shifted = 0
    for _, c in ipairs(chapters) do
        if c.time > 0 then
            c.time = math.max(0, c.time + offset)
            shifted = shifted + 1
        end
    end

    mp.set_property_native("chapter-list", chapters)
    auto_save_chapters_debounced()

    mp.osd_message(
        string.format("Offset %.3f s applied to %d chapters", offset, shifted),
        3
    )
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------

-- Ctrl+Alt+Right → Snap the PREVIOUS chapter to the current playback position
mp.add_key_binding("ctrl+alt+right", "snap_prev_chapter", function()
    snap_chapter_to_playback("prev")
end)

-- Ctrl+Alt+Left → Snap the NEXT chapter to the current playback position
mp.add_key_binding("ctrl+alt+left", "snap_next_chapter", function()
    snap_chapter_to_playback("next")
end)

-- Ctrl+Alt+Up → Snap nearest PREVIOUS chapter and shift ALL later chapters by the same delta
mp.add_key_binding("ctrl+alt+up", "snap_and_shift_up", function()
    snap_and_shift_chapters("up")
end)

-- Ctrl+Alt+Down → Snap nearest NEXT chapter and shift ALL later chapters by the same delta
mp.add_key_binding("ctrl+alt+down", "snap_and_shift_down", function()
    snap_and_shift_chapters("down")
end)

-- Ctrl+O → Prompt for a global offset (seconds) and apply it to ALL chapters (excluding time 0)
mp.add_key_binding("ctrl+o", "offset_chapters_prompt", offset_chapters_prompt)

-- Shift+X → Toggle auto-save mode (keybinding handled by create_chapter.lua)
mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
