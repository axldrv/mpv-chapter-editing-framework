local mp = require "mp"
local utils = require "mp.utils"

-------------------------------------------------
-- Auto-detect mkvpropedit.exe
-------------------------------------------------
local function autodetect_mkvpropedit()
    local paths = {
        [[C:\Program Files\MKVToolNix\mkvpropedit.exe]],
        [[C:\Program Files (x86)\MKVToolNix\mkvpropedit.exe]]
    }
    for _, p in ipairs(paths) do
        local f = io.open(p, "rb")
        if f then f:close() return p end
    end
    return nil
end

local MKVPROPEDIT = autodetect_mkvpropedit()
if not MKVPROPEDIT then
    mp.osd_message("mkvpropedit.exe NOT FOUND!", 5)
    mp.msg.error("mkvpropedit.exe not found in Program Files or Program Files (x86)")
end

-------------------------------------------------
-- Auto-detect mkvextract.exe (for chapter backup)
-------------------------------------------------
local function autodetect_mkvextract()
    local paths = {
        [[C:\Program Files\MKVToolNix\mkvextract.exe]],
        [[C:\Program Files (x86)\MKVToolNix\mkvextract.exe]]
    }
    for _, p in ipairs(paths) do
        local f = io.open(p, "rb")
        if f then f:close(); return p end
    end
    return nil
end

local MKVEXTRACT = autodetect_mkvextract()

-------------------------------------------------
-- Auto-detect MP4Box.exe
-------------------------------------------------
local function autodetect_mp4box()
    local paths = {
        [[C:\Program Files\GPAC\MP4Box.exe]],
        [[C:\Program Files (x86)\GPAC\MP4Box.exe]],
        [[C:\MP4Box\MP4Box.exe]],
    }
    for _, p in ipairs(paths) do
        local f = io.open(p, "rb")
        if f then f:close() return p end
    end
    return nil
end

local MP4BOX = autodetect_mp4box()
if not MP4BOX then
    mp.msg.warn("MP4Box.exe not found – MP4 chapter editing will be disabled.")
end

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function file_exists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true end
    return false
end

local function is_valid_xml(path)
    local f = io.open(path, "rb")
    if not f then return false end
    local data = f:read("*a")
    f:close()
    data = data:gsub("\239\187\191","") -- remove BOM
    return data:match("<%s*Chapters%s*>") ~= nil
end

local function run_cmd(cmd_table)
    local res = mp.command_native({
        name = "subprocess",
        args = cmd_table,
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
    })
    return (res.status == 0), res.stdout, res.stderr
end

-- Safe path escaping for PowerShell
local function escape_ps_path(path)
    -- Replace single quotes with two single quotes (PowerShell escaping)
    return path:gsub("'", "''")
end

-- Recycle XML/TXT files by folder
local function recycle_xml_txt_in_folder(folder)
    local ps = string.format([[
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8
Add-Type -AssemblyName Microsoft.VisualBasic
Set-Location -LiteralPath '%s'
$xml = @(Get-ChildItem -File -Filter *.xml)
$txt = @(Get-ChildItem -File -Filter *.txt)
if ($xml.Count -eq 0 -and $txt.Count -eq 0) { 'XML=0'; 'TXT=0'; exit 0 }
foreach($f in $xml){ [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f.FullName,'OnlyErrorDialogs','SendToRecycleBin') }
foreach($f in $txt){ [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f.FullName,'OnlyErrorDialogs','SendToRecycleBin') }
'XML=' + $xml.Count
'TXT=' + $txt.Count
]], escape_ps_path(folder))

    return run_cmd({
        "powershell.exe",
        "-NoLogo", "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command", ps
    })
end

