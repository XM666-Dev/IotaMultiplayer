dofile_once("mods/iota_multiplayer/lib.lua")

bindings[MP()] = {
    switch_focus = {
        order_id = "a",
        name = "Switch Focus（切换焦点）",
        desc = "Switch Focus（切换焦点）",
        keys = { ["g"] = 1 }
    },
    teleport = {
        order_id = "b",
        name = "Teleport（传送）",
        desc = "Teleport（传送）",
        keys = { ["t"] = 1 }
    }
}

for i = 2, tonumber(ModSettingGet(MP.player_num)) do
    local j = i - 1
    bindings[MP.p .. i] = {
        up = {
            order_id = "a",
            name = "$controls_up",
            desc = "$controls_up",
            keys = { [j .. "gpd_l2"] = 1 }
        },
        down = {
            order_id = "b",
            name = "$controls_down",
            desc = "$controls_down",
            keys = { [j .. "gpd_btn_lv_+"] = 1 }
        },
        left = {
            order_id = "c",
            name = "$controls_left",
            desc = "$controls_left",
            keys = { [j .. "gpd_btn_lh_-"] = 1 }
        },
        right = {
            order_id = "d",
            name = "$controls_right",
            desc = "$controls_right",
            keys = { [j .. "gpd_btn_lh_+"] = 1 }
        },
        aimv = {
            order_id = "e",
            name = "$controls_aim_stick $controls_up $controls_down",
            desc = "$controls_aim_stick $controls_up $controls_down",
            keys = { "is_axis", j .. "gpd_axis_rv" }
        },
        aimh = {
            order_id = "f",
            name = "$controls_aim_stick $controls_left $controls_right",
            desc = "$controls_aim_stick $controls_left $controls_right",
            keys = { "is_axis", j .. "gpd_axis_rh" }
        },
        usewand = {
            order_id = "g",
            name = "$controls_usewand",
            desc = "$controls_usewand",
            keys = { [j .. "gpd_r2"] = 1 }
        },
        sprayflask = {
            order_id = "h",
            name = "$controls_sprayflask",
            desc = "$controls_sprayflask",
            keys = { [j .. "gpd_r2"] = 1 }
        },
        throw = {
            order_id = "i",
            name = "$controls_throw",
            desc = "$controls_throw",
            keys = { [j .. "gpd_y"] = 1 }
        },
        kick = {
            order_id = "j",
            name = "$controls_kick",
            desc = "$controls_kick",
            keys = { [j .. "gpd_b"] = 1 }
        },
        inventory = {
            order_id = "k",
            name = "$controls_inventory",
            desc = "$controls_inventory",
            keys = { [j .. "gpd_select"] = 1 }
        },
        interact = {
            order_id = "l",
            name = "$controls_use",
            desc = "$controls_use",
            keys = { [j .. "gpd_a"] = 1 }
        },
        itemnext = {
            order_id = "m",
            name = "$controls_itemnext",
            desc = "$controls_itemnext",
            keys = { [j .. "gpd_r1"] = 1 }
        },
        itemprev = {
            order_id = "n",
            name = "$controls_itemprev",
            desc = "$controls_itemprev",
            keys = { [j .. "gpd_l1"] = 1 }
        },
        itemslot1 = {
            order_id = "o",
            name = "$controls_itemslot1",
            desc = "$controls_itemslot1",
            keys = {}
        },
        itemslot2 = {
            order_id = "p",
            name = "$controls_itemslot2",
            desc = "$controls_itemslot2",
            keys = {}
        },
        itemslot3 = {
            order_id = "q",
            name = "$controls_itemslot3",
            desc = "$controls_itemslot3",
            keys = {}
        },
        itemslot4 = {
            order_id = "r",
            name = "$controls_itemslot4",
            desc = "$controls_itemslot4",
            keys = {}
        },
        itemslot5 = {
            order_id = "s",
            name = "$controls_itemslot5",
            desc = "$controls_itemslot5",
            keys = {}
        },
        itemslot6 = {
            order_id = "t",
            name = "$controls_itemslot6",
            desc = "$controls_itemslot6",
            keys = {}
        },
        itemslot7 = {
            order_id = "u",
            name = "$controls_itemslot7",
            desc = "$controls_itemslot7",
            keys = {}
        },
        itemslot8 = {
            order_id = "v",
            name = "$controls_itemslot8",
            desc = "$controls_itemslot8",
            keys = {}
        }
    }
end
