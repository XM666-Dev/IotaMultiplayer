dofile_once("data/scripts/lib/mod_settings.lua")

local mod_id
if GameGetWorldStateEntity() ~= 0 then
    dofile_once("mods/iota_multiplayer/lib.lua")
    dofile_once("mods/iota_multiplayer/files/scripts/lib/csv.lua")

    local translations = parse_csv(ModTextFileGetContent("mods/iota_multiplayer/files/translations.csv"))

    function get_text(key)
        local text = translations.get(key, get_language())
        return text ~= "" and text or translations.get(key, "en")
    end

    mod_id = get_id(MOD)
    mod_settings_version = 1
    mod_settings = {
        GetterTable({
            category_id = "share",
            settings = {
                GetterTable({
                    id = "share_money",
                    value_default = true,
                    scope = MOD_SETTING_SCOPE_RUNTIME
                }, {
                    ui_name = function() return get_text("iota_multiplayer.setting_share_money") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_share_money") end
                }),
                GetterTable({
                    id = "share_temple_heart",
                    value_default = true,
                    scope = MOD_SETTING_SCOPE_RUNTIME
                }, {
                    ui_name = function() return get_text("iota_multiplayer.setting_share_temple_heart") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_heart") end
                }),
                GetterTable({
                    id = "share_temple_refresh",
                    value_default = true,
                    scope = MOD_SETTING_SCOPE_RUNTIME
                }, {
                    ui_name = function() return get_text("iota_multiplayer.setting_share_temple_refresh") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_refresh") end
                }),
                GetterTable({
                    id = "share_temple_perk",
                    value_default = true,
                    scope = MOD_SETTING_SCOPE_RUNTIME
                }, {
                    ui_name = function() return get_text("iota_multiplayer.setting_share_temple_perk") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_perk") end
                })
            }
        }, {
            ui_name = function() return get_text("iota_multiplayer.setting_share") end,
            ui_description = function() return get_text("iota_multiplayer.settingdesc_share") end
        }),
        GetterTable({
            category_id = "friendly_fire",
            settings = {
                GetterTable({
                    id = "friendly_fire_percentage",
                    value_default = 0.5,
                    value_min = 0,
                    value_max = 1,
                    value_display_multiplier = 100,
                    value_display_formatting = " $0 %",
                    scope = MOD_SETTING_SCOPE_RUNTIME
                }, {
                    ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_percentage") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_percentage") end

                }),
                GetterTable({
                    id = "friendly_fire_kick",
                    value_default = false,
                    scope = MOD_SETTING_SCOPE_RUNTIME
                }, {
                    ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_kick") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_kick") end
                }),
                GetterTable({
                    id = "friendly_fire_kick_drop",
                    value_default = false,
                    scope = MOD_SETTING_SCOPE_RUNTIME
                }, {
                    ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_kick_drop") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_kick_drop") end
                })
            }
        }, {
            ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire") end,
            ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire") end
        })
    }
else
    mod_id = "iota_multiplayer"
    mod_settings_version = 1
    mod_settings = {
        {
            id = "_",
            ui_name = "Enter a world to edit settings.",
            not_setting = true
        }
    }
end

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
