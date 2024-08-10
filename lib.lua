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
    player_positions = SerializedAccessor(VariableAccessor("iota_multiplayer.player_positions", "value_string"), "mods/iota_multiplayer/player_positions.lua", "mods/iota_multiplayer/player_positions_value_date.lua", "mods/iota_multiplayer/player_positions_file_date.lua"),
    player_indexs = SerializedAccessor(VariableAccessor("iota_multiplayer.player_indexs", "value_string"), "mods/iota_multiplayer/player_indexs.lua", "mods/iota_multiplayer/player_indexs_value_date.lua", "mods/iota_multiplayer/player_indexs_file_date.lua"),
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
    index = VariableAccessor("iota_multiplayer.index", "value_int"),
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
    return validate_entity(player) and setmetatable({ id = player }, player_metatable) or {}
end

function add_player(player)
    EntityAddTag(player, "iota_multiplayer.player")
    mod.max_index = mod.max_index + 1
    local player_data = Player(player)
    player_data.index = mod.max_index
    EntityAddComponent2(player, "LuaComponent", {
        script_source_file = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_damage_about_to_be_received = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_kick = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_damage_received = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
        script_polymorphing_to = "mods/iota_multiplayer/files/scripts/animals/player_callbacks.lua",
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

function get_attack_index(attacks)
    local index = 0
    for i, v in ipairs(attacks) do
        if ComponentGetIsEnabled(v) then
            index = i
        end
    end
    return index
end

function warp(value, from, to)
    return (value - from) % (to - from) + from
end

function get_attack_table(ai, attack)
    local animation = "attack_ranged"
    local frames_between
    local action_frame
    local entity_file
    local entity_count_min
    local entity_count_max
    local offset_x
    local offset_y
    if ai ~= nil and ComponentGetValue2(ai, "attack_ranged_enabled") then
        frames_between = ComponentGetValue2(ai, "attack_ranged_frames_between")
        action_frame = ComponentGetValue2(ai, "attack_ranged_action_frame")
        entity_file = ComponentGetValue2(ai, "attack_ranged_entity_file")
        entity_count_min = ComponentGetValue2(ai, "attack_ranged_entity_count_min")
        entity_count_max = ComponentGetValue2(ai, "attack_ranged_entity_count_max")
        offset_x = ComponentGetValue2(ai, "attack_ranged_offset_x")
        offset_y = ComponentGetValue2(ai, "attack_ranged_offset_y")
    end
    if attack ~= nil then
        animation = ComponentGetValue2(attack, "animation_name")
        frames_between = ComponentGetValue2(attack, "frames_between")
        action_frame = ComponentGetValue2(attack, "attack_ranged_action_frame")
        entity_file = ComponentGetValue2(attack, "attack_ranged_entity_file")
        entity_count_min = ComponentGetValue2(attack, "attack_ranged_entity_count_min")
        entity_count_max = ComponentGetValue2(attack, "attack_ranged_entity_count_max")
        offset_x = ComponentGetValue2(attack, "attack_ranged_offset_x")
        offset_y = ComponentGetValue2(attack, "attack_ranged_offset_y")
    end
    return {
        animation = animation,
        frames_between = frames_between,
        action_frame = action_frame,
        entity_file = entity_file,
        entity_count_min = entity_count_min,
        entity_count_max = entity_count_max,
        offset_x = offset_x,
        offset_y = offset_y,
    }
end

-- 计算变换矩阵
function createTransformationMatrix(x, y, rotation, scale_x, scale_y)
    local cos_r = math.cos(rotation)
    local sin_r = math.sin(rotation)

    return {
        { scale_x * cos_r, -scale_y * sin_r, x },
        { scale_x * sin_r, scale_y * cos_r,  y },
        { 0,               0,                1 },
    }
end

-- 矩阵相乘
function multiplyMatrices(m1, m2)
    local result = {}
    for i = 1, 3 do
        result[i] = {}
        for j = 1, 3 do
            result[i][j] = m1[i][1] * m2[1][j] + m1[i][2] * m2[2][j] + m1[i][3] * m2[3][j]
        end
    end
    return result
end

-- 从矩阵提取变换参数
function extractTransformationParameters(matrix)
    local scale_x = math.sqrt(matrix[1][1] ^ 2 + matrix[2][1] ^ 2)
    local scale_y = math.sqrt(matrix[1][2] ^ 2 + matrix[2][2] ^ 2)
    local rotation = math.atan2(matrix[2][1], matrix[1][1])
    local x = matrix[1][3]
    local y = matrix[2][3]

    return x, y, rotation, scale_x, scale_y
end

-- 计算两个变换的乘积并返回结果变换的参数
function combineTransformations(x1, y1, rotation1, scale_x1, scale_y1, x2, y2, rotation2, scale_x2, scale_y2)
    local matrix1 = createTransformationMatrix(x1, y1, rotation1, scale_x1, scale_y1)
    local matrix2 = createTransformationMatrix(x2, y2, rotation2, scale_x2, scale_y2)
    local combinedMatrix = multiplyMatrices(matrix1, matrix2)

    return extractTransformationParameters(combinedMatrix)
end

function shoot_projectile(entity)
    local controls = EntityGetFirstComponent(entity, "ControlsComponent")
    local ai = EntityGetFirstComponentIncludingDisabled(entity, "AnimalAIComponent")
    local attacks = EntityGetComponent(entity, "AIAttackComponent") or {}
    local attack_index = get_attack_index(attacks)
    local attack_table = get_attack_table(ai, attacks[attack_index])
    if controls ~= nil and ComponentGetValue2(controls, "polymorph_next_attack_frame") <= GameGetFrameNum() and attack_table.entity_file ~= nil then
        local x, y, rotation, scale_x, scale_y = EntityGetTransform(entity)
        x, y = combineTransformations(x, y, rotation, scale_x, scale_y, attack_table.offset_x, attack_table.offset_y, 0, 1, 1)
        local target_x, target_y = ComponentGetValue2(controls, "mMousePosition")
        local projectile_entity = EntityLoad(attack_table.entity_file, x, y)
        GameShootProjectile(entity, x, y, target_x, target_y, projectile_entity)
        ComponentSetValue2(controls, "polymorph_next_attack_frame", GameGetFrameNum() + attack_table.frames_between)
    end
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
        GamePrint(GameTextGet("$log_coop_resurrected_player", player_data.index))
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