-------------------------------------------------
-- MKV chapter updater
-------------------------------------------------
local function mkvpropedit_update(mkv, chapters_file)
    if not MKVPROPEDIT then
        mp.osd_message("mkvpropedit.exe NOT found.", 4)
        return false
    end

    mkv = mkv:gsub('"', '""')
    chapters_file = chapters_file:gsub('"', '""')

    local ps_script = string.format([[
        $ErrorActionPreference = "Stop"
        $mkv = "%s"
        $chap = "%s"
        & "%s" "--chapters" $chap $mkv
    ]], mkv, chapters_file, MKVPROPEDIT)

    local ok, stdout, stderr = run_cmd({"powershell", "-NoLogo", "-NoProfile", "-Command", ps_script})
    if not ok then
        mp.msg.error("mkvpropedit failed:\n" .. tostring(stderr or ""))
    end
    return ok
end

-------------------------------------------------
-- Universal chapter updater (MKV + MP4)
-------------------------------------------------
local function update_chapters(video, chapter_file)
    local ext = video:match("%.([^.]+)$")
    if not ext then
        mp.osd_message("Could not detect file extension.", 3)
        return false
    end
    ext = ext:lower()

    if ext == "mkv" then
        local is_xml = chapter_file:lower():match("%.xml$")
        if is_xml and not is_valid_xml(chapter_file) then
            mp.osd_message("Invalid XML chapter file: " .. chapter_file, 3)
            return false
        end
        return mkvpropedit_update(video, chapter_file)

    elseif ext == "mp4" then
        if not MP4BOX then
            mp.osd_message("MP4Box.exe NOT found – cannot update MP4 chapters.", 4)
            return false
        end

        local vid = video:gsub('"', '""')
        local chap = chapter_file:gsub('"', '""')

        local ps_script = string.format([[
            $ErrorActionPreference = "Stop"
            & "%s" -chap "%s" "%s"
        ]], MP4BOX, chap, vid)

        return run_cmd({"powershell", "-NoLogo", "-NoProfile", "-Command", ps_script})
    end

    mp.osd_message("Unsupported format: " .. ext, 3)
    return false
end

-------------------------------------------------
-- OSD progress
-------------------------------------------------
local function show_progress(current, total, action, fullname)
    if total == 0 then
        mp.osd_message("Preparing…", 1)
        return
    end
    local percent = math.floor(current / total * 100)
    if fullname then
        local name_only = fullname:match("([^\\/]+)$") or fullname
        mp.osd_message(string.format("%s… %d%%\n%s", action, percent, name_only), 1)
    else
        mp.osd_message(string.format("%s… %d%%", action, percent), 1)
    end
end

