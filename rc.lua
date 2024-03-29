-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
local tyrannical = require("tyrannical")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")
-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

local with_dpi = beautiful.xresources.apply_dpi
local get_dpi = beautiful.xresources.get_dpi

require("spotify")
client_utils = require("client_utils")
apps = require("apps")

awful.client.property.persist("startup", "boolean")
awful.client.property.persist("disp", "string")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Setup some tags
-- {{{ Tyrannical Tags
tyrannical.tags = {
    {
        name        = "Code",                 -- Call the tag "Term"
        icon   = gears.filesystem.get_configuration_dir() .. "material-awesome/theme/icons/code-braces.svg",
        init        = true,                   -- Load the tag on startup
        exclusive   = true,                   -- Refuse any other type of clients (by classes)
        screen      = screen.count()>1 and {2,3} or {1},
        floating    = false,
        layout      = awful.layout.suit.tile, -- Use the tile layout
        force_screen = true,
        on_select   = function() client_utils.run_once(apps.terminal.cmd, apps.code.rules) end,
        class       = { --Accept the following classes, refuse everything else (because of "exclusive=true")
            "xterm" , "urxvt" , "aterm","URxvt","XTerm","konsole","terminator","gnome-terminal", "Dbeaver", "Java", "jetbrains-idea"
        }
    } ,
    {
        name        = "Mail",                 -- Call the tag "Mail"
        icon   = gears.filesystem.get_configuration_dir() .. "material-awesome/theme/icons/ship-wheel.svg",
        init        = true,                   -- Load the tag on startup
        on_select   = function()
                client_utils.run_once(apps.gmail.cmd, apps.gmail.rules)
                client_utils.run_once(apps.calendar.cmd, apps.calendar.rules)
            end,
        exclusive   = true,                   -- Refuse any other type of clients (by classes)
        screen      = {1},
        layout      = awful.layout.suit.max, -- Use the tile layout
        force_screen = true,
        floating    = false, -- Use the tile layout
        instance = {apps.gmail.rules.instance, apps.calendar.rules.instance},
    } ,
    {
        name        = "Internet",
        icon   = gears.filesystem.get_configuration_dir() .. "material-awesome/theme/icons/google-chrome.svg",
        init        = true,
        exclusive   = true,
        screen      = screen.count()>2 and {1,3} or {1,2},-- Setup on screen 2 if there is more than 1 screen, else on screen 1
        on_select   = function() client_utils.run_once(apps.chrome.cmd, apps.internet.rules) end,
        screen      = screen.count()>1 and {2,3} or {1},
        floating    = false,
        layout      = awful.layout.suit.max,      -- Use the max layout
        force_screen = true,
        class = {
            "Opera"         , "Firefox"        , "Rekonq"    , "Dillo"        , "Arora",
            "Google-chrome", "nightly"   , "minefield" }
    } ,
    {
        name        = "Comms",
        icon   = gears.filesystem.get_configuration_dir() .. "material-awesome/theme/icons/forum.svg",
        screen      = {1},
        on_select   = function() client_utils.run_once(apps.slack.cmd, apps.slack.rules) end,
        init        = true, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        layout      = awful.layout.suit.tile,
        force_screen = true,
        floating    = false,
        instance = {apps.google_chat.rules.instance},
        class = { "slack", "zoom", "Zoom" }
    } ,
    {
        name        = "Others",
        icon   = gears.filesystem.get_configuration_dir() .. "material-awesome/theme/icons/flask.svg",
        screen      = {1,2,3},
        fallback    = true,
        floating    = true,
        init        = true, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        layout      = awful.layout.suit.floating
    } ,
}

-- Ignore the tag "exclusive" property for the following clients (matched by classes)
tyrannical.properties.intrusive = {
    "ksnapshot"     , "pinentry"       , "gtksu"     , "kcalc"        , "xcalc"               ,
    "feh"           , "Gradient editor", "About KDE" , "Paste Special", "Background color"    ,
    "kcolorchooser" , "plasmoidviewer" , "Xephyr"    , "kruler"       , "plasmaengineexplorer",
    "Gnome-screenshot"
}

-- Ignore the tiled layout for the matching clients
tyrannical.properties.floating = {
    "MPlayer"      , "pinentry"        , "ksnapshot"  , "pinentry"     , "gtksu"          ,
    "xine"         , "feh"             , "kmix"       , "kcalc"        , "xcalc"          ,
    "yakuake"      , "Select Color$"   , "kruler"     , "kcolorchooser", "Paste Special"  ,
    "New Form"     , "Insert Picture"  , "kcharselect", "mythfrontend" , "plasmoidviewer"
}

-- Make the matching clients (by classes) on top of the default layout
tyrannical.properties.ontop = {
    "Xephyr"       , "ksnapshot"       , "kruler"
}

-- Force the matching clients (by classes) to be centered on the screen on init
tyrannical.properties.placement = {
    kcalc = awful.placement.centered
}

tyrannical.settings.block_children_focus_stealing = true --Block popups ()
tyrannical.settings.group_children = true --Force popups/dialogs to have the same tags as the parent client

-- }}}

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.max,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after =  { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = {
                  menu_awesome,
                  { "Debian", debian.menu.Debian_menu.Debian },
                  menu_terminal,
                }
    })
