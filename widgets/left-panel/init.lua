local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local with_dpi = beautiful.xresources.apply_dpi

local LeftPanel = function(s)

    left_panel = awful.wibar({ position = "left", screen = s, width=with_dpi(300) })

    mytextclock = wibox.widget.textclock()

    left_panel:setup {
        layout = wibox.layout.align.vertical,
        mytextclock,
        nil,
        require("widgets.left-panel.exit-button"),
    }

    return left_panel
end

return LeftPanel
