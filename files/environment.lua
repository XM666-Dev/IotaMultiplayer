local current = getfenv()
local meta = {__index = current, __newindex = current}
local __loadonce = {}
local __loaded = {}
local t
t = setmetatable({
    dofile_once = function(filename)
        local result = nil
        local cached = __loadonce[filename]
        if cached ~= nil then
            result = cached[1]
        else
            local f, err = setfenv(loadfile(filename), t)
            if f == nil then return f, err end
            local __newindex = meta.__newindex
            meta.__newindex = nil
            result = f()
            meta.__newindex = __newindex
            __loadonce[filename] = {result}
            do_mod_appends(filename)
        end
        return result
    end,
    dofile = function(filename)
        local f = __loaded[filename]
        if f == nil then
            f, err = setfenv(loadfile(filename), t)
            if f == nil then return f, err end
            __loaded[filename] = f
        end
        local __newindex = meta.__newindex
        meta.__newindex = nil
        local result = f()
        meta.__newindex = __newindex
        do_mod_appends(filename)
        return result
    end,
}, meta)
setfenv(3, t)
