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
    max_index = VariableAccessor("iota_multiplayer.max_index", "value_int"),
    player_positions = SerializedAccessor(
        VariableAccessor("iota_multiplayer.player_positions", "value_string", "{}"),
        "mods/iota_multiplayer/player_positions.lua",
        "mods/iota_multiplayer/player_positions_value_date.lua",
        "mods/iota_multiplayer/player_positions_file_date.lua"
    ),
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
    sprite = ComponentAccessor(EntityGetFirstComponent, "SpriteComponent", "lukki_disable"),
    aiming_reticle = ComponentAccessor(EntityGetFirstComponent, "SpriteComponent", "aiming_reticle"),
    genome = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "GenomeDataComponent"),
    character_data = ComponentAccessor(EntityGetFirstComponent, "CharacterDataComponent"),
    inventory = ComponentAccessor(EntityGetFirstComponent, "Inventory2Component"),
    index = VariableAccessor("iota_multiplayer.index", "value_int"),
    previous_aim_x = VariableAccessor("iota_multiplayer.previous_aim_x", "value_string"),
    previous_aim_y = VariableAccessor("iota_multiplayer.previous_aim_y", "value_string"),
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
        return mnee.mnin_bind("iota_multiplayer" .. self.index, bind_id, dirty_mode, pressed_mode, is_vip, strict_mode, inmode)
    end),
    mnin_axis = ConstantAccessor(function(self, bind_id, is_alive, pressed_mode, is_vip, inmode)
        return mnee.mnin_axis("iota_multiplayer" .. self.index, bind_id, is_alive, pressed_mode, is_vip, inmode)
    end),
    mnin_stick = ConstantAccessor(function(self, bind_id, pressed_mode, is_vip, inmode)
        return mnee.mnin_stick("iota_multiplayer" .. self.index, bind_id, pressed_mode, is_vip, inmode)
    end),
    jpad_check = ConstantAccessor(function(self, bind_id)
        return mnee.jpad_check(mnee.get_pbd(mnee.get_bindings()["iota_multiplayer" .. self.index][bind_id]).main)
    end),
}
function Player(player)
    return validate(player) and setmetatable({ id = player }, player_metatable) or {}
end

function add_player(player)
    EntityAddTag(player, "iota_multiplayer.player")
    mod.max_index = mod.max_index + 1
    local player_data = Player(player)
    player_data.index = mod.max_index
    EntityAddComponent2(player, "LuaComponent", {
        script_kick = "mods/iota_multiplayer/files/scripts/magic/player_friendly_fire.lua",
        script_damage_about_to_be_received = "mods/iota_multiplayer/files/scripts/magic/player_friendly_fire.lua",
        script_damage_received = "mods/iota_multiplayer/files/scripts/magic/player_damage.lua",
        script_polymorphing_to = "mods/iota_multiplayer/files/scripts/magic/player_polymorph.lua",
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
    set_component_enabled(player_data.genome._id, not dead)
    set_component_enabled(player_data.damage_model._id, not dead)
    local effect = get_game_effect(player, "POLYMORPH")
    if effect == nil then
        effect = get_game_effect(player, "POLYMORPH_RANDOM")
    end
    if effect == nil then
        effect = get_game_effect(player, "POLYMORPH_UNSTABLE")
    end
    if effect ~= nil then
        set_component_enabled(effect, not dead)
    end
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
        local protection_polymorph, protection_polymorph_entity = GetGameEffectLoadTo(player, "PROTECTION_POLYMORPH", true)
        ComponentSetValue2(protection_polymorph, "frames", -1)
        EntityAddTag(protection_polymorph_entity, "iota_multiplayer.protection_polymorph")
    else
        EntityAddTag(player, "hittable")
        GamePlayAnimation(player, "intro_stand_up", 2)
        player_data.damage_model.hp = player_data.damage_model.max_hp
        EntityInflictDamage(player, 0.04, "DAMAGE_PROJECTILE", "", "NONE", 0, 0)
        player_data.damage_model.hp = player_data.damage_model.max_hp
        GamePrint(GameTextGet("$log_coop_resurrected_player", player_data.index))
        local protection_polymorph_entity = get_children(player, "iota_multiplayer.protection_polymorph")[1]
        if protection_polymorph_entity ~= nil then
            local protection_polymorph = EntityGetFirstComponent(protection_polymorph_entity, "GameEffectComponent")
            if protection_polymorph ~= nil then
                ComponentSetValue2(protection_polymorph, "frames", 0)
            end
        end
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
    })
    return entity
end

function teleport(entity, from_x, from_y, to_x, to_y)
    EntitySetTransform(entity, to_x, to_y)
    EntityLoad("data/entities/particles/teleportation_source.xml", from_x, from_y)
    EntityLoad("data/entities/particles/teleportation_target.xml", to_x, to_y)
    GamePlaySound("data/audio/Desktop/misc.bank", "misc/teleport_use", to_x, to_y)
end
