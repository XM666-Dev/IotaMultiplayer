dofile_once("mods/iota_multiplayer/files/scripts/lib/isutilities.lua")
dofile_once("mods/mnee/lib.lua")

MULTIPLAYER = ModIDData("iota_multiplayer")

function set_dictionary_metatable()
    local world_state = GameGetWorldStateEntity()
    setmetatable(_G, DictionaryMetatable {
        spawned_player = TagEntityEntry(MULTIPLAYER.spawned_player),
        gui_enabled_player = TagEntityEntry(MULTIPLAYER.gui_enabled_player),
        camera_centered_player = TagEntityEntry(MULTIPLAYER.camera_centered_player),
        max_user = EntityVariableEntry(world_state, MULTIPLAYER.max_user, INT)
    })
end

function PlayerData(player)
    if not player then
        return {}
    end
    local controls_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    local shooter_component = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
    local listener_component = EntityGetFirstComponentIncludingDisabled(player, "AudioListenerComponent")
    local gui_component = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
    local wallet_component = EntityGetFirstComponentIncludingDisabled(player, "WalletComponent")
    local t = {
        controls = ComponentData(controls_component),
        shooter = ComponentData(shooter_component),
        listener = ComponentData(listener_component),
        gui = ComponentData(gui_component),
        wallet = ComponentData(wallet_component),
        mnin_bind = function(self, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode)
            return mnee.mnin_bind(MULTIPLAYER .. self.user, name, dirty_mode, pressed_mode, is_vip, loose_mode, key_mode)
        end,
        mnin_axis = function(self, name, dirty_mode, pressed_mode, is_vip, key_mode)
            return mnee.mnin_axis(MULTIPLAYER .. self.user, name, dirty_mode, pressed_mode, is_vip, key_mode)
        end,
        mnin_stick = function(self, name, dirty_mode, pressed_mode, is_vip, key_mode)
            return mnee.mnin_stick(MULTIPLAYER .. self.user, name, dirty_mode, pressed_mode, is_vip, key_mode)
        end
    }
    setmetatable(t, DictionaryMetatable {
        user = EntityVariableEntry(player, MULTIPLAYER.user, INT),
        previous_money = EntityVariableEntry(player, MULTIPLAYER.previous_money, INT)
    })
    return t
end

function add_player(player)
    EntityAddTag(player, MULTIPLAYER.player)
    max_user = max_user + 1
    PlayerData(player).user = max_user
end

function load_player(x, y)
    local player = EntityLoad("data/entities/player.xml", x, y)
    add_player(player)
    return player
end

function get_players()
    return EntityGetWithTag(MULTIPLAYER.player)
end

function set_gui_enabled(player, enabled)
    local player_data = PlayerData(player)
    local gui_component = get_id(player_data.gui)
    if enabled then
        EntitySetComponentIsEnabled(player, gui_component, true)
    elseif ComponentGetIsEnabled(gui_component) then
        EntityRemoveComponent(player, gui_component)
        local component = EntityAddComponent2(player, "InventoryGuiComponent")
        EntitySetComponentIsEnabled(player, component, false)
    end
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

function is_mouse_down_filter(name, pressed_mode)
    if not entity then
        entity = EntityCreateNew()
    end
    local controls = EntityGetFirstComponent(entity, "ControlsComponent") or EntityAddComponent2(entity, "ControlsComponent")
    if name == "mouse_left" then
        if pressed_mode then
            return ComponentGetValue2(controls, "mButtonFrameLeftClick") == GameGetFrameNum()
        end
        return ComponentGetValue2(controls, "mButtonDownLeftClick")
    elseif name == "mouse_right" then
        if pressed_mode then
            return ComponentGetValue2(controls, "mButtonFrameRightClick") == GameGetFrameNum()
        end
        return ComponentGetValue2(controls, "mButtonDownRightClick")
    end
end
