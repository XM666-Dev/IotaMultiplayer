dofile_once("mods/iota_multiplayer/files/scripts/lib/tactic.lua")
dofile_once("mods/mnee/lib.lua")

MAX_PLAYER_NUM = 8

mod = Entity{
    id = {get = GameGetWorldStateEntity},
    gui_owner_index = CombinedField(NumericField(FileField("mods/iota_multiplayer/files/gui_owner_index.txt")), function(v)
        if v ~= nil then return v end
        return Player(get_player_gui_enabled()).index
    end),
    camera_center_index = VariableField("iota_multiplayer.camera_center_index", "value_int"),
    money = VariableField("iota_multiplayer.money", "value_int"),
    auto_teleport = VariableField("iota_multiplayer.auto_teleport", "value_bool", true),
} ()

Player = Entity{
    controls = ComponentField("ControlsComponent"),
    shooter = ComponentField("PlatformShooterPlayerComponent"),
    listener = ComponentField("AudioListenerComponent"),
    gui = ComponentField("InventoryGuiComponent"),
    wallet = ComponentField("WalletComponent"),
    pickupper = ComponentField("ItemPickUpperComponent"),
    hitbox = ComponentField("HitboxComponent", EntityGetFirstComponent),
    damage_model = ComponentField("DamageModelComponent"),
    genome = ComponentField("GenomeDataComponent"),
    ingestion = ComponentField("IngestionComponent"),
    alive = ComponentField("StreamingKeepAliveComponent", EntityGetFirstComponent),
    log = ComponentField("GameLogComponent"),
    sprite = ComponentField("SpriteComponent", "character"),
    aiming_reticle = ComponentField("SpriteComponent", "aiming_reticle"),
    character_data = ComponentField("CharacterDataComponent"),
    collision = ComponentField("PlayerCollisionComponent"),
    inventory = ComponentField("Inventory2Component"),
    autoaim = ComponentField{"LuaComponent", "iota_multiplayer.autoaim", _tags = "iota_multiplayer.autoaim", _enabled = false, script_shot = "mods/iota_multiplayer/files/scripts/perks/autoaim_shot.lua"},
    index = VariableField("iota_multiplayer.index", "value_int"),
    previous_money = VariableField("iota_multiplayer.previous_money", "value_int"),
    damage_frame = VariableField("iota_multiplayer.damage_frame", "value_int"),
    damage_message = VariableField("iota_multiplayer.damage_message", "value_string"),
    damage_responsible = VariableField("iota_multiplayer.damage_responsible", "value_string"),
    load_frame = VariableField("iota_multiplayer.load_frame", "value_int"),
    ingestion_data = VariableField("iota_multiplayer.ingestion_data", "value_string"),
}
function Player:add()
    if EntityHasTag(self.id, "iota_multiplayer.player") then
        return
    end
    EntityAddTag(self.id, "iota_multiplayer.player")
    EntityAddComponent2(self.id, "LuaComponent", {
        script_kick = "mods/iota_multiplayer/files/scripts/magic/player_friendly_fire.lua",
        script_damage_about_to_be_received = "mods/iota_multiplayer/files/scripts/magic/player_friendly_fire.lua",
        script_shot = "mods/iota_multiplayer/files/scripts/magic/player_friendly_fire.lua",
        script_damage_received = "mods/iota_multiplayer/files/scripts/magic/player_damage.lua",
        script_polymorphing_to = "mods/iota_multiplayer/files/scripts/magic/player_polymorph.lua",
    })
end

function Player:get_arm_r()
    return get_children(self.id, "player_arm_r")[1]
end

function Player:is_inventory_open()
    if self.index == mod.gui_owner_index then
        self = Player(get_player_gui_enabled())
    end
    return self.controls_.mButtonFrameInventory == get_frame_num_next() ~= (self.gui_.mActive or false) and not InputIsKeyJustDown(Key_ESCAPE)
end

