dofile_once("mods/iota_multiplayer/files/scripts/lib/sule.lua")(function()
    dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

    local old_init = init
    function _G.init(x, y, w, h)
        old_init(x, y, w, h)
        perk_spawn_with_data(x + 345, y + 400, {
            ui_name = "$log_coop_started",
            ui_description = "$log_coop_started",
            perk_icon = "mods/iota_multiplayer/files/items_gfx/perks/coop.png",
        }, "mods/iota_multiplayer/files/scripts/perks/coop_pickup.lua")
        perk_spawn_with_data(x + 390, y + 395, {
            ui_name = "$action_autoaim",
            ui_description = "$actiondesc_autoaim",
            perk_icon = "mods/iota_multiplayer/files/items_gfx/perks/autoaim.png",
        }, "mods/iota_multiplayer/files/scripts/perks/autoaim_pickup.lua")
    end
end)
