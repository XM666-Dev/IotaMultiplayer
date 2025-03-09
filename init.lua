--IotaMultiplayer - Created by ImmortalDamned
--Github https://github.com/XM666-Dev/IotaMultiplayer

dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")
local nxml = dofile_once("mods/iota_multiplayer/files/scripts/lib/nxml.lua")

ModLuaFileAppend("data/scripts/biomes/mountain/mountain_left_entrance.lua", "mods/iota_multiplayer/files/scripts/biomes/mountain/mountain_left_entrance_appends.lua")
ModLuaFileAppend("data/scripts/items/heart_fullhp_temple.lua", "mods/iota_multiplayer/files/scripts/items/share_appends.lua")
ModLuaFileAppend("data/scripts/items/spell_refresh.lua", "mods/iota_multiplayer/files/scripts/items/share_appends.lua")
for i, filename in ipairs{"data/entities/items/pickup/heart_fullhp_temple.xml", "data/entities/items/pickup/spell_refresh.xml"} do
    for xml in nxml.edit_file(filename) do
        xml:create_child("LuaComponent", {script_item_picked_up = "mods/iota_multiplayer/files/scripts/items/share_pickup.lua"})
    end
end
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/iota_multiplayer/files/scripts/biomes/temple_altar_appends.lua")
ModLuaFileAppend("data/scripts/perks/perk.lua", "mods/iota_multiplayer/files/scripts/perks/perk_appends.lua")
ModLuaFileAppend("data/scripts/newgame_plus.lua", "mods/iota_multiplayer/files/scripts/newgame_plus_appends.lua")
ModLuaFileAppend("mods/mnee/bindings.lua", "mods/iota_multiplayer/files/scripts/mnee.lua")
ModLuaFileAppend("mods/spell_lab_shugged/files/gui/get_player.lua", "mods/iota_multiplayer/files/scripts/get_player_appends.lua")
ModTextFileSetContent("mods/iota_multiplayer/files/scripts/get_player_appends.lua", 'dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua") function get_player() return get_player_at_index(mod.camera_center_index) end')

append_translations("mods/iota_multiplayer/files/translations.csv")

local gui = GuiCreate()

local function get_magic_numbers()
    local t = {}
    for k, v in string.gmatch(ModTextFileGetContent("data/magic_numbers.xml"), '(%g+)%s*=%s*"(.-)"') do
        t[k] = v
    end
    return t
end
local function MagicNumbers(t)
    local list = {"<MagicNumbers "}
    for k, v in pairs(t) do
        local value_type = type(v)
        if value_type == "number" then
            v = ("%f"):format(v)
        end
        if value_type == "boolean" then
            v = v and "1" or "0"
        end
        table.insert(list, ('%s="%s"'):format(k, v))
    end
    table.insert(list, "/>")
    return table.concat(list)
end
local function add_magic_numbers(t)
    ModTextFileSetContent("mods/iota_multiplayer/files/magic_numbers.xml", MagicNumbers(t))
    ModMagicNumbersFileAdd("mods/iota_multiplayer/files/magic_numbers.xml")
end
local magic_numbers = get_magic_numbers()
local magic_numbers_mod = {UI_COOP_QUICK_INVENTORY_HEIGHT = 0, UI_COOP_STAT_BARS_HEIGHT = 0}

if GameGetWorldStateEntity() == 0 then
    ModSettingSet("iota_multiplayer.camera_zoom_max", ModSettingGetNextValue("iota_multiplayer.camera_zoom_max"))
end
if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= 1 then
    magic_numbers_mod.VIRTUAL_RESOLUTION_X = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_max")
    magic_numbers_mod.VIRTUAL_RESOLUTION_Y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_max")
    ModTextFileSetContent("data/shaders/post_final.vert", ModTextFileGetContent("data/shaders/post_final.vert")
        :gsub(("90.0 * camera_inv_zoom_ratio"):raw(), ("90.0 * camera_inv_zoom_ratio * %f"):format(ModSettingGet("iota_multiplayer.camera_zoom_max")))
        :gsub("\n", "\nuniform vec4 internal_zoom;", 1)
        :gsub("gl_MultiTexCoord0", "gl_MultiTexCoord0 * internal_zoom - internal_zoom * 0.5 + 0.5")
        :gsub("gl_MultiTexCoord1", "gl_MultiTexCoord1 * internal_zoom - internal_zoom * 0.5 + 0.5")
    )
