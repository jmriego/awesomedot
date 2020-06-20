local awful = require('awful')
local beautiful = require('beautiful')
local gears = require("gears")
local wibox = require('wibox')

local with_dpi = beautiful.xresources.apply_dpi

local LeftPanel = function(s)

    left_panel = awful.wibar({ position = "left", screen = s, width=with_dpi(300), visible=false })

    volume_header = wibox.widget {
        markup = 'Audio Settings',
        font = 'Roboto medium 14',
        widget = wibox.widget.textbox
    }

    volume_bar = require("widgets.volume-slider")({
        height=with_dpi(32),
        progressbar_height=with_dpi(2)
    })

    hardware_header = wibox.widget {
        markup = 'Hardware Monitor',
        font = 'Roboto medium 14',
        widget = wibox.widget.textbox
    }

    cpu_bar = require("widgets.cpu-widget")({
        height=with_dpi(32),
        progressbar_height=with_dpi(2)
    })

    left_panel:setup {
        layout = wibox.container.margin,
        { layout = wibox.container.margin,
            {
                layout = wibox.layout.align.vertical,
                wibox.widget {
                    spacing = with_dpi(20),
                    layout = wibox.layout.fixed.vertical,
                    volume_header,
                    volume_bar,
                    hardware_header,
                    cpu_bar,
                    -- hardware_header
                },
                nil,
                require("widgets.left-panel.exit-button"),
            },
        },
        ontop = true,
        top=with_dpi(20),
        bottom=with_dpi(10),
        left=with_dpi(10),
        right=with_dpi(20)
    }

    local timers = { volume_bar.watchtimer, cpu_bar.watchtimer }
    review_timers = function()
        for _,t in ipairs(timers) do
            if not left_panel.visible and t.started then
                t:stop()
            elseif left_panel.visible and not t.started then
                t:start()
            end
        end
        return false -- it will make the timer at startup to stop after the first run
    end

    left_panel:connect_signal("property::visible", review_timers)
    left_panel:connect_signal("mouse::leave", function()
        left_panel.visible = false
    end)

    gears.timer.start_new(2, review_timers)
    return left_panel
end

return LeftPanel
