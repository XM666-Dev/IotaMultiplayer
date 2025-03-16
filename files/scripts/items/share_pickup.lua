dofile_once("mods/iota_multiplayer/files/scripts/lib/tactic.lua")

local entities = {}
local components = {}
local function insert_components(entity)
    for i, component in ipairs(EntityGetAllComponents(entity)) do
        table.insert(components, {component, ComponentGetIsEnabled(component)})
    end
    for i, child in ipairs(get_children(entity)) do
        insert_components(child)
    end
end
function item_pickup(item)
    table.insert(entities, item)
    insert_components(item)
end

function ____cached_func()
    for i, entity in ipairs(entities) do
        EntityRemoveFromParent(entity)
    end
    for i, v in ipairs(components) do
        set_component_enabled(unpack(v))
    end
    entities = {}
    components = {}
end
