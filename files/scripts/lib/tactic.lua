dofile_once("data/scripts/lib/utilities.lua")

--#region

NUMERIC_CHARACTERS = "0123456789"

local ModTextFileSetContent = ModTextFileSetContent
function append_translations(filename)
    local common = "data/translations/common.csv"
    ModTextFileSetContent(common, ModTextFileGetContent(common) .. ModTextFileGetContent(filename):match("^.-\n(.*)$"))
end

function has_flag_run_or_add(flag)
    return GameHasFlagRun(flag) or GameAddFlagRun(flag)
end

function validate(id)
    return id and id > 0 and id or nil
end

function remove_component(component)
    EntityRemoveComponent(ComponentGetEntity(component), component)
end

function set_component_tags(component, tags)
    local entity = ComponentGetEntity(component)
    if validate(entity) then
        for tag in ComponentGetTags(component):gmatch("[^,]+") do
            ComponentRemoveTag(component, tag)
        end
        for i, tag in ipairs(tags) do
            ComponentAddTag(component, tag)
        end
    end
end

function set_component_enabled(component, enabled)
    local entity = ComponentGetEntity(component)
    if validate(entity) then
        EntitySetComponentIsEnabled(entity, component, enabled)
    end
end

function refresh_sprite(sprite)
    local entity = ComponentGetEntity(sprite)
    if validate(entity) then
        EntityRefreshSprite(entity, sprite)
    end
end

function get_children(entity, ...)
    return EntityGetAllChildren(entity, ...) or {}
end

function get_inventory_items(entity)
    return GameGetAllInventoryItems(entity) or {}
end

function get_game_effect(entity, name)
    local effect = GameGetGameEffect(entity, name)
    return validate(effect), validate(ComponentGetEntity(effect))
end

function get_last_component(components)
    local index = 0
    for i, v in ipairs(components) do
        if ComponentGetIsEnabled(v) then
            index = i
        end
    end
    return index, components[index]
end

function get_attack_info(entity, ai, attacks)
    local animation_name = "attack_ranged"
    local frames_between
    local action_frame
    local entity_file
    local entity_count_min
    local entity_count_max
    local offset_x
    local offset_y
    if ai ~= nil then
        frames_between = ComponentGetValue2(ai, "attack_ranged_frames_between")
        action_frame = ComponentGetValue2(ai, "attack_ranged_action_frame")
        entity_file = ComponentGetValue2(ai, "attack_ranged_entity_file")
        entity_count_min = ComponentGetValue2(ai, "attack_ranged_entity_count_min")
        entity_count_max = ComponentGetValue2(ai, "attack_ranged_entity_count_max")
        offset_x = ComponentGetValue2(ai, "attack_ranged_offset_x")
        offset_y = ComponentGetValue2(ai, "attack_ranged_offset_y")
    end
    local x, y = EntityGetTransform(entity)
    for i, attack in ipairs(attacks) do
        SetRandomSeed(x + 0.11231 + GameGetFrameNum(), y + 0.2341)
        if Random(100) <= ComponentGetValue2(attack, "use_probability") then
            animation_name = ComponentGetValue2(attack, "animation_name")
            frames_between = ComponentGetValue2(attack, "frames_between")
            action_frame = ComponentGetValue2(attack, "attack_ranged_action_frame")
            entity_file = ComponentGetValue2(attack, "attack_ranged_entity_file")
            entity_count_min = ComponentGetValue2(attack, "attack_ranged_entity_count_min")
            entity_count_max = ComponentGetValue2(attack, "attack_ranged_entity_count_max")
            offset_x = ComponentGetValue2(attack, "attack_ranged_offset_x")
            offset_y = ComponentGetValue2(attack, "attack_ranged_offset_y")
        end
    end
    if entity_file == "data/entities/projectiles/acidshot.xml" and EntityGetFilename(entity) ~= "data/entities/animals/acidshooter.xml" then
        entity_file = nil
    end
    return {
        animation_name = animation_name,
        frames_between = frames_between,
        action_frame = action_frame,
        entity_file = entity_file,
        entity_count_min = entity_count_min,
        entity_count_max = entity_count_max,
        offset_x = offset_x,
        offset_y = offset_y,
    }
end

