dofile_once("mods/iota_multiplayer/lib.lua")

function polymorphing_to(string_entity_we_are_about_to_polymorph_to)
    local this_data = Player(string_entity_we_are_about_to_polymorph_to)
    table.insert(player_indexs, {
        EntitiesGetMaxID() + 1,
        this_data.index,
        EntityHasTag(string_entity_we_are_about_to_polymorph_to, "iota_multiplayer.primary_player"),
        EntityHasTag(string_entity_we_are_about_to_polymorph_to, "iota_multiplayer.gui_enabled_player"),
        EntityHasTag(string_entity_we_are_about_to_polymorph_to, "iota_multiplayer.camera_centered_player"),
    })
end

for i, v in ipairs(player_indexs or {}) do
    local player, index, is_primary_player, is_gui_enabled_player, is_camera_centered_player = unpack(v)
    local player_data = Player(player)
    player_data.index = index
    EntityAddTag(player, "iota_multiplayer.player")
    if is_primary_player then
        EntityAddTag(player, "iota_multiplayer.primary_player")
    end
    if is_gui_enabled_player then
        EntityAddTag(player, "iota_multiplayer.gui_enabled_player")
    end
    if is_camera_centered_player then
        EntityAddTag(player, "iota_multiplayer.camera_centered_player")
    end
    local ai = EntityGetFirstComponent(player, "AnimalAIComponent")
    if ai ~= nil then
        set_component_enabled(ai, false)
    end
    local bound = EntityGetFirstComponent(player, "CameraBoundComponent")
    if bound ~= nil then
        EntityRemoveComponent(player, bound)
    end
    EntityAddComponent2(player, "StreamingKeepAliveComponent")
end
player_indexs = {}
