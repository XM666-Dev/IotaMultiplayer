dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

function item_pickup(item, pickupper)
    local pickupper_object = Player(pickupper)
    pickupper_object.autoaim._enabled = not pickupper_object.autoaim._enabled
    GamePrint(table.concat{GameTextGet("$action_autoaim"), " ", GameTextGet(pickupper_object.autoaim._enabled and "$option_on" or "$option_off")})
end
