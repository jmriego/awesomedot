local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')
local mat_icon = require('widget.material.icon')
local dpi = require('beautiful').xresources.apply_dpi
local icons = require('theme.icons')

local exit_button = wibox.widget {
        {
            image = icons.logout,
            widget = wibox.widget.imagebox
        },
        {
            text = 'End work session',
            font = 'Roboto medium 13',
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.align.horizontal,
        forced_height = dpi(24)
}

exit_button:buttons(
  awful.util.table.join(
    awful.button(
      {},
      1,
      function()
        panel:toggle()
        _G.exit_screen_show()
      end
    )
  )
)

return exit_button
