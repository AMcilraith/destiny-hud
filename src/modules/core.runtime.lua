local Runtime = {}
Runtime.__index = Runtime
function Runtime.new(program, report)
return setmetatable({ program = program, report = report, running = true }, Runtime)
end
function Runtime:stop(reason, stage)
if not self.running then return true end
self.running = false
local okay, failure = pcall(self.program.close, self.program)
if self.report ~= nil then
local detail
if not okay then detail = tostring(failure) end
pcall(self.report, reason or "closed", detail, stage)
end
return okay, failure
end
function Runtime:step(...)
if not self.running then return end
local okay, failure = pcall(self.program.step, self.program, ...)
if not okay then self:stop(tostring(failure), "step"); return end
local successor = self.program.successor
if successor ~= nil then
self.program = successor
if self.changed ~= nil then self:changed() end
end
end
function Runtime:after()
if not self.running or self.program.after == nil then return end
local okay, failure = pcall(self.program.after, self.program)
if not okay then self:stop(tostring(failure), "after") end
end
function Runtime:install(environment)
assert(type(environment.update) == "function", "no-global-update")
assert(not self.installed, "already-installed")
local original_update, original_shutdown = environment.update, environment.shutdown
local runtime = self
local function finish(...)
runtime:after()
local top = environment.update
if runtime.running and runtime.program.menu_outermost then
if top ~= (runtime.outer or runtime.base) then
runtime.outer_inner = top
runtime.outer = runtime:link(top, finish)
environment.update = runtime.outer
end
elseif runtime.outer ~= nil then
if top == runtime.outer then environment.update = runtime.outer_inner end
runtime.outer, runtime.outer_inner = nil, nil
end
if runtime.boundary ~= nil then runtime:boundary() end
return ...
end
runtime.base = runtime:link(original_update, finish)
environment.update = runtime.base
if type(original_shutdown) == "function" then
environment.shutdown = function(...)
runtime:stop()
return original_shutdown(...)
end
end
self.installed = true
return self
end
function Runtime:link(inner, finish)
local runtime, wrapper = self, nil
wrapper = function(...)
if wrapper ~= (runtime.outer or runtime.base) then return inner(...) end
runtime:step(...)
return finish(inner(...))
end
return wrapper
end
return Runtime
