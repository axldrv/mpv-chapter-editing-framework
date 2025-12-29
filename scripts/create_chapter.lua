local mp = require("mp")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local CHAPTER_PREFIX = "Chapter"     -- Base name applied to new chapters (updated when cycling prefixes with Ctrl+SPACE)
local CHAPTER_DEFAULT = "Chapter 1"  -- Default chapter name applied to timestamp 00:00:000 (updated when cycling with Shift+P)
local DUPLICATE_MARGIN = 0.5         -- seconds: ignore if too close to another chapter
local AUTO_SAVE_MODE = "xml"         -- "xml" or "chap_txt"

-------------------------------------------------
-- CHANGE CHAPTER PREFIX
-------------------------------------------------
local CHAPTER_PREFIXES = { "Chapter", "Scene", "Act", "Part", "Episode", "Credits"} -- Prefix list used when cycling chapter names (Ctrl+SPACE) 
local current_prefix_index = 1

local function cycle_chapter_prefix()
    current_prefix_index = current_prefix_index + 1
    if current_prefix_index > #CHAPTER_PREFIXES then current_prefix_index = 1 end
    CHAPTER_PREFIX = CHAPTER_PREFIXES[current_prefix_index]
    mp.osd_message("Chapter Name set to: " .. CHAPTER_PREFIX, 3)
end

local CHAPTER_DEFAULTS = { "Chapter 1", "Cold Open", "Previously on...", "Opening" } -- Optional names for the chapter at timestamp 00:00:000 (cycled with Shift+P)
local current_default_index = 1

local function cycle_chapter_default()
    current_default_index = current_default_index + 1
    if current_default_index > #CHAPTER_DEFAULTS then current_default_index = 1 end
    CHAPTER_DEFAULT = CHAPTER_DEFAULTS[current_default_index]
    mp.osd_message("00:00:000-Chapter-Name set to: " .. CHAPTER_DEFAULT, 4)
end

-------------------------------------------------
-- PREFIXES THAT SHOULD NOT HAVE NUMBERS
-------------------------------------------------
local NO_NUMBER_PREFIXES = { "Episode", "Credits" } -- Chapters with these prefixes are created without a trailing number (e.g., "Credits" instead of "Credits 1")

local function prefix_needs_number(prefix)
    for _, p in ipairs(NO_NUMBER_PREFIXES) do
        if p == prefix then return false end
    end
    return true
end

-------------------------------------------------
-- HELPERS
-------------------------------------------------

-- Required for Windows InputBox to work safely

local function escape_quotes(str)

    return (str or ""):gsub("'", "''"):gsub('"', '""')

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

