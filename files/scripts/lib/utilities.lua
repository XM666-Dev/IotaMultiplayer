dofile_once("mods/iota_multiplayer/files/scripts/lib/tactic.lua")
dofile_once("mods/mnee/lib.lua")

MAX_PLAYER_NUM = 8

mod = Entity{
    id = {get = GameGetWorldStateEntity},
    gui_enabled_index = VariableField("iota_multiplayer.gui_enabled_index", "value_int"),
    gui_owner_index = CombinedField(NumericField(FileField("mods/iota_multiplayer/files/gui_owner_index.txt")), function(v)
        if v ~= nil then return v end
        return mod.gui_enabled_index
    end),
    camera_center_index = VariableField("iota_multiplayer.camera_center_index", "value_int"),
    money = VariableField("iota_multiplayer.money", "value_int"),
    player_positions = SerializedField(VariableField("iota_multiplayer.player_positions", "value_string", "{}")),
    auto_teleport = VariableField("iota_multiplayer.auto_teleport", "value_bool"),
} ()

Player = Entity{
    controls = ComponentField("ControlsComponent"),
    shooter = ComponentField("PlatformShooterPlayerComponent"),
    listener = ComponentField("AudioListenerComponent"),
    gui = ComponentField("InventoryGuiComponent"),
    wallet = ComponentField("WalletComponent"),
    pickupper = ComponentField("ItemPickUpperComponent"),
    damage_model = ComponentField("DamageModelComponent"),
    genome = ComponentField("GenomeDataComponent"),
    alive = ComponentField("StreamingKeepAliveComponent"),
    log = ComponentField("GameLogComponent"),
    sprite = ComponentField("SpriteComponent", "character"),
    aiming_reticle = ComponentField("SpriteComponent", "aiming_reticle"),
    character_data = ComponentField("CharacterDataComponent"),
    inventory = ComponentField("Inventory2Component"),
    autoaim = ComponentField{"LuaComponent", "iota_multiplayer.autoaim", _tags = "iota_multiplayer.autoaim", _enabled = false, script_shot = "mods/iota_multiplayer/files/scripts/perks/autoaim_shot.lua"},
    index = VariableField("iota_multiplayer.index", "value_int"),
    previous_aim_x = VariableField("iota_multiplayer.previous_aim_x", "value_string"),
    previous_aim_y = VariableField("iota_multiplayer.previous_aim_y", "value_string"),
    dead = VariableField("iota_multiplayer.dead", "value_bool"),
    previous_money = VariableField("iota_multiplayer.previous_money", "value_int"),
    damage_frame = VariableField("iota_multiplayer.damage_frame", "value_int"),
    damage_message = VariableField("iota_multiplayer.damage_message", "value_string"),
    damage_entity_thats_responsible = VariableField("iota_multiplayer.damage_entity_thats_responsible", "value_int"),
    load_frame = VariableField("iota_multiplayer.load_frame", "value_int"),
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
        self = Player(get_player_at_index_including_disabled(mod.gui_enabled_index))
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

function Player:set_dead(dead)
    if self.damage_model ~= nil then
        set_component_enabled(self.damage_model._id, not dead)
    end
    if self.genome ~= nil then
        set_component_enabled(self.genome._id, not dead)
    end
    if self.alive ~= nil then
        --set_component_enabled(self.alive._id, not dead)
    end
    local polymorph
    local children = get_children(self.id)
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
        --EntityAddChild(GameGetPlayerStatsEntity(0), self.id)

        EntityRemoveTag(self.id, "hittable")

        local protection_polymorph, protection_polymorph_entity = GetGameEffectLoadTo(self.id, "PROTECTION_POLYMORPH", true)
        ComponentSetValue2(protection_polymorph, "frames", -1)
        EntityAddTag(protection_polymorph_entity, "iota_multiplayer.protection_polymorph")

        local sprites = EntityGetComponent(self.id, "SpriteComponent") or {}
        for i, sprite in ipairs(sprites) do
            if polymorph ~= nil then
                ComponentSetValue2(sprite, "alpha", 0.25)
            end
            EntityRefreshSprite(self.id, sprite)
        end
        GamePrintImportant("$log_coop_partner_is_dead")

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
        --EntityRemoveFromParent(self.id)

        EntityAddTag(self.id, "hittable")

        local protection_polymorph_entity = get_children(self.id, "iota_multiplayer.protection_polymorph")[1]
        if protection_polymorph_entity ~= nil then
            local protection_polymorph = EntityGetFirstComponent(protection_polymorph_entity, "GameEffectComponent")
            if protection_polymorph ~= nil then
                ComponentSetValue2(protection_polymorph, "frames", 0)
            end
        end

        GamePlayAnimation(self.id, "intro_stand_up", 0x7FFFFFFF)
        local sprites = EntityGetComponent(self.id, "SpriteComponent") or {}
        for i, sprite in ipairs(sprites) do
            if polymorph ~= nil then
                ComponentSetValue2(sprite, "alpha", 1)
            end
        end
        GamePrintImportant(GameTextGet("$log_coop_resurrected_player", self.index))

        self.damage_model_.hp = 0.04
        self.damage_model_.is_on_fire = false
        local protection_all = GetGameEffectLoadTo(self.id, "PROTECTION_ALL", true)
        ComponentSetValue2(protection_all, "frames", 60)
    end
    self.dead = dead
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
        return not player_object.dead
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
        return player_object.index == index and not player_object.dead
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
