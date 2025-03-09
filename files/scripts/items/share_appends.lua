dofile_once("mods/iota_multiplayer/files/scripts/lib/environment.lua")
dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local Share = Entity{shared_indexs = SerializedField(VariableField("iota_multiplayer.shared_indexs", "value_string", "{}"))}
local ids = {
    ["data/entities/items/pickup/heart_fullhp_temple.xml"] = "iota_multiplayer.share_temple_heart",
    ["data/entities/items/pickup/spell_refresh.xml"] = "iota_multiplayer.share_temple_refresh",
}
local raw_item_pickup = item_pickup
function item_pickup(item, pickupper, name)
    local share_object = Share(item)
    local pickupper_object = Player(pickupper)
    local shared_indexs = share_object.shared_indexs
    table.insert(shared_indexs, pickupper_object.index)
    share_object.shared_indexs = shared_indexs

    local raw_entity_kill = EntityKill
    if ModSettingGet(ids[EntityGetFilename(item)]) and #shared_indexs < #get_players_including_disabled() then
        EntityKill = function() end
    end
    raw_item_pickup(item, pickupper, name)
    EntityKill = raw_entity_kill
end