function Player:mnin_bind(bind_id, dirty_mode, pressed_mode, is_vip, strict_mode, inmode)
    return mnee.mnin_bind("iota_multiplayer" .. self.index, bind_id, dirty_mode, pressed_mode, is_vip, strict_mode, inmode)
end

function Player:mnin_axis(bind_id, is_alive, pressed_mode, is_vip, inmode)
    return mnee.mnin_axis("iota_multiplayer" .. self.index, bind_id, is_alive, pressed_mode, is_vip, inmode)
end

function Player:mnin_stick(bind_id, pressed_mode, is_vip, inmode)
    return mnee.mnin_stick("iota_multiplayer" .. self.index, bind_id, pressed_mode, is_vip, inmode)
end

function Player:jpad_check(bind_id)
    return mnee.jpad_check(mnee.get_pbd(mnee.get_bindings()["iota_multiplayer" .. self.index][bind_id]).main)
end

function Player:get_camera_pos()
    if self.shooter ~= nil and self.inventory ~= nil then
        return self.shooter.mDesiredCameraPos()
    end
    return EntityGetTransform(self.id)
end

function Player:get_edit_count()
    local edit_count = GameGetGameEffectCount(self.id, "EDIT_WANDS_EVERYWHERE") - GameGetGameEffectCount(self.id, "NO_WAND_EDITING")
    local this_x, this_y = EntityGetTransform(self.id)
    for i, workshop in ipairs(EntityGetWithTag("workshop")) do
        local workshop_hitbox = EntityGetFirstComponent(workshop, "HitboxComponent")
        if workshop_hitbox ~= nil and self.hitbox ~= nil then
            local workshop_x, workshop_y = EntityGetTransform(workshop)
            local left = workshop_x + ComponentGetValue2(workshop_hitbox, "aabb_min_x") - self.hitbox.aabb_max_x
            local right = workshop_x + ComponentGetValue2(workshop_hitbox, "aabb_max_x") - self.hitbox.aabb_min_x
            local up = workshop_y + ComponentGetValue2(workshop_hitbox, "aabb_min_y") - self.hitbox.aabb_max_y
            local down = workshop_y + ComponentGetValue2(workshop_hitbox, "aabb_max_y") - self.hitbox.aabb_min_y
            if this_x >= left and this_x <= right and this_y >= up and this_y <= down then
                edit_count = edit_count + 1
                break
            end
        end
    end
    return edit_count
end

