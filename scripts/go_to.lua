local mp = require("mp")
local utils = require("mp.utils")

local function escape_quotes(str)
    return (str or ""):gsub("'", "''"):gsub('"', '""')
end

-- Ask user for a timestamp (via PowerShell InputBox)
local function ask_timestamp(default_time)
    local res = utils.subprocess({
        args = {
            "powershell", "-NoProfile", "-Command",
            "Add-Type -AssemblyName Microsoft.VisualBasic;" ..
            string.format(
                "[Microsoft.VisualBasic.Interaction]::InputBox('Go to time (HH:MM:SS.mmm or seconds):', 'Go To Time', '%s')",
                escape_quotes(default_time or "")
            )
        },
        cancellable = false
    })

    if res.status == 0 then
        return (res.stdout or ""):gsub("[\r\n]+", "")
    end
    return nil
end

-- Convert HH:MM:SS.mmm or MM:SS.mmm or seconds to numeric seconds
local function parse_time(input)
    if not input or input == "" then return nil end
    input = input:gsub(",", ".")  -- accept comma as decimal

    local parts = {}
    for part in input:gmatch("[^:]+") do
        table.insert(parts, part)
    end

    local seconds = 0
    if #parts == 3 then
        seconds = tonumber(parts[1] or 0) * 3600 + tonumber(parts[2] or 0) * 60 + tonumber(parts[3] or 0)
    elseif #parts == 2 then
        seconds = tonumber(parts[1] or 0) * 60 + tonumber(parts[2] or 0)
    elseif #parts == 1 then
        seconds = tonumber(parts[1] or 0)
    else
        return nil
    end
    return seconds
end

-- Go to user-specified timestamp
local function go_to_time()
    local input = ask_timestamp()
    if not input or input == "" then
        mp.osd_message("Go to time canceled.")
        return
    end

    local seconds = parse_time(input)
    if not seconds then
        mp.osd_message("Invalid time format!")
        return
    end

    mp.set_property_number("time-pos", seconds)
    mp.osd_message("Jumped to "..input)
end

-------------------------------------------------
-- KEYBINDINGS
-------------------------------------------------
-- Shift+G to open Go To box
mp.add_key_binding("shift+g", "go_to_time", go_to_time, {repeatable=false})
