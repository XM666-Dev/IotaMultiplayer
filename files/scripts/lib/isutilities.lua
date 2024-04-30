dofile_once("data/scripts/lib/utilities.lua")

--#region

function DictionaryMT(entries)
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

function ComponentValueEntry(component, field_name)
    return {
        get = function()
            return ComponentGetValue2(component, field_name)
        end,
        set = function(...)
            ComponentSetValue2(component, field_name, ...)
        end
    }
end

function EntityVariableEntry(entity, variable_name, field_name)
    local component = entity_get_or_add_variable_component(entity, variable_name)
    return ComponentValueEntry(component, field_name)
end

function StateVariableEntry(variable_name, field_name)
    local state = GameGetWorldStateEntity()
    return EntityVariableEntry(state, variable_name, field_name)
end

function TagEntityEntry(tag)
    return {
        get = function()
            return tag_get_entity(tag)
        end,
        set = function(v)
            tag_set_entity(tag, v)
        end
    }
end

function ComponentData(component)
    local t = {}
    setmetatable(t, {
        __index = function(_, k)
            return ComponentGetValue2(component, k)
        end,
        __newindex = function(_, k, v)
            ComponentSetValue2(component, k, v)
        end,
        __call = function(_, k)
            return ComponentValueEntry(component, k)
        end,
        __len = function()
            return component
        end
    })
    return t
end

function Namespace(name)
    local t = {}
    setmetatable(t, {
        __index = function(_, k)
            return name .. "." .. k
        end,
        __call = function()
            return name
        end
    })
    return t
end

--#endregion

String = "value_string"
Int = "value_int"
Bool = "value_bool"
Float = "value_float"

function entity_get_or_add_variable_component(entity, variable_name)
    return get_variable_storage_component(entity, variable_name) or
        EntityAddComponent2(entity, "VariableStorageComponent", { name = variable_name })
end

function entity_get_variable(entity, variable_name, field_name)
    local component = entity_get_or_add_variable_component(entity, variable_name)
    return ComponentGetValue2(component, field_name)
end

function entity_set_variable(entity, variable_name, field_name, value)
    local component = entity_get_or_add_variable_component(entity, variable_name)
    ComponentSetValue2(component, field_name, value)
end

function state_get_variable(variable_name, field_name)
    local state = GameGetWorldStateEntity()
    return entity_get_variable(state, variable_name, field_name)
end

function state_set_variable(variable_name, field_name, value)
    local state = GameGetWorldStateEntity()
    entity_set_variable(state, variable_name, field_name, value)
end

function tag_get_entity(tag)
    return EntityGetWithTag(tag)[1]
end

function tag_set_entity(tag, entity)
    EntityRemoveTag(tag_get_entity(tag), tag)
    EntityAddTag(entity, tag)
end

function entity_get_children(entity)
    return EntityGetAllChildren(entity) or {}
end

function has_flag_run_once(flag)
    if state_get_variable(flag, Bool) then
        return true
    end
    state_set_variable(flag, Bool, true)
    return false
end

function print_table(t)
    local str = ""
    for _, v in ipairs(t) do
        str = str .. tostring(v)
    end
    GamePrint(str)
end

function table_find(list, f)
    for _, v in ipairs(list) do
        if f(v) then
            return v
        end
    end
end

function table_filter(list, f)
    local t = {}
    for _, v in ipairs(list) do
        if f(v) then
            table.insert(t, v)
        end
    end
    return t
end

function table_iterate(list, comp, value)
    for _, v in ipairs(list) do
        if comp(v, value) then
            value = v
        end
    end
    return value
end