end
local previous_frame
local previous_internal_zoom
local function get_camera_info()
    local players = table.filter(get_players(), function(v) return Player(v).load_frame ~= GameGetFrameNum() end)
    local positions = {}
    local camera_center_player = get_player_at_index(mod.camera_center_index)
    local camera_center_player_object = Player(camera_center_player)
    local center_x, center_y = camera_center_player_object:get_camera_pos()
    local min_resolution_x, min_resolution_y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_min"), tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_min")
    local max_resolution_x, max_resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")), tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local x, y = player_object:get_camera_pos()
        if not ModSettingGet("iota_multiplayer.camera_unique") or player_object.index == mod.camera_center_index then
            local expand_width = max_resolution_x - min_resolution_x
            local expand_height = max_resolution_y - min_resolution_y
            local shrink_width = max_resolution_x - min_resolution_x * 0.5
            local shrink_height = max_resolution_y - min_resolution_y * 0.5
            local pos_x, pos_y = EntityGetTransform(player)
            local shrink_x = math.max(math.abs(pos_x - center_x) - shrink_width, 0)
            local shrink_y = math.max(math.abs(pos_y - center_y) - shrink_height, 0)
            shrink_x = shrink_x * tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y)
            shrink_y = shrink_y * tonumber(magic_numbers.VIRTUAL_RESOLUTION_X)
            local shrink = math.max(shrink_x, shrink_y)
            shrink_x = shrink / tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y)
            shrink_y = shrink / tonumber(magic_numbers.VIRTUAL_RESOLUTION_X)
            expand_width = math.max(expand_width - shrink_x, 0)
            expand_height = math.max(expand_height - shrink_y, 0)
            x = clamp(x, center_x - expand_width, center_x + expand_width)
            y = clamp(y, center_y - expand_height, center_y + expand_height)
            table.insert(positions, {x, y})
        end
    end
    local min_x, min_y = table.iterate(positions, function(a, b)
        return a[1] < b[1]
    end)[1], table.iterate(positions, function(a, b)
        return a[2] < b[2]
    end)[2]
    local max_x, max_y = table.iterate(positions, function(a, b)
        return a[1] > b[1]
    end)[1], table.iterate(positions, function(a, b)
        return a[2] > b[2]
    end)[2]
    local camera_x, camera_y = (min_x + max_x) / 2, (min_y + max_y) / 2
    local resolution_x, resolution_y = math.min(max_x - min_x + min_resolution_x, max_resolution_x), math.min(max_y - min_y + min_resolution_y, max_resolution_y)
    local internal_zoom = math.max(resolution_x / max_resolution_x, resolution_y / max_resolution_y)
    local frame = GameGetFrameNum()
    if previous_frame == nil or previous_frame < frame then
        previous_frame = frame
        if previous_internal_zoom ~= nil then
            previous_internal_zoom = lerp(previous_internal_zoom, internal_zoom, 0.0625)
        else
            previous_internal_zoom = internal_zoom
        end
    end
    return camera_x, camera_y, previous_internal_zoom
end

local raw_game_get_camera_bounds = GameGetCameraBounds
function GameGetCameraBounds()
    local x, y, w, h = raw_game_get_camera_bounds()
    local camera_x, camera_y, internal_zoom = get_camera_info()
    local ratio = 0.5 - internal_zoom / 2
    return x + w * ratio, y + h * ratio, w * internal_zoom, h * internal_zoom
end

local raw_get_resolution = get_resolution
function get_resolution(gui)
    local width, height = raw_get_resolution(gui)
    local camera_x, camera_y, internal_zoom = get_camera_info()
    return width * internal_zoom, height * internal_zoom
end

add_magic_numbers(magic_numbers_mod)

function OnWorldInitialized()
    for i, pos in ipairs(mod.player_positions) do
        EntityKill(EntityLoad("mods/iota_multiplayer/files/entities/buildings/keep_alive.xml", unpack(pos)))
    end
end

