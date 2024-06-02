dofile_once("mods/iota_multiplayer/lib.lua")

mneedata[get_id(MOD)] = {
    name = "$iota_multiplayer.bindings_common",
    desc = "$iota_multiplayer.bindingsdesc_common"
}

bindings[get_id(MOD)] = {
    switch_player = {
        order_id = "a",
        name = "$iota_multiplayer.binding_switch_player",
        desc = "$iota_multiplayer.bindingdesc_switch_player",
        keys = { ["g"] = 1 }
    },
    toggle_teleport = {
        order_id = "b",
        name = "$iota_multiplayer.binding_toggle_teleport",
        desc = "$iota_multiplayer.bindingdesc_toggle_teleport",
        keys = { ["t"] = 1 }
    }
}

for i = 1, 8 do
    local id = i - 1
    local jpad = i > 1 and i < 6
    local function get_player_bindingdesc(param)
        return GameTextGet("$iota_multiplayer.bindingdesc_player", tostring(i), GameTextGet(param))
    end
    mneedata[MOD .. i] = {
        name = function()
            return GameTextGet("$iota_multiplayer.bindings_player", tostring(i))
        end,
        desc = function()
            return GameTextGet("$iota_multiplayer.bindingsdesc_player", tostring(i))
        end,
        is_hidden = function()
            ModAccessorTable(_G)
            return max_user < i
        end
    }
    bindings[MOD .. i] = {
        up = {
            order_id = "a",
            name = "$controls_up",
            desc = function() return get_player_bindingdesc("$controls_up") end,
            jpad_type = "MOTION",
            deadzone = 0.1,
            keys = { [jpad and id .. "gpd_l2" or "w"] = 1 },
            keys_alt = { [jpad and "_" or "space"] = 1 }
        },
        down = {
            order_id = "b",
            jpad_type = "MOTION",
            deadzone = 0.5,
            name = "$controls_down",
            desc = function() return get_player_bindingdesc("$controls_down") end,
            keys = { [jpad and id .. "gpd_btn_lv_+" or "s"] = 1 }
        },
        left = {
            order_id = "c",
            jpad_type = "MOTION",
            deadzone = 0.5,
            name = "$controls_left",
            desc = function() return get_player_bindingdesc("$controls_left") end,
            keys = { [jpad and id .. "gpd_btn_lh_-" or "a"] = 1 }
        },
        right = {
            order_id = "d",
            jpad_type = "MOTION",
            deadzone = 0.5,
            name = "$controls_right",
            desc = function() return get_player_bindingdesc("$controls_right") end,
            keys = { [jpad and id .. "gpd_btn_lh_+" or "d"] = 1 }
        },
        aimv = {
            is_hidden = true,
            keys = { "is_axis", jpad and id .. "gpd_axis_rv" or "_" }
        },
        aimh = {
            is_hidden = true,
            keys = { "is_axis", jpad and id .. "gpd_axis_rh" or "_" }
        },
        aim = {
            order_id = "e",
            jpad_type = "AIM",
            deadzone = 0.15,
            name = "$controls_aim_stick",
            desc = function() return GameTextGet("$iota_multiplayer.bindingdesc_aim", tostring(i), GameTextGet("$controls_aim_stick")) end,
            axes = { "aimh", "aimv" },
        },
        usewand = {
            order_id = "f",
            deadzone = 0.25,
            name = "$controls_usewand",
            desc = function() return get_player_bindingdesc("$controls_usewand") end,
            keys = { [jpad and id .. "gpd_r2" or "mouse_left"] = 1 }
        },
        sprayflask = {
            order_id = "g",
            deadzone = 0.25,
            name = "$controls_sprayflask",
            desc = function() return get_player_bindingdesc("$controls_sprayflask") end,
            keys = { [jpad and id .. "gpd_r2" or "mouse_left"] = 1 }
        },
        throw = {
            order_id = "h",
            name = "$controls_throw",
            desc = function() return get_player_bindingdesc("$controls_throw") end,
            keys = { [jpad and id .. "gpd_y" or "mouse_right"] = 1 }
        },
        kick = {
            order_id = "i",
            name = "$controls_kick",
            desc = function() return get_player_bindingdesc("$controls_kick") end,
            keys = { [jpad and id .. "gpd_b" or "f"] = 1 },
            keys_alt = { [jpad and id .. "gpd_l3" or "_"] = 1 }
        },
        inventory = {
            order_id = "j",
            name = "$controls_inventory",
            desc = function() return get_player_bindingdesc("$controls_inventory") end,
            keys = { [jpad and id .. "gpd_select" or "i"] = 1 },
            keys_alt = { [jpad and "_" or "tab"] = 1 }
        },
        interact = {
            order_id = "k",
            name = "$controls_use",
            desc = function() return get_player_bindingdesc("$controls_use") end,
            keys = { [jpad and id .. "gpd_a" or "e"] = 1 }
        },
        dropitem = {
            order_id = "n",
            name = "$controls_drop_item",
            desc = function() return get_player_bindingdesc("$controls_drop_item") end,
            keys = { [jpad and id .. "gpd_x" or "_"] = 1 }
        },
        itemnext = {
            order_id = "l",
            name = "$controls_itemnext",
            desc = function() return get_player_bindingdesc("$controls_itemnext") end,
            keys = { [jpad and id .. "gpd_r1" or "mouse_wheel_down"] = 1 }
        },
        itemprev = {
            order_id = "m",
            name = "$controls_itemprev",
            desc = function() return get_player_bindingdesc("$controls_itemprev") end,
            keys = { [jpad and id .. "gpd_l1" or "mouse_wheel_up"] = 1 }
        }
    }
end