local function format_time(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local total_ms = math.floor(seconds * 1000 + 0.5)
    local hours = math.floor(total_ms / 3600000)
    local mins = math.floor((total_ms % 3600000) / 60000)
    local secs = math.floor((total_ms % 60000) / 1000)
    local msecs = total_ms % 1000
    return string.format("%02d:%02d:%02d.%03d", hours, mins, secs, msecs)
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
-- EXPORT MANUAL HELPERS
-------------------------------------------------
local function write_chapter_txt()
    local all_chapters = mp.get_property_native("chapter-list")
    if not all_chapters or #all_chapters == 0 then
        mp.osd_message("No chapters to export.", 2)
        return
    end
    local lines = {}
    for _, c in ipairs(all_chapters) do
        table.insert(lines, format_time(c.time).." - "..c.title)
    end
    local path = mp.get_property("path")
    if not path then mp.osd_message("No file path available.", 2); return end
    local dir, name_ext = utils.split_path(path)
    local name = name_ext:gsub("%.%w+$", "")
    local out_path = utils.join_path(dir, name.."_chapters.txt")
    local file = io.open(out_path, "w")
    if not file then
        mp.osd_message("Error: cannot create TXT file", 2)
        return
    end
    file:write(table.concat(lines, "\n"))
    file:close()
    mp.osd_message("TXT exported: "..out_path, 2)
end

local function write_chapter_chap_txt()
    local all_chapters = mp.get_property_native("chapter-list")
    if not all_chapters or #all_chapters == 0 then
        mp.osd_message("No chapters to export.", 2)
        return
    end
    local lines = {}
    for i, c in ipairs(all_chapters) do
        local num = string.format("%02d", i)
        table.insert(lines, "CHAPTER"..num.."="..format_time(c.time))
        table.insert(lines, "CHAPTER"..num.."NAME="..c.title)
    end
    local path = mp.get_property("path")
    if not path then mp.osd_message("No file path available.", 2); return end
    local dir, name_ext = utils.split_path(path)
    local name = name_ext:gsub("%.%w+$", "")
    local out_path = utils.join_path(dir, name..".txt")
    local file = io.open(out_path, "w")
    if not file then
        mp.osd_message("Error: cannot create CHAP TXT file", 2)
        return
    end
    file:write(table.concat(lines, "\n"))
    file:close()
    mp.osd_message("CHAP TXT exported: "..out_path, 2)
end

-------------------------------------------------
-- CREATE CHAPTER (AUTO-NUMBERED)
-------------------------------------------------
local function create_chapter()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local all_chapters = mp.get_property_native("chapter-list") or {}

    -- normalize near-zero times
    for _, c in ipairs(all_chapters) do
        if math.abs(c.time or 0) < 0.05 then c.time = 0.0 end
    end

    -- prevent duplicates
    for _, c in ipairs(all_chapters) do
        if math.abs(c.time - time_pos) < DUPLICATE_MARGIN then
            mp.osd_message(CHAPTER_PREFIX.." already exists near "..format_time(time_pos), 1.5)
            return
        end
    end

    -- ensure a 00:00 chapter exists
    local has_zero = false
    for _, c in ipairs(all_chapters) do
        if math.abs(c.time - 0.0) < 0.05 then has_zero = true; break end
    end
    if not has_zero then
        table.insert(all_chapters, { title = CHAPTER_DEFAULT, time = 0.0 })
    end

    -- insert empty title (will be auto-numbered)
    table.insert(all_chapters, { title = "", time = time_pos })

    -- sort chapters
    table.sort(all_chapters, function(a,b) return a.time < b.time end)

    -- find insertion index
    local insert_index = 1
    for i, c in ipairs(all_chapters) do
        if math.abs(c.time - time_pos) < 0.001 then
            insert_index = i
            break
        end
    end

    -- detect previous number of the same prefix
    local prev_num = 0
    for i = insert_index - 1, 1, -1 do
        local num = all_chapters[i].title:match(CHAPTER_PREFIX.." (%d+)")
        if num then
            prev_num = tonumber(num)
            break
        end
    end

-- renumber the inserted chapter and all following chapters with the same prefix
if prefix_needs_number(CHAPTER_PREFIX) then
    local chapter_index = prev_num + 1
    for i = insert_index, #all_chapters do
        local c = all_chapters[i]
        if c.title == "" or c.title:match("^"..CHAPTER_PREFIX.." %d+$") then
            c.title = CHAPTER_PREFIX.." "..chapter_index
            chapter_index = chapter_index + 1
        end
    end
else
    -- no numbering for this prefix (e.g. "Credits")
    all_chapters[insert_index].title = CHAPTER_PREFIX
end


    mp.set_property_native("chapter-list", all_chapters)
    auto_save_chapters()
    mp.osd_message(CHAPTER_PREFIX.." added at "..format_time(time_pos), 1.5)
end

-------------------------------------------------
-- CREATE CHAPTER (TIMESTAMP AS NAME)
-------------------------------------------------
local function create_chapter_with_time()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local all_chapters = mp.get_property_native("chapter-list") or {}

    -- prevent duplicates
    for _, c in ipairs(all_chapters) do
        if math.abs(c.time - time_pos) < DUPLICATE_MARGIN then
            mp.osd_message(CHAPTER_PREFIX.." already exists near "..format_time(time_pos), 1.5)
            return
        end
    end

    -- ensure first timestamp chapter at 00:00 if empty
    if #all_chapters == 0 then
        table.insert(all_chapters, { title = format_time(0), time = 0 })
    end

    local chapter_title = format_time(time_pos)
    table.insert(all_chapters, { title = chapter_title, time = time_pos })

    table.sort(all_chapters, function(a,b) return a.time < b.time end)
    mp.set_property_native("chapter-list", all_chapters)
    auto_save_chapters()
    mp.osd_message(CHAPTER_PREFIX.." added at "..chapter_title, 1.5)
end

-------------------------------------------------
-- DELETE AND RENAME FUNCTIONS
-------------------------------------------------
local function delete_previous_chapter()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end
    local all_chapters = mp.get_property_native("chapter-list") or {}
    if #all_chapters == 0 then
        mp.osd_message("No "..CHAPTER_PREFIX.."s to delete.", 1.5)
        return
    end

    -- Find previous chapter
    local prev_index = nil
    for i, c in ipairs(all_chapters) do
        if c.time <= time_pos then prev_index = i else break end
    end
    if not prev_index then
        mp.osd_message("No previous "..CHAPTER_PREFIX.." found.", 1.5)
        return
    end

    -- Detect prefix of the deleted chapter
    local deleted_prefix, deleted_number = all_chapters[prev_index].title:match("^(.-) (%d+)$")
    table.remove(all_chapters, prev_index)

    -- Renumber subsequent chapters with the same prefix
    if deleted_prefix and deleted_number then
        local number = tonumber(deleted_number)
        for i = prev_index, #all_chapters do
            local c = all_chapters[i]
            local c_prefix, c_num = c.title:match("^(.-) (%d+)$")
            if c_prefix == deleted_prefix then
                c.title = c_prefix .. " " .. tostring(number)
                number = number + 1
            end
        end
    end

    mp.set_property_native("chapter-list", all_chapters)
    auto_save_chapters()
    mp.osd_message("Previous "..CHAPTER_PREFIX.." deleted.", 1.5)
end

local function rename_all_chapters()
    local all_chapters = mp.get_property_native("chapter-list") or {}
    local count = #all_chapters
    if count == 0 then
        mp.osd_message("No "..CHAPTER_PREFIX.."s to rename.", 1.5)
        return
    end

    table.sort(all_chapters, function(a,b) return a.time < b.time end)

    if all_chapters[1].time > 0.05 then
        table.insert(all_chapters, 1, { title = CHAPTER_DEFAULT, time = 0.0 })
        count = count + 1
    end

    for i, c in ipairs(all_chapters) do
        c.title = string.format(CHAPTER_PREFIX.." %01d", i)
    end

    mp.set_property_native("chapter-list", all_chapters)
    auto_save_chapters()
    mp.osd_message("Renamed "..count.." "..CHAPTER_PREFIX.."s.", 2)
end

local function rename_chapters_with_time()
    local all_chapters = mp.get_property_native("chapter-list") or {}
    if #all_chapters == 0 then mp.osd_message("No "..CHAPTER_PREFIX.."s to rename.", 1.5); return end
    table.sort(all_chapters, function(a,b) return a.time < b.time end)
    local cleaned = {}
    local last_time = -999
    for _, c in ipairs(all_chapters) do
        local t = c.time or 0.0
        if math.abs(t) < 0.05 then t = 0.0 end
        if math.abs(t - last_time) >= DUPLICATE_MARGIN then
            table.insert(cleaned, { title = format_time(t), time = t })
            last_time = t
        end
    end
    if #cleaned == 0 or cleaned[1].time > 0.05 then
        table.insert(cleaned, 1, { title = format_time(0), time = 0.0 })
    end
    mp.set_property_native("chapter-list", cleaned)
    auto_save_chapters()
    mp.osd_message("Renamed "..#cleaned.." "..CHAPTER_PREFIX.."s to timestamps.", 2)
end

-------------------------------------------------
-- INPUTBOX FOR CHAPTER PREFIX
-------------------------------------------------

local function ask_chapter_prefix()
    local res = utils.subprocess({
        args = {
            "powershell", "-NoProfile", "-Command",
            "Add-Type -AssemblyName Microsoft.VisualBasic;" ..
            string.format(
                "[Microsoft.VisualBasic.Interaction]::InputBox('Set chapter prefix:', 'Chapter Prefix', '%s')",
                escape_quotes(CHAPTER_PREFIX or "")
            )
        },
        cancellable = false
    })

    if res.status == 0 then
        local prefix = (res.stdout or ""):gsub("[\r\n]+", "")
        if prefix ~= "" then
            CHAPTER_PREFIX = prefix
            mp.osd_message("Prefix set to '"..CHAPTER_PREFIX.."'", 2)
        else
            mp.osd_message("Prefix unchanged", 2)
        end
    end
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
-- C → Add chapter with auto-numbering (Chapter 1, 2, ...)
mp.add_key_binding("c", "create_chapter", create_chapter, {repeatable=true})

-- Shift+C → Add chapter with timestamp title (00:01:23.456)
mp.add_key_binding("shift+c", "create_chapter_with_time", create_chapter_with_time, {repeatable=true})

-- Shift+D → Delete the previous (or current) chapter
mp.add_key_binding("shift+d", "delete_previous_chapter", delete_previous_chapter, {repeatable=false})

-- Shift+R → Rename all chapters sequentially ("Chapter N, …")
mp.add_key_binding("shift+r", "rename_all_chapters", rename_all_chapters, {repeatable=false})

-- Shift+M → Rename all chapters with their timestamps
mp.add_key_binding("shift+m", "rename_chapters_with_time", rename_chapters_with_time, {repeatable=false})

-- Shift+B → Export/save chapters to XML (manual; auto-save runs on changes too)
mp.add_key_binding("shift+b", "write_chapter_xml", auto_save_chapters, {repeatable=false})

-- Shift+T → Export chapters to a human-readable TXT file (manual)
mp.add_key_binding("shift+t", "write_chapter_txt", write_chapter_txt, {repeatable=false})

-- H → Export chapters to mp4 compatible format (manual)
mp.add_key_binding("h", "write_chapter_chap_txt", write_chapter_chap_txt, {repeatable=false})

-- Ctrl+SPACE → Cycle through Chapter prefixes
mp.add_key_binding("ctrl+SPACE",  cycle_chapter_prefix, {repeatable=false})

-- Shift+P → Cycle through 1st Chapter prefixes
mp.add_key_binding("shift+p", "cycle_chapter_default", cycle_chapter_default, {repeatable=false})

-- Ctrl+Q → Asks for default chapter name
mp.add_key_binding("ctrl+q", "ask_chapter_prefix", ask_chapter_prefix)

-- Shift+X → Toggle auto-save mode (XML ↔ CHAP TXT)
mp.add_key_binding("shift+x", "toggle_auto_save", function()
    mp.commandv("script-message", "toggle_auto_save_mode")
end)

mp.register_script_message("toggle_auto_save_mode", toggle_auto_save_mode)
