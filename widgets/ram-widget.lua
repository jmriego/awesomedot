local volume_slider = require("widgets.volume-slider")

local total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap

local get_ram_value = function(stdout)
    total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap =
        stdout:match('(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*Swap:%s*(%d+)%s*(%d+)%s*(%d+)')

    return math.floor((total-used) / (total+total_swap) * 100 + 0.5)
end

local function worker(args)
    local args = args or {}
    args.read_only = true
    args.get_volume_cmd = [[bash -c "LANGUAGE=en_US.UTF-8 free | grep -z Mem.*Swap.*"]]
    args.get_current_value = get_ram_value
    args.read_only = true
    args.icons = "memory"
    local ram_widget = volume_slider(args)
    return ram_widget
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
