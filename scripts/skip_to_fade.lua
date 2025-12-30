----------------------------
-- USER CONFIG
----------------------------
local duration  = 1.5   -- minimum black duration in seconds
local threshold = 1.0   -- how dark (0.0–1.0) the frame must be
----------------------------

local detecting     = false
local normal_speed  = 1
local seek_position = 0.0
local detect_label  = "blackdetect"

-- Remove blackdetect filter if present
local function del_filter()
    local vfs = mp.get_property_native("vf") or {}
    for i, vf in ipairs(vfs) do
        if vf.label == detect_label then
            table.remove(vfs, i)
            mp.set_property_native("vf", vfs)
            return
        end
    end
end

-- Stop detection
-- jump = true  → seek to detected black
-- jump = false → just stop scanning
local function stop(jump)
    del_filter()
    detecting = false
    mp.set_property("speed", normal_speed)

    if jump and seek_position > 0 then
        mp.commandv("seek", seek_position, "absolute", "exact")
    end
end

-- Poll blackdetect metadata
local function poll()
    if not detecting then return end

    local res = mp.get_property_native("vf-metadata/" .. detect_label) or {}
    local black_start = tonumber(res["lavfi.black_start"])

    if black_start then
        seek_position = black_start
        stop(true)
        return
    end

    mp.add_timeout(duration, detect)
end

-- Add blackdetect filter
function detect()
    if not detecting then return end

    del_filter()
    mp.command(string.format(
        'vf add @%s:lavfi=graph="blackdetect=d=%s:pic_th=%s"',
        detect_label, duration, threshold
    ))

    mp.add_timeout(duration, poll)
end

-- Toggle detection
function toggle_detect()
    if detecting then
        stop(false)  -- manual stop, no seek
    else
        detecting = true
        seek_position = 0
        normal_speed = mp.get_property_native("speed")
        mp.set_property("speed", 50)
        detect()
    end
end

-------------------------------------------------
-- KEYBINDING
-------------------------------------------------
mp.add_key_binding("g", "skip_scene", toggle_detect)