end

mylauncher = awful.widget.button({image = beautiful.awesome_icon})
mylauncher:connect_signal(
    'button::release',
    function()
        awful.screen.focused().left_panel.visible = not awful.screen.focused().left_panel.visible
    end
)

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mybatterywidget = require("widgets.battery")
    local horizontal_layout = wibox.widget {
        icon_cmdwidget, text_widget,
        layout = wibox.layout.align.horizontal
    }

local mytaskswidget = require("widgets.taskwarrior")()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock('<span color="#ffffff" font="Ubuntu medium 10"> %d %b %H:%M </span>', 5)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        style = {
            font = "0"
        },
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox
    status_bar_height = with_dpi(18)
    s.mywibox = awful.wibar({ position = "top", screen = s, height=status_bar_height })

    s.left_panel = require("widgets.left-panel")(s, status_bar_height)

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            s.index == 1 and mybatterywidget,
            s.index == 1 and mytextclock,
            s.index == 1 and wibox.widget.systray(),
            mytaskswidget,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewprev),
    awful.button({ }, 5, awful.tag.viewnext),
    awful.button({ }, 6, function() awful.client.focus.byidx(-1) end),
    awful.button({ }, 7, function() awful.client.focus.byidx( 1) end),
    awful.button({ modkey }, 4, awful.tag.viewprev),
    awful.button({ modkey }, 5, awful.tag.viewnext)
))
-- }}}

rofi= 'rofi --dpi ' .. get_dpi() .. ' -yoffset ' .. status_bar_height .. ' -width ' .. with_dpi(400) .. ' -show combi -combi-modi window,drun -theme ' .. gears.filesystem.get_configuration_dir() .. '/rofi.rasi'

sloppyfocus_active = true

