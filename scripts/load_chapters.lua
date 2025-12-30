local utils = require("mp.utils")
local script_enabled = true
local chapters_loaded = false
local builtin_chapters = nil
local xml_chapters = nil
local xml_mtime = nil

-------------------------------------------------
-- Parse time format, supports long fractions (nanoseconds)
-------------------------------------------------
local function parse_time(time_str)
    local h, m, s, frac = time_str:match("(%d+):(%d+):(%d+)%.?(%d*)")
    h, m, s = tonumber(h), tonumber(m), tonumber(s)
    local ms = 0

    if frac and #frac > 0 then
        -- Convert whatever fraction exists (up to nanoseconds) into milliseconds
        frac = frac .. string.rep("0", math.max(0, 3 - #frac))
        ms = tonumber(frac:sub(1, 3)) or 0
    end

    return h * 3600 + m * 60 + s + ms / 1000
end

-------------------------------------------------
-- Parse chapters from XML file (now accepts newlines!)
-------------------------------------------------
local function parse_xml_chapters(xml_path)
    local chapters = {}
    local file = io.open(xml_path, "r")
    if not file then return chapters end
    local content = file:read("*all")
    file:close()

    -- FIXED: Match across newlines using [%s%S]
    for atom in content:gmatch("<ChapterAtom>([%s%S]-)</ChapterAtom>") do
        local time = atom:match("<ChapterTimeStart>(.-)</ChapterTimeStart>")
        local title = atom:match("<ChapterString>(.-)</ChapterString>") or "Untitled"
        if time then
            table.insert(chapters, { title = title, time = parse_time(time) })
        end
    end

    return chapters
end

-------------------------------------------------
-- Try to load XML chapters if the file exists
-------------------------------------------------
local function load_xml_if_exists()
    local path = mp.get_property("path")
    if not path then return nil end

    local dir, name_ext = utils.split_path(path)
    local name = name_ext:match("(.+)%.%w+$") or name_ext
    local xml_path = utils.join_path(dir, name .. ".xml")

    local info = utils.file_info(xml_path)
    if info then
        if not xml_mtime or xml_mtime ~= info.mtime then
            local parsed = parse_xml_chapters(xml_path)
            if #parsed > 0 then
                xml_chapters = parsed
                xml_mtime = info.mtime
                return xml_chapters
            end
        end
        return xml_chapters
    end

    xml_chapters = nil
    xml_mtime = nil
    return nil
end

-------------------------------------------------
-- Automatically load XML chapters on file load
-------------------------------------------------
local function autoload_xml_chapters()
    if not script_enabled then return end

    builtin_chapters = nil
    xml_chapters = nil
    xml_mtime = nil
    chapters_loaded = false

    builtin_chapters = mp.get_property_native("chapter-list")

    local loaded = load_xml_if_exists()
    if loaded then
        mp.set_property_native("chapter-list", xml_chapters)
        mp.osd_message(string.format("Loaded %d chapters from XML.", #xml_chapters), 2)
        mp.commandv("show-text", "📘 XML Chapters Active", "2000", "top-right")
        chapters_loaded = true
    else
        mp.set_property_native("chapter-list", builtin_chapters or {})
        mp.commandv("show-text", "🎬 Embedded Chapters Active", "2000", "top-right")
    end
end

-------------------------------------------------
-- Toggle between XML and embedded chapters (Ctrl+L)
-------------------------------------------------
local function toggle_chapters()
    if not script_enabled then
        mp.osd_message("❌ XML Chapter Loader is disabled.", 3)
        mp.commandv("show-text", "❌ XML Loader Disabled", "2000", "top-right")
        return
    end

    load_xml_if_exists()

    if not xml_chapters or #xml_chapters == 0 then
        mp.osd_message("No XML chapters found.", 3)
        return
    end

    if builtin_chapters == nil then
        builtin_chapters = mp.get_property_native("chapter-list")
    end

    if chapters_loaded then
        mp.set_property_native("chapter-list", builtin_chapters or {})
        mp.osd_message("Restored embedded chapters.", 3)
        mp.commandv("show-text", "🎬 Embedded Chapters Active", "2000", "top-right")
        chapters_loaded = false
    else
        mp.set_property_native("chapter-list", xml_chapters)
        mp.osd_message("Applied XML chapters.", 3)
        mp.commandv("show-text", "📘 XML Chapters Active", "2000", "top-right")
        chapters_loaded = true
    end
end

-------------------------------------------------
-- Toggle script enable/disable
-------------------------------------------------
local function toggle_script_enabled()
    script_enabled = not script_enabled
    local status = script_enabled and "🟢 XML Chapter Loader Enabled" or "❌ XML Chapter Loader Disabled"
    mp.osd_message(status, 2)
    mp.commandv("show-text", status, "2000", "top-right")

    if not script_enabled then
        if builtin_chapters then
            mp.set_property_native("chapter-list", builtin_chapters)
            chapters_loaded = false
        end
    else
        autoload_xml_chapters()
    end
end

-------------------------------------------------
-- KEYBINDINGS + event registration
-------------------------------------------------
mp.add_key_binding("ctrl+l", "toggle_chapters", toggle_chapters)
mp.add_key_binding("shift+l", "toggle_script_enabled", toggle_script_enabled)
mp.register_event("file-loaded", autoload_xml_chapters)
