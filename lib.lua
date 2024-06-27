dofile_once("mods/iota_multiplayer/files/scripts/lib/sult.lua")
dofile_once("mods/mnee/lib.lua")

MOD = ModData("iota_multiplayer")

function ModAccessorTable(t)
    local world_state = GameGetWorldStateEntity()
    return AccessorTable(t, {
        primary_player = TagEntityAccessor(MOD.primary_player),
        gui_enabled_player = TagEntityAccessor(MOD.gui_enabled_player, is_player_enabled),
        previous_gui_enabled_player = TagEntityAccessor(MOD.previous_gui_enabled_player),
        camera_centered_player = TagEntityAccessor(MOD.camera_centered_player, is_player_enabled),
        previous_camera_centered_player = TagEntityAccessor(MOD.previous_camera_centered_player),
        max_user = EntityVariableAccessor(world_state, MOD.max_user, "value_int"),
        money = EntityVariableAccessor(world_state, MOD.money, "value_int")
    })
end

function PlayerData(player)
    local wallet = EntityGetFirstComponentIncludingDisabled(player, "WalletComponent")
    return validate_entity(player) and AccessorTable({
        controls = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")),
        shooter = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")),
        listener = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "AudioListenerComponent")),
        gui = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")),
        wallet = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "WalletComponent")),
        pick_upper = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "ItemPickUpperComponent")),
        damage_model = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")),
        lukki_disable_sprite = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "SpriteComponent", "lukki_disable")),
        genome = ComponentData(EntityGetFirstComponentIncludingDisabled(player, "GenomeDataComponent")),
        get_arm_r = function(self)
            local children = get_children(player)
            return children[table.find(children, function(child)
                return EntityGetName(child) == "arm_r" or EntityHasTag(child, "player_arm_r")
            end)]
        end,
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
    }, {
        user = EntityVariableAccessor(player, MOD.user, "value_int"),
        dead = EntityVariableAccessor(player, MOD.dead, "value_bool"),
        previous_money = EntityVariableAccessor(player, MOD.previous_money, "value_int", wallet and ComponentGetValue2(wallet, "money")),
        last_damage_message = EntityVariableAccessor(player, MOD.last_damage_message, "value_string"),
        last_damage_entity_thats_responsible = EntityVariableAccessor(player, MOD.last_damage_entity_thats_responsible, "value_int")
    }) or {}
end

function add_player(player)
    EntityAddTag(player, MOD.player)
    max_user = max_user + 1
    local player_data = PlayerData(player)
    player_data.user = max_user
    EntityAddComponent2(player, "LuaComponent", {
        script_source_file = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_damage_received = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_damage_about_to_be_received = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_kick = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua"
    })
end

function load_player(x, y)
    local player = EntityLoad("data/entities/player.xml", x, y)
    add_player(player)
    return player
end

function get_players_including_disabled()
    return EntityGetWithTag(MOD.player)
end

function get_players()
    return table.filter(get_players_including_disabled(), function(player)
        local player_data = PlayerData(player)
        return not player_data.dead
    end)
end

function is_player_enabled(player)
    local player_data = PlayerData(player)
    return not player_data.dead
end

function set_dead(player, dead)
    local player_data = PlayerData(player)
    EntitySetComponentIsEnabled(player, get_id(player_data.genome), not dead)
    EntitySetComponentIsEnabled(player, get_id(player_data.damage_model), not dead)
    if dead then
        EntityRemoveTag(player, "hittable")
        if player_data.controls ~= nil then
            local controls_component = get_id(player_data.controls)
            for k in pairs(ComponentGetMembers(controls_component) or {}) do
                if k:find("mButtonDown") and not k:find("mButtonDownDelayLine") then
                    ComponentSetValue2(controls_component, k, false)
                end
            end
        end
    else
        EntityAddTag(player, "hittable")
        GamePlayAnimation(player, "intro_stand_up", 2)
        player_data.damage_model.hp = player_data.damage_model.max_hp
        EntityInflictDamage(player, 0.04, "DAMAGE_PROJECTILE", "", "NONE", 0, 0)
        player_data.damage_model.hp = player_data.damage_model.max_hp
        GamePrint(GameTextGet("$log_coop_resurrected_player", player_data.user))
    end
    player_data.dead = dead
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

local max_id = 0x7FFFFFFF
ids = {}
function new_id(s)
    if ids[s] == nil then
        ids[s] = max_id
        max_id = max_id - 1
    end
    return ids[s]
end
