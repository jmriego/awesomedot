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

return {
    serialise_screen_tags = serialise_screen_tags,
    restore_screen = restore_screen,
    restore_tags = restore_tags,
    backup_clients_screen = backup_clients_screen
}
