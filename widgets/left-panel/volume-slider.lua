-------------------------------------------------
-- Volume Bar Widget for Awesome Window Manager
-- Shows the current volume level
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volumebar-widget

-- @author Pavel Makhov
-- @copyright 2018 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local GET_VOLUME_CMD = 'amixer -D pulse sget Master'
local STEP = 5
local SET_VOLUME_CMD = function(x) return 'amixer -D pulse sset Master ' .. x .. '%' end
local TOG_VOLUME_CMD = 'amixer -D pulse sset Master toggle'
local PATH_TO_ICONS = gears.filesystem.get_configuration_dir() .. "widgets/icons/"
local ICONS = {
    ["default"] = "audio-volume-high-symbolic",
    ["mute"] = "audio-volume-muted-symbolic",
    [0] = "audio-volume-muted-symbolic",
    [1] = "audio-volume-low-symbolic",
    [50] = "audio-volume-medium-symbolic",
    [75] = "audio-volume-high-symbolic"
}
local GET_CURRENT_VALUE = function(stdout)
    local mute = string.match(stdout, "%[(o%D%D?)%]")    -- \[(o\D\D?)\] - [on] or [off]
    local volume = string.match(stdout, "(%d?%d?%d)%%")  -- (\d?\d?\d)\%)
    volume = tonumber(string.format("% 3d", volume))
    return mute == "off" and "mute" or volume
end


local widget = {}

local function worker(args)

    local args = args or {}

    local height = args.height
    local width = args.width
    local progressbar_height = args.progressbar_height
    local icon_height = args.icon_height
    local bar_shape = args.bar_shape or 'rounded_rect'
    local handle_shape = args.handle_shape or 'circle'
    local margins = args.margins or 10

    local get_volume_cmd = args.get_volume_cmd or GET_VOLUME_CMD
    local set_volume_cmd = args.set_volume_cmd or SET_VOLUME_CMD
    local step = args.step or STEP
    local tog_volume_cmd = args.tog_volume_cmd or TOG_VOLUME_CMD
    local path_to_icons = args.path_to_icons or PATH_TO_ICONS
    local icons = args.icons or ICONS
    local get_current_value = args.get_current_value or GET_CURRENT_VALUE

    local get_icon = function(v)
        icon = icons[v] or icons.default or ""
        max_val = nil
        for key, value in pairs(icons) do
            if type(key) == "number" and type(v) == "number" then
                max_val = max_val == nil and key or max_val
                if v >= key and key >= max_val then
                    icon = value
                    max_val = key
                end
            end
        end
        return path_to_icons .. icon .. ".svg"
    end

    local volumeicon_widget = wibox.widget {
        id = "icon",
        image = get_icon(),
        widget = wibox.widget.imagebox,
    }

    local volumeprogressbar_widget = wibox.widget {
        id = "progressbar",
        max_value = 100,
        shape = gears.shape[shape],
        widget = wibox.widget.progressbar,
    }

    local volumeslider_widget = wibox.widget {
        id = "slider",
        maximum = 100,
        bar_height = 0,
        handle_shape = gears.shape[handle_shape],
        widget = wibox.widget.slider
    }

    local volumebar_with_margins = wibox.widget {
        widget = wibox.container.constraint,
        wibox.widget {
            layout = wibox.container.margin,
            wibox.widget {
                wibox.widget {
                    volumeicon_widget,
                    widget = wibox.container.constraint,
                    height = icon_height,
                },
                wibox.widget {
                    wibox.widget {
                        wibox.widget {
                            wibox.widget {
                                volumeprogressbar_widget,
                                widget = wibox.container.constraint,
                                height = progressbar_height,
                            },
                            layout = wibox.container.margin,
                            top = (height - progressbar_height) / 2
                        },
                        layout = wibox.layout.align.vertical
                    },
                    volumeslider_widget,
                    layout = wibox.layout.stack
                },
                layout = wibox.layout.align.horizontal
            }
        },
        top = type(margins) == "table" and margins.top or margins,
        bottom = type(margins) == "table" and margins.bottom or margins,
        left = type(margins) == "table" and margins.left or 0,
        right = type(margins) == "table" and margins.right or 0,
        height = height,
        -- forced_width = width
    }

    local update_graphic = function(widget, stdout, _, _, _)
        local value = get_current_value(stdout)

        volumeicon_widget.image = get_icon(value)
        if type(value) == "number" then
            volumeprogressbar_widget.value = value
            volumeslider_widget.value = value
            volumeslider_widget.visible = true
        else
            volumeprogressbar_widget.value = 0
            volumeslider_widget.visible = false
        end
    end

    volumeslider_widget:connect_signal("property::value", function()
        if value ~= volumeslider_widget.value then
            awful.spawn(set_volume_cmd(volumeslider_widget.value))
            volumeprogressbar_widget.value = volumeslider_widget.value
            volumeicon_widget.image = get_icon(volumeslider_widget.value)
        end
    end)

    volumeicon_widget:connect_signal("button::release", function(_, _, _, button)
        if (button == 1) then
            awful.spawn(tog_volume_cmd)
            spawn.easy_async(
                get_volume_cmd,
                function(stdout, stderr, exitreason, exitcode)
                    update_graphic(volumebar_widget, stdout, stderr, exitreason, exitcode)
                end)
        end
    end)

    volumeslider_widget:connect_signal("button::release", function(_, _, _, button)
        if (button == 4) then
            volumeslider_widget.value = volumeslider_widget.value + step
        elseif (button == 5) then
            volumeslider_widget.value = volumeslider_widget.value - step
        end
    end)

    _,t = watch(get_volume_cmd, 1, update_graphic, volumebar_widget)
    volumebar_with_margins.watchtimer = t
    return volumebar_with_margins
end

return setmetatable(widget, { __call = function(_, ...) return worker(...) end })
