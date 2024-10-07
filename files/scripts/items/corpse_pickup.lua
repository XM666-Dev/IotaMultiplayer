dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local hint_class = Class {
    index = VariableAccessor("iota_multiplayer.index", "value_int"),
}
local function Hint(entity)
    return setmetatable({ id = entity }, hint_class)
end
function item_pickup(entity_item, entity_pickupper, item_name)
    local this = GetUpdatedEntityID()
    local this_data = Hint(this)
    local player = get_player_at_index_including_disabled(this_data.index)
    local player_data = Player(player)
    if player_data.dead and player_data.controls ~= nil then
        player_data.controls.mButtonFrameInventory = get_frame_num_next()
    end
end
