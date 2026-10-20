local Style = require("game.destiny_style")
local Card = require("game.stratagem_card")
local OptionCell = require("game.option_cell")
local Stratagems = require("game.stratagem_inputs")
local Pack = require("game.pack")
local Native = require("native.channel")
local BOOSTERS = require("game.resources").boosters
local Feature = {}
Feature.__index = Feature
local TILES, SEGMENTS = 4, 16
local TEXT_COUNT, TEXT_SPARE, TEXT_SMALL = 42, 22, 18
-- Carried weapons are looked up this often; a weapon's HUD picture is searched for in its data this far.
local CARRIED_SECONDS, PICTURE_SEARCH = 0.5, 0x300
-- The game's standard stim maximum; the stim cells show at least this many until the game's own maximum is known.
local STIMS_STANDARD = 4
-- One-off: the counters around the game's stim count, written once per game session a few seconds into a mission,
-- so the stim and throwable maximums the game's panel shows (x2/4) can be located. Reads only.
local DUMP_AFTER, DUMP_FROM, DUMP_TO = 5, -96, 64
local NONE = "0000000000000000"
-- The player's stratagem record holds 48-byte entries from stratagem_row_record, with the entry count at
-- ENTRY_COUNT. An entry's granted byte is set for the mission's own stratagems (Reinforce, SOS, Resupply).
local ENTRY_COUNT, ENTRY_GRANTED = 1928, 9
local flip, up = Style.flip, Style.up
local MATE_ALPHA = 0.45
function Feature.new(ui, panel, weapon)
local self = setmetatable({ ui = ui, panel = panel, weapon = weapon, read = weapon.read, n = ui.n,
nodes = {}, cards = {}, fire_cell = OptionCell.new(ui), stratagems = Stratagems.new(weapon), frame = 0,
seen = {}, most = {}, loadout = {}, mates = {} }, Feature)
for index = 1, TILES do self.cards[index] = Card.new(ui) end
local made, pack = pcall(Pack.new, weapon)
if made then self.pack = pack end
local found, capacity = pcall(weapon.judge.routine, weapon.judge, "throwable_capacity")
if found then self.throwable_capacity = capacity end
return self
end
-- Hides the game's own self panel while keeping it alive: its widgets keep the values this panel reads.
function Feature:vanilla(hidden)
local panel, ui, n = self.panel, self.ui, self.n
if not panel.editable then self.hidden_at, panel.vanilla_hidden = nil, nil; return end
local base = panel.base
if self.hidden_at ~= nil and (self.hidden_at ~= base or not hidden) then
if self.hidden_at == base then ui:call("widget_opacity_set", base, n.widget_opacity_default[1]) end
self.hidden_at = nil
end
if hidden then
if self.read:value(base + n.widget_local_opacity, "f32") ~= 0 then ui:call("widget_opacity_set", base, 0) end
self.hidden_at = base
end
panel.vanilla_hidden = self.hidden_at ~= nil
end
function Feature:text(name, parent, height, layer, right)
local ui, n, held = self.ui, self.n, self.nodes
local node = ui:text_node(n.hud_text_font, n.hud_text_variant, n.hud_text_variant, height, held[name]); held[name] = node
ui:layer(node, layer); ui:anchor(node, 0, 0); ui:pivot(node, right and 1 or 0, 1)
ui:attach(parent, node)
return node
end
function Feature:image(name, parent, layer)
local ui, held = self.ui, self.nodes
local node = ui:image_node(held[name]); held[name] = node
ui:layer(node, layer); ui:anchor(node, 0, 0); ui:pivot(node, 0.5, 0.5)
ui:attach(parent, node)
return node
end
function Feature:weapon_row(key, parent, box, plate, fill, top, large)
local rect, held = Style.rect, self.nodes
rect(self.ui, held, key .. "_plate", parent, plate)
rect(self.ui, held, key .. "_shade", parent, fill)
rect(self.ui, held, key .. "_strip", parent, fill)
if large then
rect(self.ui, held, key .. "_line", parent, fill); rect(self.ui, held, key .. "_rail", parent, fill)
rect(self.ui, held, key .. "_rule", parent, fill)
end
self:image(key .. "_picture", parent, top)
self:image(key .. "_outline", parent, top); self:image(key .. "_fill", parent, top)
self:text(key .. "_count", parent, large and TEXT_COUNT or TEXT_SPARE, top, true)
self:text(key .. "_reserve", parent, TEXT_SPARE, top, false)
end
function Feature:create(parent)
local ui, n, held, rect = self.ui, self.n, self.nodes, Style.rect
local plate, fill, top = n.crosshair_track_layer, n.crosshair_fill_layer, n.hud_text_layer
ui:context(parent, function()
local root = ui:frame(held.root); held.root = root
ui:size(root, Style.size[1], Style.size[2]); ui:anchor(root, 0, 0); ui:pivot(root, 0, 0)
ui:attach(parent, root)
local at = root.at
self:image("booster", at, top)
for _, name in ipairs({ "hp_plate", "hp_track", "hp_fill", "hp_tick1", "hp_tick2", "hp_tick3", "hp_cross_v", "hp_cross_h",
"stamina_track", "stamina_fill" }) do
rect(ui, held, name, at, (name:find("track", 1, true) or name == "hp_plate") and plate or fill)
end
for index = 1, TILES do
local key = "tile" .. index
rect(ui, held, key .. "_plate", at, plate); rect(ui, held, key .. "_rail", at, fill)
rect(ui, held, key .. "_wire_top", at, fill); rect(ui, held, key .. "_wire_left", at, fill); rect(ui, held, key .. "_wire_right", at, fill)
local box = Style.stratagems[index]
local slot = ui:frame(held[key]); held[key] = slot
ui:size(slot, box[3], box[4]); ui:anchor(slot, 0, 0); ui:pivot(slot, 0, 0); ui:position(slot, box[1], up(box[2] + box[4]))
ui:attach(at, slot)
local card = self.cards[index]:create(slot.at, self.frame, n.stratagem_row_card_layer, false)
ui:anchor(card, 0.5, 0.5); ui:pivot(card, 0.5, 0.5); ui:scale(card, 1.1, 1.1)
end
for _, name in ipairs({ "pack_plate", "pack_accent", "pack_base", "pack_track", "pack_fill", "pack_glyph1", "pack_glyph2", "pack_glyph3" }) do
rect(ui, held, name, at, name == "pack_plate" and plate or fill)
end
self:text("pack_count", at, 16, top, true)
self:weapon_row("current", at, Style.weapon, plate, fill, top, true)
for index = 1, 2 do self:weapon_row("other" .. index, at, Style.other[index], plate, fill, top, false) end
local cell = self.fire_cell:create(at, self.frame, n.option_cell_picture_curved)
ui:anchor(cell, 0, 0); ui:pivot(cell, 0.5, 0.5); ui:scale(cell, 1.5, 1.5)
for index = 1, 2 do
local key = "item" .. index
rect(ui, held, key .. "_plate", at, plate); rect(ui, held, key .. "_rule", at, fill)
self:image(key .. "_icon", at, top)
self:text(key .. "_count", at, TEXT_SMALL, top, false)
for cell_index = 1, SEGMENTS do rect(ui, held, key .. "_cell" .. cell_index, at, fill) end
end
end)
self.parent = parent
end
function Feature:alive(parent)
local alive = self.ui:alive(self.nodes.root)
if alive == nil then return nil end
if self.parent ~= parent or not alive then
self:drop(); self:create(parent)
end
return true
end
local function same_avatar(self, avatar)
if self.avatar ~= avatar then self.avatar, self.seen, self.most, self.booster = avatar, {}, {}, nil end
end
-- The weapon's data entry: the book the game reads its magazine icons and HUD picture from.
function Feature:book(record)
local weapon = self.weapon
local key = weapon:key(record)
if key == nil then return nil end
if key == false then key = NONE end
local book = weapon.judge:call(weapon.weapon_data_find, weapon.judge:uint64_of(key))
if book ~= nil and book ~= 0 then return book end
end
-- Learns where a weapon's HUD picture sits in its data entry from the weapon in hand, once.
function Feature:learn_picture(book, picture)
if self.picture_at ~= nil or book == nil or picture == nil then return end
for offset = 0, PICTURE_SEARCH - 8, 8 do
if self.read:value(book + offset, "hex64") == picture then self.picture_at = offset; return end
end
end
function Feature:picture_of(book)
if self.picture_at == nil or book == nil then return nil end
local picture = self.read:value(book + self.picture_at, "hex64")
if picture ~= NONE then return picture end
end
-- Every weapon the player carries, so the spare rows show their pictures and magazine icons before they are held.
function Feature:carried(avatar)
local now = os.clock()
if self.carried_at ~= nil and now >= self.carried_at and now - self.carried_at < CARRIED_SECONDS then return end
self.carried_at = now
local weapon, n = self.weapon, self.n
local inventory = weapon:manager(n.inventory_manager)
if inventory == nil then return end
for slot = 1, 3 do
local entity = weapon:item(inventory, avatar, slot)
if entity ~= nil and entity ~= weapon.invalid_entity then
local row = self.seen[slot]
if row == nil or row.wield ~= entity or (row.picture == nil and self.picture_at ~= nil) then
local record = weapon:record(entity)
local book = self:book(record)
local fresh = { wield = entity, picture = self:picture_of(book) }
fresh.outline, fresh.fill = weapon:ammo_icons(record)
if row ~= nil and row.wield == entity then fresh.count, fresh.reserve, fresh.share, fresh.size = row.count, row.reserve, row.share, row.size end
if fresh.picture == nil and row ~= nil and row.wield == entity then fresh.picture = row.picture end
self.seen[slot] = fresh
end
end
end
end
-- The weapon in hand: its live HUD picture, the drawn round count, spare magazines and their icons.
function Feature:current(ammo, avatar, wield, heat)
local read, n, weapon = self.read, self.n, self.weapon
local slot = ammo.slot
if slot == nil or ammo.throwing or slot < 1 or slot > 3 then return nil end
local picture = read:value(self.panel.base + n.self_panel_weapon_picture, "hex64")
if picture == NONE then picture = nil end
if wield == nil then wield = weapon:wield(avatar) end
local row = self.seen[slot]
if row == nil or row.picture ~= picture or row.wield ~= wield then
local record = weapon:record(wield)
row = { picture = picture, wield = wield }
row.outline, row.fill = weapon:ammo_icons(record)
self.seen[slot] = row
if self.picture_at == nil then self:learn_picture(self:book(record), picture) end
end
row.count, row.reserve = nil, nil
if not ammo.hidden and heat == nil then row.count = ammo.drawn end
if ammo.spare_on then row.reserve = ammo.reserve end
row.share = nil
if type(ammo.empty) == "number" and not ammo.hidden then row.share = math.max(0, math.min(1, 1 - ammo.empty)) end
row.size = self.panel:magazine_size()
return slot, row
end
function Feature:picture(name, texture, size, box, colour, material)
local ui, node = self.ui, self.nodes[name]
if texture == NONE then texture = nil end
ui:image(node, texture, material or self.n.flat_ammo_icon_material)
if texture == nil then return end
local w, h = box[3], box[4]
if size ~= nil and size[1] > 0 and size[2] > 0 then
local k = math.min(w / size[1], h / size[2]); w, h = size[1] * k, size[2] * k
end
ui:size(node, w, h); ui:position(node, box[1] + box[3] / 2, up(box[2] + box[4] / 2))
ui:colour(node, colour[1], colour[2], colour[3])
end
function Feature:words(name, value, x, y, colour)
local ui, node = self.ui, self.nodes[name]
if value == nil then ui:text(node, nil); return end
ui:text(node, value); ui:position(node, x, up(y))
ui:colour(node, colour[1], colour[2], colour[3])
end
function Feature:put_weapon(key, box, row, slot, large)
local ui, held, place = self.ui, self.nodes, Style.place
local x, y, w, h = box[1], box[2], box[3], box[4]
place(ui, held[key .. "_plate"], flip(box), Style.dark, Style.dark_alpha)
local share = row and row.share
local k = share ~= nil and 1 - share or 0
local shade = share ~= nil and { (176 * share + 255 * k) / 255, (190 * share + 72 * k) / 255, (193 * share + 62 * k) / 255 } or Style.white
place(ui, held[key .. "_shade"], flip({ x + 3, y + 1, w, h - 3 }), shade, (large and 36 or 26) / 255, share ~= nil and (w - 6) * share or 0)
place(ui, held[key .. "_strip"], row and flip({ x + w, y, 5, h }) or nil, Style.slot_colour[slot] or Style.white, 1)
if large then
place(ui, held[key .. "_line"], flip({ x, y + h - 2, w, 2 }), Style.white, 1)
place(ui, held[key .. "_rail"], flip({ x, y, 3, h }), Style.yellow, 1)
place(ui, held[key .. "_rule"], flip({ x + 159, y + 14, 1, 52 }), Style.muted, 52 / 255)
end
local picture_box = large and { x + 8, y + 12, 146, 56 } or { x + 10, y + 3, 64, 22 }
self:picture(key .. "_picture", row and row.picture, nil, picture_box, Style.white)
local count, reserve = row and row.count, row and row.reserve
self:words(key .. "_count", count, x + w - 12, y + (large and 18 or 3), count == 0 and Style.red or Style.white)
local icon_box = large and { x + 168, y + 22, 18, 22 } or { x + 82, y + 5, 14, 18 }
local outline, fill
if reserve ~= nil then outline = row.outline; if reserve > 0 then fill = row.fill end end
self:picture(key .. "_outline", outline, row and row.size, icon_box, large and Style.white or Style.muted)
self:picture(key .. "_fill", fill, row and row.size, icon_box, large and Style.white or Style.muted)
self:words(key .. "_reserve", reserve, x + (large and 191 or 104), y + (large and 17 or 3), reserve == 0 and Style.red or Style.white)
end
function Feature:put_item(index, count, texture, size, material, colour, box, floor)
local ui, held, place = self.ui, self.nodes, Style.place
local key = "item" .. index
local x, y, w, h = box[1], box[2], box[3], box[4]
local most = self.most[index]
if type(count) == "number" and (most == nil or count > most) then most = count; self.most[index] = most end
if type(floor) == "number" and floor >= 1 and (most == nil or floor > most) then most = floor end
local ink = count == 0 and Style.red or colour
place(ui, held[key .. "_plate"], flip(box), Style.dark, Style.dark_alpha)
place(ui, held[key .. "_rule"], flip({ x + 61, y + 19, w - 66, 1 }), Style.track, Style.track_alpha)
self:picture(key .. "_icon", texture, size, { x + 2, y + 2, 30, h - 4 }, ink, material)
self:words(key .. "_count", count, x + 38, y + 4, Style.white)
local cells = most ~= nil and math.min(SEGMENTS, most) or 0
local gap = 3
local cell_y = y + math.floor((h - 8) / 2)
local width = cells > 0 and (w - 68 - (cells - 1) * gap) / cells or 0
for cell = 1, SEGMENTS do
local node = held[key .. "_cell" .. cell]
if cell <= cells then
local filled = type(count) == "number" and cell <= count
place(ui, node, flip({ x + 63 + (cell - 1) * (width + gap), cell_y, width, 8 }), filled and ink or Style.track, filled and 1 or Style.track_alpha)
else ui:show(node, false) end
end
end
-- The entries the player chose, in loadout order; mission stratagems are skipped.
function Feature:choices(record)
local read, n, rows = self.read, self.n, self.loadout
for index = 1, TILES do rows[index] = nil end
if record == nil then return rows end
local count = read:value(record + ENTRY_COUNT, "u32")
if count == nil or count > n.stratagem_row_cap then count = n.stratagem_row_cap end
local found = 0
for entry = 0, count - 1 do
local at = record + n.stratagem_row_record + entry * n.stratagem_row_stride
local kind, granted = read:value(at, "u32"), read:value(at + ENTRY_GRANTED, "u8")
if kind ~= nil and kind ~= 0 and granted == 0 then
found = found + 1; rows[found] = entry
if found == TILES then break end
end
end
return rows
end
function Feature:put_tile(index, dt, record, row)
local ui, n, read, held, place = self.ui, self.n, self.read, self.nodes, Style.place
local box, key = Style.stratagems[index], "tile" .. index
local x, y, w, h = box[1], box[2], box[3], box[4]
if row == nil then record = nil; row = index - 1 end
local original = self.panel.mission + n.hud_widgets_panels_stratagem_hud_at + n.stratagem_list
local offset = n.stratagem_list_first_row + n.stratagem_row_card + row * n.stratagem_list_row_size
local state = read:value(original + offset + n.component_card_state, "u32")
if state ~= n.component_card_calling and state ~= n.component_card_cooling then state = n.component_card_ready end
local card = self.cards[index]
if record ~= nil and (state == n.component_card_calling or state == n.component_card_cooling) and card.node ~= nil and card.node.live then
local denominator = read:value(original + offset + n.component_card_denominator, "u32")
if denominator ~= nil then ui:put(card.node.at + n.component_card_denominator, denominator) end
end
local ready = record ~= nil and state == n.component_card_ready
place(ui, held[key .. "_plate"], flip(box), Style.plate, record ~= nil and Style.plate_alpha or Style.dark_alpha)
place(ui, held[key .. "_rail"], flip({ x, y + h - 5, w, 5 }), ready and Style.yellow or Style.grey, 1)
local wire = record ~= nil and (ready and 0.8 or 0.44) or 0.28
place(ui, held[key .. "_wire_top"], flip({ x, y, w, 1 }), Style.white, wire)
place(ui, held[key .. "_wire_left"], flip({ x, y, 1, h }), Style.white, wire)
place(ui, held[key .. "_wire_right"], flip({ x + w - 1, y, 1, h }), Style.white, wire)
if record == nil then card:update(self.frame, nil); return end
card:update(self.frame, dt, row, record, state)
end
function Feature:step(values, avatar, players, wield, slots, booster, heat, mates)
self.frame = self.frame + 1
local panel, ui, n, held, place = self.panel, self.ui, self.n, self.nodes, Style.place
self:vanilla(values["hud.destiny.hide"] == 1)
if not panel.editable then self:drop(); return end
local parent = self.read:ptr(panel.base + n.widget_parent)
if parent == nil then return end
if self:alive(parent) == nil then return end
local root = held.root
if not panel.ready or avatar == nil then ui:show(root, false); return end
same_avatar(self, avatar)
local size = self.read:vector(parent + n.widget_local_size, 2)
local width, height = 1920, 1080
if size ~= nil and size[1] > 0 and size[2] > 0 then width, height = size[1], size[2] end
local scale = (Style.sizes[values["hud.destiny.size"] + 1] or 1) * Style.base_scale
ui:scale(root, scale, scale)
ui:position(root, width * values["hud.destiny.x"] / 100, height * values["hud.destiny.y"] / 100)
ui:opacity(root, values["hud.destiny.opacity"])
ui:show(root, true)
local emblem = Style.emblem
local cx, cy = emblem[1] + emblem[3] / 2, emblem[2] + emblem[4] / 2
if booster ~= nil and BOOSTERS[booster] ~= nil then self.booster = booster end
self:picture("booster", self.booster and BOOSTERS[self.booster], nil, { cx - 26, cy - 24, 52, 48 }, Style.white, n.picture_material)
local body = panel:health()
local share = body and body.health
if type(share) == "number" then share = math.max(0, math.min(1, share)) else share = nil end
local hp, ink, icon = Style.hp, Style.health(share, os.clock()), Style.hp_icon
place(ui, held.hp_plate, flip(Style.hp_plate), Style.dark, Style.dark_alpha)
place(ui, held.hp_cross_v, flip({ icon[1] + 5, icon[2], 6, icon[4] }), ink, 1)
place(ui, held.hp_cross_h, flip({ icon[1], icon[2] + 5, icon[3], 6 }), ink, 1)
place(ui, held.hp_track, flip(hp), Style.track, Style.track_alpha)
place(ui, held.hp_fill, flip(hp), ink, 1, share ~= nil and hp[3] * share or 0)
for tick = 1, 3 do place(ui, held["hp_tick" .. tick], flip({ hp[1] + hp[3] * tick / 4, hp[2], 1, hp[4] }), Style.dark, Style.dark_alpha) end
local stamina, bar = panel:stamina(), Style.stamina
if type(stamina) == "number" then stamina = math.max(0, math.min(1, stamina)) else stamina = nil end
place(ui, held.stamina_track, flip(bar), Style.track, Style.track_alpha)
place(ui, held.stamina_fill, flip(bar), Style.yellow, 1, stamina ~= nil and bar[3] * stamina or 0)
local record = self.stratagems:record(avatar, players, 0)
local chosen = self:choices(record)
for index = 1, TILES do self:put_tile(index, panel.dt, record, chosen[index]) end
local sample = panel:events(false, false, true, true)
local ammo = sample and sample.ammo
local packed = self:put_pack(sample, avatar, wield)
local items = packed and Style.consumables or Style.consumables_stacked
self:carried(avatar)
local slot, row
if ammo ~= nil then slot, row = self:current(ammo, avatar, wield, heat) end
self:put_weapon("current", Style.weapon, row, slot, true)
local others = {}
for other = 1, 3 do if other ~= slot then others[#others + 1] = other end end
for index = 1, 2 do
local other = others[index]
self:put_weapon("other" .. index, Style.other[index], other and self.seen[other], other, false)
end
local box = Style.weapon
local cell = self.fire_cell.node
if cell ~= nil and cell.live then ui:position(cell, box[1] + 254, up(box[2] + 40)) end
if slots ~= nil and row ~= nil then self.fire_cell:update(self.frame, unpack(slots[2], 1, 3)) else self.fire_cell:update(0) end
local icon, icon_size = panel:throwable_icon()
self:put_item(1, ammo and ammo.stims, n.stim_icon_material, { n.self_stim_icon_width, n.self_stim_icon_height }, nil, Style.cyan, items[1], STIMS_STANDARD)
self:put_item(2, ammo and ammo.throwables_drawn, icon, icon_size, nil, Style.yellow, items[2], self:throwables_max(avatar))
self:dump_counters(ammo)
self:squad(mates, scale)
self:lift_squad(height * values["hud.destiny.y"] / 100 + Style.size[2] * scale)
end
-- The game's own throwable maximum for this avatar (what its panel shows after the slash).
function Feature:throwables_max(avatar)
local weapon = self.weapon
if self.throwable_capacity == nil or avatar == nil then return nil end
local inventory = weapon:manager(self.n.inventory_manager)
if inventory == nil then return nil end
local value = weapon.judge:call(self.throwable_capacity, inventory, avatar)
if type(value) == "number" and value >= 1 and value <= 64 then return value end
end
function Feature:dump_counters(ammo)
if self.dumped or ammo == nil then return end
local now = os.clock()
self.dump_from = self.dump_from or now
if now - self.dump_from < DUMP_AFTER then return end
self.dumped = true
local read, n, base = self.read, self.n, self.panel.base
local lines = { string.format("Destiny HUD panel counters: stims %s, throwables %s, spare magazines %s (offsets from the stim count)",
tostring(ammo.stims), tostring(ammo.throwables_drawn), tostring(ammo.reserve_drawn)) }
for offset = DUMP_FROM, DUMP_TO, 4 do
local at = base + n.self_panel_stims + offset
lines[#lines + 1] = string.format("%+d i32=%s u32=%s f32=%s", offset, tostring(read:value(at, "i32")), tostring(read:value(at, "u32")), tostring(read:value(at, "f32")))
end
local directory, save = os.getenv("APPDATA"), Native.save()
if directory ~= nil and save ~= nil then save(directory .. "/destiny_hud_panel_dump.txt", table.concat(lines, "\n") .. "\n") end
end
-- The worn backpack: a Guard Dog drone shows its gun's recharge, a shield pack its charge or, once broken, its
-- recharge in red, a pack with its own countdown that countdown, and any other pack the game's own gauge.
-- An ammo backpack also shows the rounds left for the weapon it feeds.
function Feature:put_pack(sample, avatar, wield)
local ui, held, place, values = self.ui, self.nodes, Style.place, self.pack
local worn = sample ~= nil and sample.worn == true
local gauge = sample ~= nil and sample.gauge or nil
local kind, share, colour, remaining = "gauge", gauge, Style.white, nil
if values ~= nil and sample ~= nil and (worn or sample.ammo ~= nil) then
local key = wield ~= nil and self.weapon:key(self.weapon:record(wield)) or nil
values:observe(avatar, key, sample.spare, worn, gauge)
kind, remaining = values.kind or "gauge", values.remaining
if kind == "drone" then
share = values.left ~= nil and 1 - values.left or 1
if values.busy then colour = Style.yellow end
elseif kind == "shield" then
share = values.left ~= nil and 1 - values.left or 0
colour = Style.red
elseif kind == "countdown" then
share = values.share
if values.busy then colour = Style.yellow end
else share = values.share end
end
local shown = worn or remaining ~= nil
local pack = Style.pack
place(ui, held.pack_plate, shown and flip(pack) or nil, Style.dark, Style.dark_alpha)
place(ui, held.pack_accent, shown and flip({ pack[1], pack[2], 2, pack[4] }) or nil, Style.yellow, 1)
place(ui, held.pack_base, shown and flip({ pack[1] + 5, pack[2] + pack[4] - 2, pack[3] - 10, 1 }) or nil, Style.track, Style.track_alpha)
local glyph = Style.pack_glyphs[kind] or Style.pack_glyphs.pack
for index = 1, 3 do place(ui, held["pack_glyph" .. index], shown and flip(glyph[index]) or nil, colour, 1) end
local track = flip(Style.pack_track)
local bar = worn and type(share) == "number"
place(ui, held.pack_track, bar and track or nil, Style.track, Style.track_alpha)
place(ui, held.pack_fill, bar and track or nil, colour, 1, bar and track[3] * math.max(0, math.min(1, share)) or 0)
local at = Style.pack_count
self:words("pack_count", shown and remaining or nil, at[1], at[2], remaining == 0 and Style.red or Style.white)
return shown
end
-- Teammates keep the game's own compact squad rows (name, health, gear) in a smaller Destiny frame. Each row
-- shrinks with the panel around its own pivot, so the list keeps its place above the panel.
function Feature:unscale(seat)
if seat.scaled ~= nil and seat.parent ~= nil and self.read:value(seat.parent, "u32") ~= 0 then
self.ui:call("widget_scale_set", seat.parent, self.ui:pair(1, 1))
end
seat.scaled = nil
end
function Feature:squad(rows, scale)
local ui, n, read, place = self.ui, self.n, self.read, Style.place
for index = 1, n.hud_squad_count do
local seat = self.mates[index]
if seat == nil then seat = { held = {} }; self.mates[index] = seat end
local row = rows and rows[index]
local parent = row and row.parent
if parent ~= seat.parent or (seat.held.plate ~= nil and ui:alive(seat.held.plate) == false) then
for _, node in pairs(seat.held) do ui:destroy(node) end
self:unscale(seat)
seat.parent = nil
if parent ~= nil then
ui:context(parent, function()
Style.rect(ui, seat.held, "plate", parent, n.crosshair_track_layer)
Style.rect(ui, seat.held, "rail", parent, n.crosshair_fill_layer)
Style.rect(ui, seat.held, "line", parent, n.crosshair_fill_layer)
end)
seat.parent = parent
end
end
if parent ~= nil and scale ~= nil and seat.scaled ~= scale then
ui:call("widget_scale_set", parent, ui:pair(scale, scale))
seat.scaled = scale
end
if parent ~= nil then
local size = read:vector(parent + n.widget_local_size, 2)
if size ~= nil and size[1] > 0 and size[2] > 0 then
local w, h = size[1], size[2]
place(ui, seat.held.plate, { -6, -3, w + 12, h + 6 }, Style.dark, MATE_ALPHA)
place(ui, seat.held.rail, { -6, -3, 2, h + 6 }, row.dead == true and Style.red or Style.yellow, 1)
place(ui, seat.held.line, { -6, -3, w + 12, 1 }, Style.white, 0.5)
end
end
end
end
-- The game's squad list sits just above its own self panel, which is shorter than the Destiny panel. While the
-- Destiny panel shows, the list moves up by the difference so it stays clear of the panel; its own position comes
-- back when the panel closes. top: the Destiny panel's top edge, in the parent's units.
local SQUAD_GAP = 8
function Feature:lift_squad(top)
local panel, n, read = self.panel, self.n, self.read
local at = panel.mission + n.hud_widgets_panels_squad_panel_at
if self.lift_at ~= nil and self.lift_at ~= at then self:drop_lift() end
local now = read:vector(at + n.widget_local_position, 2)
local own = read:vector(panel.base + n.widget_local_size, 2)
if now == nil or own == nil then return end
if self.lift_at == nil then self.lift_at, self.lift_home = at, { now[1], now[2] } end
local home = self.lift_home
local wanted = home[2] + math.max(0, top + SQUAD_GAP - own[2])
local function near(a, b) return b ~= nil and math.abs(a - b) < 0.5 end
if not near(now[1], home[1]) or not near(now[2], wanted) then
if not near(now[2], self.lift_y) and not near(now[2], home[2]) then home[1], home[2] = now[1], now[2]; wanted = home[2] + math.max(0, top + SQUAD_GAP - own[2]) end
self.ui:call("widget_position_set", at, self.ui:pair(home[1], wanted))
self.lift_y = wanted
end
end
function Feature:drop_lift()
if self.lift_at ~= nil and self.panel.editable and self.lift_at == self.panel.mission + self.n.hud_widgets_panels_squad_panel_at then
self.ui:call("widget_position_set", self.lift_at, self.ui:pair(self.lift_home[1], self.lift_home[2]))
end
self.lift_at, self.lift_home, self.lift_y = nil, nil, nil
end
function Feature:drop_squad()
for _, seat in pairs(self.mates) do
for _, node in pairs(seat.held) do self.ui:destroy(node) end
self:unscale(seat)
seat.parent = nil
end
end
function Feature:drop()
for _, card in ipairs(self.cards) do card:close() end
self.fire_cell:close()
for _, node in pairs(self.nodes) do self.ui:destroy(node) end
self.parent = nil
end
function Feature:close()
self:vanilla(false)
self:drop_lift()
self:drop()
self:drop_squad()
end
return Feature
