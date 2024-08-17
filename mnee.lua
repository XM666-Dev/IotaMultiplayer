dofile_once("mods/iota_multiplayer/lib.lua")

mneedata.iota_multiplayer = {
    name = "$iota_multiplayer.bindings_common",
    desc = "$iota_multiplayer.bindingsdesc_common",
}

bindings.iota_multiplayer = {
    switch_player = {
        order_id = "a",
        name = "$iota_multiplayer.binding_switch_player",
        desc = "$iota_multiplayer.bindingdesc_switch_player",
        keys = { ["g"] = 1 },
    },
    toggle_teleport = {
        order_id = "b",
        name = "$iota_multiplayer.binding_toggle_teleport",
        desc = "$iota_multiplayer.bindingdesc_toggle_teleport",
        keys = { ["t"] = 1 },
    },
}

for i = 1, 8 do
    local order = 0
    local function next_order()
        local s = string.char(order)
        order = order + 1
        return s
    end
    local function get_player_bindingdesc(param)
        return GameTextGet("$iota_multiplayer.bindingdesc_player", tostring(i), GameTextGet(param))
    end
    local jpad = i > 1 and i < 6 and i - 1
    mneedata["iota_multiplayer" .. i] = {
        name = function()
            return GameTextGet("$iota_multiplayer.bindings_player", tostring(i))
        end,
        desc = function()
            return GameTextGet("$iota_multiplayer.bindingsdesc_player", tostring(i))
        end,
        is_hidden = function()
            return i > mod.max_index
        end,
    }
    bindings["iota_multiplayer" .. i] = {
        up = {
            order_id = next_order(),
            name = "$controls_up",
            desc = function() return get_player_bindingdesc("$controls_up") end,
            jpad_type = "MOTION",
            deadzone = 0.1,
            keys = { [jpad and jpad .. "gpd_l2" or "w"] = 1 },
            keys_alt = { [jpad and "_" or "space"] = 1 },
        },
        down = {
            order_id = next_order(),
            name = "$controls_down",
            desc = function() return get_player_bindingdesc("$controls_down") end,
            jpad_type = "MOTION",
            deadzone = 0.5,
            keys = { [jpad and jpad .. "gpd_btn_lv_+" or "s"] = 1 },
        },
        left = {
            order_id = next_order(),
            name = "$controls_left",
            desc = function() return get_player_bindingdesc("$controls_left") end,
            jpad_type = "MOTION",
            deadzone = 0.5,
            keys = { [jpad and jpad .. "gpd_btn_lh_-" or "a"] = 1 },
        },
        right = {
            order_id = next_order(),
            name = "$controls_right",
            desc = function() return get_player_bindingdesc("$controls_right") end,
            jpad_type = "MOTION",
            deadzone = 0.5,
            keys = { [jpad and jpad .. "gpd_btn_lh_+" or "d"] = 1 },
        },
        aimv = {
            is_hidden = true,
            keys = { "is_axis", jpad and jpad .. "gpd_axis_rv" or "_" },
        },
        aimh = {
            is_hidden = true,
            keys = { "is_axis", jpad and jpad .. "gpd_axis_rh" or "_" },
        },
        aim = {
            order_id = next_order(),
            name = "$controls_aim_stick",
            desc = function() return GameTextGet("$iota_multiplayer.bindingdesc_aim", tostring(i), GameTextGet("$controls_aim_stick")) end,
            jpad_type = "AIM",
            deadzone = 0.15,
            axes = { "aimh", "aimv" },
        },
        usewand = {
            order_id = next_order(),
            name = "$controls_usewand",
            desc = function() return get_player_bindingdesc("$controls_usewand") end,
            deadzone = 0.25,
            keys = { [jpad and jpad .. "gpd_r2" or "mouse_left"] = 1 },
        },
        sprayflask = {
            order_id = next_order(),
            name = "$controls_sprayflask",
            desc = function() return get_player_bindingdesc("$controls_sprayflask") end,
            deadzone = 0.25,
            keys = { [jpad and jpad .. "gpd_r2" or "mouse_left"] = 1 },
        },
        throw = {
            order_id = next_order(),
            name = "$controls_throw",
            desc = function() return get_player_bindingdesc("$controls_throw") end,
            keys = { [jpad and jpad .. "gpd_y" or "mouse_right"] = 1 },
        },
        kick = {
            order_id = next_order(),
            name = "$controls_kick",
            desc = function() return get_player_bindingdesc("$controls_kick") end,
            keys = { [jpad and jpad .. "gpd_b" or "f"] = 1 },
            keys_alt = { [jpad and jpad .. "gpd_l3" or "_"] = 1 },
        },
        inventory = {
            order_id = next_order(),
            name = "$controls_inventory",
            desc = function() return get_player_bindingdesc("$controls_inventory") end,
            keys = { [jpad and jpad .. "gpd_select" or "i"] = 1 },
            keys_alt = { [jpad and "_" or "tab"] = 1 },
        },
        interact = {
            order_id = next_order(),
            name = "$controls_use",
            desc = function() return get_player_bindingdesc("$controls_use") end,
            keys = { [jpad and jpad .. "gpd_a" or "e"] = 1 },
        },
        dropitem = {
            order_id = next_order(),
            name = "$controls_drop_item",
            desc = function() return get_player_bindingdesc("$controls_drop_item") end,
            keys = { [jpad and jpad .. "gpd_x" or "_"] = 1 },
        },
        itemnext = {
            order_id = next_order(),
            name = "$controls_itemnext",
            desc = function() return get_player_bindingdesc("$controls_itemnext") end,
            keys = { [jpad and jpad .. "gpd_r1" or "mouse_wheel_down"] = 1 },
        },
        itemprev = {
            order_id = next_order(),
            name = "$controls_itemprev",
            desc = function() return get_player_bindingdesc("$controls_itemprev") end,
            keys = { [jpad and jpad .. "gpd_l1" or "mouse_wheel_up"] = 1 },
        },
    }
end
