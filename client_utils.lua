local gears = require("gears")
local awful = require("awful")

local genValidKey = function(key)
    if type(key) == "number" then
        return '['..key..']'
    elseif type(key) == "string" then
        return key
    end
end

serialise = function(data)
    local serialisedData = ""
    if type(data) == "nil"          then
        serialisedData = serialisedData .. "nil"
    elseif type(data) == "boolean"  then
        if data ==  true then
            serialisedData = serialisedData .. "true"
        else
            serialisedData = serialisedData .. "false"
        end
    elseif type(data) == "number"   then
        serialisedData = serialisedData .. data
    elseif type(data) == "string"   then
        serialisedData = serialisedData .. string.format("%q", data)
    elseif type(data) == "function" then
        -- ?
    elseif type(data) == "userdata" then
        -- ?
    elseif type(data) == "thread"   then
        -- ?
    elseif type(data) == "table"    then
        serialisedData = "{\n"
        for k, v in pairs(data) do
            local serKey = genValidKey(k)
            if serKey ~= nil then
                serialisedData = serialisedData .. "  " ..serKey .. " = " .. serialise(v) .. ",\n"
            end
        end
        serialisedData = serialisedData.."\n}"
    end
    return serialisedData
end

local serialise_screen_tags = function(c)
    local screen = c.screen.index
    local ctags = {}
    for i, t in ipairs(c:tags()) do
        ctags[i] = t.name
    end
    c.disp = serialise({screen = screen, tags = ctags})
end

local restore_screen = function(c)
    if c.disp == "" then
        return
    end

    disp = nil
    load("disp = " .. c.disp)()
    c:move_to_screen(tonumber(disp.screen))
end

local restore_tags = function(c)
    if c.disp == "" then
        return
    end

    disp = nil
    load("disp = " .. c.disp)()
    local ctags = {}

    for i, t in ipairs(disp.tags) do
        screen_tag = awful.tag.find_by_name(c.screen, t)
        if screen_tag then
            ctags[#ctags+1] = screen_tag
        end
    end

    if(#ctags == 0) then
        ctags[#ctags+1] = awful.tag.find_by_name(c.screen, "Others")
    end

    c:tags(ctags)
end

local backup_clients_screen = function()
    for _, c in ipairs(client.get()) do
        serialise_screen_tags(c)
    end
end

local history_get = function (idx, c)
    local current_client = c and c or client.focus

    local pos = 0
    for i, c in ipairs(awful.client.focus.history.list) do
       if c == current_client then
           pos = i
       end
    end

    return awful.client.focus.history.list[pos + idx]
end

local find_client = function(rules)
    if type(rules) == "table" then
        matcher = function(c) return awful.rules.match(c, rules) end
    else
        matcher = rules
    end
    for _, c in ipairs(client.get()) do
        if matcher(c) then
            return c
        end
    end
end

local run_once = function(cmd, matcher)
    c = find_client(matcher)
    if not c then
        awful.spawn(cmd)
    end
end

local run_or_raise = function(cmd, matcher)
    c = find_client(matcher)
    if c then
        c:jump_to()
    else
        awful.spawn(cmd)
    end
end

return {
    serialise_screen_tags = serialise_screen_tags,
    restore_screen = restore_screen,
    restore_tags = restore_tags,
    history_get = history_get,
    find_client = find_client,
    run_once = run_once,
    run_or_raise = run_or_raise,
    backup_clients_screen = backup_clients_screen
}
