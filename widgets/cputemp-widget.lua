local volume_slider = require("widgets.volume-slider")
local max_temp = 80

local get_temperature_value = function(stdout)
    local temp = stdout:match('(%d+)')
    collectgarbage('collect')
    return ((temp / 1000) / max_temp * 100)
end

local function worker(args)
    local args = args or {}
    widget_mount = args.mount or widget_mount
    args.read_only = true
    args.get_volume_cmd = [[bash -c "cat /sys/class/thermal/thermal_zone0/temp"]]
    args.get_current_value = get_temperature_value
    args.read_only = true
    args.icons = "thermometer"
    local storage_widget = volume_slider(args)
    return storage_widget
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