function get_attack_ranged_pos(entity, attack_info)
    local x, y, rotation, scale_x, scale_y = EntityGetTransform(entity)
    local pos_x, pos_y = attack_info.offset_x, attack_info.offset_y
    pos_x, pos_y = vec_scale(pos_x, pos_y, scale_x, scale_y)
    pos_x, pos_y = vec_rotate(pos_x, pos_y, rotation)
    pos_x, pos_y = vec_add(pos_x, pos_y, x, y)
    return pos_x, pos_y
end

local max_id = 1
function get_new_entities_range()
    local previous_max_id = max_id
    max_id = EntitiesGetMaxID()
    return previous_max_id, max_id
end

function get_frame_num_next()
    return GameGetFrameNum() + 1
end

local raw_gui
function get_resolution(gui)
    if gui == nil then
        if raw_gui == nil then
            raw_gui = GuiCreate()
        end
        gui = raw_gui
    end
    local virtual_resolution_x = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X"))
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    return virtual_resolution_x, virtual_resolution_x * screen_height / screen_width
end

function get_pos_on_screen(x, y, gui)
    if gui == nil then
        if raw_gui == nil then
            raw_gui = GuiCreate()
        end
        gui = raw_gui
    end
    local camera_x, camera_y = GameGetCameraPos()
    local bounds_width, bounds_height = select(3, GameGetCameraBounds())
    local resolution_width, resolution_height = get_resolution(gui)
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    return (x - camera_x + bounds_width * 0.5 + tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_OFFSET_X"))) / resolution_width * screen_width,
        (y - camera_y + bounds_height * 0.5 + tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_OFFSET_Y"))) / resolution_height * screen_height
end

function get_pos_in_world(x, y, gui)
    if gui == nil then
        if raw_gui == nil then
            raw_gui = GuiCreate()
        end
        gui = raw_gui
    end
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    local resolution_width, resolution_height = get_resolution(gui)
    local camera_x, camera_y = GameGetCameraPos()
    local bounds_width, bounds_height = select(3, GameGetCameraBounds())
    return x / screen_width * resolution_width + camera_x - bounds_width * 0.5 - tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_OFFSET_X")),
        y / screen_height * resolution_height + camera_y - bounds_height * 0.5 - tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_OFFSET_Y"))
end

local funcinfo = jit.util.funcinfo
function get_line(f)
    return funcinfo(f).currentline
end

local class_metatable = {
    __call = function(t, ...)
        return setmetatable(t[1](...), t)
    end,
}
local function Class(f)
    local t = {f}
    t.__index = t
    return setmetatable(t, class_metatable)
end
Window = Class(function(gui)
    return {gui = gui, max_id = 0xFFFFFFFFFFFF, ids = {}}
end)

function Window:begin(depth)
    GuiStartFrame(self.gui)
    return DrawList(self, depth)
end

DrawList = Class(function(window, depth)
    return {window = window, depth = depth, layer_depth = depth + 1, draws = {}, hash_counts = {}}
end)

function DrawList:add(...)
    table.insert(self.draws, {...})
end

function DrawList:bind(hash)
    local hash_count = (self.hash_counts[hash] or 0) + 1
    local hash_key = bit.bor(hash, bit.lshift(hash_count, 16))
    self.hash_counts[hash] = hash_count

    local id = self.window.ids[hash_key]
    if id == nil then
        id = self.window.max_id
        self.window.ids[hash_key] = id
        self.window.max_id = id - 1
    end
    table.insert(self.draws[#self.draws], 2, id)
end

local layer_step = 1 / 1024
function DrawList:layer()
    local depth = self.layer_depth
    self.layer_depth = depth - layer_step
    table.insert(self.draws, {GuiZSet, depth})
end

function DrawList:dispatch()
    for i, draw in ipairs(self.draws) do
        draw[1](self.window.gui, unpack(draw, 2))
    end
end

function serialize(v)
    local type = type(v)
    if type == "number" then
        return ("%.16a"):format(v)
    elseif type == "string" then
        return ("%q"):format(v)
    elseif type == "table" then
        local formatters = {}
        local values = {}
        serialize_parse(v, formatters, values)
        return table.concat(formatters):format(unpack(values))
    end
    return tostring(v)
end

function serialize_parse(v, formatters, values)
    local type = type(v)
    if type == "number" then
        table.insert(formatters, "%.16a")
    elseif type == "string" then
        table.insert(formatters, "%q")
    elseif type == "table" then
        table.insert(formatters, "{")
        for key, value in pairs(v) do
            table.insert(formatters, "[")
            serialize_parse(key, formatters, values)
            table.insert(formatters, "]=")
            serialize_parse(value, formatters, values)
            table.insert(formatters, ",")
        end
        table.insert(formatters, "}")
        return
    else
        table.insert(formatters, "%s")
    end
    table.insert(values, v)
end

function serialize_safe(v)
    local type = type(v)
    if type == "number" then
        return ("%.16a"):format(v)
    elseif type == "string" then
        return table.concat{"'", ("%q"):format(v):sub(2, -2), "'"}
    elseif type == "table" then
        local formatters = {}
        local values = {}
        serialize_parse_safe(v, formatters, values)
        return table.concat(formatters):format(unpack(values))
    end
    return tostring(v)
end

function serialize_parse_safe(v, formatters, values)
    local type = type(v)
    if type == "number" then
        table.insert(formatters, "%.16a")
    elseif type == "string" then
        table.insert(formatters, "'")
        table.insert(formatters, ("%q"):format(v):sub(2, -2))
        table.insert(formatters, "'")
    elseif type == "table" then
        table.insert(formatters, "{")
        for key, value in pairs(v) do
            table.insert(formatters, "[")
            serialize_parse_safe(key, formatters, values)
            table.insert(formatters, "]=")
            serialize_parse_safe(value, formatters, values)
            table.insert(formatters, ",")
        end
        table.insert(formatters, "}")
        return
    else
        table.insert(formatters, "%s")
    end
    table.insert(values, v)
end

local tactic_filename = funcinfo(setfenv(1, getfenv())).source
local temporary_filename = tactic_filename .. "/temporary.lua"
function deserialize(s)
    ModTextFileSetContent(temporary_filename, "return " .. s)
    local f, err = loadfile(temporary_filename)
    if f == nil then return f, err end
    return f()
end

local languages = {
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
}
function get_language()
    return languages[GameTextGet("$current_language")]
end

local function log_parse(v, formatters, values)
    local type = type(v)
    if type == "nil" then
        table.insert(formatters, type)
        return
    elseif type == "string" then
        table.insert(formatters, v)
        return
    elseif type == "table" then
        table.insert(formatters, "{")
        for key, value in pairs(v) do
            log_parse(key, formatters, values)
            table.insert(formatters, "=")
            log_parse(value, formatters, values)
            table.insert(formatters, ",")
        end
        table.insert(formatters, "}")
        return
    end
    table.insert(formatters, "%s")
    table.insert(values, v)
end
function log(...)
    local formatters = {}
    local values = {}
    local count = select("#", ...)
    for i = 1, count do
        local v = select(i, ...)
        log_parse(v, formatters, values)
        if i < count then
            table.insert(formatters, ",")
        end
    end
    local s = table.concat(formatters):format(unpack(values))
    print(s)
    GamePrint(s)
end

--#endregion

--#region

local operands = {}
local function pop_operand()
    return table.remove(operands)
end
function operand(v)
    table.insert(operands, v)
    return pop_operand
end

function string.raw(s)
    local bytes = {}
    for i, v in ipairs{s:byte(1, #s)} do
        if v < 48 or v > 57 and v < 65 or v > 90 and v < 97 or v > 122 then
            table.insert(bytes, 37)
        end
        table.insert(bytes, v)
    end
    return string.char(unpack(bytes))
end

function table.find(list, pred)
    if type(pred) == "function" then
        for i, v in ipairs(list) do
            if pred(v) then
                return v, i
            end
        end
    else
        for i, v in ipairs(list) do
            if v == pred then
                return v, i
            end
        end
    end
end

function table.filter(list, pred)
    local filtered = {}
    for i, v in ipairs(list) do
        if pred(v) then
            table.insert(filtered, v)
        end
    end
    return filtered
end

function table.iterate(list, comp)
    local iterated
    for i, v in ipairs(list) do
        if iterated == nil or comp(v, iterated) then
            iterated = v
        end
    end
    return iterated
end

function table.duplicate(t)
    local duplicated = {}
    for k, v in pairs(t) do
        duplicated[k] = v
    end
    return duplicated
end

function math.round(x)
    return math.floor(x + 0.5)
end

function lerp(from, to, weight)
    return from + (to - from) * weight
end

function lerp_clamped(from, to, weight)
    return lerp(from, to, clamp(weight, 0, 1))
end

local tau = math.pi * 2
function lerp_angle(from, to, weight)
    local difference = (to - from + math.pi) % tau - math.pi
    return from + difference * weight
end

function lerp_angle_vector(x1, y1, x2, y2, weight)
    local angle1 = math.atan2(y1, x1)
    local angle2 = math.atan2(y2, x2)
    local lerped_angle = lerp_angle(angle1, angle2, weight)
    local length1 = math.sqrt(x1 * x1 + y1 * y1)
    local length2 = math.sqrt(x2 * x2 + y2 * y2)
    local lerped_length = lerp(length1, length2, weight)
    return math.cos(lerped_angle) * lerped_length, math.sin(lerped_angle) * lerped_length
end

function warp(value, from, to)
    return value % (to - from) + from
end

function point_in_rectangle(x, y, left, up, right, down)
    return x >= left and x <= right and y >= up and y <= down
end

function extract_rgba(color)
    return bit.band(bit.rshift(color, 24), 255) / 255,
        bit.band(bit.rshift(color, 16), 255) / 255,
        bit.band(bit.rshift(color, 8), 255) / 255,
        bit.band(color, 255) / 255
end

function extract_abgr(color)
    return bit.band(color, 255) / 255,
        bit.band(bit.rshift(color, 8), 255) / 255,
        bit.band(bit.rshift(color, 16), 255) / 255,
        bit.band(bit.rshift(color, 24), 255) / 255
end

function extract_rgb(color)
    return bit.band(bit.rshift(color, 16), 255) / 255,
        bit.band(bit.rshift(color, 8), 255) / 255,
        bit.band(color, 255) / 255
end

function compose_rgba(r, g, b, a)
    return bit.bor(
        bit.lshift(r * 255, 24),
        bit.lshift(g * 255, 16),
        bit.lshift(b * 255, 8),
        a * 255
    )
end

function compose_abgr(r, g, b, a)
    return bit.bor(
        bit.lshift(a * 255, 24),
        bit.lshift(b * 255, 16),
        bit.lshift(g * 255, 8),
        r * 255
    )
end

function compose_rgb(r, g, b)
    return bit.bor(
        bit.lshift(r * 255, 16),
        bit.lshift(g * 255, 8),
        b * 255
    )
end

--#endregion

local null = setmetatable({}, {
    __index = function(t, k)
        if type(k) == "string" and k:find("_$") then return t end
    end,
    __newindex = function() end,
})
local function __index(t, k)
    local conditional = false
    if k:find("_$") then
        k = k:sub(1, -2)
        conditional = true
    end
    local field = getmetatable(t)[k]
    assert(field ~= nil or k == "id", "field does not exist: " .. k)
    if type(field) == "table" then
        local v = field:get(t, k)
        if v == nil and conditional then return null end
        return v
    end
    return field
end
local function __newindex(t, k, v)
    local field = getmetatable(t)[k]
    assert(field ~= nil, "field does not exist: " .. k)
    field:set(t, k, v)
end
---@class Entity
---@field id integer
---@type table|fun(fields: table): fun(entity_id: integer): Entity
EntityClass = setmetatable({
    __call = function(t, entity_id)
        return setmetatable({id = validate(entity_id)}, t)
    end,
}, {
    __call = function(t, fields)
        fields.__index = __index
        fields.__newindex = __newindex
        return setmetatable(fields, t)
    end,
})

local vector_metatable = {
    __call = function(self)
        return ComponentGetValue2(self.id, self.field)
    end,
    __index = function(self, k)
        return select(k, ComponentGetValue2(self.id, self.field))
    end,
    __newindex = function(self, k, v)
        local values = {ComponentGetValue2(self.id, self.field)}
        values[k] = v
        ComponentSetValue2(self.id, self.field, unpack(values))
    end,
}
local attribute_getters = {_tags = ComponentGetTags, _enabled = ComponentGetIsEnabled, _entity = ComponentGetEntity, _members = ComponentGetMembers, _typename = ComponentGetTypeName}
local attribute_setters = {_tags = set_component_tags, _enabled = set_component_enabled}
local component_metatable = {
    __index = function(self, k)
        if k:find("_$") then
            k = k:sub(1, -2)
        end
        local f = attribute_getters[k]
        if f ~= nil then
            return f(self._id)
        end
        local v = {ComponentGetValue2(self._id, k)}
        if #v > 1 then
            return setmetatable({id = self._id, field = k}, vector_metatable)
        end
        return v[1]
    end,
    __newindex = function(self, k, v)
        local f = attribute_setters[k]
        if f ~= nil then
            f(self._id, v)
            return
        end
        if v ~= nil then
            if type(v) == "table" then
                if getmetatable(v) == vector_metatable then
                    ComponentSetValue2(self._id, k, ComponentGetValue2(v.id, v.field))
                    return
                end
                ComponentSetValue2(self._id, k, unpack(v))
                return
            end
            ComponentSetValue2(self._id, k, v)
        end
    end,
}
local function EntityGetFirstComponentWithValue(entity_id, table_of_component_values, ...)
    local f = EntityGetFirstComponentIncludingDisabled
    local t = {...}
    local v = select(-1, ...)
    if type(v) == "function" then
        f = v
        t[#t] = nil
    end
    local component = f(entity_id, unpack(t))
    if component ~= nil then return component end
    if entity_id == nil then return nil end
    return EntityAddComponent2(entity_id, ..., table_of_component_values)
end
---@class ComponentField
---@type table|fun(component_type_name: string|table, tag: string|function?, ...): ComponentField
ComponentField = Class(function(...)
    local field = {EntityGetFirstComponentIncludingDisabled, ...}
    local v = select(-1, ...)
    local s = type(v)
    if s == "table" then
        local table_of_component_values
        for key, value in pairs(v) do
            if type(key) == "string" then
                if table_of_component_values == nil then
                    table_of_component_values = {}
                end
                table_of_component_values[key] = value
            end
        end
        field = {EntityGetFirstComponentWithValue, table_of_component_values, unpack(v)}
    elseif s == "function" then
        field[1] = v
        field[#field] = nil
    end
    return field
end)

function ComponentField:get(entity, k)
    local id = self[1](entity.id, unpack(self, 2))
    if id ~= nil then
        local v = setmetatable({_id = id}, component_metatable)
        rawset(entity, k, v)
        return v
    end
end

---@class VariableField
---@type table|fun(tag: string, field: "value_string"|"value_int"|"value_bool"|"value_float", default?: string|integer|boolean|number): VariableField
VariableField = Class(function(tag, field, default)
    return {tag = tag, field = field, default = default}
end)

function VariableField:get(entity, k)
    local variable = EntityGetFirstComponentIncludingDisabled(entity.id, "VariableStorageComponent", self.tag)
    if variable ~= nil then
        return ComponentGetValue2(variable, self.field)
    elseif self.default ~= nil then
        return self.default
    elseif self.field == "value_string" then
        return ""
    elseif self.field == "value_bool" then
        return false
    end
    return 0
end

function VariableField:set(entity, k, v)
    if entity.id ~= nil then
        local variable = EntityGetFirstComponentIncludingDisabled(entity.id, "VariableStorageComponent", self.tag)
        if variable ~= nil then
            ComponentSetValue2(variable, self.field, v)
            return
        end
        EntityAddComponent2(entity.id, "VariableStorageComponent", {_tags = self.tag, [self.field] = v})
    end
end

FileField = Class(function(f, default)
    local filename = ("%s/%s.txt"):format(tactic_filename, get_line(f))
    return {filename, default}
end)

function FileField:get()
    if not ModDoesFileExist(self[1]) then return self[2] end
    return ModTextFileGetContent(self[1])
end

function FileField:set(entity, k, v)
    ModTextFileSetContent(self[1], v)
end

NumericField = Class(function(field)
    return {field}
end)

function NumericField:get(entity, k)
    return tonumber(self[1]:get(entity, k))
end

function NumericField:set(entity, k, v)
    self[1]:set(entity, k, ("%.16a"):format(v))
end

SerializedField = Class(function(field, safe)
    return {field, safe}
end)

function SerializedField:get(entity, k)
    return deserialize(self[1]:get(entity, k))
end

function SerializedField:set(entity, k, v)
    self[1]:set(entity, k, (self[2] and serialize_safe or serialize)(v))
end

local index_table_metatable = {
    __call = function(t, indexes)
        t[1] = indexes
        return t
    end,
    __index = function(t, k)
        local index = t[1][k]
        if index ~= nil then return index(t, k) end
    end,
}
function IndexTable(t)
    return setmetatable(t, index_table_metatable)
end
