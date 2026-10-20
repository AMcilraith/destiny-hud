local Settings = require("core.settings")
local Squad = require("game.squad_inputs")
local Product = {}
Product.__index = Product
function Product.new(access, n, settings, report)
local okay, why = access.read:status()
assert(okay, why)
report = report or function() end
settings = settings or Settings.new(require("options"))
local panel = require("game.panel").new(access.read, n)
local ui = require("game.ui").new(access, n)
local weapon = require("game.weapon").new(access.read, access.call.judge, n)
return setmetatable({ panel = panel, weapon = weapon, settings = settings, report = report,
options = require("game.weapon_options").new(weapon),
menu = require("features.menu").new(ui, settings, report),
destiny = require("features.destiny_panel").new(ui, panel, weapon),
squad = Squad.new(weapon), slots = { {}, {}, {} } }, Product)
end
function Product:step(dt)
self.dt = dt
self.weapon:frame()
self.settings:poll()
local menu = self.menu
if menu ~= nil then menu:before(); self.menu_outermost = menu.outermost end
local destiny = self.destiny
if destiny == nil then return end
self.panel:observe()
local avatar, player, players, seated, wield, heat, booster, mates
if self.panel.ready then
avatar, player, players = self.weapon:avatar(self.panel)
if avatar ~= nil then seated = self.weapon:seated(avatar); wield = self.weapon:wield(avatar) end
self.options:observe(wield)
self.slots[2][1], self.slots[2][2], self.slots[2][3] = self.options:sample(2)
heat = self.weapon:heat_index(self.panel, avatar, seated, wield, self.options, nil)
self.squad:observe(self.panel, true, avatar, player, players, nil)
mates = self.squad.rows
if self.squad.view ~= nil then booster = self.squad.view.passive_booster end
end
local okay, why = pcall(destiny.step, destiny, self.settings.values, avatar, players, wield, self.slots, booster, heat, mates)
if not okay then
pcall(destiny.close, destiny)
self.destiny = nil
self.report({ event = "feature", id = "destiny_panel", action = "off", detail = tostring(why) })
end
end
function Product:after()
if self.menu == nil then return end
self.menu:after(self.dt)
self.menu_outermost = self.menu.outermost
end
function Product:close()
local failures = {}
local function finish(owner, method, ...)
if owner == nil then return end
local okay, why = pcall(owner[method], owner, ...)
if not okay then failures[#failures + 1] = tostring(why) end
end
finish(self.menu, "close")
finish(self.destiny, "close")
finish(self.options, "clear")
if #failures > 0 then error(table.concat(failures, "\n"), 0) end
end
return Product