-- {{{ Key bindings
globalkeys = gears.table.join(

    awful.key({ modkey }, "F1",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey }, "h",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey }, "l",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey, "Shift"   }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Client Focus by direction
    awful.key({ modkey, "Control" }, "h", function () awful.client.focus.global_bydirection("left", client.focus, true) end,
              {description = "focus the client left of the focused", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.client.focus.global_bydirection("down", client.focus, true) end,
              {description = "focus the client down of the focused", group = "client"}),
    awful.key({ modkey, "Control" }, "k", function () awful.client.focus.global_bydirection("up", client.focus, true) end,
              {description = "focus the client up of the focused", group = "client"}),
    awful.key({ modkey, "Control" }, "l", function () awful.client.focus.global_bydirection("right", client.focus, true) end,
              {description = "focus the client right of the focused", group = "client"}),

    awful.key({ modkey, "Control" }, "f", function () sloppyfocus_active = not sloppyfocus_active end,
              {description = "toggle sloppy focus follow mouse", group = "client"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),

    awful.key({ modkey }, ".",
              function() end,
              function ()
                  client_utils.run_or_raise(apps.chrome.cmd, apps.chrome.rules)
                  gears.timer.start_new(
                      0.2,
                      function ()
                          root.fake_input("key_press", "Control_L")
                          root.fake_input("key_press", "period")
                          root.fake_input("key_release", "period")
                          root.fake_input("key_release", "Control_L")
                          return false
                      end)
              end,
              {description = "choose chrome tab", group = "launcher"}),

    awful.key({ modkey, "Control" }, "r", function()
        client_utils.backup_clients_screen()
        awesome.restart()
        end,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey, "Mod1"   }, "Escape", naughty.destroy_all_notifications,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "Right",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "Left",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "Left",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "Right",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "Left",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "Right",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "Return", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "Return", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),

    -- Menubar replaced with Rofi
    awful.key({ modkey }, "space", function() awful.util.spawn(rofi) end,
              {description = "show the menubar", group = "launcher"}),

    awful.key({ }, "XF86AudioMute", function () awful.util.spawn("amixer -D pulse sset Master toggle") end, false),
    awful.key({ }, "XF86AudioLowerVolume", function () awful.util.spawn("amixer -D pulse sset Master 5%-") end, false),
    awful.key({ }, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer -D pulse sset Master 5%+") end, false),
    awful.key({ }, "XF86AudioPlay", sendToSpotify("PlayPause")), --  XF86AudioPlay
    awful.key({ }, "XF86AudioNext", sendToSpotify("Next")), -- XF86AudioNext
    awful.key({ }, "XF86AudioPrev", sendToSpotify("Previous")) -- XF86AudioPrev
)

clientkeys = gears.table.join(
    awful.key({ modkey, "Mod1" }, "Return",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey }, "f",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen(); c:jump_to()  end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),

    awful.key({ modkey, "Shift"   }, "F1", function (c) naughty.notify({ title = c.name:gsub('[^%g%s]',''), text = "{class=" .. c.class .. ", instance=" .. c.instance .. ", role=" .. (c.role or "") .."}" }) end,
              {description = "show client details", group = "client"}),

    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)


-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local c = client.focus
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              c:move_to_tag(tag)
                              client_utils.serialise_screen_tags(c)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local c = client.focus
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              c:toggle_tag(tag)
                              client_utils.serialise_screen_tags(c)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

local is_screen_connected = function(name)
    for s in screen do
        for out, _ in pairs (s.outputs) do
            if gears.string.startswith(tostring(out), name)
              or tostring(out) == string.gsub(name, "-", "-1-", 1) then
                return tostring(out)
            end
        end
    end
    return false
end

local laptop_screen = "eDP-1"
local main_screen = "DP-1"
local second_screen = "DP-3"
local screen_shortcuts_preferences = {
    [second_screen] = "uiop[",
    [main_screen]   = "jkl;'",
    [laptop_screen] = "m,./"
}

-- assign the tag shortcuts to each found screen following the table above
-- the screen name can be eDP-1-1 instead of eDP-1 so we need to verify every name just in case
local screen_tag_shortcuts = {}
for screen_name, shortcuts in pairs(screen_shortcuts_preferences) do
    local screen_found = is_screen_connected(screen_name)
    if screen_found then
        screen_tag_shortcuts[screen_found] = shortcuts
    end
end

-- if we didnt assign the jkl; keys to the main screen, try to assign it to the second screen or the laptop screen instead
if not gears.table.hasitem(screen_tag_shortcuts, screen_shortcuts_preferences[main_screen]) then
    for _, screen_name in ipairs({second_screen, laptop_screen}) do
        local screen_found = is_screen_connected(screen_name)
        if screen_found then
            screen_tag_shortcuts[screen_found] = screen_shortcuts_preferences[main_screen]
        end
    end
end

for s in screen do
    local tag_shortcuts = nil
    for out, _ in pairs (s.outputs) do
        tag_shortcuts = screen_tag_shortcuts[out]
    end
    if tag_shortcuts then
        for tag_num = 1, #tag_shortcuts do
            local tag_key = tag_shortcuts:sub(tag_num, tag_num)
            globalkeys = gears.table.join(globalkeys,
                awful.key({ modkey, "Mod1" }, tag_key,
                    function()
                        awful.screen.focus(s)
                        local tag = awful.screen.focused().tags[tag_num]
                        if tag then
                            tag:view_only()
                        end
                    end,
                    {description = "view tag #" .. tag_num .. " in screen " .. s.index, group = "tag"}
                )
            )
            globalkeys = gears.table.join(globalkeys,
                awful.key({ modkey, "Mod1", "Shift" }, tag_key,
                    function()
                        local c = client.focus
                        local tag = s.tags[tag_num]
                        if c and tag then
                            awful.screen.focus(s)
                            c:move_to_tag(tag)
                            client_utils.serialise_screen_tags(c)
                        end
                    end,
                    {description = "move focused client to tag #" .. tag_num .. " in screen " .. s.index, group = "tag"}
                )
            )
        end
    end
end

-- Open App shortcuts
globalkeys = gears.table.join(globalkeys,
    awful.key({ modkey, "Mod1" }, "XF86AudioPlay",
        function() client_utils.run_or_raise(apps.spotify.cmd, apps.spotify.rules) end,
        {description = "Open Spotify", group = "launcher"}), --  XF86AudioPlay

    awful.key({ modkey, "Mod1" }, "space", function () client_utils.run_or_raise(apps.terminal.cmd, apps.terminal.rules) end,
              {description = "go to terminal", group = "launcher"}),

    awful.key({ modkey, "Mod1", "Shift"  }, "space", function () awful.spawn(terminal) end,
              {description = "open a new terminal", group = "launcher"})
)

local app_shortcuts = {
    ["GMail"] = function() client_utils.run_or_raise(apps.gmail.cmd, apps.gmail.rules) end,
    ["Calendar"] = function() client_utils.run_or_raise(apps.calendar.cmd, apps.calendar.rules) end,
    ["Browser"] = function() client_utils.run_or_raise(apps.chrome.cmd, apps.chrome.rules) end,
    ["Firefox"] = function() client_utils.run_or_raise(apps.firefox.cmd, apps.firefox.rules) end,
    ["Slack"] = function() client_utils.run_or_raise(apps.slack.cmd, apps.slack.rules) end,
    ["DBeaver"] = function() client_utils.run_or_raise(apps.dbeaver.cmd, apps.dbeaver.rules) end,
    ["keepassXc"] = function() client_utils.run_or_raise(apps.keepassxc.cmd, apps.keepassxc.rules) end,
    ["cHat"] = function() client_utils.run_or_raise(apps.google_chat.cmd, apps.google_chat.rules) end,
    ["Zoom"] = function() client_utils.run_or_raise(apps.zoom.cmd, apps.zoom.rules) end,
}

for app, func in pairs(app_shortcuts) do
    -- app shortcut is the first upppercase letter in the app name
    -- or the first letter if no upppercase is found
    local key = app:sub(1,1):lower()
    for i = 1, #app do
        local c = app:sub(i, i)
        if string.match(c, "%u") then
            key = c:lower()
            break
        end
    end
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey, "Mod1" }, key, func, {description = "Open " .. app, group = "launcher"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end),
    awful.button({ modkey }, 6, function() awful.client.focus.byidx(-1) end),
    awful.button({ modkey }, 7, function() awful.client.focus.byidx( 1) end),
    awful.button({ modkey }, 4, function(c) awful.tag.viewprev(c.screen) end),
    awful.button({ modkey }, 5, function(c) awful.tag.viewnext(c.screen) end)
)

