local volume_slider = require("widgets.volume-slider")
local idle_prev = 0
local total_prev = 0

local get_cpu_value = function(stdout)
  local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
    stdout:match('(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s')

  local total = user + nice + system + idle + iowait + irq + softirq + steal

  local diff_idle = idle - idle_prev
  local diff_total = total - total_prev
  local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10
  total_prev = total
  idle_prev = idle
  collectgarbage('collect')
  return diff_usage
end

local function worker(args)
    local idle_prev = 0
    local total_prev = 0


    local args = args or {}
    args.read_only = true
    args.get_volume_cmd = [[bash -c "cat /proc/stat | grep '^cpu '"]]
    args.get_current_value = get_cpu_value
    args.read_only = true
    args.icons = "cpu-64-bit"
    local cpu_widget = volume_slider(args)
    return cpu_widget
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
