dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local player_indexs = {}
function polymorphing_to(polymorphed)
    table.insert(player_indexs, {EntitiesGetMaxID() + 1, Player(polymorphed).index})
end

function ____cached_func()
    for i, v in ipairs(player_indexs) do
        local player, index = unpack(v)
        local player_object = Player(player)
        player_object:add()
        player_object.index = index
        player_object.controls_.polymorph_hax = true
        local ai = EntityGetFirstComponent(player, "AnimalAIComponent")
        set_component_enabled(ai, false)
        local bound = EntityGetFirstComponent(player, "CameraBoundComponent")
        remove_component(bound)
    end
    player_indexs = {}
end
