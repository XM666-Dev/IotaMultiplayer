dofile_once("mods/iota_multiplayer/files/scripts/lib/sult.lua")
dofile_once("mods/mnee/lib.lua")

local function is_player_enabled(player)
    local player_data = Player(player)
    return not player_data.dead
end
local mod_metatable = Metatable {
    id = { get = GameGetWorldStateEntity },
    primary_player = EntityAccessor("iota_multiplayer.primary_player"),
    gui_enabled_player = EntityAccessor("iota_multiplayer.gui_enabled_player", is_player_enabled),
    previous_gui_enabled_player = EntityAccessor("iota_multiplayer.previous_gui_enabled_player"),
    camera_centered_player = EntityAccessor("iota_multiplayer.camera_centered_player", function(player)
        return is_player_enabled(player) or #get_players() < 1
    end),
    previous_camera_centered_player = EntityAccessor("iota_multiplayer.previous_camera_centered_player"),
    max_user = VariableAccessor("iota_multiplayer.max_user", "value_int"),
    player_positions = VariableAccessor("iota_multiplayer.player_positions", "value_string"),
}
mod = setmetatable({}, mod_metatable)

local player_metatable = Metatable {
    controls = ComponentAccessor(EntityGetFirstComponent, "ControlsComponent"),
    shooter = ComponentAccessor(EntityGetFirstComponent, "PlatformShooterPlayerComponent"),
    listener = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "AudioListenerComponent"),
    gui = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "InventoryGuiComponent"),
    wallet = ComponentAccessor(EntityGetFirstComponent, "WalletComponent"),
    pick_upper = ComponentAccessor(EntityGetFirstComponent, "ItemPickUpperComponent"),
    damage_model = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "DamageModelComponent"),
    lukki_disable_sprite = ComponentAccessor(EntityGetFirstComponent, "SpriteComponent", "lukki_disable"),
    genome = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "GenomeDataComponent"),
    character_data = ComponentAccessor(EntityGetFirstComponent, "CharacterDataComponent"),
    inventory = ComponentAccessor(EntityGetFirstComponent, "Inventory2Component"),
    user = VariableAccessor("iota_multiplayer.user", "value_int"),
    dead = VariableAccessor("iota_multiplayer.dead", "value_bool"),
    previous_money = VariableAccessor("iota_multiplayer.previous_money", "value_int"),
    damage_frame = VariableAccessor("iota_multiplayer.damage_frame", "value_int"),
    damage_message = VariableAccessor("iota_multiplayer.damage_message", "value_string"),
    damage_entity_thats_responsible = VariableAccessor("iota_multiplayer.damage_entity_thats_responsible", "value_int"),
    get_arm_r = ConstantAccessor(function(self)
        return get_children(self.id, "player_arm_r")[1]
    end),
    is_inventory_open = ConstantAccessor(function(self)
        return self.gui ~= nil and self.gui.mActive
    end),
    mnin_bind = ConstantAccessor(function(self, bind_id, dirty_mode, pressed_mode, is_vip, strict_mode, inmode)
        return mnee.mnin_bind("iota_multiplayer" .. self.user, bind_id, dirty_mode, pressed_mode, is_vip, strict_mode, inmode)
    end),
    mnin_axis = ConstantAccessor(function(self, bind_id, is_alive, pressed_mode, is_vip, inmode)
        return mnee.mnin_axis("iota_multiplayer" .. self.user, bind_id, is_alive, pressed_mode, is_vip, inmode)
    end),
    mnin_stick = ConstantAccessor(function(self, bind_id, pressed_mode, is_vip, inmode)
        return mnee.mnin_stick("iota_multiplayer" .. self.user, bind_id, pressed_mode, is_vip, inmode)
    end),
    jpad_check = ConstantAccessor(function(self, bind_id)
        return mnee.jpad_check(mnee.get_pbd(mnee.get_bindings()["iota_multiplayer" .. self.user][bind_id]).main)
    end),
}
function Player(player)
    return validate_entity(player) and setmetatable({ id = player }, player_metatable) or {}
end

function add_player(player)
    EntityAddTag(player, "iota_multiplayer.player")
    mod.max_user = mod.max_user + 1
    local player_data = Player(player)
    player_data.user = mod.max_user
    EntityAddComponent2(player, "LuaComponent", {
        script_source_file = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_damage_about_to_be_received = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_kick = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_damage_received = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
    })
end

function load_player(x, y)
    local player = EntityLoad("data/entities/player.xml", x, y)
    add_player(player)
    return player
end

function get_players_including_disabled()
    return EntityGetWithTag("iota_multiplayer.player")
end

function get_players()
    return table.filter(get_players_including_disabled(), function(player)
        local player_data = Player(player)
        return not player_data.dead
    end)
end

function set_dead(player, dead)
    local player_data = Player(player)
    EntitySetComponentIsEnabled(player, player_data.genome._id, not dead)
    EntitySetComponentIsEnabled(player, player_data.damage_model._id, not dead)
    if dead then
        EntityRemoveTag(player, "hittable")
        if player_data.controls ~= nil then
            local controls_component = player_data.controls._id
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
        update_transform_rotation = false,
    })
    EntityAddComponent2(entity, "ItemComponent", {
        item_name = perk_data.ui_name,
        ui_description = perk_data.ui_description,
        ui_display_description_on_pick_up_hint = true,
        play_spinning_animation = false,
        play_hover_animation = false,
        play_pick_sound = true,
    })
    EntityAddComponent2(entity, "SpriteOffsetAnimatorComponent", {
        sprite_id = -1,
        x_amount = 0,
        x_phase = 0,
        x_phase_offset = 0,
        x_speed = 0,
        y_amount = 2,
        y_speed = 3,
    })
    EntityAddComponent2(entity, "LuaComponent", {
        script_item_picked_up = script_item_picked_up,
        execute_every_n_frame = -1,
    })
    return entity
end

function teleport(entity, from_x, from_y, to_x, to_y)
    EntitySetTransform(entity, to_x, to_y)
    EntityLoad("data/entities/particles/teleportation_source.xml", from_x, from_y)
    EntityLoad("data/entities/particles/teleportation_target.xml", to_x, to_y)
    GamePlaySound("data/audio/Desktop/misc.bank", "misc/teleport_use", to_x, to_y)
end
