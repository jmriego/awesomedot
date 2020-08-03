local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local cmdwidget = require("widgets.cmdwidget")

local function worker(args)
    local blink_timer = nil
    local completed_tasks_widget = cmdwidget({
            icon="calendar-check",
            visible_fn=function(stdout) return tonumber(stdout)>0 end,
            cmd="task status=completed end=today count",
            popup_cmd="task status=completed end=today all"})
    local due_today_tasks_widget = cmdwidget({
            icon="calendar-alert",
            visible_fn=function(stdout)
                           blink_timer:start()
                           return tonumber(stdout)>0 end,
            cmd="task 'due<=today' status:pending count",
            popup_cmd="task 'due<=today' status:pending all"})
    local inbox_tasks_widget = cmdwidget({
            icon="mailbox-up-outline",
            visible_fn=function(stdout)
                           blink_timer:start()
                           return tonumber(stdout)>0 end,
            cmd="task +in status:pending count",
            popup_cmd="task in"})

    local mytaskswidget =  wibox.widget {
        wibox.widget {
            completed_tasks_widget, due_today_tasks_widget, inbox_tasks_widget,
            layout = wibox.layout.align.horizontal
        },
        widget = wibox.container.background
    }

    local color = "#000000"
    local bg_urgent = beautiful.get().bg_urgent

    local blink_task_widgets = function()
        if due_today_tasks_widget.visible or inbox_tasks_widget.visible then
            color = color == "#000000" and bg_urgent or "#000000"
        else
            color = "#000000"
        end
        mytaskswidget.bg = color
        return due_today_tasks_widget.visible or inbox_tasks_widget.visible 
    end

    blink_timer = gears.timer.start_new(1, blink_task_widgets)
    return mytaskswidget
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
