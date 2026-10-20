local Style = {}
local function rgb(r, g, b) return { r / 255, g / 255, b / 255 } end
Style.white, Style.muted, Style.yellow = rgb(244, 246, 239), rgb(166, 177, 177), rgb(255, 214, 67)
Style.dark, Style.track, Style.red = rgb(12, 20, 24), rgb(94, 103, 104), rgb(255, 95, 74)
Style.grey, Style.green, Style.violet = rgb(128, 140, 144), rgb(124, 216, 116), rgb(158, 128, 226)
Style.plate, Style.edge, Style.cyan = rgb(39, 48, 46), rgb(164, 175, 160), rgb(90, 215, 255)
Style.dark_alpha, Style.track_alpha, Style.plate_alpha = 174 / 255, 108 / 255, 225 / 255
Style.slot_colour = { Style.white, Style.green, Style.violet }
Style.blue, Style.orange, Style.burgundy = rgb(80, 160, 255), rgb(255, 150, 40), rgb(110, 16, 32)
-- Below this share the health colour pulses between burgundy and red, one full cycle per PULSE_SECONDS.
Style.critical_health, Style.pulse_seconds = 0.15, 0.75
-- Health colour by the share left: the first step the share reaches wins; anything lower is red.
Style.health_steps = { { 0.9, Style.white }, { 0.8, Style.blue }, { 0.7, Style.green },
{ 0.5, Style.yellow }, { 0.25, Style.orange } }
-- The Default size draws Destiny's 1080p layout at 70%, about the game's own HUD size; squad rows follow it.
Style.base_scale = 0.7
-- The Size choice in the menu: Default, 25% Larger, 50% Larger.
Style.sizes = { 1, 1.25, 1.5 }
-- Panel geometry in 1080p units, top-down from the panel's top-left corner (Destiny HUD 1.3.0's layout).
-- The game's UI measures y upward from the bottom; Style.flip converts a top-down box.
Style.size = { 812, 198 }
Style.emblem, Style.hp, Style.stamina = { 20, -10, 80, 80 }, { 126, 24, 676, 12 }, { 100, 42, 702, 4 }
-- The health bar's own backing plate and the medical cross in front of it.
Style.hp_plate, Style.hp_icon = { 100, 20, 706, 20 }, { 105, 22, 16, 16 }
Style.stratagems = { { 100, 50, 82, 82 }, { 188, 50, 82, 82 }, { 276, 50, 82, 82 }, { 364, 50, 82, 82 } }
Style.pack, Style.weapon = { 100, 136, 346, 20 }, { 454, 52, 348, 80 }
-- Backpack row: a glyph for the kind of pack, its bar, and the rounds left in an ammo backpack.
Style.pack_track, Style.pack_count = { 124, 141, 270, 10 }, { 440, 135 }
Style.pack_glyphs = {
pack = { { 106, 141, 12, 12 }, { 109, 139, 6, 2 }, { 108, 145, 8, 1 } },
drone = { { 104, 144, 16, 3 }, { 109, 141, 6, 9 }, { 110, 150, 4, 2 } },
shield = { { 105, 140, 14, 8 }, { 107, 148, 10, 3 }, { 110, 151, 4, 2 } },
}
Style.other = { { 454, 136, 348, 28 }, { 454, 168, 348, 28 } }
Style.consumables = { { 100, 166, 170, 26 }, { 276, 166, 170, 26 } }
-- Without a backpack, stims and grenades take the backpack row too: two full-width rows beside the spare weapons.
Style.consumables_stacked = { { 100, 136, 346, 28 }, { 100, 168, 346, 28 } }
function Style.flip(box)
if box == nil then return nil end
return { box[1], Style.size[2] - box[2] - box[4], box[3], box[4] }
end
function Style.up(y) return Style.size[2] - y end
-- Game colour vectors are read blue first; Gauge:paint takes them that way.
function Style.vector(colour) return { colour[3], colour[2], colour[1] } end
-- now: seconds from any steady clock; it only drives the critical pulse.
function Style.health(share, now)
if type(share) ~= "number" then return Style.white end
for _, step in ipairs(Style.health_steps) do
if share >= step[1] then return step[2] end
end
if share >= Style.critical_health or type(now) ~= "number" then return Style.red end
local mix = (math.sin(now * 2 * math.pi / Style.pulse_seconds) + 1) / 2
local low, high = Style.burgundy, Style.red
return { low[1] + (high[1] - low[1]) * mix, low[2] + (high[2] - low[2]) * mix, low[3] + (high[3] - low[3]) * mix }
end
-- A solid rectangle: an image node drawn with the game's flat fill material, coloured by the widget colour.
function Style.rect(ui, held, name, parent, layer)
local node = ui:image_node(held[name]); held[name] = node
ui:material(node, ui.n.flat_fill_material)
ui:anchor(node, 0, 0); ui:pivot(node, 0, 0)
ui:layer(node, layer)
ui:attach(parent, node)
return node
end
function Style.place(ui, node, box, colour, alpha, width)
if box == nil or (width ~= nil and width <= 0) then ui:show(node, false); return end
ui:position(node, box[1], box[2]); ui:size(node, width or box[3], box[4])
ui:colour(node, colour[1], colour[2], colour[3]); ui:opacity(node, alpha or 1)
ui:show(node, true)
end
return Style
