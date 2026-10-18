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
if ModIsEnabled("spell_lab_shugged") then
    ModLuaFileAppend("mods/spell_lab_shugged/files/gui/get_player.lua", "mods/iota_multiplayer/files/scripts/get_player_appends.lua")
end
ModTextFileSetContent("mods/iota_multiplayer/files/scripts/get_player_appends.lua", 'dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua") function get_player() return get_player_at_index(mod.camera_center_index) end')

append_translations("mods/iota_multiplayer/files/translations.csv")

local gui = GuiCreate()

local magic_numbers = nxml.parse_file("data/magic_numbers.xml").attr
local magic_numbers_mod = {UI_COOP_QUICK_INVENTORY_HEIGHT = 0, UI_COOP_STAT_BARS_HEIGHT = 0}
if not validate(GameGetWorldStateEntity()) then
    ModSettingSet("iota_multiplayer.camera_zoom_max", ModSettingGetNextValue("iota_multiplayer.camera_zoom_max"))
end
if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= 1 then
    magic_numbers_mod.VIRTUAL_RESOLUTION_X = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_max")
    magic_numbers_mod.VIRTUAL_RESOLUTION_Y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_max")
    ModTextFileSetContent("data/shaders/post_final.vert", ModTextFileGetContent("data/shaders/post_final.vert")
        :gsub(("90.0 * camera_inv_zoom_ratio"):raw(), ("90.0 * camera_inv_zoom_ratio * %f"):format(ModSettingGet("iota_multiplayer.camera_zoom_max")))
        :gsub("\n", "\nuniform vec4 camera_zoom;", 1)
        :gsub("gl_MultiTexCoord0", "gl_MultiTexCoord0 * camera_zoom - camera_zoom * 0.5 + 0.5")
        :gsub("gl_MultiTexCoord1", "gl_MultiTexCoord1 * camera_zoom - camera_zoom * 0.5 + 0.5")
    )
    if ModSettingGet("iota_multiplayer.camera_disable_filter") then
        for i, filename in ipairs{
            "data/shaders/imgui_potion_icon.frag",
            "data/shaders/imgui_status_icon.frag",
            "data/shaders/post_cell_res_blit.frag",
            "data/shaders/sprite_cellgrid_preprocessed.frag",
            "data/shaders/sprite_cellgrid.frag",
            "data/shaders/sprite_damage_critical_hit_highlight.frag",
            "data/shaders/sprite_damage_highlight.frag",
            "data/shaders/sprite_default.frag",
            "data/shaders/sprite_invisible.frag",
            "data/shaders/sprite_stains_no_fade.frag",
            "data/shaders/sprite_stains.frag",
            "data/shaders/sprite_static_tile_bg.frag",
            "data/shaders/sprite_temple_rock.frag",
            "data/shaders/sprite_wand_shot.frag",
        } do
            ModTextFileSetContent(filename, ModTextFileGetContent(filename):gsub("#define PIXEL_ART_FILTER", ""))
        end
        ModTextFileSetContent("data/shaders/sprite_cellgrid.frag", ModTextFileGetContent("data/shaders/sprite_cellgrid.frag")
            :gsub("uv *= tex_size_pixels;", "")
            :gsub("uv = floor(uv) + x;", "")
            :gsub("result /= vec4(tex_size_pixels,tex_size_pixels);", "")
        )
    end
end
ModMagicNumbersFileAdd("mods/iota_multiplayer/files/magic_numbers.xml")
ModTextFileSetContent("mods/iota_multiplayer/files/magic_numbers.xml", tostring(nxml.new_element("MagicNumbers", magic_numbers_mod)))

local previous_frame
local previous_camera_zoom
local function compute_camera_info()
    local positions = {}
    local camera_center_player = get_player_at_index(mod.camera_center_index)
    local camera_center_player_object = Player(camera_center_player)
    local center_x, center_y = camera_center_player_object:get_camera_pos()
    local min_resolution_x, min_resolution_y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_min"), tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_min")
    local max_resolution_x, max_resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")), tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))
    local expand_width = max_resolution_x - min_resolution_x
    local expand_height = max_resolution_y - min_resolution_y
    local shrink_width = max_resolution_x - min_resolution_x * 0.5
    local shrink_height = max_resolution_y - min_resolution_y * 0.5
    local players = table.filter(get_players(), function(v) return Player(v).load_frame ~= GameGetFrameNum() end)
    if ModSettingGet("iota_multiplayer.camera_centered_only") then
        players = {camera_center_player}
    end
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local x, y = player_object:get_camera_pos()
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
    local camera_x, camera_y = (min_x + max_x) * 0.5, (min_y + max_y) * 0.5
    local resolution_x, resolution_y = math.min(max_x - min_x + min_resolution_x, max_resolution_x), math.min(max_y - min_y + min_resolution_y, max_resolution_y)
    local camera_zoom = math.max(resolution_x / max_resolution_x, resolution_y / max_resolution_y)
    local frame = GameGetFrameNum()   
    if previous_frame == nil or previous_frame < frame then
        previous_frame = frame
        if previous_camera_zoom ~= nil then
            previous_camera_zoom = lerp(previous_camera_zoom, camera_zoom, 0.0625)
        else
            previous_camera_zoom = camera_zoom
        end
    end
    return camera_x, camera_y, previous_camera_zoom
end
local camera_info, camera_info_valid = {}, false
local function invalidate_camera_info() camera_info_valid = false end
local function get_camera_info()
   if not camera_info_valid or (previous_camera_zoom == nil or previous_frame ~= GameGetFrameNum()) then
        camera_info[1], camera_info[2], camera_info[3] = compute_camera_info()
        camera_info_valid = true
    end
    return camera_info[1], camera_info[2], camera_info[3]
end

local raw_game_get_camera_bounds = GameGetCameraBounds
function GameGetCameraBounds()
    local x, y, w, h = raw_game_get_camera_bounds()
    local camera_zoom = select(3, get_camera_info())
    local ratio = (1 - camera_zoom) * 0.5
    return x + w * ratio, y + h * ratio, w * camera_zoom, h * camera_zoom
end

