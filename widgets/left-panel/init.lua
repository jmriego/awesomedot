local awful = require('awful')
local beautiful = require('beautiful')
local gears = require("gears")
local wibox = require('wibox')

local with_dpi = beautiful.xresources.apply_dpi

local LeftPanel = function(s, status_bar_height)

    local left_panel = wibox {
        screen = s,
        width=with_dpi(300),
        height = s.geometry.height - status_bar_height,
        x = s.geometry.x,
        y = s.geometry.y + status_bar_height,
        ontop = true
    }

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

    ram_bar = require("widgets.ram-widget")({
        height=with_dpi(32),
        progressbar_height=with_dpi(2)
    })

    temperature_bar = require("widgets.cputemp-widget")({
        height=with_dpi(32),
        progressbar_height=with_dpi(2)
    })

    storage_bar = require("widgets.storage-widget")({
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
                    ram_bar,
                    temperature_bar,
                    storage_bar,
                },
                nil,
                require("widgets.left-panel.exit-button")(),
            },
        },
        ontop = true,
        top=with_dpi(20),
        bottom=with_dpi(10),
        left=with_dpi(10),
        right=with_dpi(20)
    }

    local timers = {
        volume_bar.watchtimer,
        cpu_bar.watchtimer,
        ram_bar.watchtimer,
        temperature_bar.watchtimer,
        storage_bar.watchtimer }
    local review_timers = function()
        for _,t in ipairs(timers) do
            if not left_panel.visible and t.started then
                t:stop()
            elseif left_panel.visible and not t.started then
                t:start()
            end
        end
        return left_panel.visible -- it will make the timer stop checking after this is no longer visible
    end

    left_panel:connect_signal("property::visible", review_timers)
    left_panel:connect_signal("mouse::leave", function()
        left_panel.visible = false
    end)

    gears.timer.start_new(2, review_timers)
    return left_panel
end

return setmetatable({}, { __call = function(_, ...) return LeftPanel(...) end })
