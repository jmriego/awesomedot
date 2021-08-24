local gears = require("gears")
local awful = require("awful")
local client_utils = require("client_utils")

local internet = {
    rules = function(c)
                return gears.table.hasitem(client_utils.client_tag_names(c), "Internet") and
                c.screen == awful.screen.focused()
            end
}

local code = {
    rules = function(c)
                return gears.table.hasitem(client_utils.client_tag_names(c), "Code") and
                c.screen == awful.screen.focused()
            end
}

local chrome = {
    cmd = 'google-chrome-stable --force-device-scale-factor=1.0',
    rules = {instance="google-chrome"}
}

local firefox = {
    cmd = 'env GDK_DPI_SCALE=0.75 firefox',
    rules = {class="Firefox"}
}

local gmail = {
    cmd = chrome.cmd .. ' --app="https://mail.google.com"',
    rules = {instance="mail.google.com"}
}

local calendar = {
    cmd = chrome.cmd .. ' --app="https://www.google.com/calendar/render"',
    rules = {instance="www.google.com__calendar_render"}
}

local slack = {
    cmd = 'slack',
    rules = {instance=="Slack"}
}

local google_chat = {
    cmd = chrome.cmd .. ' --app-id="mdpkiolbdkhdjpekfbkbmhigcaggjagi"',
    rules = {instance="crx_mdpkiolbdkhdjpekfbkbmhigcaggjagi"}
}

local dbeaver = {
    cmd = 'env GDK_DPI_SCALE=0.75 dbeaver-ce',
    rules = {instance="DBeaver"}
}

local terminal = {
    cmd = 'xterm',
    rules = {class="XTerm"}
}

local spotify = {
    cmd = 'spotify',
    rules = {class="Spotify"}
}

local keepassxc = {
    cmd = 'keepassxc',
    rules = {instance="KeePassXC"}
}

return {
 internet = internet,
 code = code,
 gmail = gmail,
 calendar = calendar,
 chrome = chrome,
 firefox = firefox,
 slack = slack,
 google_chat = google_chat,
 dbeaver = dbeaver,
 terminal = terminal,
 spotify = spotify,
 keepassxc = keepassxc
}
