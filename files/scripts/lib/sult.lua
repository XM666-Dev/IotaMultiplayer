dofile_once("data/scripts/lib/utilities.lua")

--#region

function AccessorTable(t, accessors)
    return setmetatable(t, {
        __index = function(t, k)
            local accessor = accessors[k]
            if accessor then
                return accessor.get()
            end
        end,
        __newindex = function(t, k, v)
            local accessor = accessors[k]
            if accessor then
                return accessor.set(v)
            end
            rawset(t, k, v)
        end
    })
end

function Data(t, accessors)
    return setmetatable(t, {
        __index = function(t, k)
            return (accessors[k] or rawget)(t, k)
        end,
        __newindex = function(t, k, v)
            (accessors[k] or rawset)(t, k, v)
        end
    })
end

function EntityVariableAccessor(entity, name, field, value)
    local variable = get_variable_storage_component_or_add(entity, name, field, value)
    return {
        get = function()
            return ComponentGetValue2(variable, field)
        end,
        set = function(...)
            ComponentSetValue2(variable, field, ...)
        end
    }
end

function TagEntityAccessor(tag, pred)
    return {
        get = function()
            local entity = get_tag_entity(tag)
            if pred then
                return pred(entity) and entity or nil
            end
            return entity
        end,
        set = function(v)
            set_tag_entity(tag, v)
        end
    }
end

function ComponentData(component)
    local list_component_data = setmetatable({}, {
        __index = function(t, k)
            return { ComponentGetValue2(component, k) }
        end,
        __newindex = function(t, k, v)
            ComponentSetValue2(component, k, unpack(v))
        end
    })
    return component and setmetatable({}, {
        id = component,
        __index = function(t, k)
            return ComponentGetValue2(component, k)
        end,
        __newindex = function(t, k, v)
            ComponentSetValue2(component, k, v)
        end,
        __call = function(t, ...)
            return list_component_data
        end
    })
end

function ModData(mod)
    return setmetatable({}, {
        id = mod,
        __index = function(t, k)
            return mod .. "." .. k
        end,
        __concat = function(t1, t2)
            return mod .. t2
        end
    })
end

--#endregion

--#region

function get_variable_storage_component_or_add(entity, name, field, value)
    return get_variable_storage_component(entity, name) or EntityAddComponent2(entity, "VariableStorageComponent", { name = name, [field] = value })
end

function get_tag_entity(tag)
    return EntityGetWithTag(tag)[1]
end

function set_tag_entity(tag, entity)
    for i, tagged_entity in ipairs(EntityGetWithTag(tag)) do
        EntityRemoveTag(tagged_entity, tag)
    end
    EntityAddTag(entity, tag)
end

--#endregion

--#region

function append_translations(filename)
    local common = "data/translations/common.csv"
    ModTextFileSetContent(common, ModTextFileGetContent(common) .. ModTextFileGetContent(filename):gsub("(.-\n)", "", 1))
end

function has_flag_run_or_add(flag)
    return GameHasFlagRun(flag) or GameAddFlagRun(flag)
end

function get_id(data)
    return getmetatable(data).id
end

function validate_entity(entity)
    return entity and entity > 0 and entity or nil
end

function get_children(entity)
    return EntityGetAllChildren(entity) or {}
end

function get_inventory_items(entity)
    return GameGetAllInventoryItems(entity) or {}
end

function get_camera_corner()
    local camera_x, camera_y = GameGetCameraPos()
    local x, y, w, h = GameGetCameraBounds()
    return camera_x - w / 2, camera_y - h / 2
end

function get_camera_zoom(gui)
    local camera_x, camera_y, camera_w, camera_h = GameGetCameraBounds()
    local screen_w, screen_h = GuiGetScreenDimensions(gui)
    return screen_w / camera_w, screen_h / camera_h
end

function get_pos_on_screen(gui, x, y)
    local camera_x, camera_y = get_camera_corner()
    local zoom_x, zoom_y = get_camera_zoom(gui)
    return (x - camera_x) * zoom_x, (y - camera_y) * zoom_y
end

function get_frame_num_next()
    return GameGetFrameNum() + 1
end

local ModTextFileSetContent = ModTextFileSetContent

