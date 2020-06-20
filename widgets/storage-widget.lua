local volume_slider = require("widgets.volume-slider")

local widget_mount = '/'
local disks = {}

local get_storage_value = function(stdout)
    for line in stdout:gmatch("[^\r\n$]+") do
      local filesystem, size, used, avail, perc, mount =
        line:match('([%p%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d]+)%%%s+([%p%w]+)')
  
      disks[mount]            = {}
      disks[mount].filesystem = filesystem
      disks[mount].size       = size
      disks[mount].used       = used
      disks[mount].avail      = avail
      disks[mount].perc       = perc
      disks[mount].mount      = mount
    end
    return tonumber(disks[widget_mount].perc)
end

local function worker(args)
    local args = args or {}
    widget_mount = args.mount or widget_mount
    args.read_only = true
    args.get_volume_cmd = [[bash -c "df | tail -n +2"]]
    args.get_current_value = get_storage_value
    args.read_only = true
    args.icons = "harddisk"
    local storage_widget = volume_slider(args)
    return storage_widget
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
