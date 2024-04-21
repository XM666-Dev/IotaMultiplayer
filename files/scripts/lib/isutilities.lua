dofile_once("data/scripts/lib/utilities.lua")

function create_dictionary_metatable(entries)
    return {
        __index = function(t, k)
            local entry = entries[k]
            if entry then
                return entry.get()
            end
            return rawget(t, k)
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

function tag_get_entity(tag)
    return EntityGetWithTag(tag)[1]
end

function tag_set_entity(tag, entity)
    local entities = EntityGetWithTag(tag)
    for _, entity in ipairs(entities) do
        EntityRemoveTag(entity, tag)
    end
    if entity ~= nil then
        EntityAddTag(entity, tag)
    end
end

function tag_entry_entity(tag)
    return {
        get = function()
            return tag_get_entity(tag)
        end,
        set = function(v)
            tag_set_entity(tag, v)
        end
    }
end

String = "value_string"
Int = "value_int"
Bool = "value_bool"
Float = "value_float"

function var_get(entity, name, field)
    local comp = get_variable_storage_component(entity, name)
    if comp then
        return ComponentGetValue2(comp, field)
    end
end

function var_set(entity, name, field, value)
    local comp = get_variable_storage_component(entity, name)
    if comp then
        return ComponentSetValue2(comp, field, value)
    end
    EntityAddComponent2(entity, "VariableStorageComponent", { name = name, [field] = value })
end

function var_entry(entity, name, field)
    return {
        get = function()
            return var_get(entity, name, field)
        end,
        set = function(v)
            var_set(entity, name, field, v)
        end
    }
end

function global_get(name, field)
    local state = GameGetWorldStateEntity()
    return var_get(state, name, field)
end

function global_set(name, field, value)
    local state = GameGetWorldStateEntity()
    var_set(state, name, field, value)
end

function global_entry(name, field)
    return {
        get = function()
            return global_get(name, field)
        end,
        set = function(v)
            global_set(name, field, v)
        end
    }
end

function namespace(name)
    local t = {}
    setmetatable(t, {
        __index = function(_, k)
            return name .. "." .. k
        end,
        __tostring = function(_)
            return name
        end
    })
    return t
end

function create_component_table(comp)
    local t = {}
    setmetatable(t, {
        __index = function(_, k)
            return ComponentGetValue2(comp, k)
        end,
        __newindex = function(_, k, v)
            ComponentSetValue2(comp, k, v)
        end,
        __call = function(_, k)
            return {
                get = function()
                    return ComponentGetValue2(comp, k)
                end,
                set = function(...)
                    ComponentSetValue2(comp, k, ...)
                end
            }
        end
    })
    return t
end

function has_flag_run_once(flag)
    if global_get(flag, Bool) then
        return true
    end
    global_set(flag, Bool, true)
    return false
end

function entity_get_children(entity)
    return EntityGetAllChildren(entity) or {}
end

function printv(...)
    local str = ""
    for _, v in ipairs({ ... }) do
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
