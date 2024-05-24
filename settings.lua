dofile_once("mods/iota_multiplayer/lib.lua")
dofile_once("data/scripts/lib/mod_settings.lua")

local parse_csv = dofile_once("mods/iota_multiplayer/files/scripts/lib/csv.lua")
local translations = parse_csv(ModTextFileGetContent("mods/iota_multiplayer/files/translations.csv"))

function get_text(key)
    local text = translations.get(key, get_language())
    return text ~= "" and text or translations.get(key, "en")
end

local mod_id = get_id(MULTIPLAYER)
mod_settings_version = 1
mod_settings = {
    Setting({
        id = "player_num",
        value_default = 2,
        value_min = 1,
        value_max = 8,
        scope = MOD_SETTING_SCOPE_NEW_GAME
    }, {
        ui_name = function() return get_text("iota_multiplayer.setting_player_num") end,
        ui_description = function() return get_text("iota_multiplayer.settingdesc_player_num") end
    }),
    Setting({
        id = "temple_heart_share",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME
    }, {
        ui_name = function() return get_text("iota_multiplayer.setting_temple_heart_share") end,
        ui_description = function() return get_text("iota_multiplayer.settingdesc_temple_heart_share") end
    }),
    Setting({
        id = "temple_refresh_share",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME
    }, {
        ui_name = function() return get_text("iota_multiplayer.setting_temple_refresh_share") end,
        ui_description = function() return get_text("iota_multiplayer.settingdesc_temple_refresh_share") end
    }),
    Setting({
        id = "temple_perk_respawn",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME
    }, {
        ui_name = function() return get_text("iota_multiplayer.setting_temple_perk_respawn") end,
        ui_description = function() return get_text("iota_multiplayer.settingdesc_temple_perk_respawn") end
    }),
    Setting({
        id = "kick_immunity",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME
    }, {
        ui_name = function() return get_text("iota_multiplayer.setting_kick_immunity") end,
        ui_description = function() return get_text("iota_multiplayer.settingdesc_kick_immunity") end
    })
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
