dofile_once("data/scripts/lib/mod_settings.lua")

local function Table(t, getters, setters)
    return setmetatable(t, {
        __index = function(t, k)
            return (getters[k] or rawget)(t, k)
        end,
        __newindex = function(t, k, v)
            (setters[k] or rawset)(t, k, v)
        end,
    })
end
---@param str string
local function parse_csv(str)
    local cellDatas = {}
    local rowHeads = {}
    local cellArrangement = {}
    local result
    local tempKey = nil
    ---设置指定行列单元格的值
    ---* 使用行列号(从1开始的数字)来作为索引
    ---* 不存在的单元格会自动新建
    ---@param row number
    ---@param column number
    local set = function(row, column, value)
        if column == 1 then
            cellDatas[value] = {}
            table.insert(cellArrangement, value)
            tempKey = value
        end
        table.insert(cellDatas[tempKey], value)
        if row == 1 then rowHeads[value] = column end
    end
    result = {
        rowHeads = rowHeads,
        cellDatas = cellDatas,
        cellArrangement = cellArrangement,
        ---获取key对应值
        ---@param row string
        ---@param column string
        ---@return string|nil
        get = function(row, column)
            -- 尝试转为数字索引
            column = rowHeads[column]
            row = cellDatas[row]
            if column and row then
                local result = row[column]                                                              -- 34为"符号
                if string.byte(result, 1, 1) == 34 and string.byte(result, #result, #result) == 34 then --删除开头和结尾的" 因为实际游戏中也不存在
                    return string.sub(result, 2, string.len(result) - 1)
                end
                return result
            else
                return nil
            end
        end,
        tostring = function()
            local cache = {}
            local newRowHeads = {}
            for v, k in pairs(rowHeads) do
                newRowHeads[k] = v
            end
            local rowHeadSize = #newRowHeads

            for i = 1, rowHeadSize do
                if newRowHeads[i] ~= "" then
                    table.insert(cache, newRowHeads[i])
                end
                if i ~= rowHeadSize then
                    table.insert(cache, ",")
                end
            end
            local cellSize = #cellArrangement
            for i = 1, cellSize do
                local key = cellArrangement[i]
                local value = cellDatas[key]
                local size = #value
                for v_i, vstr in pairs(value) do  --解析数组
                    if vstr ~= "" then
                        table.insert(cache, vstr) --插入字符串
                    end
                    if v_i ~= size then           --防止最后一个插入,
                        table.insert(cache, ",")
                    end
                end
                if i ~= cellSize then         --防止最后一个插入\n
                    table.insert(cache, "\n") --插入换行符
                end
            end
            return table.concat(cache)
        end,
    }
    local state_quotationMark = false -- 双引号状态机
    local usub = string.sub
    local codepoint = string.byte
    local StartPos = 1 --用于记录一个需要被剪切的字符串的起始位
    local charNum = 0
    local posRow = 1
    local posColumn = 1
    for i = 1, #str do
        charNum = codepoint(str, i, i)
        if state_quotationMark then               -- 处于双引号包裹中
            state_quotationMark = (charNum ~= 34) --减少分支优化
            if charNum == 92 then                 --转义符考虑
                i = i + 1                         --当前字符是转义符，下一个字符也应该跳过，所以加1，下一次循环再加1
            end
        else
            if charNum == 34 then                                  -- 34为"符号
                state_quotationMark = true                         -- 进入双引号包裹
            elseif charNum == 44 then                              -- 分隔符为en逗号 44为,
                set(posRow, posColumn, usub(str, StartPos, i - 1)) --i-1是为了不要把,加进去
                StartPos = i + 1                                   --重设起始位
                posColumn = posColumn + 1
            elseif charNum == 10 then                              --10为\n
                -- 对连续换行(空行)和"\n"(Windows换行符)特殊处理
                if (codepoint(str, i - 1, i - 1) ~= 10) then
                    set(posRow, posColumn, usub(str, StartPos, i - 1))
                    StartPos = i + 1
                    posRow = posRow + 1
                    posColumn = 1
                end
            end
        end
    end
    set(posRow, posColumn, usub(str, StartPos, #str - 1))
    return result
end
local translations = parse_csv([[
,en,ru,pt-br,es-es,de,fr-fr,it,pl,zh-cn,jp,ko,
iota_multiplayer.bindings_common,mp common,,,,,,,,联机常用,,,
iota_multiplayer.bindingsdesc_common,mp common bindings.,,,,,,,,联机常用的按键绑定。,,,
iota_multiplayer.binding_switch_player,switch player,,,,,,,,切换玩家,,,
iota_multiplayer.bindingdesc_switch_player,switch camera&gui between players.,,,,,,,,在玩家之间切换摄像机和用户界面。,,,
iota_multiplayer.binding_toggle_teleport,toggle teleport,,,,,,,,开关传送,,,
iota_multiplayer.bindingdesc_toggle_teleport,enable/disable auto teleport.,,,,,,,,启用/禁用自动传送。,,,
iota_multiplayer.bindings_player,player $0,,,,,,,,玩家$0,,,
iota_multiplayer.bindingsdesc_player,player $0 bindings.,,,,,,,,玩家$0的按键绑定。,,,
iota_multiplayer.bindingdesc_player,control player $0 $1.,,,,,,,,控制玩家$0$1。,,,
iota_multiplayer.bindingdesc_aim,"control player $0 $1, unbind to use mouse aiming.",,,,,,,,控制玩家$0$1，解绑以使用鼠标瞄准。,,,
iota_multiplayer.setting_share,SHARE,,,,,,,,共享,,,
iota_multiplayer.settingdesc_share,About resource sharing,,,,,,,,资源共享相关,,,
iota_multiplayer.setting_share_money,Money,,,,,,,,金钱,,,
iota_multiplayer.settingdesc_share_money,Are money sharing for players?,,,,,,,,是否为玩家共享金钱？,,,
iota_multiplayer.setting_share_temple_heart,Temple heart,,,,,,,,圣山红心,,,
iota_multiplayer.settingdesc_share_temple_heart,Do temple hearts spawn for others when picked up?,,,,,,,,圣山红心被捡起时是否为其他玩家生成？,,,
iota_multiplayer.setting_share_temple_refresh,Temple refresh,,,,,,,,圣山刷新器,,,
iota_multiplayer.settingdesc_share_temple_refresh,Do temple refreshs spawn for others when picked up?,,,,,,,,圣山刷新器被捡起时是否为其他玩家生成？,,,
iota_multiplayer.setting_share_temple_perk,Temple perk,,,,,,,,圣山天赋,,,
iota_multiplayer.settingdesc_share_temple_perk,Do temple perks respawn for others when picked up?,,,,,,,,圣山天赋被捡起时是否为其他玩家重新生成？,,,
iota_multiplayer.setting_friendly_fire,FRIENDLY FIRE,,,,,,,,友伤,,,
iota_multiplayer.settingdesc_friendly_fire,About friendly fire,,,,,,,,友军误伤相关,,,
iota_multiplayer.setting_friendly_fire_percent,Percent,,,,,,,,百分比,,,
iota_multiplayer.settingdesc_friendly_fire_percent,The percent of friendly fire between players.,,,,,,,,玩家之间的友伤百分比。,,,
iota_multiplayer.setting_friendly_fire_kick,Kick,,,,,,,,踢击,,,
iota_multiplayer.settingdesc_friendly_fire_kick,Do players received friendly fire when kicked?,,,,,,,,玩家被踢击时是否受到友伤？,,,
iota_multiplayer.setting_friendly_fire_kick_drop,Kick drop,,,,,,,,踢击掉落,,,
iota_multiplayer.settingdesc_friendly_fire_kick_drop,Do players drop items when kicked?,,,,,,,,玩家被踢击时是否掉落物品？,,,
iota_multiplayer.setting_camera,Camera,,,,,,,,摄像机,,,
iota_multiplayer.settingdesc_camera,About camera tweaks,,,,,,,,摄像机调整相关,,,
iota_multiplayer.setting_camera_zoom,Zoom,,,,,,,,缩放,,,
iota_multiplayer.settingdesc_camera_zoom,Camera zoom multiplier.,,,,,,,,摄像机的缩放倍数。,,,
iota_multiplayer.menugiveup,Give up,,,,,,,,放弃,,,
]])
local function get_language()
    return ({
        ["English"] = "en",
        ["русский"] = "ru",
        ["Português (Brasil)"] = "pt-br",
        ["Español"] = "es-es",
        ["Deutsch"] = "de",
        ["Français"] = "fr-fr",
        ["Italiano"] = "it",
        ["Polska"] = "pl",
        ["简体中文"] = "zh-cn",
        ["日本語"] = "jp",
        ["한국어"] = "ko",
    })[GameTextGet("$current_language")]
end
local function get_text(key)
    local text = translations.get(key, get_language())
    return text ~= "" and text or translations.get(key, "en")
end

local mod_id = "iota_multiplayer"
mod_settings_version = 1
mod_settings = {
    Table({
        category_id = "share",
        settings = {
            Table({
                id = "share_money",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }, {
                ui_name = function() return get_text("iota_multiplayer.setting_share_money") end,
                ui_description = function() return get_text("iota_multiplayer.settingdesc_share_money") end,
            }),
            Table({
                id = "share_temple_heart",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }, {
                ui_name = function() return get_text("iota_multiplayer.setting_share_temple_heart") end,
                ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_heart") end,
            }),
            Table({
                id = "share_temple_refresh",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }, {
                ui_name = function() return get_text("iota_multiplayer.setting_share_temple_refresh") end,
                ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_refresh") end,
            }),
            Table({
                id = "share_temple_perk",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }, {
                ui_name = function() return get_text("iota_multiplayer.setting_share_temple_perk") end,
                ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_perk") end,
            }),
        },
    }, {
        ui_name = function() return get_text("iota_multiplayer.setting_share") end,
        ui_description = function() return get_text("iota_multiplayer.settingdesc_share") end,
    }),
    Table({
        category_id = "friendly_fire",
        settings = {
            Table({
                id = "friendly_fire_percent",
                value_default = 0.5,
                value_min = 0,
                value_max = 1,
                value_display_multiplier = 100,
                value_display_formatting = " $0 %",
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }, {
                ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_percent") end,
                ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_percent") end,
            }),
            Table({
                id = "friendly_fire_kick",
                value_default = false,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }, {
                ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_kick") end,
                ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_kick") end,
            }),
            Table({
                id = "friendly_fire_kick_drop",
                value_default = false,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }, {
                ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_kick_drop") end,
                ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_kick_drop") end,
            }),
        },
    }, {
        ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire") end,
        ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire") end,
    }),
    Table({
        category_id = "camera",
        settings = {
            Table({
                id = "camera_zoom",
                value_default = 1,
                value_min = 1,
                value_max = 3,
                value_display_multiplier = 100,
                value_display_formatting = " $0 %",
                scope = nil,
            }, {
                ui_name = function() return get_text("iota_multiplayer.setting_camera_zoom") end,
                ui_description = function() return get_text("iota_multiplayer.settingdesc_camera_zoom") end,
            }),
        },
    }, {
        ui_name = function() return get_text("iota_multiplayer.setting_camera") end,
        ui_description = function() return get_text("iota_multiplayer.settingdesc_camera") end,
    }),
}

function ModSettingsUpdate(init_scope)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
