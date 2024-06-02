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

function ComponentValueAccessor(component, field)
    return {
        get = function()
            return ComponentGetValue2(component, field)
        end,
        set = function(...)
            ComponentSetValue2(component, field, ...)
        end
    }
end

function EntityVariableAccessor(entity, name, field, value)
    local component = get_variable_storage_component_or_add(entity, name, field, value)
    return ComponentValueAccessor(component, field)
end

function TagEntityAccessor(tag)
    return {
        get = function()
            return get_tag_entity(tag)
        end,
        set = function(v)
            set_tag_entity(tag, v)
        end
    }
end

function ComponentData(component)
    return component and setmetatable({}, {
        id = component,
        __index = function(t, k)
            return ComponentGetValue2(component, k)
        end,
        __newindex = function(t, k, v)
            ComponentSetValue2(component, k, v)
        end,
        __call = function(t, ...)
            return ComponentValueAccessor(component, ...)
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

FIELD_STRING = "value_string"
FIELD_INT = "value_int"
FIELD_BOOL = "value_bool"
FIELD_FLOAT = "value_float"

function get_variable_storage_component_or_add(entity, name, field, value)
    return get_variable_storage_component(entity, name) or EntityAddComponent2(entity, "VariableStorageComponent", { name = name, [field] = value })
end

function get_tag_entity(tag)
    return EntityGetWithTag(tag)[1]
end

function set_tag_entity(tag, entity)
    for _, tagged_entity in ipairs(EntityGetWithTag(tag)) do
        EntityRemoveTag(tagged_entity, tag)
    end
    EntityAddTag(entity, tag)
end

function is_vaild(id)
    return id and id > 0
end

function get_id(t)
    return getmetatable(t).id
end

function get_first_component_data_including_disabled(entity, type, ...)
    return ComponentData(EntityGetFirstComponentIncludingDisabled(entity, type, ...))
end

--#endregion

--#region

function append_translations(filename)
    local common = "data/translations/common.csv"
    ModTextFileSetContent(common, ModTextFileGetContent(common) .. ModTextFileGetContent(filename))
end

function has_flag_run_or_add(flag)
    return GameHasFlagRun(flag) or GameAddFlagRun(flag)
end

function get_camera_corner()
    local camera_x, camera_y = GameGetCameraPos()
    local _, _, w, h = GameGetCameraBounds()
    return camera_x - w / 2, camera_y - h / 2
end

function get_camera_zoom(gui)
    local _, _, camera_w, camera_h = GameGetCameraBounds()
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

function get_children(entity)
    return EntityGetAllChildren(entity) or {}
end

function to_string(value)
    if type(value) == "table" then
        local s = ""
        for i, v in ipairs(value) do
            s = s .. v .. (i < #value and "," or "")
        end
        local i = 1
        for k, v in pairs(value) do
            s = s .. k .. "=" .. v .. (i < #value and "," or "")
            i = i + 1
        end
        return s
    end
    return tostring(value)
end

function debug_print(...)
    local s = ""
    for _, v in ipairs({ ... }) do
        s = s .. to_string(v)
    end
    print(s)
    GamePrint(s)
end

--#endregion

--#region

function math.round(x)
    return math.floor(x + 0.5)
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
    for _, v in ipairs(list) do
        if pred(v) then
            table.insert(result, v)
        end
    end
    return result
end

function table.iterate(list, comp, value)
    for _, v in ipairs(list) do
        if comp(v, value) then
            value = v
        end
    end
    return value
end

--#endregion

--#region

NUMERIC_CHARACTERS = "0123456789"

function GetterTable(t, getters)
    return setmetatable(t, {
        __index = function(t, k)
            local getter = getters[k]
            return getter and getter()
        end
    })
end

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

--#endregion
