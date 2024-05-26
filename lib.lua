local sult = dofile_once("mods/iota_multiplayer/files/scripts/lib/sult.lua")
return sult.Script(function()
    sult:import()

    dofile_once("mods/mnee/lib.lua")

    MOD = ModData("iota_multiplayer")

    function ModAccessorMetatable()
        local world_state = GameGetWorldStateEntity()
        return AccessorMetatable {
            primary_player = TagEntityAccess(MOD.primary_player),
            gui_enabled_player = TagEntityAccess(MOD.gui_enabled_player),
            previous_gui_enabled_player = TagEntityAccess(MOD.previous_gui_enabled_player),
            camera_centered_player = TagEntityAccess(MOD.camera_centered_player),
            previous_camera_centered_player = TagEntityAccess(MOD.previous_camera_centered_player),
            max_user = EntityVariableAccess(world_state, MOD.max_user, INT),
            money = EntityVariableAccess(world_state, MOD.money, INT)
        }
    end

    function ModAccessor()
        return setmetatable({}, ModAccessorMetatable())
    end

    function set_mod_accessor()
        setmetatable(_G, ModAccessorMetatable())
    end

    function PlayerData(player)
        if not is_vaild(player) then
            return {}
        end
        local t = {
            controls = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")),
            shooter = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")),
            listener = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "AudioListenerComponent")),
            gui = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")),
            wallet = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "WalletComponent")),
            pick_upper = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "ItemPickUpperComponent")),
            is_inventory_open = function(self)
                return self.gui and self.gui.mActive
            end,
            mnin_bind = function(self, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode)
                return mnee.mnin_bind(MOD .. self.user, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode)
            end,
            mnin_axis = function(self, name, dirty_mode, pressed_mode, is_vip, key_mode)
                return mnee.mnin_axis(MOD .. self.user, name, dirty_mode, pressed_mode, is_vip, key_mode)
            end,
            mnin_stick = function(self, name, dirty_mode, pressed_mode, is_vip, key_mode)
                return mnee.mnin_stick(MOD .. self.user, name, dirty_mode, pressed_mode, is_vip, key_mode)
            end
        }
        setmetatable(t, AccessorMetatable {
            user = EntityVariableAccess(player, MOD.user, INT)
        })
        return t
    end

    function add_player(player)
        EntityAddTag(player, MOD.player)
        max_user = max_user + 1
        PlayerData(player).user = max_user
        EntityAddComponent2(player, "LuaComponent", {
            script_source_file = "mods/iota_multiplayer/files/scripts/animals/player_callback.lua",
            script_damage_about_to_be_received = "mods/iota_multiplayer/files/scripts/animals/player_callback.lua",
            script_kick = "mods/iota_multiplayer/files/scripts/animals/player_callback.lua"
        })
    end

    function load_player(x, y)
        local player = EntityLoad("data/entities/player.xml", x, y)
        add_player(player)
        return player
    end

    function get_players()
        return EntityGetWithTag(MOD.player)
    end

    function perk_spawn_with_data(x, y, perk_data, script_item_picked_up)
        local entity = EntityLoad("data/entities/items/pickup/perk.xml", x, y)
        EntityAddComponent2(entity, "SpriteComponent", {
            image_file = perk_data.perk_icon or "data/items_gfx/perk.xml",
            offset_x = 8,
            offset_y = 8,
            update_transform = true,
            update_transform_rotation = false
        })
        EntityAddComponent2(entity, "ItemComponent", {
            item_name = perk_data.ui_name,
            ui_description = perk_data.ui_description,
            ui_display_description_on_pick_up_hint = true,
            play_spinning_animation = false,
            play_hover_animation = false,
            play_pick_sound = true
        })
        EntityAddComponent2(entity, "SpriteOffsetAnimatorComponent", {
            sprite_id = -1,
            x_amount = 0,
            x_phase = 0,
            x_phase_offset = 0,
            x_speed = 0,
            y_amount = 2,
            y_speed = 3
        })
        EntityAddComponent2(entity, "LuaComponent", {
            script_item_picked_up = script_item_picked_up,
            execute_every_n_frame = -1
        })
        return entity
    end

    function teleport(entity, from_x, from_y, to_x, to_y)
        EntitySetTransform(entity, to_x, to_y)
        EntityLoad("data/entities/particles/teleportation_source.xml", from_x, from_y)
        EntityLoad("data/entities/particles/teleportation_target.xml", to_x, to_y)
        GamePlaySound("data/audio/Desktop/misc.bank", "misc/teleport_use", to_x, to_y)
    end
end)
