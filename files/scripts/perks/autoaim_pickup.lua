dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

function item_pickup(item, pickupper)
    local pickupper_object = Player(pickupper)
    local enabled = not ComponentGetIsEnabled(pickupper_object.autoaim._id)
    set_component_enabled(pickupper_object.autoaim._id, enabled)
    GamePrint(table.concat{GameTextGet("$action_autoaim"), " ", GameTextGet(enabled and "$option_on" or "$option_off")})
end
