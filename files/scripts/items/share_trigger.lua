dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local share_class = Class {
    shared_indexs = VariableAccessor("iota_multiplayer.shared_indexs", "value_string", "{}"),
}
local function Share(id)
    return setmetatable({ id = id }, share_class)
end
function collision_trigger(colliding)
    local this = GetUpdatedEntityID()
    local this_data = Share(this)
    local shared_indexs = deserialize(this_data.shared_indexs)
    local colliding_data = Player(colliding)
    if table.find(shared_indexs, function(v) return v == colliding_data.index end) then return end
    table.insert(shared_indexs, colliding_data.index)
    this_data.shared_indexs = serialize(shared_indexs)

    local x, y = EntityGetTransform(this)
    GamePickUpInventoryItem(colliding, this)
    EntitySetTransform(this, x, y)
    EntityRemoveFromParent(this)
    local components = EntityGetAllComponents(this)
    for i, component in ipairs(components) do
        set_component_enabled(component, true)
    end

    if #shared_indexs == #get_players_including_disabled() then
        EntityKill(this)
    end
end
