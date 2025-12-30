local mp = require "mp"
local utils = require "mp.utils"

-- margin in seconds to handle floating-point imprecision and small overlaps
local MARGIN = 1.50
-- OSD message duration (in seconds)
local OSD_DURATION = 3.0

-- Helper function: show chapter name or fallback message
local function show_chapter_message(prefix, chapter)
    local name = (chapter and chapter.title) and chapter.title or "(Untitled Chapter)"
    mp.osd_message(string.format("%s: %s", prefix, name), OSD_DURATION)
end

-- Jump to the previous chapter (with margin tolerance)
local function goto_previous_chapter()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters available", OSD_DURATION)
        return
    end

    for i = #chapters, 1, -1 do
        if chapters[i].time < time_pos - MARGIN then
            mp.set_property_number("time-pos", chapters[i].time)
            show_chapter_message("Jumped to previous chapter", chapters[i])
            return
        end
    end

    mp.osd_message("Already at first chapter", OSD_DURATION)
end

-- Jump to the next chapter
local function goto_next_chapter()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local chapters = mp.get_property_native("chapter-list") or {}
    if #chapters == 0 then
        mp.osd_message("No chapters available", OSD_DURATION)
        return
    end

    for i = 1, #chapters do
        if chapters[i].time > time_pos + MARGIN then
            mp.set_property_number("time-pos", chapters[i].time)
            show_chapter_message("Jumped to next chapter", chapters[i])
            return
        end
    end

    mp.osd_message("Already at last chapter", OSD_DURATION)
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
mp.add_key_binding("ctrl+left", "goto_previous_chapter", goto_previous_chapter)
mp.add_key_binding("ctrl+right", "goto_next_chapter", goto_next_chapter)