-------------------------------------------------
-- Replace chapters recursively (MKV + MP4)
-------------------------------------------------
local function replace_chapters_recursive()
    local video_path = mp.get_property("path")
    if not video_path then
        mp.osd_message("No file loaded.", 2)
        return
    end

    local current_folder = utils.split_path(video_path):gsub("[\\/]+$", "")
    local parent = current_folder:match("^(.*)[\\/][^\\/]+$") or current_folder

    mp.osd_message("Scanning video files recursively…", 2)

    -- Use PowerShell with proper UTF-8 encoding and safe path handling
    local ps_script = string.format([[
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Use -LiteralPath to handle special characters
$startDir = '%s'

# Build list of MKV and MP4 files
$videoFiles = @()
Get-ChildItem -LiteralPath $startDir -Recurse -File -Filter "*.mkv" | ForEach-Object {
    $videoFiles += $_.FullName
}
Get-ChildItem -LiteralPath $startDir -Recurse -File -Filter "*.mp4" | ForEach-Object {
    $videoFiles += $_.FullName
}

# Output each file on its own line
foreach ($file in $videoFiles) {
    Write-Output $file
}
]], escape_ps_path(parent))

    local ok, stdout, stderr = run_cmd({"powershell", "-NoLogo", "-NoProfile", "-Command", ps_script})
    if not ok then
        mp.msg.error("Error scanning folders: " .. tostring(stderr or ""))
        mp.osd_message("Error scanning folders.", 3)
        return
    end

    local video_list = {}
    for v in stdout:gmatch("[^\r\n]+") do
        table.insert(video_list, v)
    end

    local total = #video_list
    if total == 0 then
        mp.osd_message("No MKV/MP4 files found.", 2)
        return
    end

    local count_updated = 0
    local scanned_folders = {}

    for i, vid in ipairs(video_list) do
        show_progress(i, total, "Updating chapters", vid)

        local folder = vid:match("^(.*[\\/])") or ""
        scanned_folders[folder] = true

        local base = vid:match("([^\\/]+)%.[^%.]+$")
        local ext = vid:match("%.([^.]+)$")
        ext = ext and ext:lower() or ""

        local chapter_file = nil
        if ext == "mkv" then
            local xml = folder .. base .. ".xml"
            if file_exists(xml) and is_valid_xml(xml) then
                chapter_file = xml
            end
        elseif ext == "mp4" then
            local txt = folder .. base .. ".txt"
            if file_exists(txt) then
                chapter_file = txt
            end
        end

        if chapter_file and update_chapters(vid, chapter_file) then
            count_updated = count_updated + 1
        end
    end

    local folder_list = {}
    for f,_ in pairs(scanned_folders) do
        table.insert(folder_list, f)
    end
    table.sort(folder_list)

    mp.osd_message(
        string.format("Done. Updated %d of %d file(s).\n\nScanned folders:\n%s",
            count_updated, total, table.concat(folder_list, "\n")),
        math.max(5, #folder_list)
    )
end

-------------------------------------------------
-- Toggle replace mode
-------------------------------------------------
local replace_mode_all = false
local function toggle_replace_mode()
    replace_mode_all = not replace_mode_all
    local mode_text = replace_mode_all and "All videos (MKV+MP4) in folder" or "Only current video"
    mp.osd_message("Replace chapters mode: " .. mode_text, 2)
end

-------------------------------------------------
-- Replace chapters in current folder (or only current file)
-------------------------------------------------
local function replace_chapters_current_folder()
    local video_path = mp.get_property("path")
    if not video_path then
        mp.osd_message("No file loaded.", 2)
        return
    end

    local current_folder = utils.split_path(video_path):gsub("[\\/]+$", "")

    if replace_mode_all then
        mp.osd_message("Scanning MKV/MP4 in current folder…", 4)

        local ps_script = string.format([[
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$currentDir = '%s'
$videoFiles = @()
Get-ChildItem -LiteralPath $currentDir -File -Filter "*.mkv" | ForEach-Object {
    $videoFiles += $_.FullName
}
Get-ChildItem -LiteralPath $currentDir -File -Filter "*.mp4" | ForEach-Object {
    $videoFiles += $_.FullName
}

foreach ($file in $videoFiles) {
    Write-Output $file
}
]], escape_ps_path(current_folder))

        local ok, stdout, stderr = run_cmd({"powershell", "-NoLogo", "-NoProfile", "-Command", ps_script})
        if not ok then
            mp.msg.error("Error scanning folder: " .. tostring(stderr or ""))
            mp.osd_message("Error scanning folder.", 3)
            return
        end

        local video_list = {}
        for v in stdout:gmatch("[^\r\n]+") do
            table.insert(video_list, v)
        end

        local total = #video_list
        local count = 0

        for i, vid in ipairs(video_list) do
            show_progress(i, total, "Updating chapters", vid)

            local base = vid:match("([^\\/]+)%.[^%.]+$")
            local ext = vid:match("%.([^.]+)$")
            ext = ext and ext:lower() or ""

            local chapter_file = nil
            if ext == "mkv" then
                local xml = utils.join_path(current_folder, base .. ".xml")
                if file_exists(xml) and is_valid_xml(xml) then
                    chapter_file = xml
                end
            elseif ext == "mp4" then
                local txt = utils.join_path(current_folder, base .. ".txt")
                if file_exists(txt) then
                    chapter_file = txt
                end
            end

            if chapter_file and update_chapters(vid, chapter_file) then
                count = count + 1
            end
        end

        mp.osd_message("Done. Updated " .. count .. " file(s) in current folder.", 5)

    else
        local base = video_path:match("([^\\/]+)%.[^%.]+$")
        local ext = video_path:match("%.([^.]+)$")
        ext = ext and ext:lower() or ""

        local chapter_file = nil
        if ext == "mkv" then
            local xml = utils.join_path(current_folder, base .. ".xml")
            if file_exists(xml) and is_valid_xml(xml) then
                chapter_file = xml
            end
        elseif ext == "mp4" then
            local txt = utils.join_path(current_folder, base .. ".txt")
            if file_exists(txt) then
                chapter_file = txt
            end
        end

        if chapter_file then
            if update_chapters(video_path, chapter_file) then
                mp.osd_message("Updated chapters for current video.", 3)
            else
                mp.osd_message("Failed to update chapters.", 3)
            end
        else
            mp.osd_message("No matching chapter file for current video.", 3)
        end
    end
end

-------------------------------------------------
-- Move XML + TXT recursively (smart OSD messages)
-------------------------------------------------
local function move_chapter_files_recursive()
    local video_path = mp.get_property("path")
    if not video_path then
        mp.osd_message("No file loaded.", 2)
        return
    end

    local current_folder = utils.split_path(video_path):gsub("[\\/]+$", "")
    local parent = current_folder:match("^(.*)[\\/][^\\/]+$") or current_folder

    mp.osd_message("Deleting chapter files recursively…", 2)

    local ps_script = string.format([[
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName Microsoft.VisualBasic

$startDir = '%s'
$affected = New-Object System.Collections.Generic.HashSet[string]

$xmlCount = 0
$txtCount = 0

Get-ChildItem -LiteralPath $startDir -Recurse -File |
Where-Object { $_.Extension -in '.xml','.txt' } |
ForEach-Object {
    try {
        if ($_.Extension -eq '.xml') { $xmlCount++ }
        elseif ($_.Extension -eq '.txt') { $txtCount++ }

        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
            $_.FullName,
            'OnlyErrorDialogs',
            'SendToRecycleBin'
        )

        $affected.Add($_.Directory.FullName) | Out-Null
    } catch {
        Write-Error "Failed to delete: $_"
    }
}

Write-Output "XML=$xmlCount"
Write-Output "TXT=$txtCount"
Write-Output "FOLDERS:"

foreach ($folder in ($affected | Sort-Object)) {
    Write-Output $folder
}
]], escape_ps_path(parent))

    local ok, stdout, stderr = run_cmd({
        "powershell.exe",
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command", ps_script
    })

    if not ok then
        mp.msg.error("PowerShell error: " .. tostring(stderr or ""))
        mp.osd_message("Error deleting chapter files.", 4)
        return
    end

    local folders = {}
    local in_list = false
    local xml = 0
    local txt = 0

    for line in stdout:gmatch("[^\r\n]+") do
        if line:match("^XML=") then
            xml = tonumber(line:match("XML=(%d+)")) or 0
        elseif line:match("^TXT=") then
            txt = tonumber(line:match("TXT=(%d+)")) or 0
        elseif line == "FOLDERS:" then
            in_list = true
        elseif in_list and line ~= "" then
            table.insert(folders, line)
        end
    end

    if xml == 0 and txt == 0 then
        mp.osd_message("No XML or TXT chapter files found.", 4)
        return
    end

    local total = xml + txt
    local folder_label = (#folders == 1) and "Folder affected:" or "Folders affected:"

    mp.osd_message(
        string.format(
            "Deleted %d file(s)\nXML: %d | TXT: %d\n\n%s\n%s",
            total, xml, txt,
            folder_label,
            table.concat(folders, "\n")
        ),
        math.max(5, #folders + 3)
    )
end

-------------------------------------------------
-- Move XML + TXT in current folder (smart OSD messages)
-------------------------------------------------
local function move_chapter_files_current_folder()
    local video_path = mp.get_property("path")
    if not video_path then mp.osd_message("No file loaded.", 2) return end

    local folder = utils.split_path(video_path):gsub("[\\/]+$", "")
    mp.osd_message("Deleting XML/TXT in this folder…", 2)

    local ok, stdout, stderr = recycle_xml_txt_in_folder(folder)
    if not ok then
        mp.msg.error("Delete failed: " .. tostring(stderr or ""))
        mp.osd_message("Error deleting chapter files.", 5)
        return
    end

    local xml = tonumber((stdout or ""):match("XML=(%d+)")) or 0
    local txt = tonumber((stdout or ""):match("TXT=(%d+)")) or 0

    if xml == 0 and txt == 0 then
        mp.osd_message("No XML or TXT chapter files found.", 3)
    elseif xml > 0 and txt > 0 then
        mp.osd_message(string.format("Deleted %d XML and %d TXT file(s).", xml, txt), 5)
    elseif xml > 0 then
        mp.osd_message(string.format("Deleted %d XML file(s).", xml), 5)
    else
        mp.osd_message(string.format("Deleted %d TXT file(s).", txt), 5)
    end
end

-------------------------------------------------
-- Backup and clear chapters from current MKV file
-------------------------------------------------
local function clear_chapters_current_file()
    local video_path = mp.get_property("path")
    if not video_path then
        mp.osd_message("No file loaded.", 2)
        return
    end

    if not video_path:lower():match("%.mkv$") then
        mp.osd_message("Chapter clearing is only supported for MKV.", 4)
        return
    end

    if not MKVPROPEDIT or not MKVEXTRACT then
        mp.osd_message("MKVToolNix tools not found.", 4)
        return
    end

    local chapters = mp.get_property_native("chapter-list")
    if not chapters or #chapters == 0 then
        mp.osd_message("No chapters to back up.", 3)
        return
    end

    local dir, name_ext = utils.split_path(video_path)
    local base = name_ext:gsub("%.mkv$", "")
    local backup = utils.join_path(dir, base .. ".chapters.backup.xml")

    if file_exists(backup) then
        mp.osd_message("Backup already exists:\n" .. backup, 4)
        return
    end

    mp.osd_message("Backing up chapters…", 2)

    local ok = run_cmd({
        MKVEXTRACT, video_path, "chapters", backup
    })

    if not ok or not file_exists(backup) then
        mp.osd_message("Failed to back up chapters.", 4)
        return
    end

    mp.osd_message("Backup created. Clearing chapters…", 2)

    local cleared = run_cmd({
        MKVPROPEDIT, video_path, "--chapters", ""
    })

    if cleared then
        mp.set_property_native("chapter-list", {})
        mp.osd_message("Backup saved.\n\nChapters cleared.", 5)
    else
        mp.osd_message("Failed to clear chapters.", 3)
    end
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
-- ctrl+alt+t → Toggle replace mode (Only current video / All videos in folder)
mp.add_key_binding("ctrl+alt+t", "toggle_replace_mode", toggle_replace_mode)

-- shift+ctrl+alt+m → Replace chapters recursively in all subfolders (MKV+MP4)
mp.add_key_binding("shift+ctrl+alt+m", "replace_chapters_recursive", replace_chapters_recursive)

-- ctrl+alt+m → Replace chapters in current folder (depends on mode, MKV+MP4)
mp.add_key_binding("ctrl+alt+m", "replace_chapters_current_folder", replace_chapters_current_folder)

-- shift+ctrl+alt+d → Move all XML/TXT chapter files in all subfolders to recycle bin
mp.add_key_binding("shift+ctrl+alt+d", "move_chapter_files_recursive", move_chapter_files_recursive)

-- ctrl+alt+d → Move XML/TXT chapter files in current folder to recycle bin
mp.add_key_binding("ctrl+alt+d", "move_chapter_files_current_folder", move_chapter_files_current_folder)

-- shift+ctrl+del → Clear all chapters from current MKV video
mp.add_key_binding("shift+ctrl+del", "clear_chapters_current_file", clear_chapters_current_file)
