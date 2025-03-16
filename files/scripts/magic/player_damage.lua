dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

function damage_received(damage, message, responsible, fatal, projectile_responsible)
    local this = GetUpdatedEntityID()
    local this_object = Player(this)
    if fatal and not this_object.damage_model_.wait_for_kill_flag_on_death then
        this_object.damage_model_.wait_for_kill_flag_on_death = #get_players() > 1
        this_object.damage_frame = GameGetFrameNum()
        this_object.damage_message = message
        this_object.damage_responsible = IsPlayer(responsible) and "$animal_player" or EntityGetName(responsible) or ""
    end
end