local player_spawned = false
local receiver
function OnPlayerSpawned(player)
    player_spawned = true
    local player_object = Player(player)
    player_object:add()
    player_object.index = 1
    local entity = EntityCreateNew()
    EntityAddComponent2(entity, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/magic/player_polymorph.lua"})
    EntityAddComponent2(entity, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/items/share_pickup.lua"})
    EntityAddComponent2(entity, "LuaComponent", {script_electricity_receiver_electrified = "mods/iota_multiplayer/files/scripts/magic/camera_update_pre.lua"})
    EntityAddComponent2(entity, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/magic/camera_update_post.lua"})
    receiver = EntityAddComponent2(entity, "ElectricityReceiverComponent", {electrified_msg_interval_frames = 1})
end

local function pred_filename(...)
    local filenames = {...}
    return function(v)
        for i, filename in ipairs(filenames) do
            if filename == EntityGetFilename(v) then
                return true
            end
        end
    end
end
local function pred_tag(...)
    local tags = {...}
    return function(v)
        for i, tag in ipairs(tags) do
            if EntityHasTag(v, tag) then
                return true
            end
        end
    end
end
local Share = Entity{shared_indexs = SerializedField(VariableField("iota_multiplayer.shared_indexs", "value_string", "{}"))}
local item_infos = {
    {
        pred = pred_filename("data/entities/items/pickup/heart_fullhp_temple.xml", "data/entities/items/pickup/spell_refresh.xml"),
        pickable = function(v, pickable, picker) return pickable and not table.find(Share(v).shared_indexs, Player(picker).index) end,
    },
    {
        pred = pred_tag("iota_multiplayer.player"),
        pickable = function(v, pickable)
            local object = Player(v)
            return pickable or object.dead and not object:is_inventory_open()
        end,
        name = "$iota_multiplayer.item_corpse",
        pickup_string = "$itempickup_open",
        fn = function(v, pickupper)
            Player(v).controls_.mButtonFrameInventory = get_frame_num_next()
            mod.gui_owner_index = Player(pickupper).index
        end,
    },
    {
        pred = pred_tag("coop_respawn"),
        pickable = function(v)
            local shared_indexs = Share(v).shared_indexs
            local dead_players = table.filter(get_players_including_disabled(), function(v) return Player(v).dead end)
            for i, dead_player in ipairs(dead_players) do
                local dead_player_object = Player(dead_player)
                if not table.find(shared_indexs, dead_player_object.index) then
                    return true
                end
            end
        end,
        pickup_radius = 100,
        name = "$iota_multiplayer.item_resurrect",
        pickup_string = "$iota_multiplayer.itempickup_use",
    },
}
local function get_item_info(v)
    for i, item_info in ipairs(item_infos) do
        if item_info.pred(v) then
            return item_info
        end
    end
end
local function f(v, ...)
    if type(v) == "function" then return v(...) end
    return v
end
local function get_picked(picker)
    return table.iterate(table.filter(EntityGetInRadius(0, 0, math.huge), function(v)
        local item = EntityGetFirstComponent(v, "ItemComponent")
        local pickable = item and ComponentGetValue2(item, "is_pickable")
        local pickup_radius = item and math.min(ComponentGetValue2(item, "item_pickup_radius"), 14.1)

        local item_info = get_item_info(v)
        if item_info ~= nil then
            if item_info.pickable ~= nil then
                pickable = f(item_info.pickable, v, pickable, picker)
            elseif pickable == nil then
                pickable = true
            end
            if item_info.pickup_radius ~= nil then
                pickup_radius = f(item_info.pickup_radius)
            elseif pickup_radius == nil then
                pickup_radius = 14.1
            end
        end

        local x, y = EntityGetTransform(v)
        local distance2 = get_distance2(x, y, EntityGetTransform(picker))
        return pickable and distance2 < pickup_radius * pickup_radius
    end), function(a, b)
        local ax, ay = EntityGetTransform(a)
        local a_distance2 = get_distance2(ax, ay, EntityGetTransform(picker))
        local bx, by = EntityGetTransform(b)
        local b_distance2 = get_distance2(bx, by, EntityGetTransform(picker))
        return a_distance2 < b_distance2
    end)
end
local function add_script_throw(item)
    if EntityGetComponent(item, "LuaComponent", "iota_multiplayer.item_throw") == nil then
        EntityAddComponent2(item, "LuaComponent", {
            _tags = "enabled_in_world,enabled_in_hand,enabled_in_inventory,iota_multiplayer.item_throw",
            script_source_file = "mods/iota_multiplayer/files/scripts/items/item_throw.lua",
            script_throw_item = "mods/iota_multiplayer/files/scripts/items/item_throw.lua",
        })
    end
    local children = get_children(item)
    for i, child in ipairs(children) do
        add_script_throw(child)
    end
end
local function update_common()
    local players = get_players()
    local players_including_disabled = get_players_including_disabled()

    if ModSettingGet("iota_multiplayer.share_money") then
        for i, player in ipairs(players) do
            local player_object = Player(player)
            if player_object.wallet ~= nil then
                mod.money = mod.money + player_object.wallet.money - player_object.previous_money
            end
        end
        for i, player in ipairs(players) do
            local player_object = Player(player)
            if player_object.wallet ~= nil then
                player_object.wallet.money = mod.money
                player_object.previous_money = mod.money
            end
        end
    end

    for i, player in ipairs(players) do
        local player_object = Player(player)
        local item = get_picked(player)
        player_object.pickupper_.only_pick_this_entity = -1
        if item ~= nil and EntityGetComponent(item, "ItemComponent") ~= nil then
            player_object.pickupper_.only_pick_this_entity = item
        end
        local item_info = get_item_info(item)
        if item_info ~= nil and player_object.controls_.mButtonFrameInteract == GameGetFrameNum() then
            f(item_info.fn, item, player)
        end

        if GameGetGameEffectCount(player, "EDIT_WANDS_EVERYWHERE") > GameGetGameEffectCount(player, "NO_WAND_EDITING") then
            for i, sharer in ipairs(table.filter(players, function(v)
                local x, y = EntityGetTransform(v)
                return get_distance2(x, y, EntityGetTransform(player)) < 14.1 * 14.1
            end)) do
                for i = 0, GameGetGameEffectCount(sharer, "NO_WAND_EDITING") - GameGetGameEffectCount(sharer, "EDIT_WANDS_EVERYWHERE") + #get_children(sharer, "iota_multiplayer.share") do
                    local effect, effect_entity = GetGameEffectLoadTo(sharer, "EDIT_WANDS_EVERYWHERE", true)
                    ComponentSetValue2(effect, "frames", 1)
                    EntityAddTag(effect_entity, "iota_multiplayer.share")
                end
            end
        end

        player_object.pickupper_.is_immune_to_kicks = not ModSettingGet("iota_multiplayer.friendly_fire_kick_drop")

        local items = get_inventory_items(player)
        for i, item in ipairs(items) do
            add_script_throw(item)
        end

        if player_object.damage_frame == GameGetFrameNum() then
            player_object.damage_model_.wait_for_kill_flag_on_death = false
            if player_object.damage_model_.hp < 0 then
                player_object:set_dead(true)
            end
        end

        if EntityHasTag(item, "coop_respawn") then
            local coop_respawn = item
            local coop_respawn_object = Share(coop_respawn)
            local shared_indexs = coop_respawn_object.shared_indexs
            local dead_players = table.filter(players_including_disabled, function(v) return Player(v).dead end)
            for i, dead_player in ipairs(dead_players) do
                local dead_player_object = Player(dead_player)
                if dead_player_object:mnin_bind("interact", true, true) and not table.find(shared_indexs, dead_player_object.index) then
                    table.insert(shared_indexs, dead_player_object.index)
                    coop_respawn_object.shared_indexs = shared_indexs

                    dead_player_object:set_dead(false)
                    local from_x, from_y = EntityGetTransform(dead_player)
                    local to_x, to_y = EntityGetTransform(coop_respawn)
                    teleport(dead_player, from_x, from_y, to_x, to_y)
                end
            end
        end
    end

    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        if player_object.dead then
            GamePlayAnimation(player, "intro_sleep", 0x7FFFFFFF)
        end
        local arm_r = player_object:get_arm_r()
        if arm_r ~= nil and player_object.sprite ~= nil then
            local intro = player_object.sprite.rect_animation == "intro_sleep" or player_object.sprite.rect_animation == "intro_stand_up"
            EntitySetName(arm_r, intro and "" or "arm_r")
            EntitySetComponentsWithTagEnabled(arm_r, "with_item", not intro)
        end
        if player_object.aiming_reticle ~= nil then
            local aim, aim_unbound, aim_emulated = player_object:mnin_stick("aim")
            player_object.aiming_reticle.visible = not aim_unbound and not player_object:is_inventory_open() and not player_object.dead
        end
    end

    if #players < 1 then
        local damaged_players = table.copy(players_including_disabled)
        table.sort(damaged_players, function(a, b)
            return Player(a).damage_frame < Player(b).damage_frame
        end)
        for i, player in ipairs(damaged_players) do
            local player_object = Player(player)
            set_component_enabled(player_object.damage_model._id, true)
            player_object.damage_model.wait_for_kill_flag_on_death = false
            player_object.damage_model.hp = 0
            player_object.damage_model.ui_report_damage = false
            local text = player_object.damage_message
            if EntityGetIsAlive(player_object.damage_entity_thats_responsible) then
                local name = IsPlayer(player_object.damage_entity_thats_responsible) and "$animal_player" or EntityGetName(player_object.damage_entity_thats_responsible)
                text = GameTextGet("$menugameover_causeofdeath_killer_cause", GameTextGetTranslatedOrNot(name), GameTextGetTranslatedOrNot(text))
            end
            EntityInflictDamage(player, 0.04, "", text, "NO_RAGDOLL_FILE", 0, 0, player_object.damage_entity_thats_responsible)
            player_object.damage_model.kill_now = true
            player_object.damage_model.wait_for_kill_flag_on_death = true
            player_object.damage_model.ragdoll_fx_forced = "NO_RAGDOLL_FILE"
            player_object.log_.report_death = false
        end
    end

    local player_positions = {}
    for i, player in ipairs(players_including_disabled) do
        local x, y = EntityGetTransform(player)
        player_positions[i] = {x, y}
    end
    mod.player_positions = player_positions
end

local on_screen_frames = {}
local function update_camera()
    local camera_center_player = get_player_at_index(mod.camera_center_index)
    local camera_center_player_object = Player(camera_center_player)
    local players = get_players()

    if mnee.mnin_bind("iota_multiplayer", "toggle_teleport", true, true) then
        mod.auto_teleport = not mod.auto_teleport
        GamePrint(table.concat{GameTextGet("$action_teleportation"), " ", GameTextGet(mod.auto_teleport and "$option_on" or "$option_off")})
    end
    if mod.auto_teleport and camera_center_player ~= nil then
        local min_resolution_x, min_resolution_y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_min"), tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_min")
        local max_resolution_x, max_resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")), tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))
        local center_x, center_y = camera_center_player_object:get_camera_pos()
        for i, player in ipairs(players) do
            local player_object = Player(player)
            if player_object.index ~= mod.camera_center_index then
                local shrink_width = max_resolution_x - min_resolution_x * 0.5
                local shrink_height = max_resolution_y - min_resolution_y * 0.5
                local shrink_left = center_x - shrink_width - (player_object.character_data_.collision_aabb_min_x or 0)
                local shrink_right = center_x + shrink_width - (player_object.character_data_.collision_aabb_max_x or 0)
                local shrink_top = center_y - shrink_height - (player_object.character_data_.collision_aabb_min_y or 0)
                local shrink_bottom = center_y + shrink_height - (player_object.character_data_.collision_aabb_max_y or 0)
                local pos_x, pos_y = EntityGetTransform(player)
                local shrink_x = clamp(pos_x, shrink_left, shrink_right) - pos_x
                local shrink_y = clamp(pos_y, shrink_top, shrink_bottom) - pos_y
                if shrink_x ~= 0 then
                    player_object.character_data_.mVelocity_[1] = shrink_x * 60
                end
                if shrink_y ~= 0 then
                    player_object.character_data_.mVelocity_[2] = shrink_y * 60
                end
                shrink_left = center_x - shrink_width - (player_object.character_data_.collision_aabb_max_x or 0)
                shrink_right = center_x + shrink_width - (player_object.character_data_.collision_aabb_min_x or 0)
                shrink_top = center_y - shrink_height - (player_object.character_data_.collision_aabb_max_y or 0)
                shrink_bottom = center_y + shrink_height - (player_object.character_data_.collision_aabb_min_y or 0)
                if pos_x > shrink_left and pos_x < shrink_right and pos_y > shrink_top and pos_y < shrink_bottom then
                    on_screen_frames[player_object.index] = GameGetFrameNum()
                end
                if on_screen_frames[player_object.index] ~= nil and GameGetFrameNum() - on_screen_frames[player_object.index] > 60 then
                    local from_x, from_y = EntityGetTransform(player)
                    teleport(player, from_x, from_y, EntityGetTransform(camera_center_player))
                    player_object.character_data_.mVelocity = {0, 0}
                end
            end
        end
    end

    if mnee.mnin_bind("iota_multiplayer", "switch_player", true, true) or camera_center_player == nil then
        local entities = camera_center_player ~= nil and table.filter(players, function(v)
            return Player(v).index > camera_center_player_object.index
        end) or {}
        entities = #entities > 0 and entities or players
        local next_camera_center_player = table.iterate(entities, function(a, b)
            return Player(a).index < Player(b).index
        end)
        if next_camera_center_player ~= nil then
            mod.camera_center_index = Player(next_camera_center_player).index
        end
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        if player_object.listener ~= nil then
            set_component_enabled(player_object.listener._id, player_object.index == mod.camera_center_index)
        end
    end
    if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= ModSettingGet("iota_multiplayer.camera_zoom_min") then
        ComponentSetValue2(receiver, "mLastFrameElectrified", get_frame_num_next())
    end
end

local function mnin_stick_raw(mod_id, bind_id, pressed_mode, is_vip, inmode)
    local abort_tbl = {{0, 0}, false, {false, false}, 0}
    if (GameHasFlagRun(mnee.SERV_MODE) and not (mnee.ignore_service_mode)) then return unpack(abort_tbl) end
    if (GameHasFlagRun(mnee.TOGGLER) and not (is_vip)) then return unpack(abort_tbl) end
    if (not (mnee.is_priority_mod(mod_id))) then return unpack(abort_tbl) end

    local binding = mnee.get_bindings()
    if (binding ~= nil) then binding = binding[mod_id] end
    if (binding ~= nil) then binding = binding[bind_id] end
    if (not (pen.vld(binding))) then return unpack(abort_tbl) end

    local acc = 100
    local val_x, gone_x, buttoned_x = mnee.mnin_axis(mod_id, binding.axes[1], true, pressed_mode, is_vip, inmode)
    local val_y, gone_y, buttoned_y = mnee.mnin_axis(mod_id, binding.axes[2], true, pressed_mode, is_vip, inmode)
    local direction = math.rad(math.floor(math.deg(math.atan2(val_y, val_x)) + 0.5))
    val_x, val_y = pen.rounder(mnee.apply_deadzone(math.min(val_x, 1), binding.jpad_type, binding.deadzone), acc), pen.rounder(mnee.apply_deadzone(math.min(val_y, 1), binding.jpad_type, binding.deadzone), acc)
    return {math.min(val_x, 1), math.min(val_y, 1)}, gone_x or gone_y, {buttoned_x, buttoned_y}, direction
end
local function is_pressed(a, b, emulated)
    return (a ~= b or not emulated) and b ~= 0
end
local function update_controls()
    local players = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local player_x, player_y = EntityGetTransform(player)

        if player_object.controls == nil then
            goto continue
        end

        player_object.controls.enabled = false

        if player_object.dead or player_object.sprite ~= nil and player_object.sprite.rect_animation == "intro_stand_up" then
            goto continue
        end

        player_object.controls.mButtonDownFire = player_object:mnin_bind("usewand", true, false, false, false, "guied")
        if player_object:mnin_bind("usewand", true, true, false, false, "guied") then
            player_object.controls.mButtonFrameFire = get_frame_num_next()
        end
        if player_object.controls.mButtonDownFire then
            player_object.controls.mButtonLastFrameFire = get_frame_num_next()
        end
        if player_object.controls.polymorph_hax and player_object.controls.polymorph_next_attack_frame <= get_frame_num_next() and player_object.controls.mButtonFrameFire == get_frame_num_next() then
            local ai = EntityGetFirstComponentIncludingDisabled(player, "AnimalAIComponent")
            local attacks = EntityGetComponent(player, "AIAttackComponent") or {}
            local attack_info = get_attack_info(player, ai, attacks)
            local controls = EntityGetFirstComponent(player, "ControlsComponent")
            if controls ~= nil and attack_info.entity_file ~= nil then
                local x, y = get_attack_ranged_pos(player, attack_info)
                local aiming_vector_x, aiming_vector_y = ComponentGetValue2(controls, "mAimingVector")
                local projectile_entity = EntityLoad(attack_info.entity_file, x, y)
                GameShootProjectile(player, x, y, x + aiming_vector_x, y + aiming_vector_y, projectile_entity)
            end
            player_object.controls.polymorph_next_attack_frame = get_frame_num_next() + attack_info.frames_between
        end

        player_object.controls.mButtonDownFire2 = player_object:mnin_bind("sprayflask", true, false, false, false, "guied")
        if player_object:mnin_bind("sprayflask", true, true, false, false, "guied") then
            player_object.controls.mButtonFrameFire2 = get_frame_num_next()
        end

        local throw, throw_unbound, throw_jpad = player_object:mnin_bind("throw", true, false, false, false, "guied")
        player_object.controls.mButtonDownThrow = throw and not (throw_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("throw", true, true, false, false, "guied") and player_object.controls.mButtonDownThrow then
            player_object.controls.mButtonFrameThrow = get_frame_num_next()
        end

        local interact, interact_unbound, interact_jpad = player_object:mnin_bind("interact", true)
        player_object.controls.mButtonDownInteract = interact and not (interact_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("interact", true, true) and player_object.controls.mButtonDownInteract then
            player_object.controls.mButtonFrameInteract = get_frame_num_next()
        end

        local left, left_unbound, left_jpad = player_object:mnin_bind("left", true)
        player_object.controls.mButtonDownLeft = left and not (left_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("left", true, true) and player_object.controls.mButtonDownLeft then
            player_object.controls.mButtonFrameLeft = get_frame_num_next()
        end

        local right, right_unbound, right_jpad = player_object:mnin_bind("right", true)
        player_object.controls.mButtonDownRight = right and not (right_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("right", true, true) and player_object.controls.mButtonDownRight then
            player_object.controls.mButtonFrameRight = get_frame_num_next()
        end

        local up, up_unbound, up_jpad = player_object:mnin_bind("up", true)
        player_object.controls.mButtonDownUp = up and not (up_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("up", true, true) and player_object.controls.mButtonDownUp then
            player_object.controls.mButtonFrameUp = get_frame_num_next()
        end

        local down, down_unbound, down_jpad = player_object:mnin_bind("down", true)
        player_object.controls.mButtonDownDown = down and not (down_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("down", true, true) and player_object.controls.mButtonDownDown then
            player_object.controls.mButtonFrameDown = get_frame_num_next()
        end

        player_object.controls.mButtonDownFly = player_object:mnin_bind("up", true)
        if player_object:mnin_bind("up", true, true) then
            player_object.controls.mButtonFrameFly = get_frame_num_next()
        end

        player_object.controls.mButtonDownChangeItemR = player_object:mnin_bind("itemnext", true) and ModTextFileGetContent("mods/spell_lab_shugged/scroll_box_hovered.txt") ~= "true"
        if player_object:mnin_bind("itemnext", true, true) and player_object.controls.mButtonDownChangeItemR then
            player_object.controls.mButtonFrameChangeItemR = get_frame_num_next()
            player_object.controls.mButtonCountChangeItemR = 1
        else
            player_object.controls.mButtonCountChangeItemR = 0
        end

        player_object.controls.mButtonDownChangeItemL = player_object:mnin_bind("itemprev", true) and ModTextFileGetContent("mods/spell_lab_shugged/scroll_box_hovered.txt") ~= "true"
        if player_object:mnin_bind("itemprev", true, true) and player_object.controls.mButtonDownChangeItemL then
            player_object.controls.mButtonFrameChangeItemL = get_frame_num_next()
            player_object.controls.mButtonCountChangeItemL = 1
        else
            player_object.controls.mButtonCountChangeItemL = 0
        end

        player_object.controls.mButtonDownInventory = player_object:mnin_bind("inventory", true)
        if player_object:mnin_bind("inventory", true, true) then
            player_object.controls.mButtonFrameInventory = get_frame_num_next()
        end

        player_object.controls.mButtonDownDropItem = player_object:mnin_bind("dropitem", true) and player_object:is_inventory_open()
        if player_object:mnin_bind("dropitem", true, true) and player_object.controls.mButtonDownDropItem then
            player_object.controls.mButtonFrameDropItem = get_frame_num_next()
        end

        local kick, kick_unbound, kick_jpad = player_object:mnin_bind("kick", true)
        player_object.controls.mButtonDownKick = kick and not (kick_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("kick", true, true) and player_object.controls.mButtonDownKick then
            player_object.controls.mButtonFrameKick = get_frame_num_next()
        end

        player_object.controls.mButtonDownLeftClick = player_object.index == 1 and mnee.mnin_key("mouse_left", false, false, "guied")
        if mnee.mnin_key("mouse_left", true, false, "guied") and player_object.controls.mButtonDownLeftClick then
            player_object.controls.mButtonFrameLeftClick = get_frame_num_next()
        end

        player_object.controls.mButtonDownRightClick = player_object.index == 1 and mnee.mnin_key("mouse_right", false, false, "guied")
        if mnee.mnin_key("mouse_right", true, false, "guied") and player_object.controls.mButtonDownRightClick then
            player_object.controls.mButtonFrameRightClick = get_frame_num_next()
        end

        player_object.controls.mFlyingTargetY = player_y - 10

        local aim, aim_unbound, aim_emulated = player_object:mnin_stick("aim")
        local CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS = tonumber(MagicNumbersGetValue("CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS"))
        if aim_unbound then
            local mouse_position_raw_x, mouse_position_raw_y = InputGetMousePosOnScreen()
            local mouse_position_x, mouse_position_y = get_pos_in_world(mouse_position_raw_x, mouse_position_raw_y)
            local center_x, center_y = EntityGetFirstHitboxCenter(player)
            local aiming_vector_x, aiming_vector_y = mouse_position_x - center_x, mouse_position_y - center_y
            local magnitude = math.max(math.sqrt(aiming_vector_x * aiming_vector_x + aiming_vector_y * aiming_vector_y), CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS)
            local aiming_vector_normalized_x, aiming_vector_normalized_y = aiming_vector_x / magnitude, aiming_vector_y / magnitude
            player_object.controls.mAimingVector = {aiming_vector_x, aiming_vector_y}
            player_object.controls.mAimingVectorNormalized = {aiming_vector_normalized_x, aiming_vector_normalized_y}
            local mouse_position_raw_prev = player_object.controls.mMousePositionRaw
            player_object.controls.mMousePosition = {mouse_position_x, mouse_position_y}
            player_object.controls.mMousePositionRaw = {mouse_position_raw_x, mouse_position_raw_y}
            player_object.controls.mMousePositionRawPrev = mouse_position_raw_prev
            player_object.controls.mMouseDelta = {mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2]}
            goto continue
        end
        local aim_raw = mnin_stick_raw("iota_multiplayer" .. player_object.index, "aim")
        if player_object:is_inventory_open() then
            aim = {0, 0}
            aim_raw = {0, 0}
        end
        local aiming_vector_non_zero_latest = player_object.controls.mAimingVectorNonZeroLatest
        if is_pressed(tonumber(player_object.previous_aim_x), aim_raw[1], aim_emulated[1]) or is_pressed(tonumber(player_object.previous_aim_y), aim_raw[2], aim_emulated[2]) then
            aiming_vector_non_zero_latest = aim
        end
        player_object.previous_aim_x = ("%.16a"):format(aim_raw[1])
        player_object.previous_aim_y = ("%.16a"):format(aim_raw[2])
        player_object.controls.mAimingVector = {aiming_vector_non_zero_latest[1] * CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS, aiming_vector_non_zero_latest[2] * CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS}
        player_object.controls.mAimingVectorNormalized = aim
        player_object.controls.mAimingVectorNonZeroLatest = aiming_vector_non_zero_latest
        player_object.controls.mGamepadAimingVectorRaw = aim
        local mouse_position = player_object.controls.mGamePadCursorInWorld
        local mouse_position_raw_x, mouse_position_raw_y = get_pos_on_screen(mouse_position())
        local mouse_position_raw_prev = player_object.controls.mMousePositionRaw
        player_object.controls.mMousePosition = mouse_position
        player_object.controls.mMousePositionRaw = {mouse_position_raw_x, mouse_position_raw_y}
        player_object.controls.mMousePositionRawPrev = mouse_position_raw_prev
        player_object.controls.mMouseDelta = {mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2]}
        ::continue::
    end
end

local gui_uninitialized = true
local function update_gui()
    local gui_enabled_player = get_player_at_index_including_disabled(mod.gui_enabled_index)
    local gui_enabled_player_object = Player(gui_enabled_player)
    local next_gui_enabled_player
    local next_gui_enabled_player_object
    if gui_enabled_player == nil or not gui_enabled_player_object:is_inventory_open() then
        next_gui_enabled_player = get_player_at_index(mod.camera_center_index)
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        if player_object.controls_.mButtonFrameInventory == get_frame_num_next() then
            if player_object.index == mod.gui_owner_index then
                gui_enabled_player_object.controls_.mButtonFrameInventory = get_frame_num_next()
            elseif player_object.gui ~= nil then
                next_gui_enabled_player = player
            end
        end
        if player_object.index == mod.gui_owner_index then
            gui_enabled_player_object.controls_.mButtonDownDropItem = player_object.controls_.mButtonDownDropItem
            if player_object.controls_.mButtonFrameDropItem == get_frame_num_next() then
                gui_enabled_player_object.controls_.mButtonFrameDropItem = get_frame_num_next()
            end
        end
    end

    if next_gui_enabled_player ~= nil and next_gui_enabled_player ~= gui_enabled_player then
        next_gui_enabled_player_object = Player(next_gui_enabled_player)
        if next_gui_enabled_player_object.gui ~= nil and gui_enabled_player ~= nil and gui_enabled_player_object.gui ~= nil then
            next_gui_enabled_player_object.gui.wallet_money_target = gui_enabled_player_object.gui.wallet_money_target
        end
        if gui_enabled_player ~= nil and gui_enabled_player_object.gui ~= nil then
            remove_component(gui_enabled_player_object.gui._id)
            EntityAddComponent2(gui_enabled_player, "InventoryGuiComponent")
        end
        mod.gui_enabled_index = next_gui_enabled_player_object.index
        if not next_gui_enabled_player_object.dead then
            mod.gui_owner_index = nil
        end
    end

    if gui_uninitialized then
        gui_uninitialized = false
        for i, player in ipairs(players_including_disabled) do
            local player_object = Player(player)
            if player_object.gui ~= nil then
                remove_component(player_object.gui._id)
                EntityAddComponent2(player, "InventoryGuiComponent")
            end
        end
    end

    gui_enabled_player = get_player_at_index_including_disabled(mod.gui_enabled_index)
    local interactor = table.find(players_including_disabled, function(v)
        local object = Player(v)
        return object.controls ~= nil and object.controls.mButtonFrameInteract == get_frame_num_next() and object.pickupper ~= nil and object.pickupper.only_pick_this_entity ~= -1
    end)
    if interactor ~= nil and Player(interactor).index ~= mod.gui_owner_index then
        Player(interactor).gui_.mBackgroundOverlayAlpha = (Player(gui_enabled_player).gui_.mBackgroundOverlayAlpha or 0) * 1.1320754716981132 --1 / (1 - 7 / 60)
        gui_enabled_player = interactor
    end
    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        if player_object.gui ~= nil then
            set_component_enabled(player_object.gui._id, player == gui_enabled_player)
        end
    end
end

local function update_camera_post()
    local first_player = get_player_at_index_including_disabled(1)
    if first_player ~= nil and #get_players() > 0 then
        local first_player_object = Player(first_player)
        local camera_x, camera_y, internal_zoom = get_camera_info()
        if first_player_object.shooter == nil then
            EntityAddComponent2(first_player, "PlatformShooterPlayerComponent")
        end
        first_player_object.shooter.mDesiredCameraPos = {camera_x, camera_y}
        GameSetPostFxParameter("internal_zoom", internal_zoom, internal_zoom, internal_zoom, internal_zoom)
    end
end

local colors_bar_bg = ModImageMakeEditable("data/ui_gfx/hud/colors_bar_bg.png", nil, nil)
local border_color = ModImageGetPixel(colors_bar_bg, 1, 0)
local fill_color = ModImageGetPixel(colors_bar_bg, 1, 1)
local bar_bg = ModImageMakeEditable("mods/iota_multiplayer/files/ui_gfx/hud/bar_bg.png", 3, 3)
for i = 0, 2 do
    for j = 0, 2 do
        ModImageSetPixel(bar_bg, j, i, border_color)
    end
end
ModImageSetPixel(bar_bg, 1, 1, fill_color)
local previous_picked = false
local function update_gui_mod()
    local players_including_disabled = get_players_including_disabled()
    if #players_including_disabled < 2 then return end
    GuiStartFrame(gui)

    GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
    GuiText(gui, 10, 25, "P" .. mod.gui_enabled_index)

    local widgets = {}
    local players = get_players()
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local player_x, player_y = EntityGetTransform(player)
        local hitbox = EntityGetFirstComponent(player, "HitboxComponent")
        if hitbox ~= nil then
            local offset_x, offset_y = ComponentGetValue2(hitbox, "offset")
            player_y = player_y + ComponentGetValue2(hitbox, "aabb_max_y") + offset_y
        end

        local x, y = get_pos_on_screen(player_x, player_y, gui)
        table.insert(widgets, function()
            GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
            GuiText(gui, x, y, "P" .. player_object.index)
        end)

        local x = x + 6
        local y = y + 3
        local width = 4
        local height = 4
        table.insert(widgets, function()
            GuiImageNinePiece(gui, new_id("bar_bg" .. i), x, y, width, height, 1, "mods/iota_multiplayer/files/ui_gfx/hud/bar_bg.png")
        end)

        if player_object.damage_model ~= nil then
            local ratio = player_object.damage_model.hp / player_object.damage_model.max_hp
            table.insert(widgets, function()
                GuiImage(gui, new_id("health_bar" .. i), x, y, "data/ui_gfx/hud/colors_health_bar.png", 1, width / 2 * ratio, height / 2)
            end)
        end
        if player_object.character_data ~= nil and player_object.character_data.mFlyingTimeLeft < player_object.character_data.fly_time_max then
            local ratio = player_object.character_data.mFlyingTimeLeft / player_object.character_data.fly_time_max
            table.insert(widgets, function()
                GuiImage(gui, new_id("flying_bar" .. i), x, y + height * ratio, "data/ui_gfx/hud/colors_flying_bar.png", 1, width / 2, height / 2 * (1 - ratio))
            end)
        end
    end
    for i, f in ipairs(widgets) do
        GuiZSetForNextWidget(gui, #widgets - i + 1001)
        f()
    end

    table.sort(players, function(a, b)
        local a_object = Player(a)
        local b_object = Player(b)
        return a_object.index < b_object.index or a_object.index == mod.gui_enabled_index
    end)
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    local x, y = screen_width / 2, screen_height - 40
    local picked = false
    for i, player in ipairs(players) do
        local item = get_picked(player)
        if item ~= nil then
            picked = true
            if EntityGetComponent(item, "ItemComponent") == nil then
                GuiAnimateBegin(gui)
                GuiAnimateAlphaFadeIn(gui, 3458923234, 0.1, 0, not previous_picked)
                GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
                local item_component = EntityGetFirstComponent(item, "ItemComponent")
                local name = item_component and ComponentGetValue2(item_component, "item_name") or ""
                local pickup_string = item_component and ComponentGetValue2(item_component, "custom_pickup_string") or ""
                if pickup_string == "" then
                    pickup_string = "$itempickup_pick"
                end
                local item_info = get_item_info(item)
                if item_info ~= nil then
                    if item_info.name ~= nil then
                        name = f(item_info.name)
                    end
                    if item_info.pickup_string ~= nil then
                        pickup_string = f(item_info.pickup_string)
                    end
                end
                GuiText(gui, x, y, GameTextGet(pickup_string, "[E]", GameTextGetTranslatedOrNot(name)))
                GuiAnimateEnd(gui)
            end
        end
    end
    previous_picked = picked
end

function OnWorldPreUpdate()
    if player_spawned then
        update_common()
        update_camera()
        update_controls()
        update_gui()
        update_camera_post()
    end
end

function OnWorldPostUpdate()
    if player_spawned then
        update_gui_mod()
    end
end
