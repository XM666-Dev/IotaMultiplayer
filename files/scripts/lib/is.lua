dofile_once("data/scripts/lib/utilities.lua")

--#region

function DictionaryMetatable(entries)
    return {
        __index = function(t, k)
            local entry = entries[k]
            if entry then
                return entry.get()
            end
        end,
        __newindex = function(t, k, v)
            local entry = entries[k]
            if entry then
                return entry.set(v)
            end
            rawset(t, k, v)
        end
    }
end

function ComponentValueEntry(component, field)
    return {
        get = function()
            return ComponentGetValue2(component, field)
        end,
        set = function(...)
            ComponentSetValue2(component, field, ...)
        end
    }
end

function EntityVariableEntry(entity, variable, field)
    local component = get_variable_storage_component_or_add(entity, variable)
    return ComponentValueEntry(component, field)
end

function TagEntityEntry(tag)
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
    local t = { id = component }
    setmetatable(t, {
        __index = function(_, k)
            return ComponentGetValue2(component, k)
        end,
        __newindex = function(_, k, v)
            ComponentSetValue2(component, k, v)
        end,
        __call = function(_, k)
            return ComponentValueEntry(component, k)
        end
    })
    return component and t
end

function ModIDData(mod_id)
    local t = { id = mod_id }
    setmetatable(t, {
        __index = function(_, k)
            return mod_id .. "." .. k
        end,
        __concat = function(_, s)
            return mod_id .. s
        end
    })
    return t
end

--#endregion

STRING = "value_string"
INT = "value_int"
BOOL = "value_bool"
FLOAT = "value_float"

function get_variable_storage_component_or_add(entity, variable)
    return get_variable_storage_component(entity, variable) or EntityAddComponent2(entity, "VariableStorageComponent", { name = variable })
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

function get_id(t)
    return rawget(t, "id")
end

function get_children(entity)
    return EntityGetAllChildren(entity) or {}
end

function has_globals_value_or_set(key)
    return GlobalsGetValue(key) ~= "" or GlobalsSetValue(key, "yes")
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

function get_pos_from_world(gui, x, y)
    local camera_x, camera_y = get_camera_corner()
    local zoom_x, zoom_y = get_camera_zoom(gui)
    return (x - camera_x) * zoom_x, (y - camera_y) * zoom_y
end

function get_frame_num_next()
    return GameGetFrameNum() + 1
end

function append_translations(filename)
    local common = "data/translations/common.csv"
    ModTextFileSetContent(common, ModTextFileGetContent(common) .. ModTextFileGetContent(filename))
end

function print_table(t)
    local s = ""
    for _, v in ipairs(t) do
        s = s .. tostring(v)
    end
    GamePrint(s)
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

NUMERIC_CHARACTERS = "0123456789"

function Setting(setting, functions)
    setmetatable(setting, {
        __index = function(_, k)
            local f = functions[k]
            return f and f()
        end
    })
    return setting
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