function serialize(v)
    return (({
        number = function(n) return ("%a"):format(n) end,
        string = function(s) return ("%q"):format(s) end,
        table = function(t)
            local s = "{"
            local i = 1
            for k, v in pairs(t) do
                s = s .. "[" .. serialize(k) .. "]=" .. serialize(v) .. (i < #t and "," or "")
                i = i + 1
            end
            return s .. "}"
        end
    })[type(v)] or tostring)(v)
end

function deserialize(s)
    ModTextFileSetContent("data/scripts/empty.lua", "return " .. s)
    local f, err = loadfile("data/scripts/empty.lua")
    if f == nil then return f, err end
    return f()
end

function SettingAccessor(id, filename, setting_date_filename, file_date_filename)
    if not ModDoesFileExist(setting_date_filename) then
        ModTextFileSetContent(setting_date_filename, "1")
    end
    if not ModDoesFileExist(file_date_filename) then
        ModTextFileSetContent(file_date_filename, "0")
    end
    local function get_setting_date()
        return tonumber(ModTextFileGetContent(setting_date_filename))
    end
    local function set_setting_date(n)
        ModTextFileSetContent(setting_date_filename, tostring(n))
    end
    local function get_file_date()
        return tonumber(ModTextFileGetContent(file_date_filename))
    end
    local function set_file_date(n)
        ModTextFileSetContent(file_date_filename, tostring(n))
    end
    return {
        cache_date = 0,
        get = function(self)
            if self.cache_date < get_setting_date() then
                if get_file_date() < get_setting_date() then
                    ModTextFileSetContent(filename, "return " .. ModSettingGet(id))
                    set_file_date(get_setting_date())
                end
                self.cache = loadfile(filename)()
                self.cache_date = get_setting_date()
            end
            return self.cache
        end,
        set = function(self, v)
            ModSettingSet(id, serialize(v))
            set_setting_date(get_setting_date() + 1)
            self.cache = v
            self.cache_date = get_setting_date()
        end
    }
end

NUMERIC_CHARACTERS = "0123456789"

function get_language()
    return ({
        ["English"] = "en",
        ["русский"] = "ru",
        ["Português (Brasil)"] = "pt-br",
        ["Español"] = "es-es",
        ["Deutsch"] = "de",
        ["Français"] = "fr-fr",
        ["Italiano"] = "it",
        ["Polska"] = "pl",
        ["简体中文"] = "zh-cn",
        ["日本語"] = "jp",
        ["한국어"] = "ko",
    })[GameTextGet("$current_language")]
end

function GetterTable(t, getters)
    return setmetatable(t, {
        __index = function(t, k)
            local getter = getters[k]
            return getter and getter()
        end
    })
end

function debug_print(...)
    local s = ""
    for i, v in ipairs({ ... }) do
        s = s .. string.from(v)
    end
    print(s)
    GamePrint(s)
end

--#endregion

--#region

function string.from(v)
    return (({
        table = function(t)
            local s = "{"
            local i = 1
            for k, v in pairs(t) do
                s = s .. string.from(k) .. "=" .. string.from(v) .. (i < #t and "," or "")
                i = i + 1
            end
            return s .. "}"
        end
    })[type(v)] or tostring)(v)
end

function string.asub(s, repl)
    return s:gsub('(%g+)%s*=%s*(%b"")', repl)
end

function table.find(list, pred)
    for i, v in ipairs(list) do
        if pred(v) then
            return i
        end
    end
end

function table.filter(list, pred)
    local result = {}
    for i, v in ipairs(list) do
        if pred(v) then
            table.insert(result, v)
        end
    end
    return result
end

function table.iterate(list, comp, value)
    for i, v in ipairs(list) do
        if comp(v, value) then
            value = v
        end
    end
    return value
end

function math.round(x)
    return math.floor(x + 0.5)
end

function lerp(from, to, weight)
    return from + (to - from) * weight
end

function lerp_clamped(from, to, weight)
    return lerp(from, to, clamp(weight, 0, 1))
end

function point_in_rectangle(x, y, left, up, right, down)
    return x >= left and x <= right and y >= up and y <= down
end

--#endregion
