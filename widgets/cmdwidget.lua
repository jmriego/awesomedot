local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local PATH_TO_ICONS = gears.filesystem.get_configuration_dir() .. "widgets/icons/"

local FREQUENCY = 30
local FONT = 'Ubuntu Mono medium 12'

local function worker(args)
    local args = args or {}

    local frequency = args.frequency or FREQUENCY
    local font = args.font or FONT
    local cmd = args.cmd
    local popup_cmd = args.popup_cmd or cmd
    local path_to_icons = args.path_to_icons or PATH_TO_ICONS
    local icon = args.icon or ""
    local visible_fn = args.visible_fn or function(stdout) return true end
    local markup_fn = args.markup_fn or function(stdout) return '<span color="#ffffff">' .. stdout .. '</span>' end

    local icon_cmdwidget = wibox.widget {
        id = "icon",
        image = path_to_icons .. icon .. ".svg",
        widget = wibox.widget.imagebox,
    }

    local text_widget = wibox.widget {
        font = font,
        widget = wibox.widget.textbox,
        ignore_markup = false
    }

    local horizontal_layout = wibox.widget {
        icon_cmdwidget, text_widget,
        layout = wibox.layout.align.horizontal
    }

    local widget_popup =
      awful.tooltip(
      {
        objects = {horizontal_layout},
        font = font,
        mode = 'outside',
        align = 'right',
        preferred_positions = {'right', 'left', 'top', 'bottom'}
      }
    )

    local update_widget = function(stdout, _, _, _)
        text_widget.markup = markup_fn(stdout)
        horizontal_layout.stdout = stdout
        horizontal_layout.visible = visible_fn(stdout)
    end

    local run_command = function()
        spawn.easy_async(
            cmd,
            function(stdout, stderr, exitreason, exitcode)
                update_widget(stdout, stderr, exitreason, exitcode)
            end)
        spawn.easy_async(
            popup_cmd,
            function(stdout, stderr, exitreason, exitcode)
                widget_popup.text = string.gsub(string.gsub(stdout, '\n$', ''), '^\n', '')
            end)
        return true
    end
    run_command()

    text_widget.watchtimer = gears.timer.start_new(frequency, run_command)
    horizontal_layout.icon_cmdwidget = icon_cmdwidget
    horizontal_layout.text_widget = text_widget
    return horizontal_layout
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
