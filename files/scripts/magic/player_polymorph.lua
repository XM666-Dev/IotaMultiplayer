dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

function polymorphing_to(string_entity_we_are_about_to_polymorph_to)
    local this_data = Player(string_entity_we_are_about_to_polymorph_to)
    table.insert(player_indexs, {
        EntitiesGetMaxID() + 1,
        this_data.index,
    })
end

for i, v in ipairs(player_indexs or {}) do
    local player, index = unpack(v)
    local player_data = Player(player)
    player_data.index = index
    EntityAddTag(player, "iota_multiplayer.player")
    local ai = EntityGetFirstComponent(player, "AnimalAIComponent")
    if ai ~= nil then
        set_component_enabled(ai, false)
    end
    local bound = EntityGetFirstComponent(player, "CameraBoundComponent")
    if bound ~= nil then
        remove_component(bound)
    end
    EntityAddComponent2(player, "StreamingKeepAliveComponent")
end
player_indexs = {}
