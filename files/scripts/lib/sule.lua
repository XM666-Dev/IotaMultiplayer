--__loadonce = {}
--dofile_once = function(filename)
--    local result = nil
--    local cached = __loadonce[filename]
--    if cached ~= nil then
--        result = cached[1]
--    else
--        local f, err = loadfile(filename)
--        if f == nil then return f, err end
--        result = f()
--        __loadonce[filename] = { result }
--        do_mod_appends(filename)
--    end
--    return result
--end
--__loaded = {}
--dofile = function(filename)
--    local f = __loaded[filename]
--    if f == nil then
--        f, err = loadfile(filename)
--        if f == nil then return f, err end
--        __loaded[filename] = f
--    end
--    local result = f()
--    do_mod_appends(filename)
--    return result
--end

local t = setmetatable({ __loaded = {}, __loadonce = {} }, { __index = _G, __call = function(t, ...) return setfenv(..., t)() end })
t.dofile = function(filename)
    local f = t.__loaded[filename]
    if f == nil then
        f, err = loadfile(filename)
        if f == nil then return f, err end
        t.__loaded[filename] = setfenv(f, t)
    end
    local result = f()
    do_mod_appends(filename)
    return result
end
t.dofile_once = function(filename)
    local result = nil
    local cached = t.__loadonce[filename]
    if cached ~= nil then
        result = cached[1]
    else
        local f, err = loadfile(filename)
        if f == nil then return f, err end
        result = setfenv(f, t)()
        t.__loadonce[filename] = { result }
        do_mod_appends(filename)
    end
    return result
end
return t
