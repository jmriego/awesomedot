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
        class       = { --Accept the following classes, refuse everything else (because of "exclusive=true")
            "xterm" , "urxvt" , "aterm","URxvt","XTerm","konsole","terminator","gnome-terminal", "Dbeaver", "Java"
        }
    } ,
    {
        name        = "Mail",                 -- Call the tag "Mail"
        icon   = gears.filesystem.get_configuration_dir() .. "material-awesome/theme/icons/ship-wheel.svg",
        init        = true,                   -- Load the tag on startup
        exec_once   = {
            "/home/jvalenzuela/workconfig/bin/gmail.sh",
            "/home/jvalenzuela/workconfig/bin/google-calendar.sh",
            -- "google-chrome-stable --app=https://mail.google.com",
            -- "google-chrome-stable --app=https://www.google.com/calendar/render",
        },
        exclusive   = true,                   -- Refuse any other type of clients (by classes)
        screen      = {1},
        layout      = awful.layout.suit.max, -- Use the tile layout
        floating    = false, -- Use the tile layout
        instance = {"mail.google.com", "www.google.com__calendar_render"},
    } ,
    {
        name        = "Internet",
        icon   = gears.filesystem.get_configuration_dir() .. "material-awesome/theme/icons/google-chrome.svg",
        init        = true,
        exclusive   = true,
        screen      = screen.count()>2 and {1,3} or {1,2},-- Setup on screen 2 if there is more than 1 screen, else on screen 1
        -- exec_once   = {"/opt/google/chrome/chrome"}, --When the tag is accessed for the first time, execute this command
        screen      = screen.count()>1 and {2,3} or {1},
        floating    = false,
        layout      = awful.layout.suit.max,      -- Use the max layout
        class = {
            "Opera"         , "Firefox"        , "Rekonq"    , "Dillo"        , "Arora",
            "Google-chrome", "nightly"   , "minefield" }
    } ,
    {
        name        = "Comms",
        icon   = gears.filesystem.get_configuration_dir() .. "material-awesome/theme/icons/forum.svg",
        screen      = {1},
        exec_once   = {"slack"}, --When the tag is accessed for the first time, execute this command
        init        = true, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        layout      = awful.layout.suit.tile,
        floating    = false,
        instance = { "crx_nckgahadagoaajjgafhacjanaoiihapd" },
        class = { "slack" }
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
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
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
            mybatterywidget,
            mytextclock,
            wibox.widget.systray(),
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

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey, "Mod1"   }, "space", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
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
    awful.key({ modkey }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Mod1" }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
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
    awful.key({ modkey, "Control" }, "q",
        function (c)
            client_log(c, "DEBUG: ")
        end ,
        {description = "write debug information about current client", group = "client"}),
    -- awful.key({ modkey, "Control" }, "m",
        -- function (c)
            -- c.maximized_vertical = not c.maximized_vertical
            -- c:raise()
        -- end ,
        -- {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)


-- Save tag names for each client so they can be reused in a different screen
local save_tags = function(c)
    local tag_names = {}
    for _, tag in pairs(c:tags()) do
        tag_names[#tag_names+1] = tag.name
    end
    c.tag_names = tag_names
    client_log(c, "saved tags: ")
end

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
                              save_tags(c)
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
                              save_tags(c)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

for s in screen do
    local tag_shortcuts = nil
    for out, _ in pairs (s.outputs) do
        if out == "DP-1" then
            tag_shortcuts = {"u", "i", "o", "p", "["}
        elseif out == "DP-3" then
            tag_shortcuts = {"j", "k", "l", ";", "'"}
        elseif out == "eDP-1" then
            tag_shortcuts = screen.count() > 1 and {"m", ",", ".", "/"} or {"j", "k", "l", ";", "'"}
        end
    end
    if tag_shortcuts then
        for tag_num, tag_key in ipairs(tag_shortcuts) do
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
        end
    end
end

sloppyfocus_active = true
clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 2, function() sloppyfocus_active = not sloppyfocus_active end),
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
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- @DOC_DIALOG_RULE@
    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    { rule = { class = "XTerm" },
      properties = { size_hints_honor = false } },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
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

client_log = function(c, extra_log)
    local out = io.open("/tmp/awesomerclua.log", "a")
    if extra_log then
        out:write(extra_log)
    end
    out:write(c.name or "?")
    out:write(" screen " .. c.screen.index)
    out:write(" tags: ")
    for _, tag in ipairs(c:tags()) do
        out:write(tag.index)
        out:write(tag.name or "?")
        out:write(",")
    end
    out:write(" screentags: ")
    for _, tag in ipairs(c.screen.tags) do
        out:write(tag.index)
        out:write(tag.name or "?")
        out:write(",")
    end
    out:write(" tagnames: ")
    if c.tag_names then
        for _, tag in ipairs(c.tag_names) do
            out:write(tag or "?")
            out:write(",")
        end
    end
    out:write("\n\n")
    io.close(out)
end

client.connect_signal("property::tags", function(c)
    client_log(c)
end)

-- Recalculate tags for a client when changing screens
client.connect_signal("property::screen", function(c)
    client_log(c, "property::screen started")
    if c.tag_names then
        tag_names = c.tag_names

        local s = c.screen
        local tags_in_screen = {}
        for _, tag in ipairs(c.tag_names) do
            screen_tag = awful.tag.find_by_name(s, tag)
            if screen_tag then
                tags_in_screen[#tags_in_screen+1] = screen_tag
            end
        end
        if #tags_in_screen == 0 then
            others_tag = awful.tag.find_by_name(s, "Others")
            c:toggle_tag(others_tag)
            others_tag:view_only()
        else
            c:tags(tags_in_screen)
            c.first_tag:view_only()
        end
    end
    client_log(c, "property::screen finished")
end)

-- check if c1 is completely inside c2
local client_inside = function(c1, c2)
    -- check if the window has coordinates (fixes case when checking against a just closed client)
    if c1 and c2 and c1.x and c2.x then
        c1_xright = c1.x + c1.width
        c1_ybottom = c1.y + c1.height
        c2_xright = c2.x + c2.width
        c2_ybottom = c2.y + c2.height
        return (c1.x >= c2.x and c1_xright <= c2_xright and c1.y >= c2.y and c1_ybottom <= c2_ybottom)
    else
        return false
    end
end

-- Enable sloppy focus, so that focus follows mouse.
-- Some windows autoraise so only follow mouse if the new client doesnt overlap
local sloppyfocus_last = nil
client.connect_signal("mouse::enter", function(c)
    if sloppyfocus_active and not client_inside(sloppyfocus_last, c) then
        c:emit_signal("request::activate", "mouse_enter", {raise = false})
        sloppyfocus_last = c
    end
end)

client.connect_signal("unmanage", function (c)
  if sloppyfocus_last == c then
    sloppyfocus_last = nil
  end
end)

client.connect_signal("focus", function(c)
    if c.tag_names == nil or #c.tag_names == 0 then
        client_log(c, "signal::focus")
        save_tags(c)
    end
    c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- Autostart Applications
awful.spawn.with_shell("xrandr --output eDP-1 --primary --mode 2560x1440 --pos 0x1602 --rotate normal --output DP-1 --mode 2560x1440 --pos 2560x0 --rotate left --output DP-2 --off --output DP-3 --mode 2560x1440 --pos 0x162 --rotate normal")
awful.spawn.with_shell("nm-applet")
awful.spawn.with_shell("compton --backend glx || killall -USR1 compton")
awful.spawn.with_shell("xrdb $HOME/.Xresources")
