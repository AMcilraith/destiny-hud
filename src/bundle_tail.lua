local function import(name)
if shared ~= nil and shared[name] ~= nil then return shared[name] end
if loaded[name] ~= nil then return loaded[name] end
local factory = modules[name]
if factory == nil then return native_require(name) end
local result = factory(import)
if result == nil then result = true end
loaded[name] = result
return result
end
return import
end)()
return import('entry')