local raw_get_resolution = get_resolution
function get_resolution(gui)
    local width, height = raw_get_resolution(gui)
    local camera_zoom = select(3, get_camera_info())
    return width * camera_zoom, height * camera_zoom
end

local receiver
function OnPlayerSpawned(player)
    local player_object = Player(player)
    player_object:add()
    player_object.index = 1
    local updator = EntityCreateNew("iota_multiplayer.updator")
    EntityAddComponent2(updator, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/magic/player_polymorph.lua"})
    EntityAddComponent2(updator, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/items/share_pickup.lua"})
    EntityAddComponent2(updator, "LuaComponent", {script_electricity_receiver_electrified = "mods/iota_multiplayer/files/scripts/magic/camera_update_pre.lua"})
    EntityAddComponent2(updator, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/magic/camera_update_post.lua"})
    receiver = EntityAddComponent2(updator, "ElectricityReceiverComponent", {electrified_msg_interval_frames = 1})

    local players = get_players_including_disabled()
    for i, initialized_player in ipairs(players) do
        local initialized_player_object = Player(initialized_player)
        initialized_player_object:set_color(initialized_player_object:get_color())
    end
end

local function update_players()
    local value = mod.player_num_target
    if value == -1 then return end
    mod.player_num_target = -1

    local players = get_players_including_disabled()
    local previous_value = #players
    if value > previous_value then
        local camera_centered_player = table.find(players, function(player)
            local player_object = Player(player)
            return player_object.index == mod.camera_center_index
        end)
        local x, y = EntityGetTransform(camera_centered_player)
        for i = previous_value + 1, value do
            local new_player = EntityLoad("data/entities/player.xml", x, y)
            local new_player_object = Player(new_player)
            new_player_object:add()
            new_player_object.index = i
        end
    elseif value < previous_value then
        for i, player in ipairs(players) do
            local player_object = Player(player)
            if player_object.index > value then
                EntityKill(player)
            end
        end
    end
end

local function add_script_throw(item)
    if EntityGetComponentIncludingDisabled(item, "ItemComponent") ~= nil and EntityGetComponentIncludingDisabled(item, "LuaComponent", "iota_multiplayer.item_throw") == nil then
        EntityAddComponent2(item, "LuaComponent", {
            _tags = "enabled_in_world,enabled_in_hand,enabled_in_inventory,iota_multiplayer.item_throw",
            script_source_file = "mods/iota_multiplayer/files/scripts/items/item_throw.lua",
            script_throw_item = "mods/iota_multiplayer/files/scripts/items/item_throw.lua",
	    execute_every_n_frame = 10
        })
    end
    local children = get_children(item)
    local skip_every = 10
    for i, child in ipairs(children) do
	if (GameGetFrameNum()+i) % skip_every == 0 then
	        add_script_throw(child)
	end
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
        if player_object:get_edit_count() > #get_children(player, "iota_multiplayer.share") then
            for i, sharer in ipairs(table.filter(players, function(v)
                local x, y = EntityGetTransform(v)
                return get_distance2(x, y, EntityGetTransform(player)) < 14.1 * 14.1
            end)) do
                for i = Player(sharer):get_edit_count(), #get_children(sharer, "iota_multiplayer.share") do
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
    end

    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        if not player_object.damage_model_._enabled then
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
            player_object.aiming_reticle.visible = not aim_unbound and not player_object:is_inventory_open() and player_object.damage_model_._enabled
        end
    end

    if #players < 1 then
        local damaged_players = table.duplicate(players_including_disabled)
        table.sort(damaged_players, function(a, b)
            return Player(a).damage_frame > Player(b).damage_frame
        end)
        for i, player in ipairs(damaged_players) do
            local player_object = Player(player)
            player_object.damage_model_._enabled = true
            player_object.damage_model_.wait_for_kill_flag_on_death = false
            player_object.damage_model_.hp = 0
            player_object.damage_model_.ui_report_damage = false
            local damage_message = player_object.damage_message
            if player_object.damage_responsible ~= "" then
                damage_message = GameTextGet("$menugameover_causeofdeath_killer_cause", GameTextGetTranslatedOrNot(player_object.damage_responsible), GameTextGetTranslatedOrNot(damage_message))
            end
            EntityInflictDamage(player, 0.04, "NONE", damage_message, "NO_RAGDOLL_FILE", 0, 0)
            player_object.damage_model_.kill_now = true
            player_object.damage_model_.wait_for_kill_flag_on_death = true
            player_object.damage_model_.ragdoll_fx_forced = "NO_RAGDOLL_FILE"
            player_object.log_.report_death = false
        end
    end

    for i, player in ipairs(players_including_disabled) do
        EntityRemoveFromParent(player)
    end
end

local on_bound_frames = {}
local function update_camera()
    local camera_center_player = get_player_at_index(mod.camera_center_index)
    local camera_center_player_object = Player(camera_center_player)
    local players = get_players()
    if mnee.mnin_bind("iota_multiplayer", "switch_player", true) or camera_center_player == nil then
        local entities = camera_center_player ~= nil and table.filter(players, function(v)
            return Player(v).index > camera_center_player_object.index
        end) or {}
        entities = #entities > 0 and entities or players
        local next_camera_center_player = table.iterate(entities, function(a, b)
            return Player(a).index < Player(b).index
        end)
        if next_camera_center_player ~= nil then
            local next_camera_center_player_object = Player(next_camera_center_player)
            mod.camera_center_index = next_camera_center_player_object.index
            next_camera_center_player_object.shooter_.mSmoothedCameraPosition = camera_center_player_object.shooter_.mSmoothedCameraPosition
            next_camera_center_player_object.shooter_.mSmoothedAimingVector = camera_center_player_object.shooter_.mSmoothedAimingVector
            next_camera_center_player_object.shooter_.mDesiredCameraPos = camera_center_player_object.shooter_.mDesiredCameraPos
        end
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        player_object.listener_._enabled = player_object.index == mod.camera_center_index
    end

    camera_center_player = get_player_at_index(mod.camera_center_index)
    camera_center_player_object = Player(camera_center_player)
    if mnee.mnin_bind("iota_multiplayer", "toggle_teleport", true) then
        if mnee.mnin_key("left_shift") then
            for i, player in ipairs(players) do
                local player_object = Player(player)
                if player_object.index ~= mod.camera_center_index then
                    local from_x, from_y = EntityGetTransform(player)
                    teleport(player, from_x, from_y, EntityGetTransform(camera_center_player))
                end
            end
        else
            mod.auto_teleport = not mod.auto_teleport
            GamePrint(table.concat{GameTextGet("$action_teleportation"), " ", GameTextGet(mod.auto_teleport and "$option_on" or "$option_off")})
        end
    end
    if mod.auto_teleport and camera_center_player ~= nil then
        local center_x, center_y = camera_center_player_object:get_camera_pos()
        local min_resolution_x, min_resolution_y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_min"), tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_min")
        local max_resolution_x, max_resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")), tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))
        local shrink_width = max_resolution_x - min_resolution_x * 0.5
        local shrink_height = max_resolution_y - min_resolution_y * 0.5
        local left = center_x - shrink_width
        local right = center_x + shrink_width
        local top = center_y - shrink_height
        local bottom = center_y + shrink_height
        for i, player in ipairs(players) do
            local player_object = Player(player)
            if player_object.index ~= mod.camera_center_index then
                local bound_left = left - (player_object.character_data_.collision_aabb_min_x or 0)
                local bound_right = right - (player_object.character_data_.collision_aabb_max_x or 0)
                local bound_top = top - (player_object.character_data_.collision_aabb_min_y or 0)
                local bound_bottom = bottom - (player_object.character_data_.collision_aabb_max_y or 0)
                local pos_x, pos_y = EntityGetTransform(player)
                local bound_x = clamp(pos_x, bound_left, bound_right) - pos_x
                local bound_y = clamp(pos_y, bound_top, bound_bottom) - pos_y
                if bound_x ~= 0 then
                    player_object.character_data_.mVelocity_[1] = bound_x * 60
                end
                if bound_y ~= 0 then
                    player_object.character_data_.mVelocity_[2] = bound_y * 60
                end
                bound_left = left - (player_object.character_data_.collision_aabb_max_x or 0)
                bound_right = right - (player_object.character_data_.collision_aabb_min_x or 0)
                bound_top = top - (player_object.character_data_.collision_aabb_max_y or 0)
                bound_bottom = bottom - (player_object.character_data_.collision_aabb_min_y or 0)
                local frame = GameGetFrameNum()
                if pos_x > bound_left and pos_x < bound_right and pos_y > bound_top and pos_y < bound_bottom or on_bound_frames[player_object.index] == nil then
                    on_bound_frames[player_object.index] = frame
                end
                if frame - on_bound_frames[player_object.index] > 60 and (camera_center_player_object.collision_.stuck_in_ground_counter or 0) < 1 then
                    on_bound_frames[player_object.index] = frame
                    local from_x, from_y = EntityGetTransform(player)
                    teleport(player, from_x, from_y, EntityGetTransform(camera_center_player))
                    player_object.character_data_.mVelocity = {0, 0}
                end
            end
        end
    end

    local first_player = get_player_at_index_including_disabled(1)
    if first_player ~= nil and #players > 0 then
        local first_player_object = Player(first_player)
        local camera_x, camera_y, camera_zoom = get_camera_info()
        if first_player_object.shooter == nil then
            EntityAddComponent2(first_player, "PlatformShooterPlayerComponent")
        end
        first_player_object.shooter.mDesiredCameraPos = {camera_x, camera_y}
        GameSetPostFxParameter("camera_zoom", camera_zoom, camera_zoom, camera_zoom, camera_zoom)
    end
    if receiver ~= nil then
        ComponentSetValue2(receiver, "mLastFrameElectrified", get_frame_num_next())
    end
end

local previous_aims = {}
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
    val_x, val_y = pen.rnd(mnee.apply_deadzone(math.min(val_x, 1), binding.jpad_type, binding.deadzone), acc), pen.rnd(mnee.apply_deadzone(math.min(val_y, 1), binding.jpad_type, binding.deadzone), acc)
    return {math.min(val_x, 1), math.min(val_y, 1)}, gone_x or gone_y, {buttoned_x, buttoned_y}, direction
end
local function is_pressed(a, b, emulated)
    return (a ~= b or not emulated) and b ~= 0
end

local aim_cache = {}
local function get_aim(po)
    local idx = po.index or 0
    local entry = aim_cache[idx]
    if entry == nil then entry = {}; aim_cache[idx] = entry end
    local frame = GameGetFrameNum()
    if entry.frame ~= frame then
	    entry.frame = frame
        entry[1], entry[2], entry[3] = po:mnin_stick("aim")
    end
    return entry[1], entry[2], entry[3]
end


-- held first; only ask for "pressed" when held is true
local function read_bind(po, action, inmode)
    local held, unbound, jpad
    if inmode then held, unbound, jpad = po:mnin_bind(action, false, false, inmode)
    else held, unbound, jpad = po:mnin_bind(action) end
    local pressed = false
    if held then
        if inmode then pressed = po:mnin_bind(action, true, false, inmode)
        else pressed = po:mnin_bind(action, true) end
    end
    return held, pressed, unbound, jpad
end

local function dir_bind(po, c, inv_open, nf, action, down_key, frame_key)
    local held, pressed, _, jpad = read_bind(po, action)
    local down = held and not (jpad and inv_open)
    c[down_key] = down
    if pressed and down then c[frame_key] = nf end
    return held, pressed
end

local S = {}  -- per-frame shared values, reused

local function update_player_controls(player, S)
    local po = Player(player)
    po.controls_.enabled = false
    local c = po.controls                      -- look up once
    if c == nil or not po.damage_model_._enabled or po.sprite_.rect_animation == "intro_stand_up" then
        return
    end
    local nf = S.nf
    local inv_open = po:is_inventory_open()    -- once, not up to 7 times
    local is_first = po.index == 1

    local held, pressed = read_bind(po, "usewand", "guied")
    c.mButtonDownFire = held
    if pressed then c.mButtonFrameFire = nf end
    if held then c.mButtonLastFrameFire = nf end

    if pressed and c.polymorph_hax and c.polymorph_next_attack_frame <= nf then
        local ai = EntityGetFirstComponentIncludingDisabled(player, "AnimalAIComponent")
        local attacks = EntityGetComponent(player, "AIAttackComponent") or {}
        local attack_info = get_attack_info(player, ai, attacks)
        local controls = EntityGetFirstComponent(player, "ControlsComponent")
        if controls ~= nil and attack_info.entity_file ~= nil then
            local x, y = get_attack_ranged_pos(player, attack_info)
            local avx, avy = ComponentGetValue2(controls, "mAimingVector")
            local projectile_entity = EntityLoad(attack_info.entity_file, x, y)
            GameShootProjectile(player, x, y, x + avx, y + avy, projectile_entity)
        end
        c.polymorph_next_attack_frame = nf + attack_info.frames_between
    end

    held, pressed = read_bind(po, "sprayflask", "guied")
    c.mButtonDownFire2 = held
    if pressed then c.mButtonFrameFire2 = nf end

    local throw, throw_pressed, _, throw_jpad = read_bind(po, "throw", "guied")
    local throw_down = throw and not (throw_jpad and inv_open)
    c.mButtonDownThrow = throw_down
    if throw_pressed and throw_down then c.mButtonFrameThrow = nf end

    local interact, _, interact_jpad = po:mnin_bind("interact")
    interact = interact and not (interact_jpad and inv_open)
    if interact and not c.mButtonDownInteract then c.mButtonFrameInteract = nf end
    c.mButtonDownInteract = interact

    dir_bind(po, c, inv_open, nf, "left",  "mButtonDownLeft",  "mButtonFrameLeft")
    dir_bind(po, c, inv_open, nf, "right", "mButtonDownRight", "mButtonFrameRight")
    local up_held, up_pressed = dir_bind(po, c, inv_open, nf, "up", "mButtonDownUp", "mButtonFrameUp")
    dir_bind(po, c, inv_open, nf, "down",  "mButtonDownDown",  "mButtonFrameDown")

    c.mButtonDownFly = up_held                 -- reuse; was 2 more mnin_bind calls
    if up_pressed then c.mButtonFrameFly = nf end

    local next_down, next_pressed = false, false
    local prev_down, prev_pressed = false, false
    if not S.unscroll then
        next_down, next_pressed = read_bind(po, "itemnext")
        prev_down, prev_pressed = read_bind(po, "itemprev")
    end
    c.mButtonDownChangeItemR = next_down
    if next_pressed then c.mButtonFrameChangeItemR = nf; c.mButtonCountChangeItemR = 1
    else c.mButtonCountChangeItemR = 0 end
    c.mButtonDownChangeItemL = prev_down
    if prev_pressed then c.mButtonFrameChangeItemL = nf; c.mButtonCountChangeItemL = 1
    else c.mButtonCountChangeItemL = 0 end

    held, pressed = read_bind(po, "inventory")
    c.mButtonDownInventory = held
    if pressed then c.mButtonFrameInventory = nf end

    -- dropitem only matters while the inventory is open
    local drop_down, drop_pressed = false, false
    if inv_open then drop_down, drop_pressed = read_bind(po, "dropitem") end
    c.mButtonDownDropItem = drop_down
    if drop_pressed then c.mButtonFrameDropItem = nf end

    dir_bind(po, c, inv_open, nf, "kick", "mButtonDownKick", "mButtonFrameKick")

    c.mButtonDownLeftClick = is_first and S.mouse_left_down
    if is_first and S.mouse_left_pressed then c.mButtonFrameLeftClick = nf end
    c.mButtonDownRightClick = is_first and S.mouse_right_down
    if is_first and S.mouse_right_pressed then c.mButtonFrameRightClick = nf end

    c.mFlyingTargetY = select(2, EntityGetTransform(player)) - 10

    local aim, aim_unbound, aim_emulated = get_aim(po)
    local len = S.aim_length
    if aim_unbound then
        local mrx, mry = InputGetMousePosOnScreen()
        local mx, my = get_pos_in_world(mrx, mry)
        local cx, cy = EntityGetFirstHitboxCenter(player)
        local avx, avy = mx - cx, my - cy
        local magnitude = math.max(math.sqrt(avx * avx + avy * avy), len)
        c.mAimingVector = {avx, avy}
        c.mAimingVectorNormalized = {avx / magnitude, avy / magnitude}
        local prev = c.mMousePositionRaw
        c.mMousePosition = {mx, my}
        c.mMousePositionRaw = {mrx, mry}
        c.mMousePositionRawPrev = prev
        c.mMouseDelta = {mrx - prev[1], mry - prev[2]}
        return
    end

    local aim_raw = mnin_stick_raw("iota_multiplayer" .. po.index, "aim")
    if inv_open then aim = {0, 0}; aim_raw = {0, 0} end
    local latest = c.mAimingVectorNonZeroLatest
    local pa = previous_aims[po.index] or {0, 0}
    if is_pressed(pa[1], aim_raw[1], aim_emulated[1]) or is_pressed(pa[2], aim_raw[2], aim_emulated[2]) then
        latest = aim
    end
    previous_aims[po.index] = aim_raw
    c.mAimingVector = {latest[1] * len, latest[2] * len}
    c.mAimingVectorNormalized = aim
    c.mAimingVectorNonZeroLatest = latest
    c.mGamepadAimingVectorRaw = aim
    local mouse_position = c.mGamePadCursorInWorld
    local mrx, mry = get_pos_on_screen(mouse_position())
    local prev = c.mMousePositionRaw
    c.mMousePosition = mouse_position
    c.mMousePositionRaw = {mrx, mry}
    c.mMousePositionRawPrev = prev
    c.mMouseDelta = {mrx - prev[1], mry - prev[2]}
end

local function update_controls()
    local nf = get_frame_num_next()
    S.nf = nf
    S.unscroll = ModTextFileGetContent("mods/spell_lab_shugged/scroll_box_hovered.txt") == "true"
        or tonumber(GlobalsGetValue(pen.GLOBAL_UNSCROLLER_SAFETY, "0")) == GameGetFrameNum()
    S.aim_length = S.aim_length or tonumber(MagicNumbersGetValue("CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS"))

    S.mouse_left_down = mnee.mnin_key("mouse_left", false, false, "guied")
    S.mouse_left_pressed = S.mouse_left_down and mnee.mnin_key("mouse_left", true, false, "guied")
    S.mouse_right_down = mnee.mnin_key("mouse_right", false, false, "guied")
    S.mouse_right_pressed = S.mouse_right_down and mnee.mnin_key("mouse_right", true, false, "guied")

    for _, player in ipairs(get_players_including_disabled()) do
        update_player_controls(player, S)
    end
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
local item_list = {
    {
        pred = pred_filename("data/entities/items/pickup/heart_fullhp_temple.xml", "data/entities/items/pickup/spell_refresh.xml"),
        is_pickable = function(v, is_pickable, picker) return is_pickable and not table.find(Share(v).shared_indexs, Player(picker).index) end,
    },
    {
        pred = pred_tag("iota_multiplayer.player"),
        is_pickable = function(v, is_pickable)
            local object = Player(v)
            return is_pickable or not object.damage_model_._enabled and object.gui ~= nil and not object:is_inventory_open()
        end,
        ui_name = "$iota_multiplayer.item_corpse",
        custom_pickup_string = "$itempickup_open",
        func = function(v, pickupper)
            Player(v).controls_.mButtonFrameInventory = get_frame_num_next()
            mod.gui_control_index = Player(pickupper).index
        end,
    },
    {
        pred = pred_tag("coop_respawn"),
        is_pickable = function(v, is_pickable)
            local shared_indexs = Share(v).shared_indexs
            return is_pickable or table.find(get_players_including_disabled(), function(player)
                local player_object = Player(player)
                return not player_object.damage_model_._enabled and not table.find(shared_indexs, player_object.index)
            end)
        end,
        item_pickup_radius = 100,
        ui_name = "$iota_multiplayer.item_resurrect",
        custom_pickup_string = function(v, picker)
            local shared_indexs = Share(v).shared_indexs
            local dead_player = table.find(get_players_including_disabled(), function(player)
                local player_object = Player(player)
                return not player_object.damage_model_._enabled and not table.find(shared_indexs, player_object.index)
            end)
            local dead_player_object = Player(dead_player)
            local input_name = dead_player_object:get_binding_keys("interact")
            local ui_name = GameTextGetTranslatedOrNot("$iota_multiplayer.item_resurrect")
            return GameTextGet("$iota_multiplayer.itempickup_use", input_name, ui_name)
        end,
    },
}

local function get_item_data(v, has_item_component)
    if v == nil then return nil end
    if has_item_component == nil then
        has_item_component = EntityGetFirstComponent(v, "ItemComponent") ~= nil
    end
    if has_item_component then
        local filename = EntityGetFilename(v)
        if filename == "data/entities/items/pickup/heart_fullhp_temple.xml"
        or filename == "data/entities/items/pickup/spell_refresh.xml" then
            return item_list[1]
        end
    end
    if EntityHasTag(v, "iota_multiplayer.player") then return item_list[2] end
    if EntityHasTag(v, "coop_respawn") then return item_list[3] end
end

local function fetch(v, ...)
    if type(v) == "function" then return v(...) end
    return v, ...
end

local picked_cache = {}

local function get_picked(picker)
    local frame = GameGetFrameNum()
    local cached = picked_cache[picker]
    if cached and cached.frame == frame and (cached.item == nil or validate(cached.item)) then
        return cached.item
    end

    local px, py = EntityGetTransform(picker)
    local candidates = EntityGetInRadius(px, py, 100)   -- was (0, 0, math.huge)

    local filtered = table.filter(candidates, function(v)
        local item = EntityGetFirstComponent(v, "ItemComponent")
        local is_pickable = item and ComponentGetValue2(item, "is_pickable") and not validate(EntityGetParent(v))
        local item_pickup_radius = item and math.min(ComponentGetValue2(item, "item_pickup_radius"), 14.1)

        local item_data = get_item_data(v, item ~= nil)
        if item_data ~= nil then
            if item_data.is_pickable ~= nil then
                is_pickable = fetch(item_data.is_pickable, v, is_pickable, picker)
            elseif is_pickable == nil then
                is_pickable = true
            end
            if item_data.item_pickup_radius ~= nil then
                item_pickup_radius = fetch(item_data.item_pickup_radius)
            elseif item_pickup_radius == nil then
                item_pickup_radius = 14.1
            end
        end

        local x, y = EntityGetTransform(v)
        local distance2 = get_distance2(x, y, px, py)
        return is_pickable and distance2 <= item_pickup_radius * item_pickup_radius
    end)

    local item = table.iterate(filtered, function(a, b)
        local ax, ay = EntityGetTransform(a)
        local bx, by = EntityGetTransform(b)
        return get_distance2(ax, ay, px, py) < get_distance2(bx, by, px, py)
    end)

    picked_cache[picker] = {frame = frame, item = item}
    return item
end
local function update_pickup()
    local players = get_players()
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local item = get_picked(player)
        player_object.pickupper_.only_pick_this_entity = -1
        if item ~= nil and EntityGetComponent(item, "ItemComponent") ~= nil then
            player_object.pickupper_.only_pick_this_entity = item
        end
        local item_data = get_item_data(item)
        if item_data ~= nil and player_object.controls_.mButtonFrameInteract == get_frame_num_next() then
            fetch(item_data.func, item, player)
        end

        if EntityHasTag(item, "coop_respawn") then
            local coop_respawn = item
            local coop_respawn_object = Share(coop_respawn)
            local shared_indexs = coop_respawn_object.shared_indexs
            local dead_players = table.filter(players_including_disabled, function(v) return not Player(v).damage_model_._enabled end)
            for i, dead_player in ipairs(dead_players) do
                local dead_player_object = Player(dead_player)
                if dead_player_object:mnin_bind("interact", true) and not table.find(shared_indexs, dead_player_object.index) then
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
end

local gui_uninitialized = true
local previous_gui_enabled_player
local function get_quick_slot(entity)
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    local ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
    return (item and ComponentGetValue2(item, "inventory_slot") or 0) + (ability and ComponentGetValue2(ability, "use_gun_script") and 0 or 4)
end

local ITEMSLOT_BINDS = {}
for i = 1, 8 do ITEMSLOT_BINDS[i] = "itemslot" .. i end

local quick_inventory_cache = {}
local function get_quick_inventory(player)
    local q = quick_inventory_cache[player]
    if q == nil or not validate(q) or EntityGetParent(q) ~= player then
        q = table.find(get_children(player), function(v) return EntityGetName(v) == "inventory_quick" end)
        quick_inventory_cache[player] = q
    end
    return q
end

local function block_item_select(player)
    local quick_inventory = get_quick_inventory(player)
    if quick_inventory == nil then return end
    for _, item in ipairs(get_children(quick_inventory)) do
        local item_component = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
        if item_component ~= nil then
            local sx, sy = ComponentGetValue2(item_component, "inventory_slot")
            if sx ~= -1 or sy ~= 0 then
                ComponentSetValue2(item_component, "inventory_slot", -1, 0)
            end
        end
    end
end

local gui_enabled_cache = {}

local function update_gui()
    local nf = get_frame_num_next()
    local gui_enabled_player = get_player_gui_enabled()
    local gui_enabled_player_object = Player(gui_enabled_player)
    local next_gui_enabled_player = gui_enabled_player
    if gui_enabled_player == nil or not gui_enabled_player_object:is_inventory_open() then
        next_gui_enabled_player = get_player_at_index(mod.camera_center_index)
    end
    if previous_gui_enabled_player ~= nil then
        next_gui_enabled_player = previous_gui_enabled_player
        previous_gui_enabled_player = nil
    end

    local players_including_disabled = get_players_including_disabled()
    local objects = {}                       -- one Player() wrapper per player per frame
    for _, player in ipairs(players_including_disabled) do
        local po = Player(player)
        objects[player] = po
        local controlled = po:is_gui_controlled()
        if po.controls_.mButtonFrameInventory == nf then
            if controlled then
                gui_enabled_player_object.controls_.mButtonFrameInventory = nf
            elseif po.gui ~= nil then
                next_gui_enabled_player = player
            end
        end
        if controlled then
            gui_enabled_player_object.controls_.mButtonDownDropItem = po.controls_.mButtonDownDropItem
            if po.controls_.mButtonFrameDropItem == nf then
                gui_enabled_player_object.controls_.mButtonFrameDropItem = nf
            end
        end
    end

    if next_gui_enabled_player ~= gui_enabled_player then
        local next_object = Player(next_gui_enabled_player)
        if gui_enabled_player_object.gui ~= nil then
            next_object.gui_.wallet_money_target = gui_enabled_player_object.gui.wallet_money_target
            remove_component(gui_enabled_player_object.gui._id)
            EntityAddComponent2(gui_enabled_player, "InventoryGuiComponent")
            gui_enabled_cache = {}           -- component was rebuilt, cached state is stale
        end
        if next_object.damage_model_._enabled then
            mod.gui_control_index = 0
        end
    end

    if gui_uninitialized then
        gui_uninitialized = false
        for _, player in ipairs(players_including_disabled) do
            local po = objects[player]
            if po.gui ~= nil then
                remove_component(po.gui._id)
                EntityAddComponent2(player, "InventoryGuiComponent")
            end
        end
        gui_enabled_cache = {}
    end

    local interactor
    for _, v in ipairs(players_including_disabled) do
        local object = objects[v]
        if object.controls_.mButtonFrameInteract == nf
        and validate(object.pickupper_.only_pick_this_entity)
        and not object:is_gui_controlled() then
            interactor = v
            break
        end
    end
    if interactor ~= nil then
        local interactor_object = objects[interactor]
        local next_object = Player(next_gui_enabled_player)
        interactor_object.gui_.mBackgroundOverlayAlpha = (next_object.gui_.mBackgroundOverlayAlpha or 0) * 1.1320754716981132
        interactor_object.gui_.wallet_money_target = next_object.gui_.wallet_money_target
        previous_gui_enabled_player = next_gui_enabled_player
        next_gui_enabled_player = interactor
    end

    -- only write _enabled when the value actually changes
    for _, player in ipairs(players_including_disabled) do
        local want = player == next_gui_enabled_player
        if gui_enabled_cache[player] ~= want then
            objects[player].gui_._enabled = want
            gui_enabled_cache[player] = want
        end
    end

    -- quick-slot hotkeys (logic unchanged)
    for _, player in ipairs(get_players()) do
        local po = objects[player] or Player(player)
        for slot_key = 1, 8 do
            if po:mnin_bind(ITEMSLOT_BINDS[slot_key], true) then
                local items = get_children(get_quick_inventory(player))
                local slots = {}
                for _, item in ipairs(items) do
                    local slot = get_quick_slot(item)
                    for _, v in pairs(slots) do
                        if v == slot then slot = slot + 1 end
                    end
                    slots[item] = slot
                end
                table.sort(items, function(a, b) return slots[a] < slots[b] end)
                for j, item in ipairs(items) do
                    if slots[item] == slot_key - 1 and po.inventory_.mSavedActiveItemIndex ~= j - 1 then
                        po.inventory_.mSavedActiveItemIndex = j - 1
                        po.inventory_.mInitialized = false
                        po.inventory_.mForceRefresh = true
                        GamePlaySound("data/audio/Desktop/ui.bank", "ui/item_equipped", nil, nil)
                    end
                end
            end
        end
    end

    local next_object = Player(next_gui_enabled_player)
    local diff = (next_object.controls_.mButtonFrameInteract or 0) - GameGetFrameNum()
    if not next_object:is_inventory_open() and (diff < 0 or diff > 1) then
        block_item_select(next_gui_enabled_player)
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
local window = Window(gui)
local bar_bg_hash = get_line(function() end)
local colors_health_bar_hash = get_line(function() end)
local colors_flying_bar_hash = get_line(function() end)
local cursor_hash = get_line(function() end)
local quick_inventory_box_hash = get_line(function() end)
local highlight_hash = get_line(function() end)
local item_sprite_hash = get_line(function() end)
local window_uninitialized = true
local bars_x, bars_y
local box_width, box_height
local highlight_width, highlight_height
local function update_window()
    if ModSettingGet("iota_multiplayer.gui_disabled") then return end

    local players_including_disabled = get_players_including_disabled()
    if #players_including_disabled < 2 then return end
    local draw_list = window:begin(1000)

    local players = get_players()
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local player_x, player_y = EntityGetTransform(player)
        player_y = player_y + (player_object.hitbox_.aabb_max_y or 0)

        local x, y = get_pos_on_screen(player_x, player_y, gui)
        draw_list:layer()
        draw_list:add(GuiOptionsAddForNextWidget, GUI_OPTION.Align_HorizontalCenter)
        draw_list:add(GuiText, x, y, "P" .. player_object.index)

        x = x + 6
        y = y + 3
        local width = 4
        local height = 4
        draw_list:add(GuiImageNinePiece, x, y, width, height, 1, "mods/iota_multiplayer/files/ui_gfx/hud/bar_bg.png")
        draw_list:bind(bar_bg_hash)

        if player_object.damage_model ~= nil then
            local ratio = player_object.damage_model.hp / player_object.damage_model.max_hp
            draw_list:layer()
            draw_list:add(GuiImage, x, y, "data/ui_gfx/hud/colors_health_bar.png", 1, width * 0.5 * ratio, height * 0.5)
            draw_list:bind(colors_health_bar_hash)
        end
        if player_object.character_data ~= nil and player_object.character_data.mFlyingTimeLeft < player_object.character_data.fly_time_max then
            local ratio = player_object.character_data.mFlyingTimeLeft / player_object.character_data.fly_time_max
            draw_list:layer()
            draw_list:add(GuiImage, x, y + height * ratio, "data/ui_gfx/hud/colors_flying_bar.png", 1, width * 0.5, height * 0.5 * (1 - ratio))
            draw_list:bind(colors_flying_bar_hash)
        end

        local camera_x, camera_y = GameGetCameraPos()
        local camera_zoom = select(3, get_camera_info())
        local resolution_x, resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")) * camera_zoom * 0.5, tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")) * camera_zoom * 0.5
        local left = camera_x - resolution_x
        local right = camera_x + resolution_x
        local up = camera_y - resolution_y
        local down = camera_y + resolution_y
        left, up = get_pos_on_screen(left, up, gui)
        right, down = get_pos_on_screen(right, down, gui)
        local cursor_x, cursor_y = get_pos_on_screen(player_x, player_y, gui)
        local cursor_width, cursor_height = GuiGetImageDimensions(gui, "mods/iota_multiplayer/files/ui_gfx/cursor.png")
        local cursor_x_clamped, cursor_y_clamped = clamp(cursor_x, left + cursor_height * 0.5, right - cursor_height * 0.5), clamp(cursor_y, up + cursor_height * 0.5, down - cursor_height * 0.5)
        if cursor_x_clamped ~= cursor_x or cursor_y_clamped ~= cursor_y then
            local rotation = math.atan2(cursor_y - cursor_y_clamped, cursor_x - cursor_x_clamped)
            x, y = vec_sub(cursor_x_clamped, cursor_y_clamped, vec_rotate(cursor_width, cursor_height * 0.5, rotation))
            draw_list:layer()
            draw_list:add(GuiImage, x, y, "mods/iota_multiplayer/files/ui_gfx/cursor.png", 1, 1, 1, rotation)
            draw_list:bind(cursor_hash)

            local mouse_x, mouse_y = InputGetMousePosOnScreen()
            mouse_x, mouse_y = vec_mult(mouse_x, mouse_y, 0.5)
            if get_distance2(mouse_x, mouse_y, cursor_x_clamped, cursor_y_clamped) < 256 then
                x, y = vec_sub(cursor_x, cursor_y, cursor_x_clamped, cursor_y_clamped)
                x, y = vec_sub(cursor_x_clamped, cursor_y_clamped, vec_mult(x, y, 16 / vec_length(x, y)))
                y = y - select(2, GuiGetTextDimensions(gui, "P" .. player_object.index)) * 0.5
                draw_list:add(GuiOptionsAddForNextWidget, GUI_OPTION.Align_HorizontalCenter)
                draw_list:add(GuiText, x, y, "P" .. player_object.index)
            end
        end
    end

    if window_uninitialized then
        window_uninitialized = false
        bars_x, bars_y = tonumber(MagicNumbersGetValue("UI_BARS_POS_X")) - 1, tonumber(MagicNumbersGetValue("UI_BARS_POS_Y"))
        box_width, box_height = GuiGetImageDimensions(gui, "data/ui_gfx/inventory/quick_inventory_box.png")
        GuiImage(gui, 1, 0, 0, "data/ui_gfx/inventory/highlight.xml")
        highlight_width, highlight_height = select(6, GuiGetPreviousWidgetInfo(gui))
    end
    local gui_enabled_player = get_player_gui_enabled()
    local ordered_players = table.filter(players, function(player) return player ~= gui_enabled_player end)
    table.sort(ordered_players, function(a, b)
        local a_object = Player(a)
        local b_object = Player(b)
        return a_object.index < b_object.index
    end)
    table.insert(ordered_players, 1, gui_enabled_player)
    local y = bars_y
    for i, player in ipairs(ordered_players) do
        if i == 1 or not GameIsInventoryOpen() then
            local text = "P" .. Player(player).index
            local x, y = bars_x - box_width * 0.5, y + box_height * 0.5
            y = y - select(2, GuiGetTextDimensions(gui, text)) * 0.5
            draw_list:layer()
            draw_list:add(GuiOptionsAddForNextWidget, GUI_OPTION.Align_HorizontalCenter)
            draw_list:add(GuiText, x, y, text)
        end
        if player ~= gui_enabled_player and not GameIsInventoryOpen() then
            local player_object = Player(player)
            local quick_inventory = table.find(get_children(player), function(v) return EntityGetName(v) == "inventory_quick" end)
            local items = get_children(quick_inventory)
            local slots = {}
            for i, item in ipairs(items) do
                local slot = get_quick_slot(item)
                for k, v in pairs(slots) do
                    if v == slot then
                        slot = slot + 1
                    end
                end
                slots[item] = slot
            end
            do
                local x = bars_x
                for i = 0, 7 do
                    draw_list:add(GuiOptionsAddForNextWidget, GUI_OPTION.NonInteractive)
                    draw_list:add(GuiImage, x, y, "data/ui_gfx/inventory/quick_inventory_box.png", 1, 1)
                    draw_list:bind(quick_inventory_box_hash)
                    if i == slots[player_object.inventory_.mActiveItem] then
                        local x, y = x + (highlight_width + 1) * 0.5, y + (highlight_height + 1) * 0.5
                        draw_list:layer()
                        draw_list:add(GuiOptionsAddForNextWidget, GUI_OPTION.NonInteractive)
                        draw_list:add(GuiImage, x, y, "data/ui_gfx/inventory/highlight.xml", 1, 1, 0, 0, GUI_RECT_ANIMATION_PLAYBACK.Loop)
                        draw_list:bind(highlight_hash)
                    end
                    x = x + box_width
                    if i == 3 then
                        x = x + 1
                    end
                end
            end
            for i, item in ipairs(items) do
                local slot = slots[item]
                local x, y = bars_x + slot * box_width, y
                x, y = vec_add(x, y, vec_mult(box_width, box_height, 0.5))
                if slot > 3 then
                    x = x + 1
                end
                local item_component = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
                local ability_component = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
                local sprite_filename = item_component and ComponentGetValue2(item_component, "ui_sprite") or ""
                if sprite_filename == "" and ability_component ~= nil then
                    sprite_filename = ComponentGetValue2(ability_component, "sprite_file")
                end
                if sprite_filename ~= "" then
                    if not sprite_filename:find(".xml$") then
                        local width, height = GuiGetImageDimensions(gui, sprite_filename)
                        x, y = vec_sub(x, y, vec_mult(width, height, 0.5))
                    end
                    draw_list:layer()
                    draw_list:add(GuiOptionsAddForNextWidget, GUI_OPTION.NonInteractive)
                    local material_inventory = EntityGetFirstComponentIncludingDisabled(item, "MaterialInventoryComponent")
                    if material_inventory ~= nil then
                        local color = GameGetPotionColorUint(item)
                        local red = bit.band(color, 0xFF) / 0xFF
                        local green = bit.band(bit.rshift(color, 8), 0xFF) / 0xFF
                        local blue = bit.band(bit.rshift(color, 16), 0xFF) / 0xFF
                        local alpha = bit.rshift(color, 24) / 0xFF
                        draw_list:add(GuiColorSetForNextWidget, red, green, blue, alpha)
                    end
                    draw_list:add(GuiImage, x, y, sprite_filename, 1, 1, 0, 0, GUI_RECT_ANIMATION_PLAYBACK.Loop)
                    draw_list:bind(item_sprite_hash)
                end
            end
        end
        y = y + box_height + 4
    end

    local picked = false
    local picked_item
    local picker
    for i, player in ipairs(ordered_players) do
        local item = get_picked(player)
        if item ~= nil then
            picked = true
            if not Player(player).gui_._enabled or EntityGetComponent(item, "ItemComponent") == nil then
                picked_item = item
                picker = player
            end
            break
        end
    end
    if picked_item ~= nil then
        local ui_name = ""
        local custom_pickup_string = "$itempickup_pick"

        local item_component = EntityGetFirstComponent(picked_item, "ItemComponent")
        if item_component ~= nil then
            ui_name = ComponentGetValue2(item_component, "item_name")
            custom_pickup_string = ComponentGetValue2(item_component, "custom_pickup_string")
            if custom_pickup_string == "" then
                custom_pickup_string = "$itempickup_pick"
            end
        end

        local ability_component = EntityGetFirstComponentIncludingDisabled(picked_item, "AbilityComponent")
        if ability_component ~= nil and EntityHasTag(picked_item, "wand") then
            ui_name = "$item_wand"
        end

        local action_component = EntityGetFirstComponent(picked_item, "ItemActionComponent")
        if action_component ~= nil then
            dofile_once("data/scripts/gun/gun_actions.lua")
            local action_id = ComponentGetValue2(action_component, "action_id")
            for i, action in ipairs(actions) do
                if action.id == action_id then
                    ui_name = action.name
                    break
                end
            end
        end

        local item_data = get_item_data(picked_item)
        if item_data ~= nil then
            if item_data.ui_name ~= nil then
                ui_name = fetch(item_data.ui_name)
            end
            if item_data.custom_pickup_string ~= nil then
                custom_pickup_string = fetch(item_data.custom_pickup_string, picked_item, picker)
            end
        end

        local screen_width, screen_height = GuiGetScreenDimensions(gui)
        local x, y = screen_width * 0.5, screen_height - 40
        local text = custom_pickup_string
        if custom_pickup_string:find("^%$") then
            local translated_input_name = Player(picker):get_binding_keys("interact")
            local translated_ui_name = GameTextGetTranslatedOrNot(ui_name)
            text = GameTextGet(custom_pickup_string, translated_input_name, translated_ui_name)
        end
        draw_list:add(GuiAnimateBegin)
        draw_list:add(GuiAnimateAlphaFadeIn, 3458923234, 0.1, 0, not previous_picked)
        draw_list:add(GuiOptionsAddForNextWidget, GUI_OPTION.Align_HorizontalCenter)
        draw_list:add(GuiText, x, y, text)
        draw_list:add(GuiAnimateEnd)
    end
    previous_picked = picked
    draw_list:dispatch()
end

function OnWorldPreUpdate()
    invalidate_camera_info()
    update_players()
    update_common()
    update_camera()
    update_controls()
    update_pickup()
    update_gui()
end

function OnWorldPostUpdate()
    invalidate_camera_info()
    update_window()
end
