dofile_once("mods/iota_multiplayer/files/scripts/lib/environment.lua")
dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local Share = Entity{shared_indexs = SerializedField(VariableField("iota_multiplayer.shared_indexs", "value_string", "{}"))}
local ids = {
    ["data/entities/items/pickup/heart_fullhp_temple.xml"] = "iota_multiplayer.share_temple_heart",
    ["data/entities/items/pickup/spell_refresh.xml"] = "iota_multiplayer.share_temple_refresh",
}
local raw_item_pickup = item_pickup
function item_pickup(item, picker, name)
    local share_data = Share(item)
    local picker_data = Player(picker)
    local shared_indexs = share_data.shared_indexs
    table.insert(shared_indexs, picker_data.index)
    share_data.shared_indexs = shared_indexs

    local share = ModSettingGet(ids[EntityGetFilename(item)]) and #shared_indexs < #get_players_including_disabled()
    local raw_entity_kill = EntityKill
    if share then
        EntityKill = function() end
    end
    raw_item_pickup(item, picker, name)
    if share then
        EntityKill = raw_entity_kill
    end
end
