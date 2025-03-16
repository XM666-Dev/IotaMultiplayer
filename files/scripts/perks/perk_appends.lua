dofile_once("mods/iota_multiplayer/files/scripts/lib/environment.lua")
dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local PerkStats = Entity{
    spawn_count = VariableField("iota_multiplayer.spawn_count", "value_int"),
}
local raw_perk_pickup = perk_pickup
function perk_pickup(entity_item, entity_who_picked, item_name, do_cosmetic_fx, kill_other_perks, no_perk_entity_)
    local x, y = EntityGetTransform(entity_item)
    local perk_stats = EntityGetInRadiusWithTag(x, y, 30, "iota_multiplayer.perk_stats")[1]
    local share = ModSettingGet("iota_multiplayer.share_temple_perk") and perk_stats ~= nil
    if share then
        local perk_stats_object = PerkStats(perk_stats)
        perk_stats_object.spawn_count = perk_stats_object.spawn_count + 1
        share = perk_stats_object.spawn_count < #get_players_including_disabled()
    end
    if share then
        for i, perk in ipairs(EntityGetWithTag("perk")) do
            EntityKill(perk)
        end
        local x, y = EntityGetTransform(perk_stats)
        perk_spawn_many(x - 30, y)
    end
    raw_perk_pickup(entity_item, entity_who_picked, item_name, do_cosmetic_fx, kill_other_perks and not share, no_perk_entity_)
end
