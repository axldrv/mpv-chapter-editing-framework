local mp = require "mp"
local utils = require "mp.utils"

-------------------------------------------------
-- AUTO-DETECT mkvextract.exe + mkvpropedit.exe
-------------------------------------------------
local function detect_tool(name)
    local paths = {
        "C:\\Program Files\\MKVToolNix\\" .. name,
        "C:\\Program Files (x86)\\MKVToolNix\\" .. name
    }

    for _, p in ipairs(paths) do
        local f = io.open(p, "rb")
        if f then f:close() return p end
    end

    return nil
end

local MKVEXTRACT = detect_tool("mkvextract.exe") or [[C:\Program Files\MKVToolNix\mkvextract.exe]]
local MKVPROPEDIT = detect_tool("mkvpropedit.exe") or nil

local overwrite_mode = false  -- false = add suffix, true = overwrite

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function run_cmd(tbl)
    local res = mp.command_native({
        name = "subprocess",
        args = tbl,
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
    })
    return res.status == 0, res.stdout, res.stderr
end

local function file_exists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true end
    return false
end

local function show_progress(current, total, filename)
    if total == 0 then
        mp.osd_message("Preparing…", 1)
        return
    end
    local percent = math.floor(current / total * 100)
    local name_only = filename and (filename:match("([^\\/]+)%.mkv$") or filename) or ""
    mp.osd_message(string.format("Extracting chapters… %d%%\n%s", percent, name_only), 1)
end

local function mkvextract_extract(mkv, xml)
    mkv = mkv:gsub('"', '""')
    xml = xml:gsub('"', '""')

    local ps_script = string.format([[
        $ErrorActionPreference = "Stop"
        $mkv = "%s"
        $xml = "%s"
        & "%s" $mkv chapters $xml
    ]], mkv, xml, MKVEXTRACT)

    return run_cmd({"powershell", "-NoLogo", "-NoProfile", "-Command", ps_script})
end

local function get_next_available_xml(base_path)
    if overwrite_mode or not file_exists(base_path) then
        return base_path
    end
    local i = 1
    local name, ext = base_path:match("^(.-)(%.xml)$")
    local candidate = string.format("%s (%d)%s", name, i, ext)
    while file_exists(candidate) do
        i = i + 1
        candidate = string.format("%s (%d)%s", name, i, ext)
    end
    return candidate
end

-------------------------------------------------
-- Extract chapters from current video
-------------------------------------------------
local function extract_chapters_current_video()
    local video_path = mp.get_property("path")
    if not video_path then return mp.osd_message("No file loaded.", 2) end

    local folder = utils.split_path(video_path):gsub("[\\/]+$", "")
    local name = video_path:match("([^\\/]+)%.mkv$")
    if not name then return mp.osd_message("Not an MKV file.", 2) end

    local base_xml = folder .. "\\" .. name .. ".xml"
    local xml = get_next_available_xml(base_xml)

    show_progress(0, 1, video_path)
    local success = mkvextract_extract(video_path, xml)

    if success then
        show_progress(1, 1, video_path)
        mp.msg.info("✓ Extracted chapters: " .. video_path .. " → " .. xml)
    else
        mp.osd_message("Failed extracting chapters.", 3)
    end
end

-------------------------------------------------
-- Extract chapters from all MKVs in the folder
-------------------------------------------------
local function extract_chapters_current_folder()
    local video_path = mp.get_property("path")
    if not video_path then return mp.osd_message("No file loaded.", 2) end

    local folder = utils.split_path(video_path):gsub("[\\/]+$", "")
    mp.osd_message("Scanning MKVs in current folder…", 2)

    local ps_script = string.format([[
        Set-Location -LiteralPath "%s"
        $OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        Get-ChildItem -Filter *.mkv | ForEach-Object { $_.FullName }
    ]], folder)

    local ok, stdout = run_cmd({"powershell", "-NoLogo", "-NoProfile", "-Command", ps_script})
    if not ok then return mp.osd_message("Error scanning folder.", 3) end

    local mkv_list = {}
    for mkv in stdout:gmatch("[^\r\n]+") do table.insert(mkv_list, mkv) end

    if #mkv_list == 0 then return mp.osd_message("No MKV files found.", 3) end

    local count = 0
    local total = #mkv_list

    for i, mkv in ipairs(mkv_list) do
        show_progress(i, total, mkv)

        local name = mkv:match("([^\\/]+)%.mkv$")
        local base_xml = folder .. "\\" .. name .. ".xml"
        local xml = get_next_available_xml(base_xml)

        local ok = mkvextract_extract(mkv, xml)
        if ok then count = count + 1 end
    end

    mp.osd_message("Done. Extracted " .. count .. " XML file(s).", 5)
end

-------------------------------------------------
-- Extract chapters from all MKVs in parent folder (recursively)
-------------------------------------------------
local function extract_chapters_parent_folder()
    local video_path = mp.get_property("path")
    if not video_path then return mp.osd_message("No file loaded.", 2) end

    local folder = utils.split_path(video_path):gsub("[\\/]+$", "")
    local parent_folder = folder:match("^(.*)[\\/][^\\/]+$") or folder

    mp.osd_message("Scanning MKVs in parent folder recursively…", 2)

    local ps_script = string.format([[
        Set-Location -LiteralPath "%s"
        $OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        Get-ChildItem -Recurse -Filter *.mkv | ForEach-Object { $_.FullName }
    ]], parent_folder)

    local ok, stdout = run_cmd({"powershell", "-NoLogo", "-NoProfile", "-Command", ps_script})
    if not ok then return mp.osd_message("Error scanning parent folder.", 3) end

    local mkv_list = {}
    for mkv in stdout:gmatch("[^\r\n]+") do table.insert(mkv_list, mkv) end

    if #mkv_list == 0 then return mp.osd_message("No MKV files found.", 3) end

    local count = 0
    local total = #mkv_list

    for i, mkv in ipairs(mkv_list) do
        show_progress(i, total, mkv)

        local name = mkv:match("([^\\/]+)%.mkv$")
        local mkv_folder = utils.split_path(mkv):gsub("[\\/]+$", "")
        local base_xml = mkv_folder .. "\\" .. name .. ".xml"
        local xml = get_next_available_xml(base_xml)

        local ok = mkvextract_extract(mkv, xml)
        if ok then count = count + 1 end
    end

    mp.osd_message("Done. Extracted " .. count .. " XML file(s) from parent folder.", 5)
end

-------------------------------------------------
-- Toggle overwrite mode
-------------------------------------------------
local function toggle_overwrite_mode()
    overwrite_mode = not overwrite_mode
    local msg = overwrite_mode and "Overwrite existing XMLs" or "Add numeric suffix"
    mp.osd_message("Chapter extraction mode: " .. msg, 3)
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
-- Shift+Ctrl+E → Extract chapters from the currently playing MKV
mp.add_key_binding("shift+ctrl+e", "extract_chapters_current_video", extract_chapters_current_video)

-- Shift+Ctrl+Alt+E → Extract chapters from all MKVs in the current folder
mp.add_key_binding("shift+ctrl+alt+e", "extract_chapters_current_folder", extract_chapters_current_folder)

-- Shift+Ctrl+Alt+U → Extract chapters from all MKVs in the parent folder (recursive)
mp.add_key_binding("shift+ctrl+alt+u", "extract_chapters_parent_folder", extract_chapters_parent_folder)

-- Shift+Ctrl+O → Toggle XML overwrite mode (overwrite vs numeric suffix)
mp.add_key_binding("shift+ctrl+o", "toggle_overwrite_mode", toggle_overwrite_mode)