function Player:set_dead(dead)
    self.damage_model_._enabled = not dead
    self.genome_._enabled = not dead
    local polymorph
    local children = get_children(self.id)
    for i, child in ipairs(children) do
        local effect = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
        if effect ~= nil and ComponentGetValue2(effect, "mSerializedData") ~= "" then
            polymorph = effect
        end
    end
    set_component_enabled(polymorph, not dead)
    if dead then
        self.ingestion_data = serialize(self.ingestion_._members):gsub('"', "'")
        remove_component(self.ingestion_._id)

        EntityRemoveTag(self.id, "hittable")

        local protection_polymorph, protection_polymorph_entity = GetGameEffectLoadTo(self.id, "PROTECTION_POLYMORPH", true)
        ComponentSetValue2(protection_polymorph, "frames", -1)
        EntityAddTag(protection_polymorph_entity, "iota_multiplayer.protection_polymorph")

        local sprites = EntityGetComponent(self.id, "SpriteComponent") or {}
        for i, sprite in ipairs(sprites) do
            if polymorph ~= nil then
                ComponentSetValue2(sprite, "alpha", 0.25)
            end
            refresh_sprite(sprite)
        end
        GamePrintImportant("$log_coop_partner_is_dead")

        self.character_data_.buoyancy_check_offset_y = 3

        if self.controls ~= nil then
            local controls_component = self.controls._id
            for i, field in ipairs{
                "mButtonDownFire",
                "mButtonDownFire2",
                "mButtonDownThrow",
                "mButtonDownInteract",
                "mButtonDownLeft",
                "mButtonDownRight",
                "mButtonDownUp",
                "mButtonDownDown",
                "mButtonDownFly",
                "mButtonDownChangeItemR",
                "mButtonDownChangeItemL",
                "mButtonDownInventory",
                "mButtonDownDropItem",
                "mButtonDownKick",
                "mButtonDownLeftClick",
                "mButtonDownRightClick",
            } do
                ComponentSetValue2(controls_component, field, false)
            end
        end
    else
        local ingestion_data = deserialize(self.ingestion_data)
        if ingestion_data ~= nil then
            local ingestion = EntityAddComponent2(self.id, "IngestionComponent")
            for k, v in pairs(ingestion_data) do
                ComponentSetValue(ingestion, k, v)
            end
        end

        EntityAddTag(self.id, "hittable")

        local protection_polymorph_entity = get_children(self.id, "iota_multiplayer.protection_polymorph")[1]
        local protection_polymorph = EntityGetFirstComponent(protection_polymorph_entity, "GameEffectComponent")
        if protection_polymorph ~= nil then
            ComponentSetValue2(protection_polymorph, "frames", 0)
        end

        GamePlayAnimation(self.id, "intro_stand_up", 0x7FFFFFFF)
        local sprites = EntityGetComponent(self.id, "SpriteComponent") or {}
        for i, sprite in ipairs(sprites) do
            if polymorph ~= nil then
                ComponentSetValue2(sprite, "alpha", 1)
            end
        end
        GamePrintImportant(GameTextGet("$log_coop_resurrected_player", self.index))

        self.character_data_.buoyancy_check_offset_y = -7

        local fire = get_game_effect(self.id, "ON_FIRE")
        self.damage_model_.hp = math.max(self.damage_model_.hp or 0, 0.04)
        self.damage_model_.invincibility_frames = (self.damage_model_.invincibility_frames or 0) + 60
        self.damage_model_.mFireFramesLeft = math.min(self.damage_model_.mFireFramesLeft or 0, fire and ComponentGetValue2(fire, "frames") or 0, 60)
    end
end

function load_player(x, y)
    local player = EntityLoad("data/entities/player.xml", x, y)
    local player_object = Player(player)
    player_object:add()
    player_object.index = #get_players_including_disabled()
    player_object.load_frame = GameGetFrameNum()
    return player
end

function get_players_including_disabled()
    return EntityGetWithTag("iota_multiplayer.player")
end

function get_players()
    return table.filter(EntityGetWithTag("iota_multiplayer.player"), function(player)
        local player_object = Player(player)
        return player_object.damage_model_._enabled
    end)
end

function get_player_at_index_including_disabled(index)
    local players = EntityGetWithTag("iota_multiplayer.player")
    return table.find(players, function(player)
        local player_object = Player(player)
        return player_object.index == index
    end)
end

function get_player_at_index(index)
    local players = EntityGetWithTag("iota_multiplayer.player")
    return table.find(players, function(player)
        local player_object = Player(player)
        return player_object.index == index and player_object.damage_model_._enabled
    end)
end

function get_player_gui_enabled()
    local players = EntityGetWithTag("iota_multiplayer.player")
    return table.find(players, function(player)
        local player_object = Player(player)
        return player_object.gui ~= nil and ComponentGetIsEnabled(player_object.gui._id)
    end)
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
    EntityAddComponent2(entity, "LuaComponent", {
        script_item_picked_up = "mods/iota_multiplayer/files/scripts/items/share_pickup.lua",
    })
    return entity
end

function teleport(entity, from_x, from_y, to_x, to_y)
    EntitySetTransform(entity, to_x, to_y)
    EntityLoad("data/entities/particles/teleportation_source.xml", from_x, from_y)
    EntityLoad("data/entities/particles/teleportation_target.xml", to_x, to_y)
    GamePlaySound("data/audio/Desktop/misc.bank", "misc/teleport_use", to_x, to_y)
end
