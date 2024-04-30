dofile_once("mods/iota_multiplayer/lib.lua")
dofile_once("data/scripts/lib/mod_settings.lua")

local numeric_characters = "0123456789"

local mod_id = MP()
mod_settings_version = 1
mod_settings = {
    {
        id = "player_num",
        ui_name = "Player num",
        ui_description = "",
        value_default = "2",
        allowed_characters = numeric_characters,
        scope = MOD_SETTING_SCOPE_NEW_GAME
    },
    {
    }
}

function ModSettingsUpdate(init_scope)
    local old_version = mod_settings_get_version(mod_id)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
