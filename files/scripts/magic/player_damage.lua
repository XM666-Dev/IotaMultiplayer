dofile_once("mods/iota_multiplayer/lib.lua")

function damage_received(damage, message, entity_thats_responsible, is_fatal, projectile_thats_responsible)
    if is_fatal then
        local this = GetUpdatedEntityID()
        local this_data = Player(this)
        this_data.damage_frame = GameGetFrameNum()
        this_data.damage_message = message
        this_data.damage_entity_thats_responsible = entity_thats_responsible
    end
end
