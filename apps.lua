local gears = require("gears")
local awful = require("awful")

local chrome = {
    cmd = 'google-chrome-stable --force-device-scale-factor=1.2',
    rules = {instance="google-chrome"}
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

local hangouts = {
    rules = {instance="crx_nckgahadagoaajjgafhacjanaoiihapd"}
}

local dbeaver = {
    cmd = 'dbeaver',
    rules = {instance="DBeaver"}
}

local terminal = {
    cmd = 'xterm',
    rules = {class="XTerm"}
}

return {
 gmail = gmail,
 calendar = calendar,
 chrome = chrome,
 slack = slack,
 hangouts = hangouts,
 dbeaver = dbeaver,
 terminal = terminal
}
