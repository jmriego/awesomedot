local awful = require('awful')
local gears = require('gears')
local wibox = require('wibox')
local beautiful = require('beautiful')
local clickable_container = require('material-awesome.widget.material.clickable-container')
local dpi = require('beautiful').xresources.apply_dpi

LOCK_CMD = 'slock'
local dir = gears.filesystem.get_configuration_dir() .. 'widgets/icons/'

-- Appearance
local icon_size = beautiful.exit_screen_icon_size or dpi(140)
local icons = {
    ["power"] = dir .. 'power.svg',
    ["logout"] = dir .. 'logout.svg',
    ["sleep"] = dir .. 'power-sleep.svg',
    ["lock"] = dir .. 'lock.svg',
    ["restart"] = dir .. 'restart.svg'}

local buildButton = function(icon)
  local abutton =
    wibox.widget {
    wibox.widget {
      wibox.widget {
        wibox.widget {
          image = icon,
          widget = wibox.widget.imagebox
        },
        top = dpi(16),
        bottom = dpi(16),
        left = dpi(16),
        right = dpi(16),
        widget = wibox.container.margin
      },
      shape = gears.shape.circle,
      forced_width = icon_size,
      forced_height = icon_size,
      widget = clickable_container
    },
    left = dpi(24),
    right = dpi(24),
    widget = wibox.container.margin
  }

  return abutton
end


function suspend_command()
  exit_screen_hide()
  awful.spawn.with_shell(LOCK_CMD .. ' & systemctl suspend')
end
function exit_command()
  _G.awesome.quit()
end
function lock_command()
  exit_screen_hide()
  awful.spawn.with_shell('sleep 1 && ' .. LOCK_CMD)
end
function poweroff_command()
  awful.spawn.with_shell('poweroff')
  awful.keygrabber.stop(_G.exit_screen_grabber)
end
function reboot_command()
  awful.spawn.with_shell('reboot')
  awful.keygrabber.stop(_G.exit_screen_grabber)
end

local poweroff = buildButton(icons.power, 'Shutdown')
poweroff:connect_signal(
  'button::release',
  function()
    poweroff_command()
  end
)

local reboot = buildButton(icons.restart, 'Restart')
reboot:connect_signal(
  'button::release',
  function()
    reboot_command()
  end
)

local suspend = buildButton(icons.sleep, 'Sleep')
suspend:connect_signal(
  'button::release',
  function()
    suspend_command()
  end
)

local exit = buildButton(icons.logout, 'Logout')
exit:connect_signal(
  'button::release',
  function()
    exit_command()
  end
)

local lock = buildButton(icons.lock, 'Lock')
lock:connect_signal(
  'button::release',
  function()
    lock_command()
  end
)

-- Get screen geometry
local screen_geometry = screen.primary.geometry

-- Create the widget
exit_screen =
  wibox(
  {
    x = screen_geometry.x,
    y = screen_geometry.y,
    visible = false,
    ontop = true,
    type = 'splash',
    height = screen_geometry.height,
    width = screen_geometry.width
  }
)

-- exit_screen.bg = beautiful.background.hue_800 .. 'dd'
-- exit_screen.fg = beautiful.exit_screen_fg or beautiful.wibar_fg or '#FEFEFE'

local exit_screen_grabber

function exit_screen_hide()
  awful.keygrabber.stop(exit_screen_grabber)
  exit_screen.visible = false
end

function exit_screen_show()
  -- naughty.notify({text = "starting the keygrabber"})
  exit_screen_grabber =
    awful.keygrabber.run(
    function(_, key, event)
      if event == 'release' then
        return
      end

      if key == 's' then
        suspend_command()
      elseif key == 'e' then
        exit_command()
      elseif key == 'l' then
        lock_command()
      elseif key == 'p' then
        poweroff_command()
      elseif key == 'r' then
        reboot_command()
      elseif key == 'Escape' or key == 'q' or key == 'x' then
        -- naughty.notify({text = "Cancel"})
        exit_screen_hide()
      -- else awful.keygrabber.stop(exit_screen_grabber)
      end
    end
  )
  exit_screen.visible = true
end

exit_screen:buttons(
  gears.table.join(
    -- Middle click - Hide exit_screen
    awful.button(
      {},
      2,
      function()
        exit_screen_hide()
      end
    ),
    -- Right click - Hide exit_screen
    awful.button(
      {},
      3,
      function()
        exit_screen_hide()
      end
    )
  )
)

-- Item placement
exit_screen:setup {
  nil,
  {
    nil,
    {
      -- {
      poweroff,
      reboot,
      suspend,
      exit,
      lock,
      layout = wibox.layout.fixed.horizontal
      -- },
      -- widget = exit_screen_box
    },
    nil,
    expand = 'none',
    layout = wibox.layout.align.horizontal
  },
  nil,
  expand = 'none',
  layout = wibox.layout.align.vertical
}

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
        exit_screen_show()
      end
    )
  )
)

local function worker(args)
    local args = args or {}
    return exit_button
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
