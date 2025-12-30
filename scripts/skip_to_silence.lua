----------------------------
-- USER CONFIG
----------------------------
local silence_threshold     = -40   -- dB
local silence_min_duration  = 1.2   -- seconds
----------------------------

local detecting     = false
local normal_speed  = 1
local seek_position = 0.0
local detect_label  = "silencedetect"

-- Remove audio filter if present
local function del_filter()
    local afs = mp.get_property_native("af") or {}
    for i, af in ipairs(afs) do
        if af.label == detect_label then
            table.remove(afs, i)
            mp.set_property_native("af", afs)
            return
        end
    end
end

-- Stop detection and jump
local function stop(jump)
    del_filter()
    detecting = false
    mp.set_property("speed", normal_speed)
    if jump and seek_position > 0 then
        mp.commandv("seek", seek_position, "absolute", "exact")
    end
end

-- Poll metadata
local function poll()
    if not detecting then return end

    local res = mp.get_property_native("af-metadata/" .. detect_label) or {}
    local s_start = tonumber(res["lavfi.silence_start"])

    if s_start then
        seek_position = s_start
        stop(true)
        return
    end

    mp.add_timeout(0.1, poll)
end

-- Add silence detect filter
local function detect()
    del_filter()
    mp.command(string.format(
        'af add @%s:lavfi=[silencedetect=noise=%sdB:d=%s]',
        detect_label, silence_threshold, silence_min_duration
    ))
    mp.add_timeout(silence_min_duration, poll)
end

-- Toggle detection
function toggle_detect()
    if detecting then
        stop(false)
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
mp.add_key_binding("n", "skip_silence", toggle_detect)