-- Set keys
root.keys(globalkeys)
local history_active = true
local history_mappings = awful.keygrabber {
    stop_key = modkey,
    stop_event = "release",
    start_callback = function() history_active = false end,
    stop_callback  = function()
        awful.client.focus.history.add(client.focus)
        history_active = true
    end,
    keybindings = {
        {{modkey         }, 'Tab', function()
            local c = client_utils.history_get(1)
            if c then
                c:jump_to()
                c:raise()
            end
        end,
        {description = "go to previous client in history", group = "client"}},
        {{modkey, 'Shift'}, 'Tab', function()
            local c = client_utils.history_get(-1)
            if c then
                c:jump_to()
                c:raise()
            end
        end,
        {description =  "go to next client in history", group = "client"}}
    },
    export_keybindings = true
}
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {

    -- @DOC_GLOBAL_RULE@
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- @DOC_FLOATING_RULE@
    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
        }
      }, properties = { floating = true }},

    -- @DOC_DIALOG_RULE@
    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    { rule = { class = "XTerm" },
      properties = { size_hints_honor = false } },

    {
        rule = {
            class = "jetbrains-studio",
            name="^win[0-9]+$"
        },
        properties = { 
            placement = awful.placement.no_offscreen,
            titlebars_enabled = false,
            focusable = false,
            floating = true,
            intrusive = true
        }
    },

    { rule = { class = "Zoom", name="zoom" },
      properties = { floating = true } },


    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when selecting a tag
-- only run it if we stay in this tag for a moment
local tag_select_timer = gears.timer({
    timeout = 0.3,
    callback = function()
                 local selected_tag = awful.screen.focused().selected_tag
                 if selected_tag.on_select and not awesome.startup then
                   selected_tag.on_select()
                 end
               end,
    single_shot = true
})

