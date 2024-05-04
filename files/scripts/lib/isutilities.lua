dofile_once("data/scripts/lib/utilities.lua")

--#region

function DictionaryMetatable(entries)
    return {
        __index = function(t, k)
            if entries[k] then
                return entries[k].get()
            end
            return rawget(t, k)
        end,
        __newindex = function(t, k, v)
            if entries[k] then
                entries[k].set(v)
                return
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
    return t
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
    EntityRemoveTag(get_tag_entity(tag), tag)
    EntityAddTag(entity, tag)
end

function get_id(t)
    return rawget(t, "id")
end

function get_children(entity)
    return EntityGetAllChildren(entity) or {}
end

function has_globals_value_or_set(key, value)
    return GlobalsGetValue(key) ~= "" or GlobalsSetValue(key, value)
end

function get_camera_top_left()
    local camera_x, camera_y = GameGetCameraPos()
    local _, _, w, h = GameGetCameraBounds()
    return camera_x - w / 2, camera_y - h / 2
end

function get_camera_zoom(gui)
    local _, _, camera_w, camera_h = GameGetCameraBounds()
    local screen_w, screen_h = GuiGetScreenDimensions(gui)
    return screen_w / camera_w, screen_h / camera_h
end

function set_translations(filename)
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
