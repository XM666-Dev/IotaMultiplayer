dofile_once("mods/iota_multiplayer/files/scripts/lib/sult.lua")
dofile_once("mods/mnee/lib.lua")

MAX_PLAYER_NUM = 8

local function is_player_enabled(player)
    local player_data = Player(player)
    return not player_data.dead
end
local mod_class = Class {
    id = { get = GameGetWorldStateEntity },
    gui_enabled_index = VariableAccessor("iota_multiplayer.gui_enabled_index", "value_int"),
    --previous_gui_enabled_index = VariableAccessor("iota_multiplayer.previous_gui_enabled_index", "value_int"),
    camera_center_index = VariableAccessor("iota_multiplayer.camera_center_index", "value_int"),
    --previous_camera_center_index = VariableAccessor("iota_multiplayer.previous_camera_center_index", "value_int"),
    money = VariableAccessor("iota_multiplayer.money", "value_int"),
    player_positions = SerializedAccessor(
        VariableAccessor("iota_multiplayer.player_positions", "value_string", "{}"),
        "mods/iota_multiplayer/player_positions.lua",
        "mods/iota_multiplayer/player_positions_value_date.lua",
        "mods/iota_multiplayer/player_positions_file_date.lua"
    ),
}
mod = setmetatable({}, mod_class)

local player_class = Class {
    controls = ComponentAccessor(EntityGetFirstComponent, "ControlsComponent"),
    shooter = ComponentAccessor(EntityGetFirstComponent, "PlatformShooterPlayerComponent"),
    listener = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "AudioListenerComponent"),
    gui = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "InventoryGuiComponent"),
    wallet = ComponentAccessor(EntityGetFirstComponent, "WalletComponent"),
    pick_upper = ComponentAccessor(EntityGetFirstComponent, "ItemPickUpperComponent"),
    damage_model = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "DamageModelComponent"),
    genome = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "GenomeDataComponent"),
    log = ComponentAccessor(EntityGetFirstComponent, "GameLogComponent"),
    sprite = ComponentAccessor(EntityGetFirstComponent, "SpriteComponent", "character"),
    aiming_reticle = ComponentAccessor(EntityGetFirstComponent, "SpriteComponent", "aiming_reticle"),
    character_data = ComponentAccessor(EntityGetFirstComponent, "CharacterDataComponent"),
    autoaim = ComponentAccessor(EntityGetFirstComponentIncludingDisabled, "LuaComponent", "iota_multiplayer.autoaim"),
    --inventory = ComponentAccessor(EntityGetFirstComponent, "Inventory2Component"),
    index = VariableAccessor("iota_multiplayer.index", "value_int"),
    previous_aim_x = VariableAccessor("iota_multiplayer.previous_aim_x", "value_string"),
    previous_aim_y = VariableAccessor("iota_multiplayer.previous_aim_y", "value_string"),
    dead = VariableAccessor("iota_multiplayer.dead", "value_bool"),
    previous_money = VariableAccessor("iota_multiplayer.previous_money", "value_int"),
    damage_frame = VariableAccessor("iota_multiplayer.damage_frame", "value_int"),
    damage_message = VariableAccessor("iota_multiplayer.damage_message", "value_string"),
    damage_entity_thats_responsible = VariableAccessor("iota_multiplayer.damage_entity_thats_responsible", "value_int"),
    load_frame = VariableAccessor("iota_multiplayer.load_frame", "value_int"),
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
    return validate(player) and setmetatable({ id = player }, player_class) or {}
end