for _, t in ipairs(root.tags()) do
    t:connect_signal("property::selected", function(t)
        if t.selected and t.on_select and not awesome.startup then
            tag_select_timer:again()
        end
    end)
end

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Recalculate tags for a client when changing screens
client.connect_signal("property::screen", function(c)
    client_utils.restore_tags(c)
end)

-- Enable sloppy focus, so that focus follows mouse.
-- We save the client stack order for the screen and replay from the first order change
client.connect_signal("mouse::enter", function(c)
    if sloppyfocus_active then
        local prev_client_stack_order = c.screen:get_clients()
        c:emit_signal("request::activate", "mouse_enter", {raise = false})
        local client_stack_order = c.screen:get_clients()

        -- check prev_client_stack_order vs client_stack_order from back to frontmost client (that's reverse order)
        local order_changed = false
        for i = #client_stack_order, 1, -1 do
            if client_stack_order[i] ~= prev_client_stack_order[i] then
                order_changed = true
            end
            -- from the first stack order change we restore the previous order
            if order_changed then
                prev_client_stack_order[i]:raise()
            end
        end
    end
end)

awful.client.focus.history.disable_tracking()
local history_timer = gears.timer({
    timeout = 0.5,
    callback = function()
        if history_active then
            awful.client.focus.history.add(client.focus)
        end
    end,
    single_shot = true
})

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
    history_timer:again()
end)

client.connect_signal("manage", function(c)
    client_utils.serialise_screen_tags(c)
end)

client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

gears.timer.delayed_call(function()
    for _, c in ipairs(client.get()) do
        client_utils.restore_screen(c)
        client_utils.restore_tags(c)
    end
end)

-- Autostart Applications
-- awful.spawn.with_shell("xrandr --output eDP-1 --auto --primary --mode 2560x1440 --pos 0x1440 --rotate normal --output DP-1 --off --output DP-2 --off --output DP-3 --off")
awful.spawn.with_shell("xrandr --output eDP-1-1 --mode 2560x1440 --pos 0x0 --rotate normal --output DP-1-1 --mode 2560x1440 --pos 2560x0 --rotate normal --output DP-1-2 --off --output DP-1-3 --mode 2560x1440 --pos 5120x0 --rotate right")
-- Mags
-- awful.spawn.with_shell("xrandr --output eDP-1-1 --mode 2560x1440 --pos 0x1440 --rotate normal --output DP-1-1 --off --output DP-1-2 --off --output DP-1-3 --mode 2560x1440 --pos 0x0 --rotate normal")
-- awful.spawn.with_shell("xrandr --output eDP-1-1 --mode 2560x1440 --pos 0x0 --rotate normal --output DP-1-1 --mode 2560x1440 --pos 2560x0 --rotate normal --output DP-1-2 --off --output DP-1-3 --mode 2560x1440 --pos 5120x0 --rotate right")
-- awful.spawn.with_shell("xrandr --output eDP-1 --auto --primary --mode 2560x1440 --pos 0x1440 --rotate normal --output DP-1 --off --output DP-2 --off --output DP-3 --mode 2560x1440 --pos 0x0 --rotate normal")

-- cheap monitor
-- awful.spawn.with_shell("xrandr --output eDP-1 --primary --mode 2560x1440 --pos 1680x0 --rotate normal --output DP-1 --off --output DP-2 --off --output DP-3 --mode 1680x1050 --pos 0x0 --rotate normal")
-- awful.spawn.with_shell("xrandr --output eDP-1-1 --mode 2560x1440 --pos 1680x0 --rotate normal --output DP-1-1 --off --output DP-1-2 --off --output DP-1-3 --mode 1680x1050 --pos 0x0 --rotate normal")

awful.spawn.with_shell("nm-applet")
awful.spawn.with_shell("killall -q compton; compton --backend glx")
awful.spawn.with_shell("xrdb $HOME/.Xresources")
awful.spawn.with_shell('imwheel -k -b "4 5 6 7 8 9 10 11 12"')
awful.spawn.with_shell('xinput map-to-output `xinput | grep "PenTablet stylus" | cut -f 2 | cut -c 4-5` ' .. (is_screen_connected('DP-1') or 'DP-1') )
