local Panel = {}
Panel.__index = Panel
function Panel.new(read, n)
return setmetatable({ read = read, n = n, ammunition = {}, body = {}, sample = {} }, Panel)
end
function Panel:observe()
local read, n = self.read, self.n
self.base, self.mission, self.ready, self.editable, self.opacity, self.dt = nil, nil, false, false, nil, nil
self.in_mission = nil
local game = read:module("game")
if game == nil then return false end
local manager = read:ptr(game + n.roots_hud_manager_rva)
if manager == nil then return false end
local mission = manager + n.hud_widgets_mission_hud
self.mission, self.base = mission, mission + n.hud_widgets_panels_self_panel_at
local scene = read:ptr(game + n.hud_scene_manager)
if scene == nil then return false end
local kind = read:value(scene + n.hud_scene, "u32")
if kind ~= nil then self.in_mission = kind == n.hud_scene_mission end
if not self.in_mission then return false end
local language = read:ptr(game + n.ui_language_manager)
if language == nil or read:value(language + n.ui_language_switch, "bool") ~= false then return false end
local first = read:value(self.base, "u32")
self.editable = read:value(manager + n.hud_built, "bool") == true and first ~= nil and first ~= 0
if not self.editable then return false end
self.ready = read:value(mission + n.hud_gate_ready, "bool") == true
self.opacity = read:value(self.base + n.widget_inherited_opacity, "f32")
if self.vanilla_hidden then
local parent = read:ptr(self.base + n.widget_parent)
if parent ~= nil then self.opacity = read:value(parent + n.widget_inherited_opacity, "f32") end
end
local clock = read:ptr(game + n.stratagem_slots_clock_global)
if clock ~= nil then self.dt = read:value(clock + n.hud_dt_at, "f32") end
return true
end
function Panel:ammo(heat_index)
if not self.ready then return nil end
local read, n, base, value = self.read, self.n, self.base, self.ammunition
local slot = read:value(base + n.hud_self_last_slot, "u32")
local state = read:value(base + n.hud_weapon_ammo_state, "i32")
local shown = state ~= nil and state ~= n.hud_ammo_none_state
value.slot, value.throwing, value.hidden = slot, slot == n.throwable_slot, state ~= nil and not shown
value.drawn = read:value(base + n.hud_weapon_count_shown, "i32")
value.reserve_drawn = read:value(base + n.hud_weapon_reserve_shown, "u32")
value.throwables_drawn = read:value(base + n.hud_self_throwables, "i32")
value.stims = read:value(base + n.self_panel_stims, "i32")
value.count, value.empty, value.reserve, value.throwables, value.throwables_unheld = nil, nil, nil, nil, nil
if shown then
value.empty = read:value(base + n.ammo_gauge, "f32")
if heat_index == nil then value.count = value.drawn end
end
local spare_on = read:value(base + n.spare_widget, "bit", n.widget_shown_bit)
value.spare_on = spare_on ~= nil and spare_on ~= 0
if spare_on ~= nil and spare_on ~= 0 then value.reserve = value.reserve_drawn end
if value.throwing then value.throwables = value.throwables_drawn
else value.throwables_unheld = value.throwables_drawn end
value.text = value.throwables
if value.text == nil then value.text = value.count end
return value
end
function Panel:health()
if not self.ready then return nil end
local read, n, body = self.read, self.n, self.body
local bar = self.base + n.self_panel_health_bar
body.health = read:value(bar + n.health_bar_drawn, "f32")
body.colour = read:vector(bar + n.health_bar_fill + n.widget_local_colour, 3)
return body
end
function Panel:ammo_style(throwing)
if not self.ready then return nil end
local read, n, base = self.read, self.n, self.base
local colour = read:vector(base + n.self_magazine_fill + n.widget_local_colour, 3)
local text_colour, opacity
if throwing then
text_colour = read:vector(base + n.self_throwable_text + n.widget_local_colour, 3)
opacity = read:value(base + n.self_throwable_text + n.widget_local_opacity, "f32")
end
if text_colour == nil then text_colour = colour end
if opacity == nil then opacity = read:value(base + n.self_weapon_block + n.widget_local_opacity, "f32") end
return text_colour, opacity, colour
end
function Panel:magazine_size()
if self.ready then return self.read:vector(self.base + self.n.panel_magazine_outline + self.n.hud_widgets_size_x, 2) end
end
function Panel:throwable_icon()
if not self.ready then return nil end
local read, n, base = self.read, self.n, self.base
return read:value(base + n.self_panel_throwable_picture, "hex64"),
read:vector(base + n.self_panel_throwable_icon + n.hud_widgets_size_x, 2)
end
function Panel:stamina()
if not self.ready then return nil end
return self.read:value(self.mission + self.n.hud_widgets_stamina_panel_at + self.n.stamina_panel_share, "f32")
end
function Panel:events(health, stamina, weapon, pack)
if not self.ready then return nil end
local read, n, base, sample = self.read, self.n, self.base, self.sample
sample.health, sample.stims, sample.stamina, sample.ammo, sample.worn, sample.gauge, sample.spare = nil, nil, nil, nil, nil, nil, nil
if weapon then sample.ammo = self:ammo(nil); sample.stims, sample.spare = sample.ammo.stims, sample.ammo.spare_on end
if health then
sample.health = read:value(base + n.self_panel_health_share, "f32")
if not weapon then sample.stims = read:value(base + n.self_panel_stims, "i32") end
end
if stamina then sample.stamina = self:stamina() end
if weapon or pack then sample.gauge = read:value(base + n.self_panel_gauge_shown, "f32") end
if pack then
local worn = read:value(base + n.self_panel_pack_cell, "bit", n.widget_shown_bit)
sample.worn = worn ~= nil and worn ~= 0
if not weapon then
local spare = read:value(base + n.spare_widget, "bit", n.widget_shown_bit)
sample.spare = spare ~= nil and spare ~= 0
end
end
return sample
end
function Panel:clock()
if self.ready then return self.read:value(self.mission + self.n.hud_clock, "f32") end
end
function Panel:ammo_count(heat_index)
if not self.ready or heat_index ~= nil then return nil end
local state = self.read:value(self.base + self.n.hud_weapon_ammo_state, "i32")
if state == nil or state == self.n.hud_ammo_none_state then return nil end
return self.read:value(self.base + self.n.hud_weapon_count_shown, "i32")
end
function Panel:weapon_mount()
if not self.editable then return nil end
local row = self.base + self.n.self_weapon_widget
local opacity = self.read:value(row + self.n.hud_widgets_shown, "f32")
return self.base + self.n.self_weapon_block, row, opacity ~= nil and opacity > 0
end
return Panel