function add_player(player)
    EntityAddTag(player, "iota_multiplayer.player")
    local player_data = Player(player)
    player_data.index = #get_players_including_disabled()
    EntityAddComponent2(player, "LuaComponent", {
        script_kick = "mods/iota_multiplayer/files/scripts/magic/player_friendly_fire.lua",
        script_damage_about_to_be_received = "mods/iota_multiplayer/files/scripts/magic/player_friendly_fire.lua",
        script_shot = "mods/iota_multiplayer/files/scripts/magic/player_friendly_fire.lua",
        script_damage_received = "mods/iota_multiplayer/files/scripts/magic/player_damage.lua",
        script_polymorphing_to = "mods/iota_multiplayer/files/scripts/magic/player_polymorph.lua",
    })
    EntityAddComponent2(player, "LuaComponent", {
        _tags = "iota_multiplayer.autoaim",
        _enabled = false,
        script_shot = "mods/iota_multiplayer/files/scripts/perks/autoaim_shot.lua",
    })
end

function load_player(x, y)
    local player = EntityLoad("data/entities/player.xml", x, y)
    add_player(player)
    local player_data = Player(player)
    player_data.load_frame = GameGetFrameNum()
    return player
end

function get_players_including_disabled()
    return EntityGetWithTag("iota_multiplayer.player")
end

function get_players()
    return table.filter(EntityGetWithTag("iota_multiplayer.player"), function(player)
        local player_data = Player(player)
        return not player_data.dead
    end)
end

function get_player_at_index_including_disabled(index)
    local players = EntityGetWithTag("iota_multiplayer.player")
    local i, player = table.find(players, function(player)
        local player_data = Player(player)
        return player_data.index == index
    end)
    return player
end

function get_player_at_index(index)
    local players = EntityGetWithTag("iota_multiplayer.player")
    local i, player = table.find(players, function(player)
        local player_data = Player(player)
        return player_data.index == index and not player_data.dead
    end)
    return player
end

function set_dead(player, dead)
    local player_data = Player(player)
    if player_data.damage_model ~= nil then
        set_component_enabled(player_data.damage_model._id, not dead)
    end
    if player_data.genome ~= nil then
        set_component_enabled(player_data.genome._id, not dead)
    end
    local polymorph
    local children = get_children(player)
    for i, child in ipairs(children) do
        local effect = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
        if effect ~= nil and ComponentGetValue2(effect, "mSerializedData") ~= "" then
            polymorph = effect
        end
    end
    if polymorph ~= nil then
        set_component_enabled(polymorph, not dead)
    end
    if dead then
        EntityRemoveTag(player, "hittable")

        local protection_polymorph, protection_polymorph_entity = GetGameEffectLoadTo(player, "PROTECTION_POLYMORPH", true)
        ComponentSetValue2(protection_polymorph, "frames", -1)
        EntityAddTag(protection_polymorph_entity, "iota_multiplayer.protection_polymorph")

        GamePlayAnimation(player, "intro_sleep", 0x7FFFFFFF)
        local sprites = EntityGetComponent(player, "SpriteComponent") or {}
        for i, sprite in ipairs(sprites) do
            if polymorph ~= nil then
                ComponentSetValue2(sprite, "alpha", 0.25)
            end
            EntityRefreshSprite(player, sprite)
        end
        GamePrintImportant("$log_coop_partner_is_dead")

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

        local protection_polymorph_entity = get_children(player, "iota_multiplayer.protection_polymorph")[1]
        if protection_polymorph_entity ~= nil then
            local protection_polymorph = EntityGetFirstComponent(protection_polymorph_entity, "GameEffectComponent")
            if protection_polymorph ~= nil then
                ComponentSetValue2(protection_polymorph, "frames", 0)
            end
        end

        GamePlayAnimation(player, "intro_stand_up", 0x7FFFFFFF)
        local sprites = EntityGetComponent(player, "SpriteComponent") or {}
        for i, sprite in ipairs(sprites) do
            if polymorph ~= nil then
                ComponentSetValue2(sprite, "alpha", 1)
            end
        end
        GamePrintImportant(GameTextGet("$log_coop_resurrected_player", player_data.index))

        if player_data.damage_model ~= nil then
            player_data.damage_model.hp = 0.04
            player_data.damage_model.is_on_fire = false
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
