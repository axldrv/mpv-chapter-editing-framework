local mp = require("mp")
local msg = require("mp.msg")
local utils = require("mp.utils")

-------------------------------------------------
-- CONFIGURATION
-------------------------------------------------
local MEDIA_EXTS = {
    mp4 = true,
    mkv = true,
    avi = true
}

-------------------------------------------------
-- STATE
-------------------------------------------------
local auto_enabled = false
local playlist_initialized = false

-------------------------------------------------
-- HELPERS
-------------------------------------------------
local function normalize_directory_path(dir)
    if not dir then return "" end
    dir = dir:gsub('^"', ''):gsub('"$', '')
    if not dir:match("[/\\]$") then
        dir = dir .. "\\"
    end
    return dir
end

local function get_media_files_in_directory(dir)
    local entries = utils.readdir(dir, "files") or {}
    local files = {}

    for _, entry in ipairs(entries) do
        if entry ~= "." and entry ~= ".." then
            local ext = entry:match("%.([^.]+)$")
            if ext and MEDIA_EXTS[ext:lower()] then
                table.insert(files, entry)
            end
        end
    end

    table.sort(files, function(a, b)
        return a:lower() < b:lower()
    end)

    return files
end

local function order_files_from_current(files, current_file)
    local start_index = 1

    for i, f in ipairs(files) do
        if f == current_file then
            start_index = i
            break
        end
    end

    local ordered = {}

    for i = start_index, #files do
        table.insert(ordered, files[i])
    end
    for i = 1, start_index - 1 do
        table.insert(ordered, files[i])
    end

    return ordered
end

-------------------------------------------------
-- PLAYLIST MANAGEMENT
-------------------------------------------------
local function add_files_to_playlist(directory, files)
    playlist_initialized = true

    local current_path = mp.get_property("path")
    local current_file = mp.get_property("filename")

    mp.commandv("playlist-clear")
    mp.commandv("loadfile", current_path, "replace", "keep-position=yes")

    for i = 2, #files do
        mp.commandv(
            "loadfile",
            directory .. files[i],
            "append-play"
        )
    end

    local added = #files - 1
    msg.info(
        "Playlist created from " .. current_file ..
        " (" .. added .. " files added)"
    )

    mp.osd_message(
        "Auto-playlist ON. Loaded " .. added .. " files to Playlist.",
        5
    )
end

local function clear_playlist_without_reloading()
    local count = mp.get_property_number("playlist-count", 1)
    local current = mp.get_property_number("playlist-pos", 0)
    local removed = 0

    if count > 1 then
        removed = count - 1
    end

    for i = count - 1, current + 1, -1 do
        mp.commandv("playlist-remove", i)
    end

    for i = current - 1, 0, -1 do
        mp.commandv("playlist-remove", i)
    end

    return removed
end

-------------------------------------------------
-- CORE LOGIC
-------------------------------------------------
local function build_playlist_from_current()
    local path = mp.get_property("path")
    if not path or path == "" then return end
    if not path:find("^%a+:") then return end

    local directory = normalize_directory_path(
        utils.split_path(path)
    )

    local current_file = mp.get_property("filename")
    local files = get_media_files_in_directory(directory)

    if #files == 0 then
        mp.osd_message("No media files found", 3)
        return
    end

    files = order_files_from_current(files, current_file)
    add_files_to_playlist(directory, files)
end

local function toggle_auto_playlist()
    auto_enabled = not auto_enabled

    if auto_enabled then
        playlist_initialized = false
        build_playlist_from_current()
    else
        local removed = clear_playlist_without_reloading()
        playlist_initialized = false

        if removed > 0 then
            mp.osd_message(
                "Auto-playlist OFF. Cleared " ..
                removed .. " files from Playlist.",
                5
            )
        else
            mp.osd_message(
                "Auto-playlist OFF. Playlist was already empty.",
                5
            )
        end
    end
end

-------------------------------------------------
-- AUTO-TRIGGER (ONCE PER SESSION)
-------------------------------------------------
mp.register_event("file-loaded", function()
    if auto_enabled and not playlist_initialized then
        build_playlist_from_current()
    end
end)

-------------------------------------------------
-- KEYBINDING
-------------------------------------------------
mp.add_key_binding("ctrl+alt+p","toggle_auto_playlist",toggle_auto_playlist)
msg.info("Auto-playlist script loaded")
