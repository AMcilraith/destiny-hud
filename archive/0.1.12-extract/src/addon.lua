local __original_boot = "\027\076\074\002\002\067\000\000\002\000\002\000\004\054\000\000\000\039\001\001\000\066\000\002\001\075\000\001\000\040\099\111\114\101\047\119\119\105\115\101\047\108\117\097\047\119\119\105\115\101\095\102\108\111\119\095\099\097\108\108\098\097\099\107\115\012\114\101\113\117\105\114\101\011\000\000\001\000\000\000\001\075\000\001\000\011\000\001\001\000\000\000\001\075\000\001\000\011\000\000\001\000\000\000\001\075\000\001\000\214\001\003\000\003\000\018\000\027\051\000\000\000\055\000\001\000\051\000\002\000\055\000\003\000\051\000\004\000\055\000\005\000\051\000\006\000\055\000\007\000\054\000\008\000\057\000\009\000\057\000\010\000\066\000\001\002\006\000\011\000\088\000\003\128\054\000\012\000\039\001\013\000\066\000\002\001\054\000\014\000\054\001\015\000\054\002\016\000\066\000\003\002\015\000\000\000\088\001\003\128\054\000\016\000\057\000\017\000\066\000\001\001\075\000\001\000\008\111\102\102\008\106\105\116\007\095\071\011\114\097\119\103\101\116\010\100\101\098\117\103\012\114\101\113\117\105\114\101\012\114\101\108\101\097\115\101\010\098\117\105\108\100\016\065\112\112\108\105\099\097\116\105\111\110\013\115\116\105\110\103\114\097\121\011\114\101\110\100\101\114\000\011\117\112\100\097\116\101\000\013\115\104\117\116\100\111\119\110\000\009\105\110\105\116\000\000"
local __original_loader = rawget(_G, 'loadstring') or rawget(_G, 'load')
local __original_chunk = __original_loader and __original_loader(__original_boot)
local __original_ok, __original_result = false, nil
if __original_chunk then __original_ok, __original_result = pcall(__original_chunk) end
local __module_registry = {}
local __module_errors = {}
local function __module_log(line)
__module_errors[#__module_errors + 1] = tostring(line)
end
local function __module_environment(name, ambient_global)
local allowed = {}
allowed["assert"] = rawget(_G, "assert")
allowed["collectgarbage"] = rawget(_G, "collectgarbage")
allowed["error"] = rawget(_G, "error")
allowed["getmetatable"] = rawget(_G, "getmetatable")
allowed["io"] = rawget(_G, "io")
allowed["ipairs"] = rawget(_G, "ipairs")
allowed["load"] = rawget(_G, "load")
allowed["loadstring"] = rawget(_G, "loadstring")
allowed["math"] = rawget(_G, "math")
allowed["next"] = rawget(_G, "next")
allowed["os"] = rawget(_G, "os")
allowed["pairs"] = rawget(_G, "pairs")
allowed["pcall"] = rawget(_G, "pcall")
allowed["rawget"] = rawget(_G, "rawget")
allowed["rawset"] = rawget(_G, "rawset")
allowed["select"] = rawget(_G, "select")
allowed["setmetatable"] = rawget(_G, "setmetatable")
allowed["string"] = rawget(_G, "string")
allowed["table"] = rawget(_G, "table")
allowed["tonumber"] = rawget(_G, "tonumber")
allowed["tostring"] = rawget(_G, "tostring")
allowed["type"] = rawget(_G, "type")
allowed["unpack"] = rawget(_G, "unpack")
if ambient_global then allowed._G = _G end
return setmetatable(allowed, {__index=function(_, key) error(name .. ": undeclared global " .. tostring(key), 0) end,__newindex=function(_, key) error(name .. ": global write " .. tostring(key), 0) end})
end
local __module_run = (function()
return function(name, factory, imports, log)
local ok, exports = pcall(factory, imports)
if not ok then log("MODULE " .. name .. " ERROR " .. tostring(exports)) return nil end
if type(exports) ~= "table" then log("MODULE " .. name .. " ERROR exports") return nil end
return exports
end
end)()
do
local __imports = {}
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("00-boot-state: imports must be a table", 0) end

local BootState = (function()
  local State = { VERSION = "boot-state-v1", result = false }

  local sr = rawget(_G, "stingray")
  local App = sr and rawget(sr, "Application") or nil

  local BRACKET_WINDOWS = 5
  State.BRACKET_WINDOWS = BRACKET_WINDOWS
  local sink, log_path = nil, nil
  local written, suppressed = 0, 0

  function State.log(line)
    if sink == nil then return end
    sink(line)
    written = written + 1
  end

  function State.attach(fn, path)
    sink, log_path = fn, path
  end

  local status_written = false

  function State.status(reason)
    if status_written then return end
    status_written = true
    pcall(function()
      local dir = os.getenv("APPDATA")
      if dir == nil then return end
      local file = io.open(dir .. "\\hd2_hud_status.txt", "w")
      if file == nil then return end
      file:write(State.VERSION .. "\n" .. tostring(reason) .. "\n")
      file:close()
    end)
  end

  function State.begin()
    return sink ~= nil
  end

  function State.brackets(window)
    if sink == nil then return false end
    if window ~= nil and window > BRACKET_WINDOWS then
      suppressed = suppressed + 1
      return false
    end
    return true
  end

  function State.globals()
    if type(_G) ~= "table" then return "not-a-table" end
    local names, total = {}, 0
    for key in pairs(_G) do
      total = total + 1
      if type(key) == "string" and #names < 12 then
        names[#names + 1] = key
      end
    end
    table.sort(names)
    return tostring(total) .. ":" .. table.concat(names, ",")
  end

  function State.log_state()
    return { path = log_path, written = written, suppressed = suppressed }
  end

  function State.clock()
    if App == nil or type(rawget(App, "time_since_launch")) ~= "function" then
      return nil
    end
    local ok, value = pcall(App.time_since_launch)
    if ok and type(value) == "number" then return App.time_since_launch end
    return nil
  end

  function State.install(worker)
    if State.installed then return false end
    local original = rawget(_G, "update")
    if type(original) ~= "function" then
      State.log("RUN product install=refused reason=no-global-update" ..
                " g=" .. type(_G) ..
                " update=" .. type(rawget(_G, "update")) ..
                " shutdown=" .. type(rawget(_G, "shutdown")) ..
                " stingray=" .. type(rawget(_G, "stingray")) ..
                " names=" .. tostring(State.globals()))
      return false
    end
    State.installed = true
    State.faults = 0
    rawset(_G, "update", function(...)
      if State.armed ~= false then
        local ok, why = pcall(function() worker:update() end)
        if not ok then
          State.faults = State.faults + 1
          State.armed = false
          State.log("RUN product worker=disarmed faults=" ..
                    tostring(State.faults) ..
                    " why=" .. string.format("%q", tostring(why)))
        end
      end
      return original(...)
    end)
    State.armed = true
    State.result = true
    State.log("RUN product install=ok hook=global-update")
    return true
  end

  return State
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return BootState end)
if not __contract_ok_1 or __contract_export_1 == nil then error("00-boot-state: missing export BootState", 0) end
return {["BootState"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("00-boot-state", true))
local __exports = __module_run("00-boot-state", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["BootState"] = __exports["BootState"]
end
end
do
local __imports = {}
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("11-resource-load: imports must be a table", 0) end

local ResourceLoad = (function()
  local Core = { VERSION = "resource-load-v1" }
  local require_of = rawget(_G, "require")
  local sr = rawget(_G, "stingray")
  local App = sr and rawget(sr, "Application") or nil

  local function available(name)
    if App == nil or type(App.can_get) ~= "function" then return nil end
    local ok, found = pcall(App.can_get, "lua", name)
    if not ok or type(found) ~= "boolean" then return nil end
    return found
  end

  function Core.load(name)
    if require_of == nil then return nil, "no-require" end
    local found = available(name)
    if found == false then return nil, "not-installed" end
    local ok, part = pcall(require_of, name)
    if not ok then return nil, found and "load-failed" or "not-found" end
    if type(part) ~= "table" then return nil, "not-a-table" end
    return part
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return ResourceLoad end)
if not __contract_ok_1 or __contract_export_1 == nil then error("11-resource-load: missing export ResourceLoad", 0) end
return {["ResourceLoad"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("11-resource-load", true))
local __exports = __module_run("11-resource-load", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["ResourceLoad"] = __exports["ResourceLoad"]
end
end
do
local __imports = {}
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("12-engine-call: imports must be a table", 0) end

local EngineCall = (function()
  local Core = { VERSION = "engine-call-v1" }

  function Core.callable(namespace, name)
    return type(namespace) == "table" and
           type(rawget(namespace, name)) == "function"
  end

  function Core.attempt(fn, ...)
    if fn == nil then return nil end
    local ok, value = pcall(fn, ...)
    if not ok then return nil end
    return value
  end

  function Core.call(counters, fn, ...)
    local result = { pcall(fn, ...) }
    if result[1] ~= true then
      counters.errors = counters.errors + 1
      return nil
    end
    counters.calls = counters.calls + 1
    return result[2]
  end

  function Core.world_is_live(worlds, wanted)
    if type(worlds) ~= "table" or wanted == nil then return false end
    for index = 1, #worlds do
      if worlds[index] == wanted then return true end
    end
    return false
  end

  function Core.counters_of(counters)
    local out = {}
    for key, value in pairs(counters or {}) do out[key] = value end
    return out
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return EngineCall end)
if not __contract_ok_1 or __contract_export_1 == nil then error("12-engine-call: missing export EngineCall", 0) end
return {["EngineCall"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("12-engine-call", false))
local __exports = __module_run("12-engine-call", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["EngineCall"] = __exports["EngineCall"]
end
end
do
local __imports = {}
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("15-gui-handle: imports must be a table", 0) end
local GuiHandle = {}

function GuiHandle.dead(value)
  if value == nil then return true end
  local ok, shown = pcall(tostring, value)
  if not ok or type(shown) ~= "string" then return true end
  return string.find(shown, "nullptr", 1, true) ~= nil or
         string.find(shown, "deleted", 1, true) ~= nil
end

local __contract_ok_1, __contract_export_1 = pcall(function() return GuiHandle end)
if not __contract_ok_1 or __contract_export_1 == nil then error("15-gui-handle: missing export GuiHandle", 0) end
return {["GuiHandle"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("15-gui-handle", false))
local __exports = __module_run("15-gui-handle", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["GuiHandle"] = __exports["GuiHandle"]
end
end
do
local __imports = {}
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("16-native-channel: imports must be a table", 0) end
local NativeChannel = (function()
  local Module = {}

  local ARENA_START = 128 * 1024
  local SPAN = 4

  function Module.span(bytes)
    if bytes == nil then return 0 end
    if type(bytes) == "string" then return #bytes end
    return bytes[-4] + bytes[-3] * 256 + bytes[-2] * 65536 + bytes[-1] * 16777216
  end

  function Module.byte(bytes, at)
    if type(bytes) == "string" then return string.byte(bytes, at + 1) end
    return bytes[at]
  end

  function Module.text(bytes, at, size)
    if bytes == nil then return nil end
    at = at or 0
    size = size or (Module.span(bytes) - at)
    if type(bytes) == "string" then return string.sub(bytes, at + 1, at + size) end
    local parts = {}
    for step = 1, size do parts[step] = string.char(bytes[at + step - 1]) end
    return table.concat(parts)
  end

  function Module.same(one, other)
    if one == nil or other == nil then return false end
    local size = Module.span(one)
    if size ~= Module.span(other) then return false end
    for at = 0, size - 1 do
      if Module.byte(one, at) ~= Module.byte(other, at) then return false end
    end
    return true
  end

  local FLOOR = 0x10000
  local CEILING = 0x800000000000

  local CDEF = table.concat({
    "void *GetModuleHandleA(const char *name);",
    "uint32_t GetModuleFileNameW(void *module, uint16_t *path,"
      .. " uint32_t capacity);",
    "void *GetCurrentProcess(void);",
    "int ReadProcessMemory(void *process, const void *address, void *buffer,"
      .. " size_t size, size_t *read);",
    "void *CreateFileW(const uint16_t *path, uint32_t access, uint32_t share,"
      .. " void *security, uint32_t disposition, uint32_t flags,"
      .. " void *template_file);",
    "int ReadFile(void *file, void *buffer, uint32_t size, uint32_t *read,"
      .. " void *overlapped);",
    "int CloseHandle(void *handle);",
    "int32_t BCryptOpenAlgorithmProvider(void **algorithm,"
      .. " const uint16_t *name, const uint16_t *provider, uint32_t flags);",
    "int32_t BCryptCloseAlgorithmProvider(void *algorithm, uint32_t flags);",
    "int32_t BCryptCreateHash(void *algorithm, void **hash, void *object,"
      .. " uint32_t object_size, const void *secret, uint32_t secret_size,"
      .. " uint32_t flags);",
    "int32_t BCryptHashData(void *hash, const void *data, uint32_t size,"
      .. " uint32_t flags);",
    "int32_t BCryptFinishHash(void *hash, void *digest, uint32_t size,"
      .. " uint32_t flags);",
    "int32_t BCryptDestroyHash(void *hash);",
  }, "\n")

  local Channel = {}
  Channel.__index = Channel

  function Module.open()
    local loader = rawget(_G, "require")
    if loader == nil then return nil, "no-require" end
    local ok, ffi = pcall(loader, "ffi")
    if not ok or ffi == nil then return nil, "ffi-unavailable" end
    if not ffi.abi("64bit") then return nil, "not-64bit" end
    pcall(ffi.cdef, CDEF)
    local loaded_kernel, kernel = pcall(ffi.load, "kernel32")
    if not loaded_kernel then return nil, "kernel32:" .. tostring(kernel) end
    local loaded_bcrypt, bcrypt = pcall(ffi.load, "bcrypt")
    if not loaded_bcrypt then return nil, "bcrypt:" .. tostring(bcrypt) end
    local self = setmetatable({
      ffi = ffi,
      kernel = kernel,
      bcrypt = bcrypt,
      process = kernel.GetCurrentProcess(),
      modules = {},
      arena = ffi.new("uint8_t[?]", ARENA_START),
      arena_size = ARENA_START,
      arena_at = 0,
      spent = {},
      count = ffi.new("size_t[1]"),
    }, Channel)
    local function as_bytes(handle)
      if handle == nil then return nil end
      return ffi.cast("uint8_t *", handle)
    end
    self.modules.exe = as_bytes(kernel.GetModuleHandleA(nil))
    self.modules.game = as_bytes(kernel.GetModuleHandleA("game.dll"))
    if self.modules.exe == nil then return nil, "exe-handle-null" end
    return self, nil
  end

  function Channel:module(which)
    return self.modules[which]
  end

  function Channel:read(address, size)
    self.reads = (self.reads or 0) + 1
    if size <= 0 then return nil end
    local want = SPAN + size
    local at = self.arena_at
    if at + want > self.arena_size then
      local grown = self.arena_size * 2
      while grown < want do grown = grown * 2 end
      self.spent[#self.spent + 1] = self.arena
      self.arena, self.arena_size, self.arena_at = self.ffi.new("uint8_t[?]", grown), grown, 0
      at = 0
    end
    local arena, count = self.arena, self.count
    local bytes = arena + at + SPAN
    if self.kernel.ReadProcessMemory(self.process, address, bytes, size, count) == 0 then
      self.read_failed = (self.read_failed or 0) + 1
      return nil
    end
    if tonumber(count[0]) ~= size then
      self.read_failed = (self.read_failed or 0) + 1
      return nil
    end
    arena[at] = size % 256
    arena[at + 1] = math.floor(size / 256) % 256
    arena[at + 2] = math.floor(size / 65536) % 256
    arena[at + 3] = math.floor(size / 16777216) % 256
    self.arena_at = at + want + (4 - want % 4) % 4
    return bytes
  end

  function Channel:rewind()
    self.arena_at = 0
    if #self.spent > 0 then self.spent = {} end
  end

  local SLOT, RAW = nil, nil

  function Channel:pointer(bytes, offset)
    offset = offset or 0
    if not bytes or offset < 0 or offset + 8 > Module.span(bytes) then return nil end
    local ffi = self.ffi
    if SLOT == nil then SLOT, RAW = ffi.new("uintptr_t[1]"), ffi.new("uint8_t[8]") end
    if type(bytes) == "string" then
      RAW[0], RAW[1], RAW[2], RAW[3], RAW[4], RAW[5], RAW[6], RAW[7] =
        bytes:byte(offset + 1, offset + 8)
      ffi.copy(SLOT, RAW, 8)
    else
      ffi.copy(SLOT, bytes + offset, 8)
    end
    if SLOT[0] < FLOOR or SLOT[0] >= CEILING then return nil end
    return ffi.cast("uint8_t *", SLOT[0])
  end

  function Channel:distance(first, second)
    local ffi = self.ffi
    return tonumber(ffi.cast("intptr_t", first) - ffi.cast("intptr_t", second))
  end

  function Channel:fingerprint(which)
    local handle = self:module(which)
    if handle == nil then return nil, "no-module" end
    local ffi, kernel, bcrypt = self.ffi, self.kernel, self.bcrypt
    local path = ffi.new("uint16_t[32768]")
    local length = kernel.GetModuleFileNameW(handle, path, 32768)
    if length == 0 or length >= 32768 then return nil, "path" end
    local file = kernel.CreateFileW(path, 0x80000000, 7, nil, 3, 0x08000000, nil)
    if file == ffi.cast("void *", -1) then return nil, "open" end
    local algorithm, hash = ffi.new("void *[1]"), ffi.new("void *[1]")
    local buffer, count = ffi.new("uint8_t[1048576]"), ffi.new("uint32_t[1]")
    local name = ffi.new("uint16_t[7]", { 83, 72, 65, 50, 53, 54, 0 })
    local total, fault, hex = 0, nil, nil
    if bcrypt.BCryptOpenAlgorithmProvider(algorithm, name, nil, 0) ~= 0 then
      fault = "provider"
    end
    if fault == nil and
       bcrypt.BCryptCreateHash(algorithm[0], hash, nil, 0, nil, 0, 0) ~= 0 then
      fault = "create"
    end
    while fault == nil do
      if kernel.ReadFile(file, buffer, 1048576, count, nil) == 0 then
        fault = "read"
        break
      end
      if count[0] == 0 then break end
      total = total + tonumber(count[0])
      if bcrypt.BCryptHashData(hash[0], buffer, count[0], 0) ~= 0 then
        fault = "update"
        break
      end
    end
    if fault == nil then
      local digest = ffi.new("uint8_t[32]")
      if bcrypt.BCryptFinishHash(hash[0], digest, 32, 0) ~= 0 then
        fault = "finish"
      else
        local parts = {}
        for index = 0, 31 do
          parts[#parts + 1] = string.format("%02x", digest[index])
        end
        hex = table.concat(parts)
      end
    end
    if hash[0] ~= nil then bcrypt.BCryptDestroyHash(hash[0]) end
    if algorithm[0] ~= nil then bcrypt.BCryptCloseAlgorithmProvider(algorithm[0], 0) end
    kernel.CloseHandle(file)
    if hex == nil then return nil, fault or "unknown" end
    return hex, total
  end

  function Channel:pinned(expected)
    local report = {}
    for _, which in ipairs({ "exe", "game" }) do
      local hex, detail = self:fingerprint(which)
      report[which] = {
        sha = hex,
        want = expected and expected[which],
        bytes = hex ~= nil and detail or nil,
        fault = hex == nil and detail or nil,
      }
      if hex == nil then return false, report end
      if expected and expected[which] and expected[which] ~= hex then
        return false, report
      end
    end
    return true, report
  end

  return Module
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return NativeChannel end)
if not __contract_ok_1 or __contract_export_1 == nil then error("16-native-channel: missing export NativeChannel", 0) end
return {["NativeChannel"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("16-native-channel", true))
local __exports = __module_run("16-native-channel", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["NativeChannel"] = __exports["NativeChannel"]
end
end
do
local __imports = {}
__imports["NativeChannel"] = __module_registry["NativeChannel"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("17-native-memory: imports must be a table", 0) end
local NativeChannel = imports["NativeChannel"]
if NativeChannel == nil then error("17-native-memory: missing import NativeChannel", 0) end
local NativeMemory = (function()
  local M = { VERSION = "native-memory-v1" }

  M.COUNT_LIMIT = 1024

  local span, byte_at = NativeChannel.span, NativeChannel.byte

  function M.u8(bytes, at)
    if bytes == nil or at == nil or at + 1 > span(bytes) then return nil end
    return byte_at(bytes, at)
  end

  function M.u32(bytes, at)
    if bytes == nil or at == nil or at + 4 > span(bytes) then return nil end
    return byte_at(bytes, at) + byte_at(bytes, at + 1) * 256
      + byte_at(bytes, at + 2) * 65536 + byte_at(bytes, at + 3) * 16777216
  end

  local F32, F64, RAW = nil, nil, nil

  local function moved(ffi, bytes, at, size)
    if RAW == nil then RAW = ffi.new("uint8_t[8]") end
    for step = 0, size - 1 do RAW[step] = byte_at(bytes, at + step) end
    return RAW
  end

  local function unpack_to(ffi, box, bytes, at, size)
    if type(bytes) == "string" then
      ffi.copy(box, moved(ffi, bytes, at, size), size)
    else
      ffi.copy(box, bytes + at, size)
    end
  end

  function M.f32(ffi, bytes, at)
    if bytes == nil or at == nil or at + 4 > span(bytes) then return nil end
    if F32 == nil then F32 = ffi.new("float[1]") end
    unpack_to(ffi, F32, bytes, at, 4)
    return tonumber(F32[0])
  end

  function M.f64(ffi, bytes, at)
    if bytes == nil or at == nil or at + 8 > span(bytes) then return nil end
    if F64 == nil then F64 = ffi.new("double[1]") end
    unpack_to(ffi, F64, bytes, at, 8)
    return tonumber(F64[0])
  end

  function M.bit(bytes, at, n)
    local byte = M.u8(bytes, at)
    if byte == nil or type(n) ~= "number" or n < 0 or n > 7 then return nil end
    return math.floor(byte / 2 ^ n) % 2
  end

  function M.i32(bytes, at)
    local value = M.u32(bytes, at)
    if value == nil then return nil end
    if value >= 2147483648 then return value - 4294967296 end
    return value
  end

  function M.decode(channel, row, where)
    local at, form = where[1], where[2]
    if form == "u32" then return M.u32(row, at) end
    if form == "i32" then return M.i32(row, at) end
    if form == "f32" then return M.f32(channel.ffi, row, at) end
    if form == "f64" then return M.f64(channel.ffi, row, at) end
    if form == "u8" then return M.u8(row, at) end
    if form == "bool" then
      local byte = M.u8(row, at)
      if byte == nil then return nil end
      return byte ~= 0
    end
    if form == "bit" then return M.bit(row, at, where[3]) end
    if form == "u64" then
      local low, high = M.u32(row, at), M.u32(row, at + 4)
      if low == nil or high == nil then return nil end
      return high * 4294967296 + low
    end
    if form == "hash64" then
      local low, high = M.u32(row, at), M.u32(row, at + 4)
      if low == nil or high == nil or (low == 0 and high == 0) then return nil end
      if low == high or low == 0 then return nil end
      return string.format("0x%08x%08x", high, low)
    end
    if form == "hex" then
      local size = where[3]
      if row == nil or type(size) ~= "number" or at + size > span(row) then return nil end
      return M.hex(row, at, size)
    end
    return nil
  end

  function M.pointer_at(channel, address)
    local raw = channel:read(address, 8)
    return raw ~= nil and channel:pointer(raw) or nil
  end

  function M.resource_at(channel, address)
    local raw = channel:read(address, 8)
    if raw == nil then return nil end
    local low, high = M.u32(raw, 0), M.u32(raw, 4)
    if low == 0 and high == 0 then return nil end
    return string.format("%08x%08x", high, low)
  end

  function M.key_of(text)
    if type(text) ~= "string" then return nil end
    if string.sub(text, 1, 2) == "0x" then text = string.sub(text, 3) end
    if #text ~= 16 then return nil end
    local bytes = {}
    for at = 15, 1, -2 do
      local byte = tonumber(string.sub(text, at, at + 1), 16)
      if byte == nil then return nil end
      bytes[#bytes + 1] = string.char(byte)
    end
    return table.concat(bytes)
  end

  local function masked(x, mask)
    local out, place = 0, 1
    while mask > 0 and x > 0 do
      if mask % 2 == 1 and x % 2 == 1 then out = out + place end
      x = math.floor(x / 2)
      mask = math.floor(mask / 2)
      place = place * 2
    end
    return out
  end

  function M.lookup(channel, layout, base, key, heads)
    local width = math.max(layout.capacity, layout.empty, layout.mult) + 4
    local slot = heads ~= nil and
      tonumber(channel.ffi.cast("uintptr_t", base)) or nil
    local header = slot ~= nil and heads[slot] or nil
    if header == nil then
      header = channel:read(base, width)
      if header ~= nil and slot ~= nil then heads[slot] = header end
    end
    if header == nil then return nil, "unread" end
    local capacity = M.u32(header, layout.capacity)
    local empty = M.u32(header, layout.empty)
    local mult = M.u32(header, layout.mult)
    if capacity == nil or empty == nil or mult == nil then return nil, "unread" end
    if capacity == 0 then return nil, "absent" end
    local rows = channel:pointer(header)
    if rows == nil then return nil, "unread" end
    local ffi = channel.ffi
    local product = ffi.new("uint64_t", key) * ffi.new("uint64_t", mult)
    local seed = tonumber(ffi.cast("uint32_t", product))
    for probe = 0, capacity - 1 do
      local row = channel:read(rows + masked(seed + probe, capacity - 1) * 8, 8)
      if row == nil then return nil, "unread" end
      local found = M.u32(row, 0)
      if found == nil then return nil, "unread" end
      if found == key then
        local value = M.u32(row, 4)
        if value == nil then return nil, "unread" end
        return value, "present"
      end
      if found == empty then return nil, "absent" end
    end
    return nil, "absent"
  end

  function M.blob(channel, table_at, spec, hash)
    if table_at == nil or hash == nil or span(hash) < 8 then return nil, "unread" end
    local buckets, size = spec.buckets, spec.size
    if buckets == nil or buckets == 0 or size == nil then return nil, "unread" end
    if M.u32(hash, 0) == 0 and M.u32(hash, 4) == 0 then return nil, "absent" end
    local slot = 0
    for at = 7, 0, -1 do
      local byte = byte_at(hash, at)
      if byte == nil then return nil, "unread" end
      slot = (slot * 256 + byte) % buckets
    end
    for probe = 0, buckets - 1 do
      local row = channel:read(table_at + ((slot + probe) % buckets) * 16, 16)
      if row == nil or span(row) < 16 then return nil, "unread" end
      if M.u32(row, 0) == M.u32(hash, 0) and M.u32(row, 4) == M.u32(hash, 4) then
        local index = M.u32(row, 8)
        if index == nil then return nil, "unread" end
        return table_at + buckets * 16 + index * size, "present"
      end
      if M.u32(row, 0) == 0 and M.u32(row, 4) == 0 then return nil, "absent" end
    end
    return nil, "absent"
  end

  function M.hex(bytes, at, size)
    at = at or 0
    size = size or (span(bytes) - at)
    local digits = {}
    for step = 0, size - 1 do
      digits[step + 1] = string.format("%02x", byte_at(bytes, at + step))
    end
    return table.concat(digits)
  end

  return M
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return NativeMemory end)
if not __contract_ok_1 or __contract_export_1 == nil then error("17-native-memory: missing export NativeMemory", 0) end
return {["NativeMemory"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("17-native-memory", false))
local __exports = __module_run("17-native-memory", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["NativeMemory"] = __exports["NativeMemory"]
end
end
do
local __imports = {}
__imports["NativeChannel"] = __module_registry["NativeChannel"]
__imports["NativeMemory"] = __module_registry["NativeMemory"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("18-native-read: imports must be a table", 0) end
local NativeChannel = imports["NativeChannel"]
if NativeChannel == nil then error("18-native-read: missing import NativeChannel", 0) end
local NativeMemory = imports["NativeMemory"]
if NativeMemory == nil then error("18-native-read: missing import NativeMemory", 0) end
local NativeRead = (function()
  local Core = { VERSION = "native-read-v1" }
  local Instance = {}
  Instance.__index = Instance

  local INVALID = 0xffffffff
  local NO_OBJECT = 0x7fff
  local MATERIAL_HIGH, MATERIAL_LOW = 0xeac0b497, 0x876adedf
  local MATERIAL_TEXTURE_AT = 140
  local u32, decode = NativeMemory.u32, NativeMemory.decode

  local function observe(observed, name, status)
    if observed == nil or observed[name] == "present" then return end
    if observed[name] == "unread" and status == "absent" then return end
    observed[name] = status
  end

  local function fill(channel, row, values, cells, only_empty, observed, missing)
    local filled = 0
    for name, where in pairs(values or {}) do
      if not only_empty or cells[name] == nil then
        local value = nil
        if row ~= nil then value = decode(channel, row, where) end
        local status = missing or "unread"
        if value ~= nil then
          cells[name] = value
          filled = filled + 1
          status = "present"
        elseif row ~= nil and where[2] == "hash64" and
            u32(row, where[1]) == 0 and u32(row, where[1] + 4) == 0 then
          status = "absent"
        end
        observe(observed, name, status)
      end
    end
    return filled
  end

  local function row_of(rows, cells)
    local one = {}
    for name in pairs(rows.values) do one[name] = cells[name] end
    for _, by in ipairs(rows.value_rows or {}) do
      for name in pairs(by.values) do one[name] = cells[name] end
    end
    return one
  end

  local function open_value_rows(channel, game, list, cells, keep, held)
    for _, by in ipairs(list or {}) do
      local index = cells[by.by]
      if not keep then cells[by.by] = nil end
      if type(index) == "number" and index >= 0 and index < by.slots then
        local seen = nil
        if held ~= nil then
          seen = held[by]
          if seen == nil then seen = {}; held[by] = seen end
          local known = seen[index]
          if known ~= nil then
            for name, value in pairs(known) do cells[name] = value end
            index = nil
          end
        end
        if index ~= nil then
          local at = game + by.at + index * by.stride
          if by.through == "pointer" then
            at = NativeMemory.pointer_at(channel, at)
          end
          if at ~= nil and at ~= 0 then
            local into = seen ~= nil and {} or cells
            fill(channel, channel:read(at, by.span or by.stride), by.values, into)
            if seen ~= nil then
              seen[index] = into
              for name, value in pairs(into) do cells[name] = value end
            end
          end
        end
      end
    end
  end

  local WIDTH = { u32 = 4, i32 = 4, f32 = 4, f64 = 8, u8 = 1, bool = 1, bit = 1,
                  hash64 = 8, u64 = 8 }

  function Core.span_of(spec)
    local fields = type(spec) == "table" and spec.fields or nil
    if type(fields) ~= "table" then return nil end
    local span = 0
    for _, where in pairs(fields) do
      local at = where[1]
      local width = where[2] == "hex" and where[3] or WIDTH[where[2]]
      if type(at) ~= "number" or type(width) ~= "number" then return nil end
      if at + width > span then span = at + width end
    end
    if span == 0 then return nil end
    return span
  end

  function Core.new(baked, channel_core)
    if type(baked) ~= "table" or type(baked.chain) ~= "table" then return nil end
    if type(baked.pin) ~= "table" or channel_core == nil then return nil end
    local self = setmetatable({}, Instance)
    self.baked = baked
    self.core = channel_core
    self.chain = baked.chain
    self.map = baked.map or {}
    self.equipment = baked.equipment
    self.relations = baked.relations or {}
    self.slot_seats = false
    self.stack_ranks = {}
    for _, source in pairs(self.relations) do
      if source.from == "slot" then
        self.slot_seats = true
      elseif source.from == "stratagem_call" then
        local seen = self.stack_ranks[source.of]
        if seen == nil or seen < source.rank then
          self.stack_ranks[source.of] = source.rank
        end
      end
    end
    self.catalog = baked.catalog or {}
    self.catalog_for, self.mirrored_for = {}, {}
    self.mirrored = false
    local function pick(asked)
      local picked = {}
      for _, spec in ipairs(self.catalog) do
        if asked[spec.component] then picked[#picked + 1] = spec end
      end
      return picked
    end
    local function narrow(name, reads, mirror_reads)
      if reads == nil then return end
      local asked = {}
      for _, component in ipairs(reads) do asked[component] = true end
      self.catalog_for[name] = pick(asked)
      if mirror_reads == nil then return end
      for _, component in ipairs(mirror_reads) do asked[component] = true end
      self.mirrored_for[name] = pick(asked)
    end
    for name, source in pairs(self.relations) do
      narrow(name, source.reads, source.mirror_reads)
    end
    narrow("roster", (baked.roster or {}).reads)
    self.sums = baked.sums or {}
    self.remaining = baked.remaining or {}
    self.charged = baked.charged or {}
    self.chamber = baked.chamber
    self.adds_only_when_mine = baked.adds_only_when_mine
    self.none_of = baked.none_of or {}
    self.nonzero = baked.nonzero or {}
    self.counts = baked.counts or {}
    self.picks = baked.picks or {}
    self.avatar_state = baked.avatar_state
    self.wired = baked.wired or {}
    self.roster = baked.roster
    self.attach = baked.attach
    self.hud_squad = baked.hud_squad
    self.comms = baked.comms
    self.stratagem_slots = baked.stratagem_slots
    self.atlas_index = baked.atlas_index
    self.resource_index = baked.resource_index
    self.material_textures = {}
    self.session = baked.session
    self.hud_widgets = baked.hud_widgets
    self.hud_gate = baked.hud_gate
    self.hud_override = baked.hud_override
    self.hud_target = baked.hud_target
    self.function_icons = baked.function_icons
    self.widget_span = Core.span_of(self.hud_widgets)
    self.action = baked.action
    self.channel, self.game, self.pinned = nil, nil, nil
    self.counters = {
      windows = 0, opened = 0, open_failed = 0, pin_ok = 0, pin_bad = 0,
      chain_read = 0, chain_failed = 0, swept = 0,
      relations_filled = 0, relations_empty = 0,
      specs_walked = 0,
      channel_reads = 0,
      channel_read_failed = 0,
      record_checked = 0, record_stale = 0,
      member_moved = 0, member_checked = 0, member_stale = 0,
      stack_over = 0,
      record_failed = 0, backref_bad = 0, component_none = 0,
      atlas_rows = 0,
      resource_types = 0, resource_rows = 0,
      material_asked = 0, material_opened = 0,
      material_unopened = 0, material_no_texture = 0,
      resource_unread = 0,
      seat_missing = 0,
      seat_barred = 0,
      door_reads = 0, door_bytes = 0,
      subject_unsettled = 0,
      slot_contested = 0, slot_attached_won = 0, slot_attach_unread = 0,
      pool_no_seat = 0, pool_map_unread = 0, pool_no_rows = 0, pool_no_row = 0,
      wired_pairs = 0,
      goid_unresolved = 0, unit_unresolved = 0,
      book_no_row = 0, book_unread = 0, book_filled = 0,
      widgets_read = 0, widgets_unread = 0, widgets_no_manager = 0,
      cells_filled = 0, cells_silenced = 0,
      action_no_seat = 0, action_no_runner = 0, action_no_reload = 0, action_gate_open = 0,
      action_filled = 0,
    }
    self.action_span = nil
    return self
  end

  function Instance:report()
    local out = {}
    for key, value in pairs(self.counters) do out[key] = value end
    return out
  end

  function Instance:refused()
    return self.refusal
  end

  function Instance:ready()
    if self.pinned == false then return nil, self.refusal or "pin" end
    if self.channel ~= nil then return self.channel, nil end
    local channel, why = self.core.open()
    if channel == nil then
      self.pinned, self.refusal = false, why or "open"
      self.counters.open_failed = self.counters.open_failed + 1
      return nil, self.refusal
    end
    if not channel:pinned(self.baked.pin) then
      self.pinned, self.refusal = false, "pin"
      self.counters.pin_bad = self.counters.pin_bad + 1
      return nil, self.refusal
    end
    local game = channel:module("game")
    if game == nil then
      self.pinned, self.refusal = false, "no-module"
      return nil, self.refusal
    end
    self.exe = channel:module("exe")
    self.channel, self.game, self.pinned = channel, game, true
    self.counters.opened = self.counters.opened + 1
    self.counters.pin_ok = self.counters.pin_ok + 1
    return channel, nil
  end

  function Core.resource_of(record, at)
    at = at or 0
    if record == nil or NativeChannel.span(record) < at + 8 then return nil end
    local low, high = u32(record, at), u32(record, at + 4)
    if low == nil or high == nil or (low == 0 and high == 0) then return nil end
    return string.format("0x%08x%08x", high, low)
  end

  local RECALL = { root = "window", head = "window", slot = "kept",
                   record = "kept", member = "kept" }

  function Instance:begin_window(mirrored)
    self.mirrored = mirrored == true
    if self.channel ~= nil then
      self.counters.channel_reads = self.channel.reads or 0
      self.counters.channel_read_failed = self.channel.read_failed or 0
    end
    if self.channel ~= nil then self.channel:rewind() end
    local memory = self.memory
    if memory == nil then
      memory = {}
      self.memory = memory
    end
    for kind, life in pairs(RECALL) do
      if life == "window" or memory[kind] == nil then memory[kind] = {} end
    end
  end

  local RECORD_AUDIT_EVERY = 64

  function Instance:recall(kind)
    local memory = self.memory
    return memory ~= nil and memory[kind] or nil
  end

  function Instance:audit_records()
    local held = self:recall("record")
    if held == nil then return end
    local channel, counters = self.channel, self.counters
    for by, seen in pairs(held) do
      for index, known in pairs(seen) do
        counters.record_checked = counters.record_checked + 1
        local at = self.game + by.at + index * by.stride
        if by.through == "pointer" then
          at = NativeMemory.pointer_at(channel, at)
        end
        local fresh = {}
        if at ~= nil and at ~= 0 then
          fill(channel, channel:read(at, by.span or by.stride), by.values, fresh)
        end
        for name, value in pairs(known) do
          if fresh[name] ~= value then
            counters.record_stale = counters.record_stale + 1
            break
          end
        end
        return
      end
    end
  end

  function Instance:audit_members()
    local member = self:recall("member")
    if member == nil then return end
    local counters = self.counters
    for entity_id, known in pairs(member) do
      for spec, heard in pairs(known) do
        if heard == false then
          local manager = spec.global ~= nil and self:global_at(spec.global) or nil
          if manager ~= nil then
            counters.member_checked = counters.member_checked + 1
            local index = self:lookup(manager + spec.map, entity_id)
            if index ~= nil and index ~= INVALID then
              counters.member_stale = counters.member_stale + 1
            end
          end
          return
        end
      end
    end
  end

  function Instance:root_at(at)
    local roots = self:recall("root")
    if roots == nil then return NativeMemory.pointer_at(self.channel, at) end
    local key = tonumber(self.channel.ffi.cast("uintptr_t", at))
    local got = roots[key]
    if got ~= nil then return got end
    local value = NativeMemory.pointer_at(self.channel, at)
    if value ~= nil then roots[key] = value end
    return value
  end

  function Instance:note_cell(at, ok)
    local seen = self.cells_seen
    if seen == nil then
      seen = {}
      self.cells_seen = seen
    end
    if ok then
      seen[at] = true
    elseif seen[at] == nil then
      seen[at] = false
    end
  end

  function Instance:global_at(rva)
    local value = self:root_at(self.game + rva)
    local seen = self.globals_seen
    if seen == nil then
      seen = {}
      self.globals_seen = seen
    end
    if value ~= nil then
      seen[rva] = true
    elseif seen[rva] == nil then
      seen[rva] = false
    end
    return value
  end

  function Instance:function_icon(value)
    local spec, channel = self.function_icons, self.channel
    if spec == nil or channel == nil then return nil end
    if type(value) ~= "number" or value < 0 or value >= spec.slots then
      return nil
    end
    local record
    if value == 0 then
      record = self.game + spec.empty_record
    else
      record = NativeMemory.pointer_at(channel, self.game + spec.at + value * 8)
    end
    if record == nil then return nil end
    local bytes = channel:read(record + spec.icon_at, 8)
    if bytes == nil then return nil end
    local low, high = u32(bytes, 0), u32(bytes, 4)
    if low == nil or high == nil or (low == 0 and high == 0) then return nil end
    return string.format("0x%08x%08x", high, low)
  end

  function Instance:ui_font()
    local spec = self.baked.ui_font
    if spec == nil or self.channel == nil then return nil end
    local font = NativeMemory.resource_at(self.channel, self.game + spec.font)
    local atlas = NativeMemory.resource_at(self.channel, self.game + spec.atlas)
    local owner = self:global_at(spec.material_owner)
    local material = owner ~= nil and
      NativeMemory.resource_at(self.channel, owner + spec.material_at) or nil
    return font, material, atlas
  end

  function Instance:deref(base, index)
    return NativeMemory.pointer_at(self.channel, base + index * 8)
  end

  function Instance:lookup(base, key)
    return NativeMemory.lookup(self.channel, self.map, base, key, self:recall("head"))
  end

  function Instance:chain_now()
    local channel, chain = self.channel, self.chain
    local players = self:global_at(chain.player_manager)
    if players == nil then return nil, "player-manager" end
    local unit = u32(channel:read(players + chain.local_unit, 4) or "", 0)
    if unit == nil or unit == 0x7fff then return nil, "local-unit" end
    local owner = self:global_at(chain.entity_owner)
    if owner == nil then return nil, "entity-owner" end
    local index = self:lookup(owner + chain.owner_map, unit)
    if index == nil or index == INVALID then return nil, "entity-index" end
    local at = owner + chain.owner_entities + index * chain.entity_stride
    local record = channel:read(at, chain.entity_stride)
    if record == nil then return nil, "entity" end
    local avatar_id = u32(record, chain.entity_id)
    local avatars = self:global_at(chain.avatar_manager)
    if avatars == nil then return nil, "avatar-manager" end
    local seat = self:lookup(avatars + chain.avatar_map, avatar_id)
    if seat == nil or seat == INVALID then return nil, "avatar-index" end
    local count = u32(channel:read(avatars + chain.avatar_count, 4) or "", 0)
    if count == nil or seat >= count then return nil, "avatar-range" end
    local controller = avatars + chain.avatar_controller +
                       seat * chain.controller_stride
    if u32(channel:read(controller + chain.identity, 4) or "", 0) ~= avatar_id then
      return nil, "controller-identity"
    end
    local state = self.avatar_state
    return { id = avatar_id, at = at, record = record,
             state_at = state ~= nil
               and avatars + state.at + seat * state.stride or nil }
  end

  function Instance:state_cells(state)
    local spec = self.avatar_state
    local cells, filled = {}, 0
    if spec ~= nil and state.state_at ~= nil then
      filled = fill(self.channel, self.channel:read(state.state_at, spec.stride),
                    spec.values, cells)
    end
    if filled == 0 then return nil end
    self.counters.cells_filled = self.counters.cells_filled + filled
    return cells
  end

  function Instance:state_slice(from, size)
    local spec = self.avatar_state
    if spec == nil then return nil, "no-state" end
    if type(from) ~= "number" or type(size) ~= "number" or from < 0 or
       size <= 0 or from + size > spec.stride then
      return nil, "range"
    end
    local channel, why = self:ready()
    if channel == nil then return nil, why end
    local state, fault = self:chain_now()
    if state == nil then return nil, fault end
    if state.state_at == nil then return nil, "no-state" end
    local bytes = channel:read(state.state_at + from, size)
    if bytes == nil then return nil, "read" end
    return bytes
  end

  function Instance:seats_of(avatar_id)
    local channel, equip = self.channel, self.equipment
    if equip == nil then return nil end
    local manager = self:global_at(equip.global)
    if manager == nil then return nil end
    local count = u32(channel:read(manager + equip.count, 4) or "", 0)
    local rows = channel:pointer(channel:read(manager + equip.rows, 8) or "")
    local back = channel:pointer(channel:read(manager + equip.backref, 8) or "")
    if count == nil or count == 0 or rows == nil or back == nil then
      return nil
    end
    local block = channel:read(rows, count * equip.stride)
    if block == nil then return nil end
    local slots = {}
    for index = 0, count - 1 do
      local base = index * equip.stride
      if u32(block, base + equip.owner) == avatar_id then
        local at = self:deref(back, index)
        local record = at ~= nil and
          channel:read(at, self.chain.entity_stride) or nil
        local id = record ~= nil and u32(record, self.chain.entity_id) or nil
        if id ~= nil and id ~= 0 and id ~= INVALID then
          local slot = u32(block, base + equip.slot)
          local seat = { entity = id, at = at, record = record }
          local held = slots[slot]
          if held ~= nil then
            self.counters.slot_contested = self.counters.slot_contested + 1
            local old_at, new_at = self:attached(held.entity), self:attached(id)
            if old_at == nil or new_at == nil then
              self.counters.slot_attach_unread = self.counters.slot_attach_unread + 1
            else
              local old_on, new_on = old_at ~= 0, new_at ~= 0
              if old_on and not new_on then
                seat = held
                self.counters.slot_attached_won = self.counters.slot_attached_won + 1
              elseif new_on and not old_on then
                self.counters.slot_attached_won = self.counters.slot_attached_won + 1
              end
            end
          end
          slots[slot] = seat
        end
      end
    end
    self.counters.swept = self.counters.swept + 1
    return slots
  end

  function Instance:component_row(spec, entity_id, size)
    local channel = self.channel
    local manager = self:global_at(spec.global)
    if manager == nil then return nil end
    local index = self:lookup(manager + spec.map, entity_id)
    if index == nil or index == INVALID then return nil end
    local rows = channel:pointer(channel:read(manager + spec.at, 8) or "")
    if rows == nil then return nil end
    return channel:read(rows + index * spec.stride, size or spec.stride)
  end

  function Instance:attached(entity_id)
    if self.attach == nil then return nil end
    return u32(self:component_row(self.attach, entity_id, 4) or "", 0)
  end

  function Instance:each_record(block_at, count, visit)
    local channel, stride = self.channel, self.chain.entity_stride
    local block = count > 0 and channel:read(block_at, count * 8) or nil
    for index = 0, (block ~= nil and count or 0) - 1 do
      local at = channel:pointer(block, index * 8)
      local record = at ~= nil and channel:read(at, stride) or nil
      if record ~= nil then
        local stop = visit(at, record)
        if stop then return stop end
      end
    end
    return nil
  end

  function Instance:entity_of(record)
    local id = u32(record, self.chain.entity_id)
    if id == nil or id == 0 or id == INVALID then return nil end
    return id
  end

  function Instance:record_of(entity_id)
    local channel, equip = self.channel, self.equipment
    if equip == nil then return nil end
    local manager = self:global_at(equip.global)
    if manager == nil then return nil end
    local index = self:lookup(manager + equip.map, entity_id)
    if index == nil or index == INVALID then return nil end
    local back = channel:pointer(channel:read(manager + equip.backref, 8) or "")
    if back == nil then return nil end
    local at = self:deref(back, index)
    local record = at ~= nil and channel:read(at, self.chain.entity_stride) or nil
    if record == nil or u32(record, self.chain.entity_id) ~= entity_id then
      return nil
    end
    return record, at
  end

  function Instance:record_by_unit(unit)
    local chain = self.chain
    local owner = self:global_at(chain.entity_owner)
    local index = owner ~= nil and self:lookup(owner + chain.owner_map, unit) or nil
    if index == nil or index == INVALID then return nil end
    local at = owner + chain.owner_entities + index * chain.entity_stride
    local record = self.channel:read(at, chain.entity_stride)
    local id = record ~= nil and u32(record, chain.entity_id) or nil
    if id == nil or id == 0 or id == INVALID then return nil end
    return id, at, record
  end

  function Instance:record_by_goid(relation, goid)
    local channel, chain = self.channel, self.chain
    for _, spec in ipairs(self.catalog) do
      local manager = spec.count ~= nil and self:global_at(spec.global) or nil
      local count = manager ~= nil and u32(channel:read(manager + spec.count, 4) or "", 0) or nil
      local back = manager ~= nil and
        channel:pointer(channel:read(manager + spec.backref, 8) or "") or nil
      local found = (count ~= nil and back ~= nil) and self:each_record(back, count,
        function(at, record)
          local id = u32(record, chain.goid_at) == goid and self:entity_of(record) or nil
          return id ~= nil and { id, at, record } or nil
        end) or nil
      if found ~= nil then return found[1], found[2], found[3] end
    end
    return nil
  end

  function Instance:record_via(relation, entity_id)
    local channel = self.channel
    for _, spec in ipairs(self.catalog) do
      local manager = spec.global ~= nil and self:global_at(spec.global) or nil
      local index = manager ~= nil and self:lookup(manager + spec.map, entity_id) or nil
      if index ~= nil and index ~= INVALID then
        local back = channel:pointer(channel:read(manager + spec.backref, 8) or "")
        local at = back ~= nil and self:deref(back, index) or nil
        local record = at ~= nil and channel:read(at, self.chain.entity_stride) or nil
        if record ~= nil and u32(record, self.chain.entity_id) == entity_id then
          return record, at
        end
      end
    end
    return nil
  end

  function Instance:book_fill(spec, key, cells, observed)
    local book, values = spec.registry, (spec.instance or {}).values
    if book == nil then return fill(self.channel, nil, values, cells, true, observed) end
    local wanting = false
    for name in pairs(values or {}) do
      if cells[name] == nil then wanting = true; break end
    end
    if not wanting then return 0 end
    local channel = self.channel
    local owner = self:global_at(self.chain.entity_owner)
    local table_at = owner ~= nil and self:root_at(owner + book.table) or nil
    if owner ~= nil then self:note_cell(book.table, table_at ~= nil) end
    local blob, status = NativeMemory.blob(channel, table_at, book, key)
    if blob == nil then
      if status == "absent" then
        self.counters.book_no_row = self.counters.book_no_row + 1
      else
        self.counters.book_unread = self.counters.book_unread + 1
      end
      return fill(channel, nil, values, cells, true, observed, status)
    end
    local row = channel:read(blob, book.size)
    if row == nil then self.counters.book_unread = self.counters.book_unread + 1 end
    local filled = fill(channel, row, values, cells, true, observed)
    self.counters.book_filled = self.counters.book_filled + filled
    return filled
  end

  function Instance:registry_cells(hash)
    local key = NativeMemory.key_of(hash)
    if key == nil then return nil end
    local cells, found = {}, false
    for _, spec in ipairs(self.catalog) do
      found = self:book_fill(spec, key, cells) > 0 or found
    end
    if not found then return nil end
    return cells
  end

  function Instance:cells_of(relation, entity_id, at, seed, mine)
    local channel = self.channel
    local cells, found, silenced = seed or {}, seed ~= nil, nil
    local observed = {}
    for name in pairs(cells) do observed[name] = "present" end
    local catalog = self.mirrored and self.mirrored_for[relation]
      or self.catalog_for[relation] or self.catalog
    self.counters.specs_walked = self.counters.specs_walked + #catalog
    local member = entity_id ~= nil and self:recall("member") or nil
    local known = nil
    if member ~= nil then
      known = member[entity_id]
      if known == nil then known = {}; member[entity_id] = known end
    end
    for _, spec in ipairs(catalog) do
      local manager = spec.global ~= nil and self:global_at(spec.global) or nil
      local index, membership = nil, "unread"
      if manager ~= nil then
        local heard = known ~= nil and known[spec] or nil
        if heard == false then
          membership = "absent"
        elseif heard ~= nil then
          index, membership = heard, "present"
        else
          index, membership = self:lookup(manager + spec.map, entity_id)
          if index == INVALID then membership = "absent" end
          if known ~= nil then
            if index ~= nil and index ~= INVALID then
              known[spec] = index
            elseif membership == "absent" then
              known[spec] = false
            end
          end
        end
        if index ~= nil and index ~= INVALID then
          for _, name in ipairs(spec.silences or {}) do
            silenced = silenced or {}
            silenced[name] = true
          end
          for cell, value in pairs(spec.ceiling or {}) do
            cells[cell] = value
            observe(observed, cell, "present")
            found = true
          end
          local back = self:root_at(manager + spec.backref)
          local pointer = back ~= nil and self:deref(back, index) or nil
          if (pointer == nil or channel:distance(pointer, at) ~= 0)
             and heard ~= nil and known ~= nil then
            self.counters.member_moved = self.counters.member_moved + 1
            known[spec] = nil
            index, membership = self:lookup(manager + spec.map, entity_id)
            if index == INVALID then index, membership = nil, "absent" end
            if index ~= nil then
              known[spec] = index
              back = self:root_at(manager + spec.backref)
              pointer = back ~= nil and self:deref(back, index) or nil
            else
              known[spec] = false
              pointer = nil
            end
          end
          if pointer == nil or channel:distance(pointer, at) ~= 0 then
            self.counters.backref_bad = self.counters.backref_bad + 1
            return nil
          end
          for _, array in ipairs(spec.arrays or {}) do
            local rows = self:root_at(manager + array.at)
            local row = rows ~= nil and
              channel:read(rows + index * array.stride, array.stride) or nil
            local filled = fill(channel, row, array.values, cells, false, observed)
            found = found or filled > 0
            self.counters.cells_filled = self.counters.cells_filled + filled
          end
        end
      end
      if membership ~= "present" then
        for _, array in ipairs(spec.arrays or {}) do
          fill(channel, nil, array.values, cells, true, observed, membership)
        end
      end
      local pool = spec.instance
      if pool ~= nil then
        local seat, status = nil, "absent"
        if pool.map ~= nil then
          status = "unread"
          if manager ~= nil then seat, status = self:lookup(manager + pool.map, entity_id) end
          if seat == INVALID then status = "absent" end
          if status == "absent" then
            self.counters.pool_no_seat = self.counters.pool_no_seat + 1
          elseif status == "unread" then
            self.counters.pool_map_unread = self.counters.pool_map_unread + 1
          end
        end
        if status == "absent" and at ~= nil then
          found = self:book_fill(spec, channel:read(at, 8), cells, observed) > 0 or found
        else
          local row = nil
          if status == "present" and membership == "present" then
            local rows = pool.at ~= nil and self:root_at(manager + pool.at) or nil
            if rows == nil then
              self.counters.pool_no_rows = self.counters.pool_no_rows + 1
            else
              row = channel:read(rows + seat * pool.stride, pool.stride)
              if row == nil then self.counters.pool_no_row = self.counters.pool_no_row + 1 end
            end
          end
          local filled = fill(channel, row, pool.values, cells, false, observed)
          found = found or filled > 0
          self.counters.cells_filled = self.counters.cells_filled + filled
        end
      end
    end
    if not found then
      self.counters.component_none = self.counters.component_none + 1
    end
    for name, parts in pairs(self.remaining) do
      local top, used = cells[parts[1]], cells[parts[2]]
      cells[parts[2]] = nil
      if type(top) == "number" and type(used) == "number" then
        local left = top - used
        if left < 0 then left = 0 end
        cells[name] = left
        found = true
      end
    end
    for name, rule in pairs(self.charged) do
      local base, add = cells[name], cells[rule.add]
      local per, times = cells[rule.per], cells[rule.times]
      cells[rule.add], cells[rule.per], cells[rule.times] = nil, nil, nil
      if type(base) == "number" and type(add) == "number" and
         type(per) == "number" and per > 0 and type(times) == "number" then
        cells[name] = base + add / per * times
      end
    end
    for name, rule in pairs(self.picks) do
      local index = cells[rule.by]
      if type(index) == "number" then
        if rule.slot ~= nil then index = math.floor(index / (4 ^ rule.slot)) % 4 end
        local part = rule.parts[index + 1]
        if part then cells[name] = cells[part] end
      end
    end
    for name, parts in pairs(self.counts) do
      local count, complete = 0, true
      for _, part in ipairs(parts) do
        local value = cells[part]
        if type(value) == "number" then
          if value > 0 then count = count + 1 end
        else
          complete = false
        end
      end
      cells[name] = nil
      if complete then cells[name] = count end
    end
    for name, part in pairs(self.nonzero) do
      local value = cells[part]
      if type(value) == "number" then cells[name] = value ~= 0 end
    end
    local spent = nil
    for name, rule in pairs(self.sums) do
      local chosen = cells[rule.by]
      if type(chosen) == "number" then
        local parts, same = rule.parts, rule.same
        local key = chosen
        if same ~= nil then key = cells[same[chosen + 1]] end
        local total = nil
        if key ~= nil then
          for index, part in ipairs(parts) do
            local kind = index - 1
            if same ~= nil then kind = cells[same[index]] end
            if kind == nil or (kind == key and type(cells[part]) ~= "number") then
              total = nil
              break
            end
            if kind == key then
              total = (total or 0) + cells[part]
            end
          end
        end
        spent = spent or {}
        for _, part in ipairs(parts) do spent[part] = true end
        for _, part in ipairs(same or {}) do spent[part] = true end
        cells[name] = total
      end
    end
    for part in pairs(spent or {}) do
      if self.sums[part] == nil then cells[part] = nil end
    end
    local holder_cell = self.adds_only_when_mine
    local holder = holder_cell ~= nil and cells[holder_cell] or nil
    local counts = mine == nil or holder == nil or holder == 0 or holder == mine
    local chamber = self.chamber
    if chamber ~= nil and counts then
      local uses = cells[chamber.uses]
      local loaded = cells[chamber.loaded]
      if uses ~= nil and uses ~= 0 and loaded ~= nil
          and cells[chamber.count] ~= nil then
        cells[chamber.count] = loaded ~= 0 and cells[chamber.count] + 1 or 0
      end
    end
    for name in pairs(silenced or {}) do
      if cells[name] ~= nil then
        cells[name] = nil
        self.counters.cells_silenced = self.counters.cells_silenced + 1
      end
    end
    if found then
      for name, parts in pairs(self.none_of) do
        local none, complete = true, true
        for _, part in ipairs(parts) do
          if cells[part] ~= nil then none = false; break end
          if observed[part] ~= "absent" then complete = false end
        end
        cells[name] = nil
        if not none or complete then cells[name] = none end
      end
    end
    return cells
  end

  function Instance:equipped(slots, slot)
    if slots == nil then
      self.counters.seat_missing = self.counters.seat_missing + 1
      return nil, nil, nil, "no-seats"
    end
    local seat = slots[slot]
    if seat == nil then
      self.counters.seat_missing = self.counters.seat_missing + 1
      return nil, nil, nil, "seat-missing"
    end
    local record, at = self:record_of(seat.entity)
    if record == nil then
      self.counters.record_failed = self.counters.record_failed + 1
      return nil, nil, nil, "record"
    end
    return seat.entity, at, record, nil
  end

  local function locate(arcs, frame)
    for index, arc in ipairs(arcs) do
      local played, total = nil, 0
      for k = 1, #arc, 2 do
        if played == nil and frame < arc[k + 1] then
          played = total + math.max(frame - arc[k], 0)
        end
        total = total + arc[k + 1] - arc[k]
      end
      if played ~= nil or index == #arcs then return index, played or total, total end
    end
    return nil
  end

  local function reload_route(route, chamber)
    if route.tactical ~= nil and chamber ~= nil then
      return chamber ~= 0 and "tactical" or "empty"
    end
    if route.only ~= nil then return "only" end
    return nil
  end

  local function route_step(path, index)
    if path == "tactical" or path == "only" then return path end
    if path == "empty" then return index > 1 and "chamber" or "empty" end
    return nil
  end

  function Instance:action_cells(out)
    local spec = self.action
    if spec == nil then return end
    local seat = out[spec.into]
    if seat == nil or not seat.entity then
      self.action_span = nil
      self.counters.action_no_seat = self.counters.action_no_seat + 1
      return
    end
    local runner = out[spec.from]
    local cells = runner ~= nil and runner.cells or nil
    local reads = spec.reads
    local ability = cells ~= nil and cells[reads.ability] or nil
    local time = cells ~= nil and cells[reads.time] or nil
    local running = cells ~= nil and cells[reads.running] or nil
    if ability == nil or time == nil or running == nil then
      self.action_span = nil
      self.counters.action_no_runner = self.counters.action_no_runner + 1
      return
    end
    local named = seat.cells[spec.reload]
    if running ~= 0 and named == nil then
      self.action_span = nil
      self.counters.action_no_reload = self.counters.action_no_reload + 1
      return
    end
    local route = spec.routes[ability]
    local open = running ~= 0 and ability == named and route ~= nil
    seat.cells[spec.cells.gate] = open
    if not open then
      self.action_span = nil
      return
    end
    self.counters.action_gate_open = self.counters.action_gate_open + 1
    local frame = time * spec.frames_per_second
    local span = self.action_span
    local same = span ~= nil and span.entity == seat.entity and span.ability == ability
    local rerun = not same or frame < span.frame
    if not same then
      local path = reload_route(route, seat.cells[spec.chamber])
      span = { entity = seat.entity, ability = ability, path = path,
               arcs = path ~= nil and route[path] or nil }
      self.action_span = span
    end
    span.frame = frame
    if span.arcs == nil then return end
    local index, played, total = locate(span.arcs, frame)
    if rerun or index ~= span.arc then
      span.arc, span.base = index, rerun and played or 0
    end
    seat.cells[spec.cells.step] = route_step(span.path, index)
    seat.cells[spec.cells.elapsed] = played - span.base
    seat.cells[spec.cells.length] = total - span.base
    self.counters.action_filled = self.counters.action_filled + 1
  end

  local function key_hex(bytes)
    if bytes == nil or NativeChannel.span(bytes) ~= 8 then return nil end
    local digits = {}
    for index = 7, 0, -1 do
      digits[#digits + 1] = string.format("%02x", NativeChannel.byte(bytes, index))
    end
    local text = table.concat(digits)
    if text == "0000000000000000" then return nil end
    return text
  end

  function Instance:roster_rows(marked)
    local spec = self.roster
    if spec == nil then return nil, "no-roster" end
    local channel, why = self:ready()
    if channel == nil then return nil, why end
    local manager = self:global_at(spec.at)
    if manager == nil then return nil, "roster" end
    local loadout = self:global_at(spec.rows.global)
    if loadout == nil then return nil, "loadout" end
    local seats = u32(channel:read(manager + spec.count, 4) or "", 0)
    if seats == nil then return nil, "roster-count" end
    local units = spec.unit_count ~= nil
      and u32(channel:read(manager + spec.unit_count, 4) or "", 0) or seats
    local out = {}
    local raw = { count = seats, unit_count = units }
    out.raw = raw
    for seat = 0, seats - 1 do
      local object = channel:pointer(
        channel:read(manager + spec.pointers + seat * spec.pointer_stride, 8) or "")
      local id = object ~= nil and
        u32(channel:read(object + spec.id, 4) or "", 0) or nil
      raw["raw_" .. seat] = object == nil and "no-ptr" or (id or "no-id")
      if id ~= nil and id ~= 0 and id ~= INVALID then
        local row = { seat = seat, id = id, cells = {} }
        row.unit = (units ~= nil and seat < units) and u32(channel:read(
          manager + spec.unit + seat * spec.unit_stride, 4) or "", 0) or nil
        local chain = self.chain
        local owner = self:global_at(chain.entity_owner)
        local index = (owner ~= nil and row.unit ~= nil and row.unit ~= INVALID)
          and self:lookup(owner + chain.owner_map, row.unit) or nil
        if index ~= nil and index ~= INVALID then
          local seat_at = owner + chain.owner_entities + index * chain.entity_stride
          local record = channel:read(seat_at, chain.entity_stride)
          local avatar_id = record ~= nil and u32(record, chain.entity_id) or nil
          if avatar_id ~= nil and avatar_id ~= 0 and avatar_id ~= INVALID then
            row.avatar = avatar_id
            local mark = marked ~= nil and marked[avatar_id] or nil
            if marked ~= nil then
              row.calls = mark ~= nil and mark.calls or {}
            end
            if mark ~= nil and mark.ping ~= nil then
              mark = mark.ping
              for name, from in pairs(spec.from_marker or {}) do
                local picture = mark[from]
                self:material_texture(picture)
                if picture ~= nil then
                  row.cells[name] = picture
                end
              end
            end
            row.cells = self:cells_of("roster", avatar_id, seat_at, row.cells)
              or row.cells
          end
        end
        for name, from in pairs(spec.at_most_zero or {}) do
          local value = row.cells[from]
          if type(value) == "number" then row.cells[name] = value <= 0 end
        end
        local index = self:lookup(loadout + spec.rows.map, id)
        if index ~= nil and index ~= INVALID then
          fill(channel, channel:read(loadout + spec.rows.at + index * spec.rows.stride,
                                     spec.rows.stride), spec.rows.values, row.cells)
        end
        open_value_rows(channel, self.game, spec.value_rows, row.cells, false,
                        self:recall("record"))
        out[#out + 1] = row
      end
    end
    if #out == 0 then return nil, "empty" end
    return out
  end

  function Instance:seat_cells(out, marked)
    local seat_of = {}
    local wanted = self.stratagem_slots ~= nil
    for _, source in pairs(self.relations) do
      if source.from == "hud_squad" or source.from == "hud_subject" then wanted = true end
    end
    if not wanted then return nil end
    local roster = self:roster_rows(marked)
    local rows = self:hud_squad_rows()
    if roster == nil or rows == nil then return end
    local by_id, seated, ids, subject = {}, {}, {}, nil
    local mirror = {}
    for _, row in ipairs(roster) do
      by_id[row.id] = row
      ids[#ids + 1] = row.seat
      local head = row.seat .. "_"
      mirror[head .. "id"] = row.id
      mirror[head .. "unit"] = row.unit
      mirror[head .. "avatar"] = row.avatar or false
    end
    for name, value in pairs(roster.raw or {}) do
      mirror[name] = value
    end
    out.roster = { cells = mirror, entity = "table" }
    for _, id in ipairs(rows) do
      if id then seated[id] = true end
    end
    for _, row in ipairs(roster) do
      if not seated[row.id] then
        if subject == nil then subject = row else subject = false end
      end
    end
    if not subject then
      self.counters.subject_unsettled = self.counters.subject_unsettled + 1
    end
    for relation, source in pairs(self.relations) do
      if source.from == "hud_squad" or source.from == "hud_subject" then
        local row
        if source.from == "hud_subject" then
          row = subject or nil
        else
          local id = rows[source.seat]
          row = id and by_id[id] or false
        end
        if row then
          out[relation] = { cells = row.cells, entity = row.id }
          seat_of[relation] = { seat = row.seat, calls = row.calls }
          self.counters.relations_filled = self.counters.relations_filled + 1
        elseif row == false then
          out[relation] = { cells = {}, entity = false }
          self.counters.relations_empty = self.counters.relations_empty + 1
        end
      end
    end
    return ids, subject and subject.seat or nil, seat_of
  end

  function Instance:session_state()
    local spec = self.session
    if spec == nil then return nil end
    local channel = self:ready()
    if channel == nil then return nil end
    local base = self:global_at(spec.global)
    if base == nil then return nil end
    local bytes = channel:read(base + spec.id, 8)
    if bytes == nil then return nil end
    return key_hex(bytes) or false
  end

  function Instance:hud_squad_rows()
    local spec, channel = self.hud_squad, self.channel
    if spec == nil or channel == nil then return nil end
    local manager = self:global_at(spec.at)
    if manager == nil then return nil end
    local function field(at, where)
      local bytes = channel:read(at + where[1], WIDTH[where[2]])
      return bytes ~= nil and decode(channel, bytes, { 0, where[2], where[3] }) or nil
    end
    local first = manager + spec.mission_hud + spec.panel + spec.first
    local out = {}
    for index = 1, spec.count do
      local at = first + (index - 1) * spec.stride
      local filled = field(at, spec.values.filled)
      if filled == nil then return nil end
      if filled == 1 then
        local id = field(at, spec.values.player)
        if id == nil then return nil end
        out[index] = id
      else
        out[index] = false
      end
    end
    return out
  end

  function Instance:tap_cells(base, values, cells)
    local channel = self.channel
    if base == nil or channel == nil then return end
    for name, where in pairs(values) do
      local bytes = channel:read(base + where[1], WIDTH[where[2]])
      if bytes ~= nil then
        cells[name] = decode(channel, bytes, { 0, where[2], where[3] })
      end
    end
  end

  function Instance:hud_gate_cells(out)
    local spec = self.hud_gate
    if spec == nil then return end
    if self:ready() == nil then return end
    local cells = {}
    local manager = self:global_at(spec.at)
    self:tap_cells(manager ~= nil and manager + spec.mission_hud or nil,
                   spec.values, cells)
    if manager ~= nil then
      self:note_cell(spec.mission_hud, next(cells) ~= nil)
    end
    if next(cells) ~= nil then
      out.hud_gate = { cells = cells, entity = "gate" }
    end
  end

  function Instance:hud_override_cells(out)
    local spec = self.hud_override
    if spec == nil or self.channel == nil then return end
    local cells = {}
    self:tap_cells(self:global_at(spec.global), spec.values, cells)
    if next(cells) ~= nil then
      out.hud_override = { cells = cells, entity = "override" }
    end
  end

  function Instance:hud_target_cells(out)
    local spec = self.hud_target
    if spec == nil or self.channel == nil then return end
    local manager = self:global_at(spec.at)
    if manager == nil then return end
    local cells = {}
    self:tap_cells(manager + spec.mission_hud + spec.panel, spec.values, cells)
    if next(cells) ~= nil then
      out.hud_target = { cells = cells, entity = "panel" }
    end
  end

  function Instance:hud_boxes()
    local spec = self.hud_widgets
    if spec == nil then return nil end
    local channel, why = self:ready()
    if channel == nil then return nil, why end
    local raw = channel:read(self.game + spec.at, 8)
    local manager = raw ~= nil and channel:pointer(raw) or nil
    if manager == nil then
      self.counters.widgets_no_manager = self.counters.widgets_no_manager + 1
      return nil, "hud-manager"
    end
    local bases = { manager, manager + spec.mission_hud }
    local fields, out, filled = spec.fields, nil, 0

    local function box(base, at)
      local row = channel:read(base + at, self.widget_span or 0x100)
      if row == nil then return nil end
      local x = decode(channel, row, fields.screen_x)
      local y = decode(channel, row, fields.screen_y)
      local w = decode(channel, row, fields.size_x)
      local h = decode(channel, row, fields.size_y)
      local scale = decode(channel, row, fields.screen_scale)
      local shown = decode(channel, row, fields.shown)
      if x == nil or y == nil or scale == nil or shown == nil then return nil end
      return { x = x, y = y, scale = scale, shown = shown,
               w = w ~= nil and w * scale or nil,
               h = h ~= nil and h * scale or nil }
    end

    for name, row in pairs(spec.widgets or {}) do
      local value = box(bases[row.base + 1], row.at)
      if value ~= nil then
        out = out or {}
        out[name] = value
        filled = filled + 1
      end
    end
    for name, row in pairs(spec.rows or {}) do
      for index = 1, row.count do
        local value = box(bases[row.base + 1],
                          row.first + (index - 1) * row.stride + row.at)
        if value ~= nil then
          out = out or {}
          out[name .. "#" .. index] = value
          filled = filled + 1
        end
      end
    end
    if filled == 0 then
      self.counters.widgets_unread = self.counters.widgets_unread + 1
      return nil, "no-box"
    end
    self.counters.widgets_read = self.counters.widgets_read + 1
    return out
  end

  function Instance:door_memory()
    if self.door_tools ~= nil then return self.door_tools end
    local channel = self:ready()
    if channel == nil then return nil end
    local game, layout, counters = self.game, self.map, self.counters
    local counted = { ffi = channel.ffi }
    function counted:read(address, size)
      counters.door_reads = counters.door_reads + 1
      counters.door_bytes = counters.door_bytes + (size or 0)
      return channel:read(address, size)
    end
    function counted:pointer(bytes, offset)
      return channel:pointer(bytes, offset)
    end
    local function through(fn, ...)
      local was = self.channel
      self.channel = counted
      local packed = { pcall(fn, ...) }
      self.channel = was
      if not packed[1] then error(packed[2], 0) end
      return unpack(packed, 2)
    end
    self.door_tools = {
      game_pin = self.baked.pin.game,
      read = function(address, size) return counted:read(address, size) end,
      pointer = function(bytes, offset) return channel:pointer(bytes, offset) end,
      global = function(rva) return NativeMemory.pointer_at(counted, game + rva) end,
      decode = function(bytes, where) return decode(channel, bytes, where) end,
      lookup = function(base, key, map)
        return NativeMemory.lookup(counted, map or layout, base, key)
      end,
      fields = function(bytes, values)
        local cells = {}
        fill(channel, bytes, values, cells)
        return cells
      end,
      entities = function(block_at, count)
        local out = {}
        through(function()
          self:each_record(block_at, count, function(_, record)
            out[#out + 1] = { entity = self:entity_of(record) or false,
                              resource = decode(channel, record, { 0, "hash64" }) }
          end)
        end)
        return out
      end,
      row = function(spec, entity_id)
        local bytes = through(function() return self:component_row(spec, entity_id) end)
        if bytes == nil then return nil end
        local cells = {}
        fill(channel, bytes, spec.values, cells)
        return cells
      end,
    }
    return self.door_tools
  end

  function Instance:resource_at(type_high, type_low, high, low)
    local spec, channel = self.resource_index, self.channel
    if spec == nil or self.exe == nil then return nil end
    local TYPE_STRIDE = 0xd0
    local ROW_STRIDE, ROW_SLOT, ROW_NEXT, BLOCK_STRIDE = 24, 8, 0x10, 0xa0
    local CHAIN_END, EMPTY_SLOT = 0x7fffffff, 0xfffffffe
    local owner = NativeMemory.pointer_at(channel, self.exe + spec.global)
    owner = owner ~= nil and NativeMemory.pointer_at(channel, owner + spec.owner) or nil
    if owner == nil then return nil end
    local types, rows = spec.types, spec.rows
    local head = owner + types.at
    local count = u32(channel:read(head + types.count, 4) or "", 0)
    local buckets = u32(channel:read(head + types.buckets, 4) or "", 0)
    local array = NativeMemory.pointer_at(channel, head + types.array)
    if array == nil or count == nil or buckets == nil or buckets < 1 then
      return nil
    end
    self.counters.resource_types = count
    local index, guard, table_at = type_high % buckets, 0, nil
    while index ~= nil and index ~= CHAIN_END and guard <= buckets do
      local at = array + index * TYPE_STRIDE
      local entry = channel:read(at, 8)
      if entry == nil then break end
      if u32(entry, 0) == type_low and u32(entry, 4) == type_high then
        table_at = at
        break
      end
      index = u32(channel:read(at + 0xc8, 4) or "", 0)
      guard = guard + 1
    end
    if table_at == nil then return nil end
    local rows_count = u32(channel:read(table_at + rows.count, 4) or "", 0)
    local rows_buckets = u32(channel:read(table_at + rows.buckets, 4) or "", 0)
    local rows_array = NativeMemory.pointer_at(channel, table_at + rows.array)
    if rows_array == nil or rows_count == nil or rows_count < 1
       or rows_buckets == nil or rows_buckets < 1 then
      return nil
    end
    self.counters.resource_rows = rows_count
    index, guard = high % rows_buckets, 0
    if u32(channel:read(rows_array + index * ROW_STRIDE + ROW_NEXT, 4) or "", 0)
       == EMPTY_SLOT then
      return nil
    end
    while index ~= nil and index ~= CHAIN_END and guard <= rows_buckets do
      local at = rows_array + index * ROW_STRIDE
      local entry = channel:read(at, 8)
      if entry == nil then break end
      if u32(entry, 0) == low and u32(entry, 4) == high then
        local slot = u32(channel:read(at + ROW_SLOT, 4) or "", 0)
        local blocks = NativeMemory.pointer_at(channel, table_at + rows.blocks)
        if slot == nil or blocks == nil then return nil end
        return NativeMemory.pointer_at(channel, blocks + slot * BLOCK_STRIDE)
      end
      index = u32(channel:read(at + ROW_NEXT, 4) or "", 0)
      guard = guard + 1
    end
    return nil
  end

  function Instance:material_texture(material)
    if type(material) ~= "string" or #material ~= 18 then return nil end
    self.counters.material_asked = self.counters.material_asked + 1
    local got = self.material_textures[material]
    if got ~= nil then return got end
    if self.resource_index == nil then return nil end
    local high = tonumber(string.sub(material, 3, 10), 16)
    local low = tonumber(string.sub(material, 11, 18), 16)
    if high == nil or low == nil then return nil end
    local at = self:resource_at(MATERIAL_HIGH, MATERIAL_LOW, high, low)
    if at == nil then
      self.counters.material_unopened = self.counters.material_unopened + 1
      return nil
    end
    local raw = self.channel:read(at + MATERIAL_TEXTURE_AT, 8) or ""
    local texture_low, texture_high = u32(raw, 0), u32(raw, 4)
    if texture_low == nil or texture_high == nil
       or (texture_low == 0 and texture_high == 0) then
      self.counters.material_no_texture = self.counters.material_no_texture + 1
      return nil
    end
    local texture = string.format("0x%08x%08x", texture_high, texture_low)
    self.material_textures[material] = texture
    self.counters.material_opened = self.counters.material_opened + 1
    return texture
  end

  function Instance:atlas_cells(out)
    local STRIDE, CHAIN_END, EMPTY = 24, 0x7fffffff, 0xfffffffe
    local PAGE_AT, WIDE_AT, TALL_AT = 8, 16, 20
    local UV_AT = { u = 24, v = 28, du = 32, dv = 36 }
    local PROBES = { { "", "ec9fe98c340b4a26" }, { "s_", "000282e39c439044" } }
    local spec, channel = self.atlas_index, self.channel
    if spec == nil or self.exe == nil then return end
    local owner = NativeMemory.pointer_at(channel, self.exe + spec.global)
    if owner == nil then self.atlas_at = nil; return end
    local table_key = channel:read(owner + spec.owner, 8)
    local table_at = channel:pointer(table_key or "")
    if table_at == nil then self.atlas_at = nil; return end
    local cells = {}
    local count = u32(channel:read(table_at + spec.count, 4) or "", 0)
    local buckets = u32(channel:read(table_at + spec.buckets, 4) or "", 0)
    cells.count, cells.buckets = count, buckets
    local levels = spec.levels
    if levels ~= nil then
      local at = NativeMemory.pointer_at(channel, owner + levels.owner)
      at = at ~= nil and NativeMemory.pointer_at(channel, at + levels.table) or nil
      if at ~= nil then
        cells.levels_count = u32(channel:read(at + levels.count, 4) or "", 0)
        cells.levels_buckets = u32(channel:read(at + levels.buckets, 4) or "", 0)
      end
    end
    local array_key = channel:read(table_at + spec.array, 8)
    local array = channel:pointer(array_key or "")
    local entries, decoded = {}, {}
    local function entry_at(index)
      if entries[index] == nil then
        entries[index] = channel:read(array + index * STRIDE, STRIDE) or false
      end
      return entries[index] or nil
    end
    local function cell_at(index, entry)
      if decoded[index] ~= nil then return decoded[index] or nil end
      decoded[index] = false
      local row = channel:pointer(entry, 8)
      local blob = row ~= nil and channel:read(row, 40) or nil
      if blob == nil or u32(blob, 0) ~= u32(entry, 0) or
         u32(blob, 4) ~= u32(entry, 4) then return nil end
      local page = Core.resource_of(blob, PAGE_AT)
      if page == nil then return nil end
      local wide, tall = u32(blob, WIDE_AT), u32(blob, TALL_AT)
      local cell = { page = page:sub(3), width = wide, height = tall,
                     aspect = tall ~= nil and tall > 0 and wide / tall or nil }
      for _, name in ipairs({ "u", "v", "du", "dv" }) do
        cell[name] = decode(channel, blob, { UV_AT[name], "f32" })
        if cell[name] == nil then return nil end
      end
      decoded[index] = cell
      return cell
    end
    if array ~= nil and count ~= nil and count > 0 and buckets ~= nil and buckets > 0 then
      for _, probe in ipairs(PROBES) do
        local tag, key = probe[1], probe[2]
        local high = tonumber(key:sub(1, 8), 16)
        local low = tonumber(key:sub(9, 16), 16)
        if high ~= nil and low ~= nil then
          local index, visited, steps = high % buckets, {}, 0
          while index ~= nil and index ~= CHAIN_END and not visited[index] and steps < count do
            visited[index] = true
            steps = steps + 1
            local entry = entry_at(index)
            if entry == nil then break end
            if u32(entry, 16) == EMPTY then break end
            if u32(entry, 0) == low and u32(entry, 4) == high then
              local cell = cell_at(index, entry)
              if cell ~= nil then
                cells[tag .. "page"] = "0x" .. cell.page
                for _, name in ipairs({ "width", "height", "u", "v", "du", "dv" }) do
                  cells[tag .. name] = cell[name]
                end
              end
              break
            end
            index = u32(entry, 16)
          end
        end
      end
    end
    local previous = self.atlas_at
    local owner_key, array_hex = NativeMemory.hex(table_key), NativeMemory.hex(array_key)
    local reusable = previous ~= nil and previous.count == count and
      previous.buckets == buckets and previous.owner == owner_key and
      previous.array == array_hex
    local readable = count ~= nil and buckets ~= nil and
      (count == 0 or (array ~= nil and buckets > 0))
    if not readable then self.atlas_at = nil end
    if readable and not reusable then
      local rows, seen, visited, complete, populated = {}, 0, {}, true, 0
      local kept = self.atlas_rows
      for bucket = 0, (count > 0 and buckets or 0) - 1 do
        if populated > count then break end
        local cursor, walking = bucket, {}
        while cursor ~= CHAIN_END do
          if cursor == nil or walking[cursor] then complete = false; break end
          if visited[cursor] then break end
          visited[cursor], walking[cursor] = true, true
          local entry = entry_at(cursor)
          if entry == nil then complete = false; break end
          local next_at = u32(entry, 16)
          if next_at == EMPTY then break end
          populated = populated + 1
          if populated > count then complete = false; break end
          local low, high = u32(entry, 0), u32(entry, 4)
          if low ~= nil and high ~= nil and (low ~= 0 or high ~= 0) then
            local key = string.format("0x%08x%08x", high, low)
            if rows[key] == nil then
              local cell = cell_at(cursor, entry)
              if cell ~= nil then
                rows[key] = cell
                seen = seen + 1
              else
                complete = false
              end
            end
          else
            complete = false
          end
          cursor = next_at
        end
      end
      if kept ~= nil then
        for key, row in pairs(kept) do
          if rows[key] == nil then rows[key] = row end
        end
      end
      complete = complete and seen == count and
        NativeMemory.hex(channel:read(owner + spec.owner, 8)) == owner_key and
        NativeMemory.hex(channel:read(table_at + spec.array, 8)) == array_hex and
        u32(channel:read(table_at + spec.count, 4) or "", 0) == count and
        u32(channel:read(table_at + spec.buckets, 4) or "", 0) == buckets
      self.atlas_rows = rows
      self.atlas_at = complete and { owner = owner_key, array = array_hex,
                                    count = count, buckets = buckets } or nil
      self.counters.atlas_rows = seen
    end
    cells.rows = self.counters.atlas_rows
    cells.complete = self.atlas_at ~= nil
    cells.cached = readable and reusable
    cells.res_types = self.counters.resource_types
    cells.res_rows = self.counters.resource_rows
    out.atlas_index = { cells = cells, entity = "table", rows = self.atlas_rows,
                        textures = self.material_textures }
  end

  function Instance:latched_span(record, due, left)
    local spans = self.stratagem_spans
    if spans == nil then spans = {}; self.stratagem_spans = spans end
    local by_due = spans[record]
    if by_due == nil then by_due = {}; spans[record] = by_due end
    local most = by_due[due]
    if most == nil or most < left then most = left; by_due[due] = left end
    return most
  end

  function Instance:expire_spans(now)
    local spans = self.stratagem_spans
    if spans == nil or type(now) ~= "number" then return end
    for record, by_due in pairs(spans) do
      for due in pairs(by_due) do
        if due <= now then by_due[due] = nil end
      end
      if next(by_due) == nil then spans[record] = nil end
    end
  end

  function Instance:row_fill(rows, one, now)
    local phase, due = nil, nil
    if type(now) == "number" then
      if type(one.call_due) == "number" and one.call_due > now then
        phase, due = "call", one.call_due
      elseif type(one.reuse_due) == "number" and one.reuse_due > now then
        phase, due = "reuse", one.reuse_due
      end
    end
    local left = due ~= nil and due - now or nil
    local ready = rows.ready
    local names = ready ~= nil and phase ~= nil and ready[phase] or nil
    if names ~= nil and names.unless ~= nil and one[names.unless] then
      names = nil
    end
    if names == nil or one.record == nil then return nil, nil end
    local span = self:latched_span(one.record, due, left)
    if names.left ~= nil then one[names.left] = left / 1000000 end
    if names.done ~= nil then one[names.done] = (span - left) / 1000000 end
    one[names.span] = span / 1000000
    local near = names.near
    if near ~= nil and left <= near.at * 1000000 then
      one[near.cell] = math.ceil(left / 1000000)
    end
    return phase, span
  end

  function Instance:stratagem_stacks(rows, now, seat_rows, seat_of)
    local stacks = {}
    local call = (rows.ready or {}).call
    for relation, at in pairs(seat_of) do
      local flying = {}
      for _, one in ipairs(seat_rows[at.seat] or {}) do
        local phase = self:row_fill(rows, one, now)
        if phase == "call" and one.picture ~= nil then flying[one.picture] = one end
      end
      local held = at.calls
      local cap = self.stack_ranks[relation]
      if held ~= nil and cap ~= nil then
        for _, mark in ipairs(held) do
          local one = flying[mark.picture]
          if one ~= nil then
            mark[call.span] = one[call.span]
            if call.left ~= nil then mark[call.left] = one[call.left] end
            if call.done ~= nil then mark[call.done] = one[call.done] end
          end
        end
        if #held > cap then
          self.counters.stack_over = self.counters.stack_over + (#held - cap)
        end
        stacks[relation] = held
      end
    end
    return stacks
  end

  function Instance:stratagem_fills(rows, cells, picks, seat_rows, seat_of)
    local now = cells.now
    self:expire_spans(now)
    for _, one in ipairs(picks or {}) do
      self:row_fill(rows, one, now)
    end
    return self:stratagem_stacks(rows, now, seat_rows, seat_of or {})
  end

  function Instance:stratagem_relations(out, picks, stacks)
    for relation, source in pairs(self.relations) do
      local one, said = nil, false
      if source.from == "stratagem_pick" and picks ~= nil then
        one, said = picks[source.pick], true
      elseif source.from == "stratagem_call" then
        local held = stacks ~= nil and stacks[source.of] or nil
        if held ~= nil then one, said = held[source.rank], true end
      end
      if said then
        if one ~= nil then
          out[relation] = { cells = one, entity = "row" }
          self.counters.relations_filled = self.counters.relations_filled + 1
        else
          out[relation] = { cells = {}, entity = false }
          self.counters.relations_empty = self.counters.relations_empty + 1
        end
      end
    end
  end

  function Instance:stratagem_cells(out, seats, subject, seat_of)
    local spec = self.stratagem_slots
    if spec == nil or seats == nil then return end
    local channel = self.channel
    local base = self:global_at(spec.global)
    if base == nil then return end
    local total = u32(channel:read(base + spec.count, 4) or "", 0)
    if total == nil then return end
    local cells = { rows = total }
    local clock = spec.clock ~= nil and self:global_at(spec.clock.global) or nil
    if clock ~= nil then
      cells.now = decode(channel, channel:read(clock + spec.clock.at, 8) or "",
                         { 0, "u64" })
    end
    local shared = spec.shared
    if shared ~= nil then
      local at = self:global_at(shared.global)
      if at ~= nil then
        cells.shared_live = u32(channel:read(at + shared.live, 4) or "", 0)
        cells.shared_due = decode(channel, channel:read(at + shared.due, 8) or "",
                                  { 0, "hash64" })
      end
    end
    local rows, from = spec.rows, spec.key_from
    local picks, seat_rows = nil, {}
    local manager = from ~= nil and self:global_at(from.of) or nil
    if manager == nil then return end
    local known = self:recall("slot")
    for _, seat in ipairs(seats) do
      local key = channel:read(manager + from.at + seat * from.stride, 8)
      local at = nil
      local heard = known ~= nil and known[seat] or nil
      if key ~= nil and heard ~= nil and
         NativeChannel.same(channel:read(base + heard * spec.stride + spec.key, 8),
                            key) then
        at = base + spec.at + heard * spec.stride
      end
      if key ~= nil and at == nil then
        for index = 0, total - 1 do
          local seek = base + index * spec.stride
          if NativeChannel.same(channel:read(seek + spec.key, 8), key) then
            at = base + spec.at + index * spec.stride
            if known ~= nil then known[seat] = index end
            break
          end
        end
      end
      if at ~= nil then
        local slots = u32(channel:read(at + rows.count, 4) or "", 0)
        cells[seat .. "_slots"] = slots
        local pick = rows.pick
        local picked = (pick ~= nil and seat == subject) and {} or nil
        if picked ~= nil then picks = picked end
        local held = {}
        seat_rows[seat] = held
        for slot = 0, math.min(slots or 0, rows.slots) - 1 do
          fill(channel, channel:read(at + rows.at + slot * rows.stride, rows.stride),
               rows.values, cells, false, nil, nil)
          open_value_rows(channel, self.game, rows.value_rows, cells, true,
                          self:recall("record"))
          local one = row_of(rows, cells)
          local spent = rows.spent
          if spent ~= nil and one[spent.from] == 0 then one[spent.cell] = true end
          held[#held + 1] = one
          if picked ~= nil and one[pick.cell] == pick.is then
            picked[#picked + 1] = one
          end
          local head = seat .. "_" .. slot .. "_"
          for name, value in pairs(one) do
            cells[head .. name] = value
            cells[name] = nil
          end
        end
      end
    end
    out.stratagem_slots = { cells = cells, entity = "table" }
    local stacks = self:stratagem_fills(rows, cells, picks, seat_rows, seat_of)
    self:stratagem_relations(out, picks, stacks)

  end

  function Instance:comms_cells(out)
    local spec = self.comms
    if spec == nil then return end
    local channel = self.channel
    local list = self:global_at(spec.global)
    if list == nil then return end
    local head = channel:read(list + spec.first, 4)
    local tail = channel:read(list + spec.last, 4)
    local first = head ~= nil and u32(head, 0) or nil
    local last = tail ~= nil and u32(tail, 0) or nil
    if first == nil or last == nil then return end
    local cells = { first = first, last = last }
    local by_owner = {}
    local index, seen = first, 0
    while index ~= last and seen < spec.slots do
      local row = channel:read(list + spec.at + index * spec.stride, spec.stride)
      if row == nil then break end
      local one = {}
      fill(channel, row, spec.values, one)
      for name, value in pairs(one) do
        cells[index .. "_" .. name] = value
      end
      if one.owner ~= nil and one.elapsed ~= nil and one.lifetime ~= nil
          and one.elapsed < one.lifetime then
        local held = by_owner[one.owner]
        if held == nil then
          held = { calls = {} }
          by_owner[one.owner] = held
        end
        if spec.call_kind ~= nil and one.kind == spec.call_kind then
          held.calls[#held.calls + 1] = one
        else
          held.ping = one
        end
      end
      seen = seen + 1
      index = index + 1
      if index >= spec.slots then index = 0 end
    end
    out.comms = { cells = cells, entity = "list" }
    return by_owner
  end

  function Instance:forget_span()
    self.action_span = nil
  end

  function Instance:window(out)
    self.counters.windows = self.counters.windows + 1
    local channel, why = self:ready()
    if channel == nil then return nil, why end
    out = out or {}
    if out.hud_gate == nil then self:hud_gate_cells(out) end
    local seats, subject, seat_of = self:seat_cells(out, self:comms_cells(out))
    self:stratagem_cells(out, seats, subject, seat_of)
    self:atlas_cells(out)
    self:hud_override_cells(out)
    self:hud_target_cells(out)
    local state, fault = self:chain_now()
    if state == nil then
      self.action_span = nil
      self.counters.chain_failed = self.counters.chain_failed + 1
      if next(out) == nil then return nil, fault end
      return out, fault
    end
    self.counters.chain_read = self.counters.chain_read + 1
    local slots = nil
    if self.slot_seats then slots = self:seats_of(state.id) end
    local function fill(relation, entity, at, seed, record)
      if entity == nil then
        self.counters.relations_empty = self.counters.relations_empty + 1
        return
      end
      local cells = self:cells_of(relation, entity, at, seed, state.id)
      if cells ~= nil then
        if record == nil and at ~= nil then
          record = self.channel:read(at, 8)
        end
        out[relation] = { cells = cells, entity = entity,
                          resource = Core.resource_of(record) }
        if out[relation].resource == nil then
          self.counters.resource_unread = self.counters.resource_unread + 1
        end
        self.counters.relations_filled = self.counters.relations_filled + 1
      end
    end
    for relation, source in pairs(self.relations) do
      if source.from == "avatar" then
        fill(relation, state.id, state.at, self:state_cells(state))
      elseif source.from == "slot" then
        local entity, at, record, why = self:equipped(slots, source.slot)
        if entity == nil and why == "seat-missing" then
          out[relation] = { cells = {}, entity = false }
          self.counters.relations_empty = self.counters.relations_empty + 1
        else
          fill(relation, entity, at, nil, record)
        end
      end
    end
    local pending = {}
    for relation, source in pairs(self.relations) do
      if source.from == "linked" or source.from == "resource" then
        pending[relation] = source
      end
    end
    local moved = true
    while moved do
      moved = false
      for relation, source in pairs(pending) do
        local host = out[source.of]
        if host ~= nil or pending[source.of] == nil then
          pending[relation], moved = nil, true
          local id = host ~= nil and host.cells[source.cell] or nil
          if source.from == "resource" then
            local cells = id ~= nil and self:registry_cells(id) or nil
            if cells == nil then
              if host ~= nil and host.entity == false then
                out[relation] = { cells = {}, entity = false }
              end
              self.counters.relations_empty = self.counters.relations_empty + 1
            else
              out[relation] = { cells = cells, entity = id,
                                resource = (string.gsub(id, "^0x", "")) }
              self.counters.relations_filled = self.counters.relations_filled + 1
            end
          else
            local vacant = host ~= nil and host.entity == false
            if id == 0 or id == INVALID or id == NO_OBJECT then
              vacant, id = true, nil
            end
            if id == nil then
              if vacant then out[relation] = { cells = {}, entity = false } end
              self.counters.relations_empty = self.counters.relations_empty + 1
            elseif source.key == "unit" then
              local entity, at, record = self:record_by_unit(id)
              if entity == nil then
                self.counters.unit_unresolved = self.counters.unit_unresolved + 1
              else
                fill(relation, entity, at, nil, record)
              end
            elseif source.key == "goid" then
              local entity, at, record = self:record_by_goid(relation, id)
              if entity == nil then
                self.counters.goid_unresolved = self.counters.goid_unresolved + 1
              else
                fill(relation, entity, at, nil, record)
              end
            else
              local record, at = self:record_of(id)
              if record == nil then record, at = self:record_via(relation, id) end
              if record == nil then
                self.counters.record_failed = self.counters.record_failed + 1
              else
                fill(relation, id, at, nil, record)
              end
            end
          end
        end
      end
    end
    for relation, source in pairs(self.relations) do
      if source.from == "first" then
        local barred = source.unless
        local vacant = nil
        for _, name in ipairs(source.of) do
          local seat = out[name]
          if seat ~= nil and barred ~= nil and seat.cells[barred] ~= nil then
            self.counters.seat_barred = self.counters.seat_barred + 1
            seat = { cells = {}, entity = false }
          end
          if seat ~= nil and seat.entity then
            out[relation] = seat
            vacant = nil
            break
          end
          if seat ~= nil and seat.entity == false then vacant = vacant or seat end
        end
        if out[relation] == nil and vacant ~= nil then out[relation] = vacant end
      end
    end
    self:action_cells(out)
    for _, row in ipairs(self.wired or {}) do
      local host, into, against = out[row.of], out[row.into], out[row.against]
      local id = host ~= nil and host.cells[row.cell] or nil
      if into ~= nil and host ~= nil and against ~= nil then
        local same
        if row.match == "resource" then
          same = (id ~= nil and id == against.resource)
        else
          same = (id ~= nil and id == against.entity)
        end
        into.cells[row.as] = same
        if same then
          self.counters.wired_pairs = self.counters.wired_pairs + 1
        end
      end
    end
    if self.counters.windows % RECORD_AUDIT_EVERY == 0 then
      self:audit_records()
      self:audit_members()
    end
    return out, nil
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return NativeRead end)
if not __contract_ok_1 or __contract_export_1 == nil then error("18-native-read: missing export NativeRead", 0) end
return {["NativeRead"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("18-native-read", false))
local __exports = __module_run("18-native-read", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["NativeRead"] = __exports["NativeRead"]
end
end
do
local __imports = {}
__imports["EngineCall"] = __module_registry["EngineCall"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("20-identity-core: imports must be a table", 0) end
local EngineCall = imports["EngineCall"]
if EngineCall == nil then error("20-identity-core: missing import EngineCall", 0) end

local IdentityCore = (function()
  local Core = { VERSION = "identity-v5" }

  local UNRESOLVED, ABSENT = "unknown", "absent"

  local Identity = {}
  Identity.__index = Identity

  function Core.new(authored)
    local self = setmetatable({}, Identity)
    self.doors = (authored or {}).doors or {}
    self.scope = nil
    self.generation = 0
    self.counters = {
      resolves = 0, unknowns = 0, absents = 0, invalidations = 0,
      world_kept = 0,
      gate_open_seated = 0,
    }
    self:reset()
    return self
  end

  function Identity:reset()
    self.generation = self.generation + 1
    self.avatar_entity = nil
    self.controlled_once = false
    self.counters.invalidations = self.counters.invalidations + 1
  end

  function Identity:sync(session, world)
    local scope = self.scope
    local reborn = scope == nil or scope.session ~= session
    if reborn or scope.world ~= world then
      self.scope = { session = session, world = world }
      if not reborn then
        self.counters.world_kept = self.counters.world_kept + 1
      end
    end
    if reborn then self:reset() end
  end

  local function cell(cells, spec)
    local name = type(spec) == "table" and spec.cell or spec
    if name == nil then return nil end
    return cells[name]
  end

  local function tally(self, prefix, reason)
    local head = type(reason) == "string" and reason:match("^[%a%-]+") or nil
    if head == nil then return end
    local key = prefix .. head:gsub("%-", "_")
    self.counters[key] = (self.counters[key] or 0) + 1
  end

  local function set(value)
    return value ~= nil and value ~= 0
  end

  local function closing_reason(doors, cells, motion)
    local seated = cell(cells, doors.seated)
    if motion == 0 and seated == 0 then return "avatar-not-in-control" end

    local hands = doors.hands
    local busy = hands ~= nil and cell(cells, hands) or nil
    if busy ~= nil and busy ~= hands.value then
      return "hands-elsewhere mode=" .. tostring(busy)
    end

    if cell(cells, doors.held) == 0 then return "hands-empty" end

    local seat = doors.seat_role
    if seat == nil or not set(seated) then return nil end
    local role = cell(cells, seat)
    for _, closed in ipairs(seat.closed or {}) do
      if role == closed then return "seat-closed role=" .. tostring(role) end
    end
    if role == seat.gunner and set(cell(cells, doors.second_gun)) then
      return "seat-twin-gun"
    end
    return nil
  end

  local function unknown(self, reason)
    self.counters.unknowns = self.counters.unknowns + 1
    tally(self, "unknown_", reason)
    return { status = UNRESOLVED, reason = reason }
  end

  function Identity:resolve(session, world, native)
    self:sync(session, world)
    if session == nil or world == nil then
      return unknown(self, "no-session-or-world")
    end
    local avatar = native ~= nil and native.avatar or nil
    if avatar == nil or avatar.entity == nil then
      return unknown(self, "no-avatar-seat")
    end
    if self.avatar_entity ~= avatar.entity then
      if self.avatar_entity ~= nil then self:reset() end
      self.avatar_entity = avatar.entity
    end
    local cells = avatar.cells or {}

    local motion = cell(cells, self.doors.motion)
    if motion ~= 0 then self.controlled_once = true end

    local reason = closing_reason(self.doors, cells, motion)
    if reason ~= nil then
      self.counters.absents = self.counters.absents + 1
      tally(self, "absent_", reason)
      local shut = { status = ABSENT, reason = reason }
      for _, slot in ipairs(self.doors.closes or {}) do shut[slot] = false end
      return shut
    end
    if motion == 0 then
      self.counters.gate_open_seated = self.counters.gate_open_seated + 1
    end
    self.counters.resolves = self.counters.resolves + 1
    return { status = "resolved", reason = "doors-open" }
  end

  function Identity:report()
    return EngineCall.counters_of(self.counters)
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return IdentityCore end)
if not __contract_ok_1 or __contract_export_1 == nil then error("20-identity-core: missing export IdentityCore", 0) end
return {["IdentityCore"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("20-identity-core", true))
local __exports = __module_run("20-identity-core", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["IdentityCore"] = __exports["IdentityCore"]
end
end
do
local __imports = {}
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("30-generated-common: imports must be a table", 0) end
local GeneratedCommon = {
  ["contract"] = "hud-nodes-v4",
  ["info_owners"] = {
    ["pack.icon"] = "backpack",
    ["pack.resource"] = "backpack",
    ["reticle.dot"] = "hand-weapon",
    ["reticle.ring"] = "hand-weapon",
    ["self.health"] = "avatar",
    ["self.stamina"] = "avatar",
    ["self.stim_icon"] = "avatar",
    ["self.stims"] = "avatar",
    ["self.throwable_fuse"] = "avatar",
    ["self.throwable_icon"] = "avatar",
    ["self.throwables"] = "avatar",
    ["squad.1"] = "seat-1",
    ["squad.2"] = "seat-2",
    ["squad.3"] = "seat-3",
    ["squad.4"] = "seat-4",
    ["squadcall.1"] = "stratagem-call-1",
    ["squadcall.10"] = "stratagem-call-10",
    ["squadcall.11"] = "stratagem-call-11",
    ["squadcall.12"] = "stratagem-call-12",
    ["squadcall.2"] = "stratagem-call-2",
    ["squadcall.3"] = "stratagem-call-3",
    ["squadcall.4"] = "stratagem-call-4",
    ["squadcall.5"] = "stratagem-call-5",
    ["squadcall.6"] = "stratagem-call-6",
    ["squadcall.7"] = "stratagem-call-7",
    ["squadcall.8"] = "stratagem-call-8",
    ["squadcall.9"] = "stratagem-call-9",
    ["squadcall.fill.1"] = "stratagem-call-1",
    ["squadcall.fill.10"] = "stratagem-call-10",
    ["squadcall.fill.11"] = "stratagem-call-11",
    ["squadcall.fill.12"] = "stratagem-call-12",
    ["squadcall.fill.2"] = "stratagem-call-2",
    ["squadcall.fill.3"] = "stratagem-call-3",
    ["squadcall.fill.4"] = "stratagem-call-4",
    ["squadcall.fill.5"] = "stratagem-call-5",
    ["squadcall.fill.6"] = "stratagem-call-6",
    ["squadcall.fill.7"] = "stratagem-call-7",
    ["squadcall.fill.8"] = "stratagem-call-8",
    ["squadcall.fill.9"] = "stratagem-call-9",
    ["stratagem.1"] = "stratagem-1",
    ["stratagem.2"] = "stratagem-2",
    ["stratagem.3"] = "stratagem-3",
    ["stratagem.4"] = "stratagem-4",
    ["stratagem.fill.1"] = "stratagem-1",
    ["stratagem.fill.2"] = "stratagem-2",
    ["stratagem.fill.3"] = "stratagem-3",
    ["stratagem.fill.4"] = "stratagem-4",
    ["stratagem.seconds.1"] = "stratagem-1",
    ["stratagem.seconds.2"] = "stratagem-2",
    ["stratagem.seconds.3"] = "stratagem-3",
    ["stratagem.seconds.4"] = "stratagem-4",
    ["weapon.count"] = "hand-weapon",
    ["weapon.mode"] = "hand-weapon",
    ["weapon.reserve"] = "hand-weapon",
    ["weapon.reserve_frame"] = "hand-weapon",
    ["weapon.reserve_icon"] = "hand-weapon",
    ["weapon.resource"] = "hand-weapon",
    ["weapon.setting"] = "hand-weapon",
    ["weapon.zeroing"] = "hand-weapon",
  },
  ["axis_icons"] = {
    ["1"] = {
      ["0"] = "0x6be28cced767bb52",
      ["1"] = "0x46271d0b4ce4136c",
      ["default"] = "0xa2ab43e85546f79a",
    },
    ["2"] = {
      ["0"] = "0x52bbfc5a70359393",
      ["1"] = "0xc7546fc9c7b6db4e",
      ["default"] = "0xf03c671b15d01a6b",
    },
    ["3"] = {
      ["1"] = "0x6115051c9558c50e",
      ["2"] = "0x3efff09cd12fb89a",
      ["3"] = "0x131742904d846798",
      ["4"] = "0x16413ee2e6725687",
      ["5"] = "0x3efff09cd12fb89a",
      ["6"] = "0x131742904d846798",
      ["7"] = "0xad2ec8830fa5a193",
      ["default"] = "0x6115051c9558c50e",
    },
    ["4"] = {
      ["lane"] = "array",
    },
    ["5"] = {
      ["0"] = "0xb3fa2dbb309b3fa4",
      ["1"] = "0x8c37e52e722473d9",
      ["default"] = "0xe109fa5ca9246b55",
    },
    ["6"] = {
      ["0"] = "0xa9f9bf81827c51e5",
      ["default"] = "0xc1028550c62fc4fa",
    },
    ["7"] = {
      ["0"] = "0x9444f481d0c82fff",
      ["1"] = "0x90aaa55682d80bb3",
      ["default"] = "0x127a9aea3916c70e",
    },
    ["8"] = {
      ["lane"] = "array",
    },
    ["9"] = {
      ["lane"] = "blob",
      ["zero_at"] = "0x160",
    },
    ["10"] = {
      ["lane"] = "blob",
      ["zero_at"] = "0x160",
    },
    ["11"] = {
      ["lane"] = "blob",
      ["zero_at"] = "0xa0",
      ["other_at"] = "0xa8",
    },
    ["12"] = {
      ["lane"] = "blob",
    },
  },
  ["books"] = {
    ["pack"] = {
      ["book"] = "backpacks",
      ["of"] = "backpack",
    },
    ["reticle"] = {
      ["book"] = "reticles",
      ["of"] = "hand-weapon",
    },
  },
  ["guest_precedence"] = {
    "hand-weapon",
    "backpack",
    "avatar",
    "seat-1",
    "seat-2",
    "seat-3",
    "seat-4",
    "stratagem-1",
    "stratagem-2",
    "stratagem-3",
    "stratagem-4",
    "stratagem-call-1",
    "stratagem-call-2",
    "stratagem-call-3",
    "stratagem-call-4",
    "stratagem-call-5",
    "stratagem-call-6",
    "stratagem-call-7",
    "stratagem-call-8",
    "stratagem-call-9",
    "stratagem-call-10",
    "stratagem-call-11",
    "stratagem-call-12",
  },
  ["layout"] = {
    ["style"] = {
      ["alpha"] = 0.9,
      ["idle_ratio"] = 0,
      ["idle_fade_seconds"] = 4,
      ["aim_settle_seconds"] = 0.1,
      ["aim_rest_dx"] = 40,
      ["aim_rest_dy"] = -10,
      ["aim_sway"] = 0.1,
      ["aim_sway_widget"] = "crosshair_dot",
    },
    ["palette"] = {
      ["normal"] = {
        ["body"] = { 240, 240, 226 },
        ["ink"] = { 120, 120, 120 },
      },
      ["warn"] = {
        ["body"] = { 235, 140, 110 },
        ["ink"] = { 165, 98, 77 },
      },
      ["full"] = {
        ["body"] = { 110, 200, 255 },
        ["ink"] = { 77, 140, 179 },
        ["lift"] = 2,
      },
    },
    ["groups"] = {
      ["gear"] = {},
      ["icons"] = {
        ["wake_from"] = "gear",
      },
      ["icons-fixed"] = {},
      ["health"] = {
        ["wake_from"] = "gear",
      },
      ["stamina"] = {
        ["wake_from"] = "gear",
      },
      ["pack"] = {},
      ["pack-gear"] = {
        ["wake_from"] = "gear",
      },
      ["squad"] = {},
      ["reticle"] = {
        ["idle_ratio"] = 1,
      },
      ["stratagem-1"] = {
        ["wake_from"] = "gear",
      },
      ["stratagem-2"] = {
        ["wake_from"] = "gear",
      },
      ["stratagem-3"] = {
        ["wake_from"] = "gear",
      },
      ["stratagem-4"] = {
        ["wake_from"] = "gear",
      },
    },
    ["primitives"] = {
      ["bar"] = {
        ["slot"] = {
          "width",
          "height",
        },
        ["style"] = {
          "width",
          "height",
          "outline",
        },
        ["needs"] = {
          "gui",
          "screen",
        },
        ["destroy"] = "destroy_rect",
        ["fraction"] = true,
      },
      ["arc"] = {
        ["slot"] = {
          "span",
        },
        ["style"] = {
          "radius",
          "span",
          "outline",
        },
        ["needs"] = {
          "gui",
          "depth",
          "screen",
          "arc_material_name",
        },
        ["destroy"] = "destroy_triangle",
        ["fraction"] = true,
      },
      ["number"] = {
        ["style"] = {
          "font",
          "align",
          "gap",
          "dy",
          "layer",
        },
        ["needs"] = {
          "gui",
          "font",
          "material",
          "screen",
        },
        ["destroy"] = "destroy_text",
        ["stacks"] = true,
      },
      ["icon"] = {
        ["slot"] = {
          "size",
        },
        ["style"] = {
          "size",
          "size_by",
          "align",
          "gap",
          "dy",
          "outline",
        },
        ["needs"] = {
          "gui",
          "icon_material_name",
          "screen",
        },
        ["destroy"] = "destroy_bitmap",
        ["stacks"] = true,
      },
    },
    ["icon_cells"] = {
      ["0x780edbf159d3e23a"] = {
        ["u"] = 0.026562,
        ["v"] = 0.044922,
      },
      ["0xf6156e4d847924d7"] = {
        ["u"] = 0.226562,
        ["v"] = 0.044922,
      },
      ["0x7af183e128935f59"] = {
        ["u"] = 0.426563,
        ["v"] = 0.044922,
      },
      ["0x94a2eeaced1e8163"] = {
        ["u"] = 0.626563,
        ["v"] = 0.044922,
      },
      ["0xc3050d68489c8c9c"] = {
        ["u"] = 0.826562,
        ["v"] = 0.044922,
      },
      ["0x78cc2a31d3500e48"] = {
        ["u"] = 0.026562,
        ["v"] = 0.294922,
      },
      ["0x883534150115b630"] = {
        ["u"] = 0.226562,
        ["v"] = 0.294922,
      },
      ["0x496624a78ecb236c"] = {
        ["u"] = 0.426563,
        ["v"] = 0.294922,
      },
      ["0xf8ee4f1775b54b75"] = {
        ["u"] = 0.626563,
        ["v"] = 0.294922,
      },
      ["0x13e43cadfa5c61ae"] = {
        ["u"] = 0.826562,
        ["v"] = 0.294922,
      },
      ["0xb84f31bbd276d34b"] = {
        ["u"] = 0.026562,
        ["v"] = 0.544922,
      },
      ["0x20d02b065ad3b523"] = {
        ["u"] = 0.226562,
        ["v"] = 0.544922,
      },
      ["0xc43230c8378d0d96"] = {
        ["u"] = 0.426563,
        ["v"] = 0.544922,
      },
      ["0xc35cd043395bc2f5"] = {
        ["u"] = 0.626563,
        ["v"] = 0.544922,
      },
      ["0x7399004594ea3e08"] = {
        ["u"] = 0.826562,
        ["v"] = 0.544922,
      },
      ["0xab2c6cd508356314"] = {
        ["u"] = 0.026562,
        ["v"] = 0.794922,
      },
      ["0xe6ef43728ad05d17"] = {
        ["u"] = 0.226562,
        ["v"] = 0.794922,
      },
      ["0x354c889ff4400b85"] = {
        ["u"] = 0.426563,
        ["v"] = 0.794922,
      },
      ["0x7118cbc8fcf28c80"] = {
        ["u"] = 0.626563,
        ["v"] = 0.794922,
      },
      ["0xa9c52a2333dfcb68"] = {
        ["u"] = 0.826562,
        ["v"] = 0.794922,
      },
    },
    ["icon_cell_shape"] = {
      ["du"] = 0.146875,
      ["dv"] = 0.160156,
      ["aspect"] = 1.146341,
    },
    ["icon_pages"] = {},
    ["door_pages"] = {
      "mods/hd2_hud/door_page_1",
      "mods/hd2_hud/door_page_2",
      "mods/hd2_hud/door_page_3",
      "mods/hd2_hud/door_page_4",
    },
  },
  ["identity"] = {
    ["doors"] = {
      ["motion"] = "raw_motion_enabled",
      ["seated"] = "raw_seat_on",
      ["held"] = "wield_0",
      ["seat_role"] = {
        ["cell"] = "raw_seat_08",
        ["closed"] = { 0, 1, 4 },
        ["gunner"] = 2,
      },
      ["second_gun"] = "wield_1",
      ["hands"] = {
        ["cell"] = "raw_motion_mode",
        ["value"] = 1,
      },
      ["closes"] = {
        "avatar",
        "backpack",
        "hand_weapon",
        "pack_link",
        "stratagem_1",
        "stratagem_2",
        "stratagem_3",
        "stratagem_4",
      },
    },
    ["reticles"] = {
      ["0x89c5493e08ca4207"] = {
        ["dot"] = "0x2f1a665b82767b50",
        ["ring"] = "0x1fc3c735d4547c90",
      },
    },
    ["booster"] = {
      ["16"] = "0x780edbf159d3e23a",
      ["11"] = "0xf6156e4d847924d7",
      ["14"] = "0x7af183e128935f59",
      ["15"] = "0x94a2eeaced1e8163",
      ["13"] = "0xc3050d68489c8c9c",
      ["9"] = "0x78cc2a31d3500e48",
      ["12"] = "0x883534150115b630",
      ["19"] = "0x496624a78ecb236c",
      ["6"] = "0xf8ee4f1775b54b75",
      ["20"] = "0x13e43cadfa5c61ae",
      ["7"] = "0xb84f31bbd276d34b",
      ["5"] = "0x20d02b065ad3b523",
      ["8"] = "0xc43230c8378d0d96",
      ["3"] = "0xc35cd043395bc2f5",
      ["17"] = "0x7399004594ea3e08",
      ["10"] = "0xab2c6cd508356314",
      ["18"] = "0xe6ef43728ad05d17",
      ["2"] = "0x354c889ff4400b85",
      ["4"] = "0x7118cbc8fcf28c80",
      ["1"] = "0xa9c52a2333dfcb68",
    },
    ["backpacks"] = {
      ["0x9ace8638421abc8e"] = {
        ["arc_max"] = 10,
      },
    },
  },
  ["native"] = {
    ["pin"] = {
      ["exe"] = "f5fee03dcfdb2e553a4752c283590950ac13316b376d8196aa556ff0400d5f06",
      ["game"] = "2e2c3b7c2500646dadd5f2b4c6e0504dbb7e7896139f64cddc0d1813c718f51e",
    },
    ["map"] = {
      ["capacity"] = 8,
      ["empty"] = 12,
      ["mult"] = 16,
    },
    ["chain"] = {
      ["player_manager"] = 53634152,
      ["local_unit"] = 936,
      ["entity_owner"] = 54968216,
      ["owner_map"] = 15871688,
      ["owner_entities"] = 15937304,
      ["goid_at"] = 16,
      ["entity_stride"] = 24,
      ["entity_id"] = 8,
      ["unit_id"] = 12,
      ["avatar_manager"] = 53636384,
      ["avatar_map"] = 248,
      ["avatar_count"] = 108,
      ["avatar_controller"] = 5495040,
      ["controller_stride"] = 4664,
      ["identity"] = 2948,
    },
    ["ui_font"] = {
      ["font"] = 58139240,
      ["atlas"] = 58142440,
      ["material_owner"] = 58479736,
      ["material_at"] = 24,
    },
    ["function_icons"] = {
      ["at"] = 58488432,
      ["slots"] = 351,
      ["icon_at"] = 16,
      ["empty_record"] = 58488160,
    },
    ["equipment"] = {
      ["global"] = 53636544,
      ["map"] = 32,
      ["backref"] = 56,
      ["rows"] = 64,
      ["count"] = 12,
      ["stride"] = 48,
      ["owner"] = 4,
      ["slot"] = 12,
    },
    ["relations"] = {
      ["held"] = {
        ["from"] = "linked",
        ["of"] = "avatar",
        ["cell"] = "wield_0",
        ["key"] = "entity",
        ["reads"] = {
          "WeaponMagazineComponent",
          "WeaponRoundsComponent",
          "WeaponHeatComponent",
          "WeaponDataComponent",
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "WeaponLinkedAmmoComponent",
          "WeaponAssistedReloadComponent",
          "WieldableComponent",
          "WeaponReloadComponent",
          "AbilityWeaponComponent",
          "WeaponChargeComponent",
          "ThrowableComponent",
        },
        ["mirror_reads"] = {
          "ShieldComponent",
          "InteractableMinigameComponent",
          "TwoPointChainComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "EmoteComponent",
        },
      },
      ["underbarrel"] = {
        ["from"] = "linked",
        ["of"] = "avatar",
        ["cell"] = "wield_1",
        ["key"] = "entity",
        ["reads"] = {
          "WeaponMagazineComponent",
          "WeaponRoundsComponent",
          "WeaponHeatComponent",
          "WeaponDataComponent",
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "WeaponLinkedAmmoComponent",
          "WeaponAssistedReloadComponent",
          "WieldableComponent",
          "WeaponReloadComponent",
          "AbilityWeaponComponent",
          "WeaponChargeComponent",
          "ThrowableComponent",
        },
        ["mirror_reads"] = {
          "ShieldComponent",
          "InteractableMinigameComponent",
          "TwoPointChainComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "EmoteComponent",
        },
      },
      ["hand-weapon"] = {
        ["from"] = "first",
        ["of"] = {
          "underbarrel",
          "held",
        },
        ["unless"] = "fuse_count",
        ["reads"] = {
          "WeaponMagazineComponent",
          "WeaponRoundsComponent",
          "WeaponHeatComponent",
          "WeaponDataComponent",
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "WeaponLinkedAmmoComponent",
          "WeaponAssistedReloadComponent",
          "WieldableComponent",
          "WeaponReloadComponent",
          "AbilityWeaponComponent",
          "WeaponChargeComponent",
          "ThrowableComponent",
        },
        ["mirror_reads"] = {
          "ShieldComponent",
          "InteractableMinigameComponent",
          "TwoPointChainComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "EmoteComponent",
        },
      },
      ["avatar"] = {
        ["from"] = "avatar",
        ["reads"] = {
          "HealthComponent",
          "MotionComponent",
          "AbilityComponent",
          "WeaponWielderComponent",
          "SeaterComponent",
          "InventoryComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "ShieldComponent",
          "InteractableMinigameComponent",
          "TwoPointChainComponent",
          "MountComponent",
          "WieldableComponent",
          "EmoteComponent",
        },
      },
      ["seat-1"] = {
        ["from"] = "hud_squad",
        ["seat"] = 1,
      },
      ["seat-2"] = {
        ["from"] = "hud_squad",
        ["seat"] = 2,
      },
      ["seat-3"] = {
        ["from"] = "hud_squad",
        ["seat"] = 3,
      },
      ["seat-4"] = {
        ["from"] = "hud_subject",
      },
      ["backpack"] = {
        ["from"] = "slot",
        ["slot"] = 6,
        ["reads"] = {
          "WeaponMagazineComponent",
          "WeaponRoundsComponent",
          "ShieldComponent",
          "ShieldControllerComponent",
          "HealthComponent",
          "DepositComponent",
          "InteractableMinigameComponent",
          "RechargeComponent",
          "DisplacementComponent",
          "TwoPointChainComponent",
          "WieldableComponent",
          "SpottableComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "EmoteComponent",
        },
      },
      ["stratagem-1"] = {
        ["from"] = "stratagem_pick",
        ["pick"] = 1,
      },
      ["stratagem-2"] = {
        ["from"] = "stratagem_pick",
        ["pick"] = 2,
      },
      ["stratagem-3"] = {
        ["from"] = "stratagem_pick",
        ["pick"] = 3,
      },
      ["stratagem-4"] = {
        ["from"] = "stratagem_pick",
        ["pick"] = 4,
      },
      ["stratagem-call-1"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-1",
        ["rank"] = 1,
      },
      ["stratagem-call-2"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-1",
        ["rank"] = 2,
      },
      ["stratagem-call-3"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-1",
        ["rank"] = 3,
      },
      ["stratagem-call-4"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-1",
        ["rank"] = 4,
      },
      ["stratagem-call-5"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-2",
        ["rank"] = 1,
      },
      ["stratagem-call-6"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-2",
        ["rank"] = 2,
      },
      ["stratagem-call-7"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-2",
        ["rank"] = 3,
      },
      ["stratagem-call-8"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-2",
        ["rank"] = 4,
      },
      ["stratagem-call-9"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-3",
        ["rank"] = 1,
      },
      ["stratagem-call-10"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-3",
        ["rank"] = 2,
      },
      ["stratagem-call-11"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-3",
        ["rank"] = 3,
      },
      ["stratagem-call-12"] = {
        ["from"] = "stratagem_call",
        ["of"] = "seat-3",
        ["rank"] = 4,
      },
      ["equipped-throwable"] = {
        ["from"] = "resource",
        ["of"] = "avatar",
        ["cell"] = "throw_res",
        ["reads"] = {
          "EncyclopediaEntryComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "ShieldComponent",
          "InteractableMinigameComponent",
          "TwoPointChainComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "WieldableComponent",
          "EmoteComponent",
        },
      },
      ["throwable"] = {
        ["from"] = "slot",
        ["slot"] = 4,
        ["reads"] = {
          "WieldableComponent",
          "ThrowableComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "ShieldComponent",
          "InteractableMinigameComponent",
          "TwoPointChainComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "EmoteComponent",
        },
      },
      ["pack-link"] = {
        ["from"] = "linked",
        ["of"] = "held",
        ["cell"] = "link_pack",
        ["key"] = "entity",
        ["reads"] = {
          "DepositComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "ShieldComponent",
          "InteractableMinigameComponent",
          "TwoPointChainComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "WieldableComponent",
          "EmoteComponent",
        },
      },
      ["pack-child"] = {
        ["from"] = "linked",
        ["of"] = "backpack",
        ["cell"] = "link_child",
        ["key"] = "goid",
        ["reads"] = {
          "WeaponMagazineComponent",
          "WeaponRoundsComponent",
          "ShieldComponent",
          "HealthComponent",
          "DepositComponent",
          "InteractableMinigameComponent",
          "RechargeComponent",
          "DisplacementComponent",
          "TwoPointChainComponent",
          "WieldableComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "EmoteComponent",
        },
      },
      ["pack-drone"] = {
        ["from"] = "linked",
        ["of"] = "backpack",
        ["cell"] = "link_drone",
        ["key"] = "goid",
        ["reads"] = {
          "MountComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "ShieldComponent",
          "InteractableMinigameComponent",
          "TwoPointChainComponent",
          "MotionComponent",
          "AbilityComponent",
          "WieldableComponent",
          "EmoteComponent",
        },
      },
      ["drone-weapon"] = {
        ["from"] = "linked",
        ["of"] = "pack-drone",
        ["cell"] = "mount_weapon",
        ["key"] = "unit",
        ["reads"] = {
          "WeaponMagazineComponent",
          "WeaponRoundsComponent",
          "ShieldComponent",
          "HealthComponent",
          "DepositComponent",
          "InteractableMinigameComponent",
          "RechargeComponent",
          "DisplacementComponent",
          "TwoPointChainComponent",
          "WieldableComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "EmoteComponent",
        },
      },
      ["pack-object"] = {
        ["from"] = "first",
        ["of"] = {
          "drone-weapon",
          "pack-child",
          "backpack",
        },
        ["reads"] = {
          "WeaponMagazineComponent",
          "WeaponRoundsComponent",
          "ShieldComponent",
          "HealthComponent",
          "DepositComponent",
          "InteractableMinigameComponent",
          "RechargeComponent",
          "DisplacementComponent",
          "TwoPointChainComponent",
          "WieldableComponent",
        },
        ["mirror_reads"] = {
          "ProjectileWeaponComponent",
          "LaserDesignatorComponent",
          "MountComponent",
          "MotionComponent",
          "AbilityComponent",
          "EmoteComponent",
        },
      },
    },
    ["catalog"] = {
      {
        ["component"] = "WeaponMagazineComponent",
        ["global"] = 53634632,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 80,
            ["stride"] = 12,
            ["values"] = {
              ["ammo"] = {
                4,
                "u32",
              },
              ["reserve"] = {
                0,
                "u32",
              },
            },
          },
          {
            ["at"] = 72,
            ["stride"] = 16,
            ["values"] = {
              ["chamber_round"] = {
                8,
                "u32",
              },
            },
          },
        },
        ["instance"] = {
          ["map"] = 96,
          ["at"] = 160,
          ["stride"] = 160,
          ["values"] = {
            ["ammo_max"] = {
              136,
              "u32",
            },
            ["spare_capacity"] = {
              148,
              "u32",
            },
            ["chambered"] = {
              156,
              "u8",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15803552,
          ["buckets"] = 540,
          ["size"] = 160,
        },
      },
      {
        ["component"] = "WeaponRoundsComponent",
        ["global"] = 53636336,
        ["map"] = 40,
        ["backref"] = 64,
        ["arrays"] = {
          {
            ["at"] = 88,
            ["stride"] = 20,
            ["values"] = {
              ["reserve"] = {
                0,
                "u32",
              },
              ["raw_selected"] = {
                4,
                "u32",
              },
              ["rounds_0"] = {
                8,
                "u32",
              },
              ["rounds_1"] = {
                12,
                "u32",
              },
            },
          },
          {
            ["at"] = 80,
            ["stride"] = 24,
            ["values"] = {
              ["chamber_round"] = {
                16,
                "u32",
              },
            },
          },
        },
        ["instance"] = {
          ["map"] = 104,
          ["at"] = 168,
          ["stride"] = 136,
          ["values"] = {
            ["kind_0"] = {
              64,
              "u32",
            },
            ["kind_1"] = {
              68,
              "u32",
            },
            ["capacity_0"] = {
              72,
              "f32",
            },
            ["capacity_1"] = {
              76,
              "f32",
            },
            ["spare_capacity"] = {
              80,
              "u32",
            },
            ["chambered"] = {
              104,
              "u8",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15804448,
          ["buckets"] = 50,
          ["size"] = 136,
        },
      },
      {
        ["component"] = "WeaponHeatComponent",
        ["global"] = 53636424,
        ["map"] = 40,
        ["backref"] = 64,
        ["arrays"] = {
          {
            ["at"] = 88,
            ["stride"] = 12,
            ["values"] = {
              ["reserve"] = {
                0,
                "u32",
              },
              ["heat"] = {
                4,
                "f32",
              },
              ["overheated"] = {
                8,
                "bool",
              },
            },
          },
          {
            ["at"] = 80,
            ["stride"] = 72,
            ["values"] = {
              ["heat_charge"] = {
                12,
                "f32",
              },
            },
          },
        },
        ["instance"] = {
          ["map"] = 104,
          ["at"] = 168,
          ["stride"] = 592,
          ["values"] = {
            ["heat_max"] = {
              96,
              "f32",
            },
            ["heat_warn"] = {
              104,
              "f32",
            },
            ["shot_heat"] = {
              116,
              "f32",
            },
            ["heat_charge_max"] = {
              148,
              "f32",
            },
            ["spare_capacity"] = {
              92,
              "u32",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15805640,
          ["buckets"] = 58,
          ["size"] = 592,
        },
      },
      {
        ["component"] = "WeaponDataComponent",
        ["global"] = 53636320,
        ["map"] = 48,
        ["backref"] = 72,
        ["arrays"] = {
          {
            ["at"] = 96,
            ["stride"] = 12,
            ["values"] = {
              ["raw_mode"] = {
                0,
                "u32",
              },
              ["raw_options"] = {
                4,
                "u32",
              },
            },
          },
          {
            ["at"] = 88,
            ["stride"] = 1008,
            ["values"] = {
              ["axis_1"] = {
                848,
                "u32",
              },
              ["axis_2"] = {
                852,
                "u32",
              },
              ["axis_3"] = {
                856,
                "u32",
              },
              ["axis_4"] = {
                860,
                "u32",
              },
            },
          },
        },
        ["instance"] = {
          ["map"] = 112,
          ["at"] = 176,
          ["stride"] = 1232,
          ["values"] = {
            ["authored_mode_1"] = {
              144,
              "u32",
            },
            ["authored_mode_2"] = {
              148,
              "u32",
            },
            ["authored_mode_3"] = {
              152,
              "u32",
            },
            ["zeroing_0"] = {
              340,
              "f32",
            },
            ["zeroing_1"] = {
              344,
              "f32",
            },
            ["zeroing_2"] = {
              348,
              "f32",
            },
            ["ub_icon_1"] = {
              168,
              "hash64",
            },
            ["ammo_icon"] = {
              1024,
              "hash64",
            },
            ["ammo_icon_empty"] = {
              1032,
              "hash64",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15805400,
          ["buckets"] = 730,
          ["size"] = 1232,
        },
      },
      {
        ["component"] = "ProjectileWeaponComponent",
        ["global"] = 53634776,
        ["map"] = 80,
        ["backref"] = 104,
        ["arrays"] = {
          {
            ["at"] = 112,
            ["stride"] = 32,
            ["values"] = {
              ["raw_rof_stage"] = {
                28,
                "u32",
              },
            },
          },
        },
        ["instance"] = {
          ["map"] = 144,
          ["at"] = 208,
          ["stride"] = 616,
          ["values"] = {
            ["program_0"] = {
              0,
              "u32",
            },
            ["program_1"] = {
              576,
              "u32",
            },
            ["rof_0"] = {
              4,
              "f32",
            },
            ["rof_1"] = {
              8,
              "f32",
            },
            ["rof_2"] = {
              12,
              "f32",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15806080,
          ["buckets"] = 542,
          ["size"] = 616,
        },
      },
      {
        ["component"] = "LaserDesignatorComponent",
        ["global"] = 53635424,
        ["map"] = 48,
        ["backref"] = 72,
        ["arrays"] = {
          {
            ["at"] = 96,
            ["stride"] = 1,
            ["values"] = {
              ["raw_guide"] = {
                0,
                "bool",
              },
            },
          },
        },
      },
      {
        ["component"] = "WeaponLinkedAmmoComponent",
        ["global"] = 53635752,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 72,
            ["stride"] = 36,
            ["values"] = {
              ["link_pack"] = {
                0,
                "u32",
              },
            },
          },
        },
        ["silences"] = {
          "reserve",
        },
      },
      {
        ["component"] = "WeaponAssistedReloadComponent",
        ["global"] = 53636072,
        ["map"] = 24,
        ["backref"] = 48,
        ["silences"] = {
          "reserve",
        },
      },
      {
        ["component"] = "ShieldComponent",
        ["global"] = 53634608,
        ["map"] = 48,
        ["backref"] = 72,
        ["arrays"] = {
          {
            ["at"] = 88,
            ["stride"] = 20,
            ["values"] = {
              ["charge"] = {
                4,
                "f32",
              },
              ["broken"] = {
                2,
                "bool",
              },
            },
          },
        },
        ["count"] = 16,
        ["instance"] = {
          ["map"] = 104,
          ["at"] = 168,
          ["stride"] = 344,
          ["values"] = {
            ["charge_max"] = {
              76,
              "f32",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15804264,
          ["buckets"] = 30,
          ["size"] = 344,
        },
      },
      {
        ["component"] = "ShieldControllerComponent",
        ["global"] = 53635088,
        ["map"] = 24,
        ["backref"] = 48,
        ["arrays"] = {
          {
            ["at"] = 64,
            ["stride"] = 8,
            ["values"] = {
              ["link_child"] = {
                4,
                "u32",
              },
            },
          },
        },
      },
      {
        ["component"] = "HealthComponent",
        ["global"] = 53634696,
        ["map"] = 4144,
        ["backref"] = 4168,
        ["arrays"] = {
          {
            ["at"] = 4184,
            ["stride"] = 440,
            ["values"] = {
              ["health"] = {
                20,
                "i32",
              },
            },
          },
          {
            ["at"] = 4192,
            ["stride"] = 28,
            ["values"] = {
              ["health_max"] = {
                20,
                "u32",
              },
            },
          },
        },
      },
      {
        ["component"] = "DepositComponent",
        ["global"] = 53634536,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 80,
            ["stride"] = 8,
            ["values"] = {
              ["remaining"] = {
                0,
                "u32",
              },
              ["link_drone"] = {
                4,
                "u32",
              },
            },
          },
        },
        ["instance"] = {
          ["map"] = 96,
          ["at"] = 160,
          ["stride"] = 152,
          ["values"] = {
            ["remaining_max"] = {
              0,
              "u32",
            },
            ["feeds_resource"] = {
              136,
              "hash64",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15804928,
          ["buckets"] = 58,
          ["size"] = 152,
        },
      },
      {
        ["component"] = "InteractableMinigameComponent",
        ["global"] = 53634816,
        ["map"] = 48,
        ["backref"] = 72,
        ["arrays"] = {
          {
            ["at"] = 96,
            ["stride"] = 48,
            ["values"] = {
              ["pack_clock"] = {
                24,
                "f32",
              },
            },
          },
        },
      },
      {
        ["component"] = "RechargeComponent",
        ["global"] = 53634920,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 72,
            ["stride"] = 4,
            ["values"] = {
              ["recharge_spent"] = {
                0,
                "f32",
              },
            },
          },
        },
        ["instance"] = {
          ["map"] = 88,
          ["at"] = 152,
          ["stride"] = 4,
          ["values"] = {
            ["recharge_max"] = {
              0,
              "f32",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15804304,
          ["buckets"] = 6,
          ["size"] = 4,
        },
      },
      {
        ["component"] = "DisplacementComponent",
        ["global"] = 53635784,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 80,
            ["stride"] = 4,
            ["values"] = {
              ["energy_spent"] = {
                0,
                "f32",
              },
            },
          },
        },
        ["ceiling"] = {
          ["energy_max"] = 100,
        },
      },
      {
        ["component"] = "TwoPointChainComponent",
        ["global"] = 53635976,
        ["map"] = 24,
        ["backref"] = 48,
        ["arrays"] = {
          {
            ["at"] = 56,
            ["stride"] = 156,
            ["values"] = {
              ["chain_weapon"] = {
                4,
                "u32",
              },
            },
          },
        },
      },
      {
        ["component"] = "MountComponent",
        ["global"] = 53634104,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 80,
            ["stride"] = 24,
            ["values"] = {
              ["mount_weapon"] = {
                4,
                "u32",
              },
            },
          },
        },
        ["count"] = 16,
      },
      {
        ["component"] = "MotionComponent",
        ["global"] = 53634392,
        ["map"] = 18592,
        ["backref"] = 18616,
        ["arrays"] = {
          {
            ["at"] = 18648,
            ["stride"] = 44,
            ["values"] = {
              ["raw_motion_mode"] = {
                28,
                "u32",
              },
              ["raw_motion_enabled"] = {
                32,
                "u8",
              },
            },
          },
        },
      },
      {
        ["component"] = "AbilityComponent",
        ["global"] = 53634624,
        ["map"] = 24,
        ["backref"] = 48,
        ["arrays"] = {
          {
            ["at"] = 56,
            ["stride"] = 224,
            ["values"] = {
              ["ability_id"] = {
                0,
                "u32",
              },
              ["ability_time"] = {
                8,
                "f32",
              },
              ["ability_running"] = {
                16,
                "u8",
              },
              ["action_events"] = {
                24,
                "u32",
              },
            },
          },
        },
      },
      {
        ["component"] = "WieldableComponent",
        ["global"] = 53634864,
        ["map"] = 24,
        ["backref"] = 48,
        ["arrays"] = {
          {
            ["at"] = 56,
            ["stride"] = 4,
            ["values"] = {
              ["raw_wielded_by"] = {
                0,
                "u32",
              },
            },
          },
        },
      },
      {
        ["component"] = "WeaponReloadComponent",
        ["global"] = 53635696,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 80,
            ["stride"] = 4,
            ["values"] = {
              ["reload_stage"] = {
                0,
                "u32",
              },
            },
          },
        },
        ["instance"] = {
          ["map"] = 96,
          ["at"] = 160,
          ["stride"] = 80,
          ["values"] = {
            ["reload_ability"] = {
              4,
              "u32",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15804416,
          ["buckets"] = 498,
          ["size"] = 80,
        },
      },
      {
        ["component"] = "AbilityWeaponComponent",
        ["instance"] = {
          ["values"] = {
            ["c4_icon_0"] = {
              24,
              "hash64",
            },
            ["c4_icon_1"] = {
              64,
              "hash64",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15805648,
          ["buckets"] = 18,
          ["size"] = 88,
        },
      },
      {
        ["component"] = "WeaponChargeComponent",
        ["global"] = 53636128,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 64,
            ["stride"] = 40,
            ["values"] = {
              ["charge_elapsed"] = {
                4,
                "f32",
              },
              ["charging"] = {
                12,
                "bool",
              },
            },
          },
        },
      },
      {
        ["component"] = "WeaponWielderComponent",
        ["global"] = 53634080,
        ["map"] = 48,
        ["backref"] = 72,
        ["arrays"] = {
          {
            ["at"] = 96,
            ["stride"] = 464,
            ["values"] = {
              ["wield_0"] = {
                0,
                "u32",
              },
              ["wield_1"] = {
                80,
                "u32",
              },
            },
          },
        },
      },
      {
        ["component"] = "SeaterComponent",
        ["global"] = 53636472,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 72,
            ["stride"] = 64,
            ["values"] = {
              ["raw_seat_on"] = {
                0,
                "u32",
              },
              ["raw_seat_08"] = {
                8,
                "u32",
              },
            },
          },
        },
      },
      {
        ["component"] = "InventoryComponent",
        ["global"] = 53634872,
        ["map"] = 40,
        ["backref"] = 64,
        ["arrays"] = {
          {
            ["at"] = 88,
            ["stride"] = 8,
            ["values"] = {
              ["num_throwables"] = {
                0,
                "u32",
              },
              ["num_stims"] = {
                4,
                "u32",
              },
            },
          },
          {
            ["at"] = 80,
            ["stride"] = 48,
            ["values"] = {
              ["throw_res"] = {
                40,
                "hash64",
              },
            },
          },
        },
      },
      {
        ["component"] = "EmoteComponent",
        ["global"] = 53634680,
        ["map"] = 32,
        ["backref"] = 56,
        ["arrays"] = {
          {
            ["at"] = 80,
            ["stride"] = 8,
            ["values"] = {
              ["emote_input"] = {
                0,
                "u32",
              },
              ["emote"] = {
                4,
                "u32",
              },
            },
          },
        },
      },
      {
        ["component"] = "ThrowableComponent",
        ["global"] = 53634240,
        ["map"] = 48,
        ["backref"] = 72,
        ["arrays"] = {
          {
            ["at"] = 80,
            ["stride"] = 120,
            ["values"] = {
              ["fuse_pick"] = {
                112,
                "u32",
              },
              ["fuse_count"] = {
                116,
                "u32",
              },
            },
          },
        },
        ["instance"] = {
          ["values"] = {
            ["fuse_icon_0"] = {
              192,
              "hash64",
            },
            ["fuse_icon_1"] = {
              216,
              "hash64",
            },
            ["fuse_icon_2"] = {
              240,
              "hash64",
            },
            ["fuse_icon_3"] = {
              264,
              "hash64",
            },
            ["fuse_icon_4"] = {
              288,
              "hash64",
            },
            ["fuse_icon_5"] = {
              312,
              "hash64",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15805584,
          ["buckets"] = 92,
          ["size"] = 360,
        },
      },
      {
        ["component"] = "SpottableComponent",
        ["instance"] = {
          ["values"] = {
            ["marker_icon"] = {
              56,
              "hash64",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15804512,
          ["buckets"] = 1386,
          ["size"] = 72,
        },
      },
      {
        ["component"] = "EncyclopediaEntryComponent",
        ["instance"] = {
          ["values"] = {
            ["entry_icon"] = {
              48,
              "hash64",
            },
          },
        },
        ["registry"] = {
          ["table"] = 15804120,
          ["buckets"] = 1330,
          ["size"] = 56,
        },
      },
    },
    ["sums"] = {
      ["ammo"] = {
        ["parts"] = {
          "rounds_0",
          "rounds_1",
        },
        ["by"] = "raw_selected",
        ["same"] = {
          "kind_0",
          "kind_1",
        },
      },
      ["ammo_max"] = {
        ["parts"] = {
          "capacity_0",
          "capacity_1",
        },
        ["by"] = "raw_selected",
        ["same"] = {
          "kind_0",
          "kind_1",
        },
      },
      ["ammo_kind"] = {
        ["parts"] = {
          "kind_0",
          "kind_1",
        },
        ["by"] = "raw_selected",
      },
    },
    ["chamber"] = {
      ["count"] = "ammo",
      ["loaded"] = "chamber_round",
      ["uses"] = "chambered",
    },
    ["avatar_state"] = {
      ["at"] = 5535792,
      ["stride"] = 120,
      ["values"] = {
        ["stamina"] = {
          36,
          "f32",
        },
        ["aiming"] = {
          18,
          "bit",
          2,
        },
        ["aiming_copy"] = {
          23,
          "bit",
          5,
        },
        ["first_person"] = {
          14,
          "bit",
          0,
        },
        ["reloading"] = {
          23,
          "bit",
          1,
        },
      },
    },
    ["action"] = {
      ["into"] = "hand-weapon",
      ["from"] = "avatar",
      ["reads"] = {
        ["ability"] = "ability_id",
        ["time"] = "ability_time",
        ["running"] = "ability_running",
      },
      ["chamber"] = "chamber_round",
      ["reload"] = "reload_ability",
      ["frames_per_second"] = 60,
      ["routes"] = {
        [164] = {
          ["only"] = {
            { 0, 180 },
          },
        },
        [165] = {
          ["only"] = {
            { 0, 180 },
          },
        },
        [166] = {
          ["only"] = {
            { 0, 110 },
          },
        },
        [167] = {
          ["only"] = {
            { 0, 180 },
          },
        },
        [549] = {
          ["only"] = {
            { 0, 180 },
          },
        },
        [618] = {
          ["only"] = {
            { 0, 90 },
          },
        },
        [620] = {
          ["only"] = {
            { 0, 90 },
          },
        },
        [665] = {
          ["only"] = {
            { 0, 200 },
          },
        },
        [666] = {
          ["only"] = {
            { 0, 200 },
          },
        },
        [720] = {
          ["only"] = {
            { 0, 200 },
          },
        },
        [811] = {
          ["only"] = {
            { 0, 185 },
          },
        },
        [812] = {
          ["only"] = {
            { 0, 40 },
          },
        },
        [837] = {
          ["only"] = {
            { 0, 90 },
          },
        },
        [839] = {
          ["only"] = {
            { 0, 90 },
          },
        },
        [962] = {
          ["only"] = {
            { 0, 80 },
          },
        },
        [965] = {
          ["only"] = {
            { 0, 280 },
          },
        },
        [1017] = {
          ["only"] = {
            { 0, 150 },
          },
        },
        [1021] = {
          ["only"] = {
            { 0, 120 },
          },
        },
        [1024] = {
          ["only"] = {
            { 0, 90 },
          },
        },
        [2326] = {
          ["only"] = {
            { 0, 210 },
          },
        },
        [2328] = {
          ["only"] = {
            { 0, 440 },
          },
        },
        [2329] = {
          ["only"] = {
            { 0, 445 },
          },
        },
        [2621] = {
          ["empty"] = {
            { 0, 90 },
          },
          ["tactical"] = {
            { 0, 90 },
          },
        },
        [2651] = {
          ["only"] = {
            { 0, 120 },
          },
        },
        [2652] = {
          ["only"] = {
            { 0, 120 },
          },
        },
        [2738] = {
          ["empty"] = {
            { 0, 150 },
          },
          ["tactical"] = {
            { 0, 86 },
          },
        },
        [2739] = {
          ["empty"] = {
            { 0, 140 },
            { 140, 200 },
          },
          ["tactical"] = {
            { 0, 120, 190, 200 },
          },
        },
        [2740] = {
          ["empty"] = {
            { 0, 220 },
            { 220, 250 },
          },
          ["tactical"] = {
            { 0, 147 },
          },
        },
        [2741] = {
          ["empty"] = {
            { 0, 140 },
            { 140, 200 },
          },
          ["tactical"] = {
            { 0, 120, 190, 200 },
          },
        },
        [2742] = {
          ["empty"] = {
            { 0, 140 },
            { 140, 180 },
          },
          ["tactical"] = {
            { 0, 110 },
          },
        },
        [2743] = {
          ["empty"] = {
            { 0, 155 },
            { 155, 190 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2744] = {
          ["empty"] = {
            { 0, 120 },
            { 120, 180 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2745] = {
          ["empty"] = {
            { 0, 145 },
            { 145, 185 },
          },
          ["tactical"] = {
            { 0, 135 },
          },
        },
        [2746] = {
          ["empty"] = {
            { 0, 130 },
            { 130, 200 },
          },
          ["tactical"] = {
            { 0, 115 },
          },
        },
        [2747] = {
          ["only"] = {
            { 0, 150 },
          },
        },
        [2748] = {
          ["empty"] = {
            { 0, 130 },
            { 130, 225 },
          },
          ["tactical"] = {
            { 0, 140 },
          },
        },
        [2749] = {
          ["empty"] = {
            { 0, 110 },
            { 110, 190 },
          },
          ["tactical"] = {
            { 0, 110 },
          },
        },
        [2750] = {
          ["empty"] = {
            { 0, 110 },
            { 110, 190 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2751] = {
          ["empty"] = {
            { 0, 110 },
            { 110, 190 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2752] = {
          ["empty"] = {
            { 0, 130 },
            { 130, 190 },
          },
          ["tactical"] = {
            { 0, 110 },
          },
        },
        [2753] = {
          ["empty"] = {
            { 0, 115 },
            { 115, 190 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2754] = {
          ["empty"] = {
            { 0, 110 },
            { 110, 180 },
          },
          ["tactical"] = {
            { 0, 125 },
          },
        },
        [2755] = {
          ["empty"] = {
            { 0, 110 },
            { 110, 180 },
          },
          ["tactical"] = {
            { 0, 125 },
          },
        },
        [2756] = {
          ["empty"] = {
            { 0, 110 },
            { 110, 180 },
          },
          ["tactical"] = {
            { 0, 110 },
          },
        },
        [2757] = {
          ["empty"] = {
            { 0, 120 },
            { 120, 180 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2758] = {
          ["empty"] = {
            { 0, 120 },
            { 120, 180 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2759] = {
          ["empty"] = {
            { 0, 130 },
            { 130, 210 },
          },
          ["tactical"] = {
            { 0, 130, 205, 210 },
          },
        },
        [2760] = {
          ["empty"] = {
            { 0, 175 },
            { 175, 210 },
          },
          ["tactical"] = {
            { 0, 125 },
          },
        },
        [2761] = {
          ["empty"] = {
            { 0, 110 },
            { 110, 180 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2762] = {
          ["empty"] = {
            { 0, 125 },
            { 125, 185 },
          },
          ["tactical"] = {
            { 0, 130 },
          },
        },
        [2763] = {
          ["empty"] = {
            { 0, 140 },
            { 140, 220 },
          },
          ["tactical"] = {
            { 0, 150 },
          },
        },
        [2764] = {
          ["empty"] = {
            { 0, 165 },
            { 165, 280 },
          },
          ["tactical"] = {
            { 0, 165 },
          },
        },
        [2765] = {
          ["empty"] = {
            { 0, 256 },
            { 256, 350 },
          },
          ["tactical"] = {
            { 0, 265 },
          },
        },
        [2766] = {
          ["empty"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 145 },
          },
          ["tactical"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 145 },
          },
        },
        [2767] = {
          ["empty"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 145 },
          },
          ["tactical"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 145 },
          },
        },
        [2768] = {
          ["empty"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 145 },
          },
          ["tactical"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 145 },
          },
        },
        [2769] = {
          ["empty"] = {
            { 0, 93 },
            { 125, 148 },
            { 148, 160 },
          },
          ["tactical"] = {
            { 0, 93 },
            { 125, 148 },
            { 148, 160 },
          },
        },
        [2770] = {
          ["empty"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 130 },
          },
          ["tactical"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 130 },
          },
        },
        [2771] = {
          ["only"] = {
            { 0, 145 },
          },
        },
        [2772] = {
          ["only"] = {
            { 0, 80 },
            { 80, 101 },
            { 101, 127 },
            { 127, 180 },
          },
        },
        [2773] = {
          ["empty"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 130 },
          },
          ["tactical"] = {
            { 0, 89 },
            { 90, 115 },
            { 115, 130 },
          },
        },
        [2774] = {
          ["empty"] = {
            { 0, 90 },
            { 212, 232 },
            { 232, 242 },
          },
          ["tactical"] = {
            { 0, 90 },
            { 212, 232 },
            { 232, 242 },
          },
        },
        [2775] = {
          ["empty"] = {
            { 0, 100 },
            { 100, 135 },
            { 135, 170 },
          },
          ["tactical"] = {
            { 0, 80 },
            { 100, 135 },
            { 135, 170 },
          },
        },
        [2776] = {
          ["only"] = {
            { 0, 200 },
          },
        },
        [2777] = {
          ["only"] = {
            { 0, 150 },
          },
        },
        [2778] = {
          ["only"] = {
            { 0, 150 },
          },
        },
        [2779] = {
          ["only"] = {
            { 0, 150 },
          },
        },
        [2780] = {
          ["only"] = {
            { 0, 220 },
          },
        },
        [2781] = {
          ["only"] = {
            { 0, 170 },
          },
        },
        [2782] = {
          ["only"] = {
            { 0, 165 },
          },
        },
        [2783] = {
          ["only"] = {
            { 0, 107 },
          },
        },
        [2784] = {
          ["only"] = {
            { 0, 220 },
          },
        },
        [2785] = {
          ["empty"] = {
            { 0, 110 },
            { 110, 180 },
          },
          ["tactical"] = {
            { 0, 110 },
          },
        },
        [2786] = {
          ["empty"] = {
            { 0, 147 },
            { 147, 210 },
          },
          ["tactical"] = {
            { 0, 165 },
          },
        },
        [2787] = {
          ["only"] = {
            { 0, 200 },
          },
        },
        [2788] = {
          ["only"] = {
            { 0, 30 },
            { 30, 50 },
            { 50, 80 },
            { 80, 150 },
            { 150, 170 },
          },
        },
        [2789] = {
          ["only"] = {
            { 0, 215 },
          },
        },
        [2790] = {
          ["only"] = {
            { 0, 140 },
          },
        },
        [2791] = {
          ["only"] = {
            { 0, 160 },
          },
        },
        [2792] = {
          ["empty"] = {
            { 0, 90 },
          },
          ["tactical"] = {
            { 0, 60 },
          },
        },
        [2793] = {
          ["empty"] = {
            { 0, 70 },
            { 70, 90 },
          },
          ["tactical"] = {
            { 0, 70 },
          },
        },
        [2794] = {
          ["empty"] = {
            { 0, 65 },
            { 65, 120 },
          },
          ["tactical"] = {
            { 0, 80 },
          },
        },
        [2795] = {
          ["only"] = {
            { 0, 125 },
            { 125, 186 },
            { 186, 270 },
          },
        },
        [2796] = {
          ["only"] = {
            { 0, 125 },
            { 125, 186 },
            { 186, 318 },
          },
        },
        [2797] = {
          ["only"] = {
            { 0, 100 },
          },
        },
        [2798] = {
          ["only"] = {
            { 0, 140 },
          },
        },
        [2799] = {
          ["only"] = {
            { 0, 110 },
          },
        },
        [2800] = {
          ["only"] = {
            { 0, 140 },
          },
        },
        [2801] = {
          ["empty"] = {
            { 0, 95 },
            { 95, 120 },
          },
          ["tactical"] = {
            { 0, 80 },
          },
        },
        [2802] = {
          ["only"] = {
            { 0, 160 },
          },
        },
        [2803] = {
          ["only"] = {
            { 0, 125 },
          },
        },
        [2804] = {
          ["only"] = {
            { 0, 160 },
          },
        },
        [2805] = {
          ["only"] = {
            { 0, 275 },
          },
        },
        [2806] = {
          ["empty"] = {
            { 0, 95 },
            { 95, 120 },
          },
          ["tactical"] = {
            { 0, 80 },
          },
        },
        [2807] = {
          ["empty"] = {
            { 0, 60 },
            { 60, 90 },
          },
          ["tactical"] = {
            { 0, 70 },
          },
        },
        [2808] = {
          ["only"] = {
            { 0, 40 },
            { 40, 150 },
            { 150, 185 },
          },
        },
        [2809] = {
          ["only"] = {
            { 0, 160 },
          },
        },
        [2810] = {
          ["empty"] = {
            { 0, 85 },
            { 85, 145 },
          },
          ["tactical"] = {
            { 0, 75 },
          },
        },
        [2811] = {
          ["empty"] = {
            { 0, 165 },
            { 165, 299 },
          },
          ["tactical"] = {
            { 0, 250 },
          },
        },
        [2812] = {
          ["empty"] = {
            { 0, 330 },
            { 330, 430 },
          },
          ["tactical"] = {
            { 0, 300, 429, 430 },
          },
        },
        [2813] = {
          ["empty"] = {
            { 0, 250 },
            { 250, 290 },
          },
          ["tactical"] = {
            { 0, 135 },
          },
        },
        [2814] = {
          ["only"] = {
            { 0, 120 },
          },
        },
        [2815] = {
          ["only"] = {
            { 0, 110 },
          },
        },
        [2816] = {
          ["only"] = {
            { 0, 250 },
          },
        },
        [2817] = {
          ["only"] = {
            { 0, 235 },
          },
        },
        [2818] = {
          ["only"] = {
            { 0, 235 },
          },
        },
        [2819] = {
          ["only"] = {
            { 0, 190 },
          },
        },
        [2820] = {
          ["empty"] = {
            { 0, 120 },
            { 120, 180 },
          },
          ["tactical"] = {
            { 0, 120 },
          },
        },
        [2821] = {
          ["only"] = {
            { 0, 480 },
          },
        },
        [2822] = {
          ["empty"] = {
            { 0, 400 },
          },
          ["tactical"] = {
            { 0, 400 },
          },
        },
        [2823] = {
          ["only"] = {
            { 0, 305 },
          },
        },
        [2824] = {
          ["only"] = {
            { 0, 360 },
          },
        },
        [2825] = {
          ["empty"] = {
            { 0, 235 },
            { 235, 320 },
          },
          ["tactical"] = {
            { 0, 269, 319, 320 },
          },
        },
        [2826] = {
          ["only"] = {
            { 0, 110 },
            { 110, 157 },
            { 157, 210 },
          },
        },
        [2827] = {
          ["only"] = {
            { 0, 20 },
          },
        },
        [2828] = {
          ["only"] = {
            { 0, 485 },
          },
        },
        [2829] = {
          ["only"] = {
            { 0, 290 },
          },
        },
        [2830] = {
          ["only"] = {
            { 0, 200 },
          },
        },
        [2831] = {
          ["only"] = {
            { 0, 60 },
          },
        },
        [2832] = {
          ["empty"] = {
            { 0, 330 },
            { 330, 430 },
          },
          ["tactical"] = {
            { 0, 300, 429, 430 },
          },
        },
        [2833] = {
          ["empty"] = {
            { 0, 256 },
            { 256, 350 },
          },
          ["tactical"] = {
            { 0, 265 },
          },
        },
        [2834] = {
          ["only"] = {
            { 0, 230 },
            { 230, 245 },
          },
        },
        [2835] = {
          ["empty"] = {
            { 0, 256 },
            { 256, 350 },
          },
          ["tactical"] = {
            { 0, 265 },
          },
        },
        [2836] = {
          ["only"] = {
            { 0, 190 },
          },
        },
        [2837] = {
          ["only"] = {
            { 0, 190 },
          },
        },
        [2838] = {
          ["only"] = {
            { 0, 85 },
          },
        },
      },
      ["cells"] = {
        ["gate"] = "reloading",
        ["elapsed"] = "action_elapsed",
        ["length"] = "action_length",
        ["step"] = "reload_step",
      },
    },
    ["attach"] = {
      ["global"] = 53634712,
      ["map"] = 24,
      ["at"] = 56,
      ["stride"] = 172,
    },
    ["session"] = {
      ["global"] = 53634720,
      ["id"] = 8,
    },
    ["hud_widgets"] = {
      ["at"] = 54973752,
      ["mission_hud"] = 2417472,
      ["fields"] = {
        ["screen_x"] = {
          148,
          "f32",
        },
        ["screen_y"] = {
          156,
          "f32",
        },
        ["size_x"] = {
          36,
          "f32",
        },
        ["size_y"] = {
          40,
          "f32",
        },
        ["screen_scale"] = {
          100,
          "f32",
        },
        ["shown"] = {
          84,
          "f32",
        },
      },
      ["widgets"] = {
        ["self_weapon"] = {
          ["base"] = 1,
          ["at"] = 2064,
        },
        ["self_health"] = {
          ["base"] = 1,
          ["at"] = 2960,
        },
        ["crosshair"] = {
          ["base"] = 1,
          ["at"] = 1684632,
          ["want"] = true,
        },
        ["crosshair_dot"] = {
          ["base"] = 1,
          ["at"] = 1685320,
          ["want"] = true,
        },
        ["stamina_b"] = {
          ["base"] = 1,
          ["at"] = 26632,
        },
      },
      ["rows"] = {
        ["squad_row"] = {
          ["base"] = 1,
          ["first"] = 131192,
          ["stride"] = 42656,
          ["at"] = 0,
          ["count"] = 3,
        },
        ["squad_pack"] = {
          ["base"] = 1,
          ["first"] = 131192,
          ["stride"] = 42656,
          ["at"] = 32224,
          ["count"] = 3,
        },
        ["squad_slot_1"] = {
          ["base"] = 1,
          ["first"] = 131192,
          ["stride"] = 42656,
          ["at"] = 33880,
          ["count"] = 3,
        },
        ["squad_slot_2"] = {
          ["base"] = 1,
          ["first"] = 131192,
          ["stride"] = 42656,
          ["at"] = 35536,
          ["count"] = 3,
        },
        ["squad_weapon"] = {
          ["base"] = 1,
          ["first"] = 131192,
          ["stride"] = 42656,
          ["at"] = 9824,
          ["count"] = 3,
        },
      },
    },
    ["hud_squad"] = {
      ["at"] = 54973752,
      ["mission_hud"] = 2417472,
      ["panel"] = 129224,
      ["first"] = 1696,
      ["stride"] = 42656,
      ["count"] = 3,
      ["values"] = {
        ["player"] = {
          42604,
          "u32",
        },
        ["filled"] = {
          0,
          "bit",
          4,
        },
      },
    },
    ["hud_gate"] = {
      ["at"] = 54973752,
      ["mission_hud"] = 2417472,
      ["values"] = {
        ["gate_run"] = {
          88,
          "u8",
        },
        ["gate_ready"] = {
          2225584,
          "u8",
        },
      },
      ["skip"] = 55068552,
      ["manager_values"] = {
        ["map_open"] = {
          4125437,
          "u8",
        },
        ["weapon_flag"] = {
          2505800,
          "u8",
        },
      },
    },
    ["hud_override"] = {
      ["global"] = 53634728,
      ["values"] = {
        ["over_active"] = {
          704,
          "u32",
        },
        ["over_weapon"] = {
          3264,
          "u32",
        },
        ["over_health"] = {
          3268,
          "u32",
        },
        ["over_stamina"] = {
          3272,
          "u32",
        },
      },
    },
    ["hud_target"] = {
      ["at"] = 54973752,
      ["mission_hud"] = 2417472,
      ["panel"] = 96,
      ["values"] = {
        ["seen_health"] = {
          22146,
          "u8",
        },
        ["seen_weapon"] = {
          22147,
          "u8",
        },
      },
    },
    ["atlas_index"] = {
      ["module"] = "exe",
      ["global"] = 27328968,
      ["owner"] = 1016,
      ["array"] = 672,
      ["count"] = 688,
      ["buckets"] = 692,
      ["levels"] = {
        ["owner"] = 824,
        ["table"] = 7224,
        ["count"] = 288,
        ["buckets"] = 292,
      },
    },
    ["resource_index"] = {
      ["module"] = "exe",
      ["global"] = 27328968,
      ["owner"] = 1016,
      ["types"] = {
        ["at"] = 744,
        ["array"] = 8,
        ["count"] = 24,
        ["buckets"] = 28,
      },
      ["rows"] = {
        ["blocks"] = 16,
        ["array"] = 40,
        ["count"] = 56,
        ["buckets"] = 60,
      },
    },
    ["comms"] = {
      ["global"] = 55037488,
      ["first"] = 8,
      ["last"] = 12,
      ["at"] = 16,
      ["stride"] = 88,
      ["slots"] = 128,
      ["values"] = {
        ["kind"] = {
          0,
          "u32",
        },
        ["at_x"] = {
          4,
          "f32",
        },
        ["at_y"] = {
          8,
          "f32",
        },
        ["lifetime"] = {
          16,
          "f32",
        },
        ["elapsed"] = {
          20,
          "f32",
        },
        ["owner"] = {
          24,
          "u32",
        },
        ["picture"] = {
          56,
          "hash64",
        },
      },
      ["call_kind"] = 20,
    },
    ["stratagem_slots"] = {
      ["global"] = 55037520,
      ["count"] = 184832,
      ["at"] = 56,
      ["stride"] = 5776,
      ["key"] = 0,
      ["key_from"] = {
        ["at"] = 712,
        ["stride"] = 56,
        ["of"] = 53634152,
      },
      ["rows"] = {
        ["at"] = 392,
        ["stride"] = 48,
        ["count"] = 1928,
        ["slots"] = 16,
        ["values"] = {
          ["record"] = {
            0,
            "u32",
          },
          ["uses"] = {
            4,
            "u32",
          },
          ["chosen"] = {
            9,
            "u8",
          },
          ["reuse_due"] = {
            24,
            "u64",
          },
          ["call_due"] = {
            32,
            "u64",
          },
        },
        ["pick"] = {
          ["cell"] = "chosen",
          ["is"] = 0,
        },
        ["spent"] = {
          ["cell"] = "spent",
          ["from"] = "uses",
        },
        ["ready"] = {
          ["call"] = {
            ["span"] = "call_span",
            ["left"] = "call_left",
            ["done"] = "call_done",
          },
          ["reuse"] = {
            ["span"] = "reuse_span",
            ["done"] = "reuse_done",
            ["unless"] = "spent",
            ["near"] = {
              ["cell"] = "reuse_soon",
              ["at"] = 5,
            },
          },
        },
        ["value_rows"] = {
          {
            ["by"] = "record",
            ["at"] = 58504704,
            ["stride"] = 8,
            ["slots"] = 151,
            ["span"] = 184,
            ["values"] = {
              ["picture"] = {
                176,
                "hash64",
              },
            },
            ["through"] = "pointer",
          },
        },
      },
      ["clock"] = {
        ["global"] = 53633864,
        ["at"] = 24,
      },
      ["shared"] = {
        ["global"] = 53634720,
        ["live"] = 8,
        ["due"] = 80,
      },
    },
    ["wired"] = {
      {
        ["of"] = "backpack",
        ["cell"] = "feeds_resource",
        ["against"] = "hand-weapon",
        ["into"] = "backpack",
        ["as"] = "spares_hand",
        ["match"] = "resource",
      },
      {
        ["of"] = "backpack",
        ["cell"] = "feeds_resource",
        ["against"] = "hand-weapon",
        ["into"] = "hand-weapon",
        ["as"] = "fed_by_pack",
        ["match"] = "resource",
      },
    },
    ["roster"] = {
      ["at"] = 53634152,
      ["pointers"] = 232,
      ["pointer_stride"] = 8,
      ["id"] = 8,
      ["unit"] = 936,
      ["unit_stride"] = 32,
      ["count"] = 132,
      ["unit_count"] = 132,
      ["rows"] = {
        ["global"] = 53634296,
        ["map"] = 2352,
        ["at"] = 2700,
        ["stride"] = 64,
        ["values"] = {
          ["booster"] = {
            0,
            "u32",
          },
        },
      },
      ["at_most_zero"] = {
        ["dead"] = "health",
      },
      ["from_marker"] = {
        ["ping"] = "picture",
      },
      ["value_rows"] = {
        {
          ["by"] = "booster",
          ["at"] = 53467800,
          ["stride"] = 56,
          ["slots"] = 21,
          ["span"] = 32,
          ["values"] = {
            ["booster"] = {
              24,
              "hash64",
            },
          },
        },
      },
      ["reads"] = {
        "HealthComponent",
      },
    },
    ["remaining"] = {
      ["recharge"] = {
        "recharge_max",
        "recharge_spent",
      },
      ["energy"] = {
        "energy_max",
        "energy_spent",
      },
    },
    ["charged"] = {
      ["heat"] = {
        ["add"] = "heat_charge",
        ["per"] = "heat_charge_max",
        ["times"] = "shot_heat",
      },
    },
    ["adds_only_when_mine"] = "raw_wielded_by",
    ["picks"] = {
      ["fuse_icon"] = {
        ["parts"] = {
          "fuse_icon_0",
          "fuse_icon_1",
          "fuse_icon_2",
          "fuse_icon_3",
          "fuse_icon_4",
          "fuse_icon_5",
        },
        ["by"] = "fuse_pick",
      },
      ["program_kind"] = {
        ["parts"] = {
          "program_0",
          "program_1",
        },
        ["by"] = "raw_options",
        ["slot"] = 1,
      },
      ["detonator_icon"] = {
        ["parts"] = {
          "c4_icon_0",
          "c4_icon_1",
        },
        ["by"] = "raw_options",
        ["slot"] = 4,
      },
      ["underbarrel_icon"] = {
        ["parts"] = {
          false,
          "ub_icon_1",
        },
        ["by"] = "raw_options",
        ["slot"] = 5,
      },
    },
    ["counts"] = {
      ["mode_choices"] = {
        "authored_mode_1",
        "authored_mode_2",
        "authored_mode_3",
      },
      ["zeroing_choices"] = {
        "zeroing_0",
        "zeroing_1",
        "zeroing_2",
      },
      ["ammo_choices"] = {
        "kind_0",
        "kind_1",
      },
      ["program_choices"] = {
        "program_0",
        "program_1",
      },
      ["rof_choices"] = {
        "rof_0",
        "rof_1",
        "rof_2",
      },
    },
    ["nonzero"] = {
      ["reload_held"] = "reload_stage",
      ["has_spare"] = "spare_capacity",
      ["magazine_fed"] = "ammo_max",
      ["rounds_fed"] = "capacity_0",
      ["heat_fed"] = "heat_max",
    },
    ["none_of"] = {
      ["own_resource"] = {
        "feeds_resource",
        "chain_weapon",
      },
    },
    ["needs"] = {
      ["action"] = {
        "hand-weapon",
      },
      ["attach"] = {
        "backpack",
        "throwable",
      },
      ["avatar_state"] = {
        "avatar",
      },
      ["comms"] = {
        "seat-1",
        "seat-2",
        "seat-3",
        "seat-4",
      },
      ["hud_squad"] = {
        "seat-1",
        "seat-2",
        "seat-3",
        "seat-4",
        "stratagem-1",
        "stratagem-2",
        "stratagem-3",
        "stratagem-4",
      },
      ["roster"] = {
        "seat-1",
        "seat-2",
        "seat-3",
        "seat-4",
        "stratagem-1",
        "stratagem-2",
        "stratagem-3",
        "stratagem-4",
      },
      ["stratagem_slots"] = {
        "stratagem-1",
        "stratagem-2",
        "stratagem-3",
        "stratagem-4",
      },
      ["wired"] = {
        "backpack",
        "hand-weapon",
      },
    },
  },
  ["axes"] = {
    {
      ["id"] = "hud",
      ["resource"] = "mods/hd2_hud/frag_hud",
    },
    {
      ["id"] = "idle",
      ["resource"] = "mods/hd2_hud/frag_idle",
    },
    {
      ["id"] = "squad",
      ["resource"] = "mods/hd2_hud/frag_squad",
    },
    {
      ["id"] = "reticle",
      ["resource"] = "mods/hd2_hud/frag_reticle",
    },
    {
      ["id"] = "stratagem",
      ["resource"] = "mods/hd2_hud/frag_stratagem",
    },
  },
}

local __contract_ok_1, __contract_export_1 = pcall(function() return GeneratedCommon end)
if not __contract_ok_1 or __contract_export_1 == nil then error("30-generated-common: missing export GeneratedCommon", 0) end
return {["GeneratedCommon"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("30-generated-common", false))
local __exports = __module_run("30-generated-common", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["GeneratedCommon"] = __exports["GeneratedCommon"]
end
end
do
local __imports = {}
__imports["ResourceLoad"] = __module_registry["ResourceLoad"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("35-fragments: imports must be a table", 0) end
local ResourceLoad = imports["ResourceLoad"]
if ResourceLoad == nil then error("35-fragments: missing import ResourceLoad", 0) end

local Fragments = (function()
  local Core = { VERSION = "fragments-v2" }
  local CONTRACT = "hud-nodes-v4"
  local TABLE_SECTIONS = { "snapshot", "signals", "role_tables",
    "authored_base", "information" }
  local LAYOUT_SECTIONS = { "places", "spots" }

  local function absorb(into, from)
    for key, value in pairs(from or {}) do into[key] = value end
  end


  local function relations_reached(relations, present)
    local keep, queue = {}, {}
    local function take(name)
      if relations[name] ~= nil and not keep[name] then
        keep[name] = true
        queue[#queue + 1] = name
      end
    end
    for name in pairs(present) do take(name) end
    local index = 1
    while index <= #queue do
      local of = relations[queue[index]].of
      if type(of) == "string" then take(of)
      elseif type(of) == "table" then
        for at = 1, #of do take(of[at]) end
      end
      index = index + 1
    end
    local out = {}
    for name in pairs(keep) do out[name] = relations[name] end
    return out
  end

  local function native_for(native, places, relations, spots)
    if native == nil then return native end
    local out = {}
    local needs = native.needs or {}
    for section, value in pairs(native) do
      local wants, live = needs[section], false
      if wants == nil then
        live = true
      else
        for index = 1, #wants do
          if relations[wants[index]] then live = true break end
        end
      end
      if live then out[section] = value end
    end
    if out.relations ~= nil then
      out.relations = relations_reached(out.relations, relations)
    end
    local spec = out.hud_widgets
    if spec == nil then return out end
    local wanted = {}
    for _, place in pairs(places) do
      local row = place
      local name = place.spot
      if type(name) == "string" and (spots or {})[name] ~= nil then
        row = spots[name]
      end
      local names = row.widget
      if type(names) ~= "table" then names = { names } end
      for index = 1, #names do wanted[names[index]] = true end
      if type(row.shown_from) == "string" then wanted[row.shown_from] = true end
    end
    local kept = {}
    absorb(kept, spec)
    kept.widgets, kept.rows = {}, {}
    local any = false
    for name, row in pairs(spec.widgets or {}) do
      if wanted[name] or row.want then kept.widgets[name], any = row, true end
    end
    for name, row in pairs(spec.rows or {}) do
      if wanted[name] or row.want then kept.rows[name], any = row, true end
    end
    out.hud_widgets = any and kept or nil
    return out
  end

  local function empty(common)
    local layout = common.layout or {}
    local out = { contract = CONTRACT, info_owners = common.info_owners,
      identity = common.identity, native = native_for(common.native, {}, {}),
      axis_icons = common.axis_icons,
      books = common.books,
      relations = {}, calls = {}, guest_order = {}, nodes = {},
      layout = { style = {}, palette = layout.palette, primitives = layout.primitives,
        groups = layout.groups,
        icon_cells = layout.icon_cells,
        icon_cell_shape = layout.icon_cell_shape,
        icon_pages = layout.icon_pages,
        door_pages = layout.door_pages,
        places = {}, spots = {} } }
    absorb(out.layout.style, layout.style)
    for _, name in ipairs(TABLE_SECTIONS) do out[name] = {} end
    return out
  end

  function Core.merge(common, load)
    common, load = common or {}, load or ResourceLoad.load
    local out = empty(common)
    local counts = { axes = 0, loaded = 0, absent = 0, rows = 0,
      no_require = 0, not_installed = 0, load_failed = 0, not_found = 0,
      not_a_table = 0, styled = 0, incompatible = 0 }
    if common.contract ~= CONTRACT then
      counts.incompatible = 1
      return out, counts
    end
    local present, called, keys = {}, {}, {}
    for _, axis in ipairs(common.axes or {}) do
      counts.axes = counts.axes + 1
      local part, why = load(axis.resource)
      if part == nil then
        counts.absent = counts.absent + 1
        if why == "no-require" then counts.no_require = counts.no_require + 1
        elseif why == "not-installed" then counts.not_installed = counts.not_installed + 1
        elseif why == "load-failed" then counts.load_failed = counts.load_failed + 1
        elseif why == "not-a-table" then counts.not_a_table = counts.not_a_table + 1
        else counts.not_found = counts.not_found + 1 end
      elseif part.contract ~= CONTRACT then
        counts.incompatible = counts.incompatible + 1
      else
        counts.loaded = counts.loaded + 1
        for _, relation in ipairs(part.relations or {}) do present[relation] = true end
        for _, relation in ipairs(part.calls or {}) do called[relation] = true end
        for _, name in ipairs(TABLE_SECTIONS) do absorb(out[name], part[name]) end
        for _, name in ipairs(LAYOUT_SECTIONS) do
          for key, value in pairs((part.layout or {})[name] or {}) do
            if out.layout[name][key] ~= nil then
              counts.incompatible = counts.incompatible + 1
            else out.layout[name][key] = value end
          end
        end
        if part.idle_ratio ~= nil then
          out.layout.style.idle_ratio = part.idle_ratio
          counts.styled = counts.styled + 1
        end
        for _, node in ipairs(part.nodes or {}) do
          if keys[node.key] then counts.incompatible = counts.incompatible + 1
          else
            keys[node.key] = true
            out.nodes[#out.nodes + 1] = node
          end
        end
      end
    end
    if counts.incompatible > 0 then return empty(common), counts end
    for relation in pairs(present) do out.relations[#out.relations + 1] = relation end
    table.sort(out.relations)
    for relation in pairs(called) do out.calls[#out.calls + 1] = relation end
    table.sort(out.calls)
    out.native = native_for(common.native, out.layout.places, called, out.layout.spots)
    table.sort(out.nodes, function(left, right) return left.key < right.key end)
    for _, candidates in pairs(out.information) do counts.rows = counts.rows + #candidates end
    for _, name in ipairs(common.guest_precedence or {}) do
      if present[name] then out.guest_order[#out.guest_order + 1] = name end
    end
    return out, counts
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return Fragments end)
if not __contract_ok_1 or __contract_export_1 == nil then error("35-fragments: missing export Fragments", 0) end
return {["Fragments"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("35-fragments", true))
local __exports = __module_run("35-fragments", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["Fragments"] = __exports["Fragments"]
end
end
do
local __imports = {}
__imports["NativeMemory"] = __module_registry["NativeMemory"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("36-addon-discovery: imports must be a table", 0) end
local NativeMemory = imports["NativeMemory"]
if NativeMemory == nil then error("36-addon-discovery: missing import NativeMemory", 0) end
local AddonDiscovery = (function()
  local Core = { VERSION = "addon-discovery-v1" }
  local FAMILY = "9ba626afa44a3aa3"
  local LUA_TYPE = "\226\023\209\044\250\141\078\161"
  local DECLARATION = '^local HD2_HUD_ADDON = "(mods/[%w_]+/[%w_/]+)"\r?\n'
  local HEADER, TYPE_ROW, ENTRY_ROW, MAGIC = 72, 32, 80, 0xf0000011
  local PREFIX = 256

  local LIMB = 65536
  local M = { 0xe995, 0x5bd1, 0xa793, 0xc6a4 }

  local function mul(a, b)
    local out, carry = {}, 0
    for i = 1, 4 do
      local sum = carry
      for j = 1, i do sum = sum + a[j] * b[i - j + 1] end
      out[i] = sum % LIMB
      carry = math.floor(sum / LIMB)
    end
    return out
  end

  local function xor16(x, y)
    local out, bit = 0, 1
    for _ = 1, 16 do
      local p, q = x % 2, y % 2
      if p ~= q then out = out + bit end
      x, y, bit = (x - p) / 2, (y - q) / 2, bit * 2
    end
    return out
  end

  local function xor(a, b)
    return { xor16(a[1], b[1]), xor16(a[2], b[2]), xor16(a[3], b[3]), xor16(a[4], b[4]) }
  end

  local function shift47(a)
    return { (math.floor(a[3] / 32768) + a[4] * 2) % LIMB, math.floor(a[4] / 32768), 0, 0 }
  end

  local function word(text, at)
    local limbs = {}
    for i = 1, 4 do
      local low = text:byte(at + 2 * i - 2) or 0
      local high = text:byte(at + 2 * i - 1) or 0
      limbs[i] = low + high * 256
    end
    return limbs
  end

  function Core.hash(name)
    local length = #name
    local h = mul({ length % LIMB, math.floor(length / LIMB), 0, 0 }, M)
    local whole = length - length % 8
    for at = 1, whole, 8 do
      local k = mul(word(name, at), M)
      k = mul(xor(k, shift47(k)), M)
      h = mul(xor(h, k), M)
    end
    if whole < length then
      h = mul(xor(h, word(name:sub(whole + 1) .. string.rep("\0", 8), 1)), M)
    end
    h = mul(xor(h, shift47(h)), M)
    h = xor(h, shift47(h))
    local bytes = {}
    for i = 1, 4 do
      bytes[#bytes + 1] = string.char(h[i] % 256, math.floor(h[i] / 256))
    end
    return table.concat(bytes)
  end

  function Core.declared(prefix)
    local name = type(prefix) == "string" and prefix:match(DECLARATION) or nil
    if name == nil or name:find("//", 1, true) or name:sub(-1) == "/" then return nil end
    return name
  end

  local u32 = NativeMemory.u32

  local function u64(bytes, at)
    local high = u32(bytes, at + 4)
    if high > 2097151 then return nil end
    return u32(bytes, at) + high * 4294967296
  end

  local function read_at(file, at, count)
    if file:seek("set", at) ~= at then return nil end
    if count == 0 then return "" end
    local bytes = file:read(count)
    if bytes == nil or #bytes ~= count then return nil end
    return bytes
  end

  local function scan_file(file, seen, names, out)
    local size = file:seek("end")
    if size == nil or size < HEADER then return false end
    local header = read_at(file, 0, HEADER)
    if header == nil or u32(header, 0) ~= MAGIC then return false end
    local types, count = u32(header, 4), u32(header, 8)
    local first = HEADER + TYPE_ROW * types
    local last = first + ENTRY_ROW * count
    if types == 0 or last > size then return false end
    for index = 0, count - 1 do
      local row = read_at(file, first + index * ENTRY_ROW, ENTRY_ROW)
      if row == nil then return false end
      if row:sub(9, 16) == LUA_TYPE then
        local key = row:sub(1, 8)
        local at, length = u64(row, 16), u32(row, 56)
        if not seen[key] and at ~= nil and at >= last and length >= 8
           and at <= size and length <= size - at then
          local envelope = read_at(file, at, 8)
          if envelope ~= nil and u32(envelope, 4) == 2 and u32(envelope, 0) <= length - 8 then
            seen[key] = true
            local prefix = read_at(file, at + 8, math.min(u32(envelope, 0), PREFIX))
            local name = Core.declared(prefix)
            if name ~= nil and not names[name] and Core.hash(name) == key then
              names[name] = true
              out[#out + 1] = name
            end
          end
        end
      end
    end
    return true
  end

  function Core.scan(files, open)
    local ordered = {}
    for index = 1, #files do ordered[index] = files[index] end
    table.sort(ordered, function(a, b)
      if a.number ~= b.number then return a.number > b.number end
      return a.path < b.path
    end)
    local seen, names, out, faults = {}, {}, {}, 0
    for index = 1, #ordered do
      local ok, file = pcall(open, ordered[index].path, "rb")
      if ok and file ~= nil then
        local read, fine = pcall(scan_file, file, seen, names, out)
        pcall(file.close, file)
        if not read or not fine then faults = faults + 1 end
      else
        faults = faults + 1
      end
    end
    return out, faults
  end

  local CDEF = table.concat({
    "uint32_t GetModuleFileNameA(void *module, char *filename, uint32_t size);",
    "void *FindFirstFileA(const char *pattern, void *data);",
    "int FindNextFileA(void *handle, void *data);",
    "int FindClose(void *handle);",
    "uint32_t GetLastError(void);",
  }, "\n")

  local function native()
    local loader = rawget(_G, "require")
    if loader == nil then return nil, "no-require" end
    local ok, ffi = pcall(loader, "ffi")
    if not ok or ffi == nil then return nil, "ffi-unavailable" end
    pcall(ffi.cdef, CDEF)
    local loaded, kernel = pcall(ffi.load, "kernel32")
    if not loaded then return nil, "kernel32" end
    return ffi, kernel
  end

  function Core.data_folder(exe)
    if type(exe) ~= "string" then return nil end
    exe = exe:gsub("\\", "/")
    local tail = "/bin/helldivers2.exe"
    if exe:lower():sub(-#tail) ~= tail then return nil end
    return exe:sub(1, -#tail - 1) .. "/data/"
  end

  function Core.list(folder)
    local ffi, kernel = native()
    if ffi == nil then return nil, kernel end
    local data = ffi.new("uint8_t[320]")
    local handle = kernel.FindFirstFileA(folder .. FAMILY .. ".patch_*", data)
    if handle == ffi.cast("void *", -1) then return {} end
    local files = {}
    repeat
      local attributes = tonumber(ffi.cast("uint32_t *", data)[0])
      if math.floor(attributes / 16) % 2 == 0 then
        local name = ffi.string(data + 44):match("^[^%z]*")
        local number = name:match("^" .. FAMILY .. "%.patch_(%d+)$")
        if number ~= nil then
          files[#files + 1] = { path = folder .. name, number = tonumber(number) }
        end
      end
    until kernel.FindNextFileA(handle, data) == 0
    kernel.FindClose(handle)
    return files
  end

  function Core.discover()
    local ffi, kernel = native()
    if ffi == nil then return nil, kernel end
    local buffer = ffi.new("char[32768]")
    local length = kernel.GetModuleFileNameA(nil, buffer, 32768)
    if length == 0 or length >= 32768 then return nil, "exe-path" end
    local folder = Core.data_folder(ffi.string(buffer, length))
    if folder == nil then return nil, "exe-name" end
    local files, why = Core.list(folder)
    if files == nil then return nil, why end
    return (Core.scan(files, io.open))
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return AddonDiscovery end)
if not __contract_ok_1 or __contract_export_1 == nil then error("36-addon-discovery: missing export AddonDiscovery", 0) end
return {["AddonDiscovery"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("36-addon-discovery", true))
local __exports = __module_run("36-addon-discovery", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["AddonDiscovery"] = __exports["AddonDiscovery"]
end
end
do
local __imports = {}
__imports["ResourceLoad"] = __module_registry["ResourceLoad"]
__imports["AddonDiscovery"] = __module_registry["AddonDiscovery"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("37-door: imports must be a table", 0) end
local ResourceLoad = imports["ResourceLoad"]
if ResourceLoad == nil then error("37-door: missing import ResourceLoad", 0) end
local AddonDiscovery = imports["AddonDiscovery"]
if AddonDiscovery == nil then error("37-door: missing import AddonDiscovery", 0) end
local Door = (function()
  local Core = { VERSION = "door-v1" }
  local DOOR = 1
  local MAX_SLOTS = 128
  local SLOTS = { "mods/hd2_hud/addon_1", "mods/hd2_hud/addon_2",
                  "mods/hd2_hud/addon_3", "mods/hd2_hud/addon_4" }
  local KINDS = { icon = true, number = true }
  local ROLES = { "body", "ink" }

  local Instance = {}
  Instance.__index = Instance

  local function whole_slots(value)
    return type(value) == "number" and value >= 1 and value <= MAX_SLOTS and
      value == math.floor(value)
  end

  local function whole_tone(row)
    if type(row) ~= "table" then return false end
    for _, role in ipairs(ROLES) do
      local colour = row[role]
      if type(colour) ~= "table" then return false end
      for index = 1, 3 do
        if type(colour[index]) ~= "number" then return false end
      end
    end
    return row.lift == nil or (type(row.lift) == "number" and row.lift > 0)
  end

  local function names_of(discover)
    local out, seen = {}, {}
    for _, name in ipairs(SLOTS) do
      out[#out + 1], seen[name] = name, true
    end
    local ok, found = pcall(discover)
    if not ok or type(found) ~= "table" then return out, false, 0 end
    local added = 0
    for _, name in ipairs(found) do
      if type(name) == "string" and not seen[name] then
        out[#out + 1], seen[name], added = name, true, added + 1
      end
    end
    return out, true, added
  end

  function Core.new(options)
    options = options or {}
    local load = options.load or ResourceLoad.load
    local self = setmetatable({ addons = {}, log = options.log }, Instance)
    self.counters = { absent = 0, broken = 0, refused = 0, loaded = 0, faulted = 0,
                      requests = 0, dropped = 0, pages_short = 0, tones_refused = 0,
                      discovered = 0, undiscovered = 0 }
    local names, listed, added = names_of(options.discover or AddonDiscovery.discover)
    self.counters.discovered = added
    if not listed then self.counters.undiscovered = 1 end
    for index, name in ipairs(names) do
      local part, why = load(name)
      if part == nil and (why == "load-failed" or why == "not-a-table") then
        self.counters.broken = self.counters.broken + 1
      elseif part == nil then
        self.counters.absent = self.counters.absent + 1
      elseif part.door ~= DOOR or type(part.frame) ~= "function" or
             not whole_slots(part.slots) then
        self.counters.refused = self.counters.refused + 1
      else
        self.counters.loaded = self.counters.loaded + 1
        self.addons[#self.addons + 1] = { part = part, prefix = "addon" .. index .. "/",
                                          tones = {} }
      end
    end
    return self
  end

  function Instance:extend(layout)
    if #self.addons == 0 then return layout end
    local out = {}
    for key, value in pairs(layout) do out[key] = value end
    for _, section in ipairs({ "places", "icon_cells", "icon_pages", "palette" }) do
      local copy = {}
      for key, value in pairs(layout[section] or {}) do copy[key] = value end
      out[section] = copy
    end
    layout = out
    local spare, next_spare = layout.door_pages or {}, 1
    for _, addon in ipairs(self.addons) do
      local part, prefix = addon.part, addon.prefix
      for slot = 1, part.slots do
        local name = prefix .. slot
        layout.places[name] = { widget = name, corner = "center", takes = "position" }
      end
      addon.tones = {}
      for name, row in pairs(part.tones or {}) do
        if type(name) == "string" and whole_tone(row) then
          layout.palette[prefix .. name] = row
          addon.tones[name] = true
        else
          self.counters.tones_refused = self.counters.tones_refused + 1
        end
      end
      local names = {}
      for name in pairs(part.pictures or {}) do names[#names + 1] = name end
      table.sort(names)
      for _, name in ipairs(names) do
        local cell = part.pictures[name]
        local page = type(cell) == "table" and cell.page or nil
        if type(page) == "string" and layout.icon_pages[page] == nil then
          if spare[next_spare] ~= nil then
            layout.icon_pages[page] = spare[next_spare]
            next_spare = next_spare + 1
          else
            self.counters.pages_short = self.counters.pages_short + 1
            page = nil
          end
        end
        if type(page) == "string" then
          layout.icon_cells[prefix .. name] = { u = cell.u, v = cell.v, du = cell.du,
                                                dv = cell.dv, aspect = cell.aspect,
                                                page = page }
        end
      end
    end
    return layout
  end

  function Instance:frame(view, boxes)
    self.pending = {}
    for _, addon in ipairs(self.addons) do
      local ok, requests = pcall(addon.part.frame, view)
      addon.called = ok
      if not ok then
        self.counters.faulted = self.counters.faulted + 1
        if self.log ~= nil then
          self.log("DOOR fault addon=" .. addon.prefix .. " why=" .. tostring(requests))
        end
      elseif type(requests) == "table" then
        for _, request in ipairs(requests) do
          local slot = request.slot
          if not KINDS[request.kind] or not whole_slots(slot) or slot > addon.part.slots or
             type(request.x) ~= "number" or type(request.y) ~= "number" then
            self.counters.dropped = self.counters.dropped + 1
          else
            local name = addon.prefix .. slot
            boxes[name] = { x = request.x, y = request.y, w = 0, h = 0, scale = 1, shown = 1 }
            self.pending[#self.pending + 1] = { name = name, addon = addon, request = request }
            self.counters.requests = self.counters.requests + 1
          end
        end
      end
    end
    return boxes
  end

  function Instance:draw(host, told)
    for _, addon in ipairs(self.addons) do
      if addon.called ~= nil then
        for slot = 1, addon.part.slots do told[addon.prefix .. slot] = true end
      end
    end
    local requests = self.pending
    for _, entry in ipairs(requests or {}) do
      local request = entry.request
      local addon, tone = entry.addon, "normal"
      if addon.tones[request.tone] then tone = addon.prefix .. request.tone end
      local spec = { key = entry.name, id = entry.name, kind = request.kind,
        place = entry.name, group = "door", level = "active", tone = tone,
        locked = false, alpha = type(request.alpha) == "number" and request.alpha or 1 }
      if type(request.layer) == "number" and request.layer == math.floor(request.layer) then
        spec.layer = request.layer
      end
      if request.kind == "icon" then
        spec.name = entry.addon.prefix .. tostring(request.picture)
        spec.size = request.size
        spec.align = request.align
        spec.unit = true
      else
        spec.text = tostring(request.text)
        spec.font = request.size
        spec.align = request.align
      end
      host[request.kind](host, spec)
    end
    self.pending = nil
    return requests
  end

  function Instance:report()
    local out = {}
    for key, value in pairs(self.counters) do out[key] = value end
    return out
  end

  Core.SLOTS, Core.DOOR, Core.MAX_SLOTS = SLOTS, DOOR, MAX_SLOTS
  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return Door end)
if not __contract_ok_1 or __contract_export_1 == nil then error("37-door: missing export Door", 0) end
return {["Door"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("37-door", true))
local __exports = __module_run("37-door", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["Door"] = __exports["Door"]
end
end
do
local __imports = {}
__imports["EngineCall"] = __module_registry["EngineCall"]
__imports["IdentityCore"] = __module_registry["IdentityCore"]
__imports["NativeChannel"] = __module_registry["NativeChannel"]
__imports["NativeRead"] = __module_registry["NativeRead"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("40-provider: imports must be a table", 0) end
local EngineCall = imports["EngineCall"]
if EngineCall == nil then error("40-provider: missing import EngineCall", 0) end
local IdentityCore = imports["IdentityCore"]
if IdentityCore == nil then error("40-provider: missing import IdentityCore", 0) end
local NativeChannel = imports["NativeChannel"]
if NativeChannel == nil then error("40-provider: missing import NativeChannel", 0) end
local NativeRead = imports["NativeRead"]
if NativeRead == nil then error("40-provider: missing import NativeRead", 0) end

local Provider = (function()
  local Core = { VERSION = "provider-v1" }

  local function slot_of(relation)
    if relation == nil then return nil end
    return (string.gsub(relation, "%-", "_"))
  end


  local Instance = {}
  Instance.__index = Instance

  local KINDS = { "authored", "table", "axis" }

  function Core.new(generated)
    local self = setmetatable({}, Instance)
    self.generated = generated or {}
    self.identity = self.generated.identity or {}
    self.signals = self.generated.signals or {}
    self.role_tables = self.generated.role_tables or {}
    self.axis_icons = self.generated.axis_icons or {}
    self.relation_of = {}
    self.column_plan = {}
    for column, source in pairs(self.generated.snapshot or {}) do
      local row = { column = column, source = source }
      local from = source.from
      if source.const ~= nil then
        row.kind = "const"
      elseif type(from) == "string" and string.sub(from, 1, 7) == "signal:" then
        row.kind, row.name = "signal", string.sub(from, 8)
      elseif type(from) == "string" and string.sub(from, 1, 7) == "native:" then
        row.kind, row.name = "native", string.sub(from, 8)
      end
      if source.relation ~= nil then self.relation_of[source.relation] = true end
      self.column_plan[#self.column_plan + 1] = row
    end
    for _, row in pairs(self.signals) do
      if row.relation ~= nil then self.relation_of[row.relation] = true end
      for _, entry in ipairs(row.sources or {}) do
        if type(entry) == "table" and entry.relation ~= nil then
          self.relation_of[entry.relation] = true
        end
      end
    end
    table.sort(self.column_plan, function(a, b) return a.column < b.column end)
    self.kinds = { unpack(KINDS) }
    local books = {}
    for kind in pairs(self.generated.books or {}) do books[#books + 1] = kind end
    table.sort(books)
    for _, kind in ipairs(books) do self.kinds[#self.kinds + 1] = kind end
    self.native_role = {}
    for _, roles in pairs(self.role_tables) do
      for _, spec in pairs(roles) do
        if type(spec) == "string" and string.sub(spec, 1, 7) == "native:" then
          self.native_role[spec] = string.sub(spec, 8)
        elseif type(spec) == "table" and type(spec.native) == "string" then
          self.native_role[spec] = string.sub(spec.native, 8)
        end
      end
    end
    self.authored_base = self.generated.authored_base or {}
    self.book_of = self.generated.books or {}
    self.books = {}
    for _, seat in pairs(self.book_of) do
      self.books[seat.book] = self.identity[seat.book] or {}
    end
    self.native = NativeRead.new(self.generated.native, NativeChannel)
    self.counters = {
      windows = 0,
      columns_filled = 0, columns_missing = 0, columns_pinned = 0,
      seats_vacant = 0,
      signals_filled = 0,
      native_windows_empty = 0, native_filled = 0,
      native_font_read = 0, native_widgets_read = 0,
    }
    self.source_kind = {}
    for _, signal in pairs(self.signals) do
      for _, entry in ipairs(signal.sources or {}) do
        for at = 1, #self.kinds do
          if type(entry) == "table" and entry[self.kinds[at]] ~= nil then
            self.source_kind[entry] = self.kinds[at]
            break
          end
        end
      end
    end
    return self
  end

  function Instance:field(signal, role)
    local row = self.signals[signal]
    if row == nil then return nil end
    return (self.role_tables[row.roles] or {})[role]
  end

  function Instance:cell_of(signal, role, native)
    local spec = self:field(signal, role)
    local relation = (self.signals[signal] or {}).relation

    if type(spec) == "table" and spec.const ~= nil then return spec.const, true end
    local native_cell = spec ~= nil and self.native_role[spec] or nil
    if native_cell == nil then return nil, false end
    local where = relation
    if type(spec) == "table" and spec.relation ~= nil then where = spec.relation end
    local seat = native ~= nil and native[where] or nil
    if seat == nil then return nil, false end
    return seat.cells[native_cell], true
  end

  function Instance:overridden(name, entry, native)
    local row = self.signals[name] or {}
    local resource = self:seated(native, entry.relation or row.relation)
    if resource == nil then return nil end
    local value = ((self.authored_base[entry.authored] or {})[resource])
    if type(value) == "table" then
      local at = entry.from ~= nil and
        self:cell_of(name, entry.from, native) or nil
      if type(at) ~= "number" then return nil end
      value = value[at + 1]
    end
    if type(value) ~= "number" or value <= 0 then return nil end
    return value
  end

  local function labelled(names, at, slot, fallback)
    if type(names) ~= "table" then return nil end
    if slot ~= nil and type(at) == "number" then
      at = math.floor(at / (4 ^ slot)) % 4
    end
    if at == nil then
      if not fallback then return nil end
      at = 0
    end
    return names[tostring(at)]
  end

  function Instance:seated(native, relation)
    local seat = native ~= nil and relation ~= nil and native[relation] or nil
    return seat ~= nil and seat.resource or nil
  end


  function Instance:from_axis(name, entry, native)
    local spec = self:field(name, entry.from)
    local where = type(spec) == "table" and spec.relation or nil
    local seat = native ~= nil and
      native[where or (self.signals[name] or {}).relation] or nil
    local cells = seat ~= nil and seat.cells or nil
    if cells == nil then return nil end
    local wanted, held = entry.axis, false
    for index = 1, 4 do
      if cells["axis_" .. index] == wanted then held = true; break end
    end
    if not held then return nil end
    local value = self:cell_of(name, entry.from, native)
    local table_of = self.axis_icons[tostring(wanted)]
    if table_of == nil then return nil end
    if table_of.lane == "blob" then
      return type(value) == "string" and value or nil
    end
    if value == true then value = 1 elseif value == false then value = 0 end
    if type(value) ~= "number" then return nil end
    if entry.slot ~= nil then
      value = math.floor(value / (4 ^ entry.slot)) % 4
    end
    if table_of.lane == "array" then
      local reader = self.native
      if reader == nil or reader.function_icon == nil then return nil end
      return reader:function_icon(value)
    end
    local icon = table_of[tostring(value)]
    if icon ~= nil then return icon end
    return table_of["default"]
  end

  function Instance:from_book(kind, name, entry, native)
    local seat = self.book_of[kind]
    if seat == nil then
      return labelled((self.identity or {})[entry.table],
                      self:cell_of(name, entry.from, native),
                      entry.slot, false)
    end
    local resource = self:seated(native, seat.of)
    local row = resource ~= nil and self.books[seat.book][resource] or nil
    if not seat.named then
      return row ~= nil and row[entry[kind]] or nil
    end
    local at, was_read = self:cell_of(name, entry.from, native)
    return labelled(row ~= nil and row[entry[kind]] or nil,
                    at, entry.slot, was_read)
  end

  function Instance:mark_of(name, called, native, answers)
    if self.signals[called] ~= nil then return self:signal(called, native, answers) end
    local mark = self:cell_of(name, called, native)
    return mark
  end

  local SHUTS = {
    { key = "needs", shut = function(self, name, called, native, answers)
        return self:mark_of(name, called, native, answers) ~= true
      end },
    { key = "choices", shut = function(self, name, called, native)
        local count = self:cell_of(name, called, native)
        return type(count) ~= "number" or count < 2
      end },
  }

  local ADJUSTS = {
    { key = "plus_when", fix = function(self, name, entry, value, native, answers)
        if type(value) ~= "number" then return value end
        local mark = self:mark_of(name, entry.plus_when, native, answers)
        if mark == nil or mark == false or mark == 0 then return value end
        return value + 1
      end },
    { key = "unless_value", fix = function(_, _, entry, value)
        if value == entry.unless_value then return nil end
        return value
      end },
  }

  local function select_source(self, name, native, answers)
    local row = self.signals[name] or {}
    local sources = row.sources
    if sources == nil then return nil, false, "no-sources" end
    local first, last = 1, #sources
    if row.pair_of ~= nil then
      local _, _, _, _, at = self:from_sources(row.pair_of, native, answers)
      if at == nil then return nil, true, "no-answer" end
      first, last = at, at
    end
    local shut = false
    for index = first, last do
      local entry = sources[index]
      local cell = entry
      local kind = self.source_kind[entry]
      local gated = false
      if type(entry) == "table" then
        for _, door in ipairs(SHUTS) do
          if entry[door.key] ~= nil and
             door.shut(self, name, entry[door.key], native, answers) then
            gated = true
            break
          end
        end
      end
      if gated then
        shut = true
        cell = nil
      elseif kind ~= nil then
        local value
        if kind == "authored" then
          value = self:overridden(name, entry, native)
        elseif kind == "axis" then
          value = self:from_axis(name, entry, native)
        else
          value = self:from_book(kind, name, entry, native)
        end
        if value ~= nil then return value, true, nil, entry.still, index end
        cell = nil
      elseif type(entry) == "table" then
        cell = entry.from
        if entry.by ~= nil then
          local at = self:cell_of(name, entry.from, native)
          cell = nil
          if type(at) == "number" then cell = entry.by[at + 1] end
          if cell == nil and at ~= nil then
            cell = entry.by[tostring(at)]
          end
          if type(cell) == "string" and #cell == 18 and string.sub(cell, 1, 2) == "0x" then
            return cell, true, nil, entry.still, index
          end
        end
      end
      local value = nil
      if type(cell) == "number" then
        value = cell
      elseif cell ~= nil then
        if cell ~= name and self.signals[cell] ~= nil then
          value = self:signal(cell, native, answers)
        else
          value = self:cell_of(name, cell, native)
        end
      end
      if type(entry) == "table" then
        for _, step in ipairs(ADJUSTS) do
          if value ~= nil and entry[step.key] ~= nil then
            value = step.fix(self, name, entry, value, native, answers)
          end
        end
      end
      if value ~= nil then
        return value, true, nil, type(entry) == "table" and entry.still, index
      end
    end
    if shut then return nil, true, "gated" end
    for index = 1, #sources do
      local entry = sources[index]
      local relation = (type(entry) == "table" and entry.relation) or row.relation
      if native ~= nil and native[relation] ~= nil then
        return nil, true, "no-answer"
      end
    end
    return nil, true, "unread"
  end

  function Instance:from_sources(name, native, answers)
    answers = answers or {}
    local answer = answers[name]
    if answer == nil then
      local value, handled, why, still, at = select_source(self, name, native, answers)
      answer = { value = value, handled = handled, why = why,
                 still = still, at = at }
      answers[name] = answer
    end
    return answer.value, answer.handled, answer.why, answer.still, answer.at
  end



  function Instance:signal(name, native, answers)
    local listed, handled, why, still = self:from_sources(name, native, answers)
    if handled then
      if listed ~= nil then return listed, nil, still end
      return nil, why or "no-answer"
    end
    return nil, why or "no-sources"
  end

  function Instance:door_view(window, screen, log, number, mirror)
    return { memory = self.native ~= nil and self.native:door_memory() or nil,
             session = window ~= nil and window.session or nil,
             screen = screen, log = log, window = number, mirror = mirror }
  end

  function Instance:doors()
    self.counters.windows = self.counters.windows + 1
    local window = { cells = {}, bearers = {}, absent = {},
                     pinned = {} }
    if self.native ~= nil then
      window.session = self.native:session_state()
      local plane = {}
      self.native:hud_gate_cells(plane)
      window.native = plane
    end
    return window
  end

  function Instance:skipped()
    if self.native ~= nil then self.native:forget_span() end
  end

  function Instance:read(window, mirrored)
    if self.native == nil then return window end
    self.native:begin_window(mirrored)
    local font, material, atlas = self.native:ui_font()
    if font ~= nil and material ~= nil and atlas ~= nil then
      window.ui_font = { font = font, material = material, atlas = atlas }
      self.counters.native_font_read = self.counters.native_font_read + 1
    end
    local boxes = self.native:hud_boxes()
    if boxes ~= nil then
      window.hud_boxes = boxes
      self.counters.native_widgets_read = self.counters.native_widgets_read + 1
    end
    local native = self.native:window(window.native)
    if native ~= nil then window.native = native end
    local avatar = native ~= nil and native.avatar or nil
    if avatar ~= nil and avatar.cells ~= nil then
      window.aiming = avatar.cells.aiming
    end
    if native == nil then
      self.counters.native_windows_empty =
        self.counters.native_windows_empty + 1
    end
    return window
  end

  function Instance:fill(identity_result, window)
    identity_result = identity_result or {}
    local native = window.native
    local answers = {}
    for relation in pairs(self.relation_of) do
      local named = identity_result[slot_of(relation)]
      if named == false then
        self.counters.seats_vacant = self.counters.seats_vacant + 1
        window.bearers[relation] = false
      else
        local seat = native ~= nil and native[relation] or nil
        if seat ~= nil and seat.entity ~= nil then
          window.bearers[relation] = seat.entity
        end
      end
    end
    for _, plan in ipairs(self.column_plan) do
      local column, source, kind = plan.column, plan.source, plan.kind
      local value, why, still = nil, nil, nil
      if kind == "const" then
        value = source.const
      elseif kind == "signal" then
        value, why, still = self:signal(plan.name, native, answers)
        if value ~= nil then
          self.counters.signals_filled = self.counters.signals_filled + 1
        end
      elseif kind == "native" then
        local seat = native ~= nil and native[source.relation] or nil
        if seat == nil then
          why = "no-native"
        else
          value = seat.cells[plan.name]
          why = "no-native-cell"
          if value ~= nil then
            self.counters.native_filled = self.counters.native_filled + 1
          end
        end
      end
      if value ~= nil then
        window.cells[column] = value
        if still == true then
          window.pinned[column] = true
          self.counters.columns_pinned = self.counters.columns_pinned + 1
        end
        self.counters.columns_filled = self.counters.columns_filled + 1
      else
        self.counters.columns_missing = self.counters.columns_missing + 1
        window.absent[column] = why or "no-source"
      end
    end
    return window
  end

  function Instance:native_refused()
    return self.native ~= nil and self.native:refused() or nil
  end

  function Instance:report()
    local out = EngineCall.counters_of(self.counters)
    if self.native ~= nil then
      for key, value in pairs(self.native:report()) do
        out["native_" .. key] = value
      end
    end
    return out
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return Provider end)
if not __contract_ok_1 or __contract_export_1 == nil then error("40-provider: missing export Provider", 0) end
return {["Provider"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("40-provider", true))
local __exports = __module_run("40-provider", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["Provider"] = __exports["Provider"]
end
end
do
local __imports = {}
__imports["EngineCall"] = __module_registry["EngineCall"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("50-snapshot: imports must be a table", 0) end
local EngineCall = imports["EngineCall"]
if EngineCall == nil then error("50-snapshot: missing import EngineCall", 0) end

local Snapshot = (function()
  local Core = { VERSION = "snapshot-v1" }

  Core.OWNER_UNKNOWN = "owner-unknown"
  Core.OWNER_VACANT = "owner-vacant"

  local Instance = {}
  Instance.__index = Instance

  function Core.new(generated)
    local self = setmetatable({}, Instance)
    self.information, self.order = generated.information or {}, {}
    for info in pairs(self.information) do self.order[#self.order + 1] = info end
    table.sort(self.order)
    self.owner_by_key = generated.info_owners or {}
    local guest_order = generated.guest_order or {}
    self.rank = {}
    for index = 1, #guest_order do
      self.rank[guest_order[index]] = index
    end
    self.counters = {
      windows = 0, drawn = 0, empty_slots = 0,
      owner_wins = 0, guest_wins = 0, undecided = 0, owner_unknown = 0,
      owner_vacant = 0,
    }
    return self
  end

  function Instance:pick(key, rows, prepared)
    local owner = self.owner_by_key[key]
    local bearer = nil
    if owner ~= nil then
      bearer = prepared.bearers[owner]
      if bearer == false then
        self.counters.owner_vacant = self.counters.owner_vacant + 1
        return nil, Core.OWNER_VACANT, bearer
      end
      if bearer == nil then
        self.counters.owner_unknown = self.counters.owner_unknown + 1
        return nil, Core.OWNER_UNKNOWN, bearer
      end
    end
    local best, best_rank, best_step, tied, missing = nil, nil, nil, false, nil
    for index = 1, #rows do
      local row = rows[index]
      local entry = prepared.candidates[row]
      if entry == nil then
        missing = prepared.rejected[row] or missing
      else
        local rank = self.rank[entry.relation] or math.huge
        if owner ~= nil and entry.relation == owner then rank = -1 end
        local step = row.rank or math.huge
        if best_rank == nil or rank < best_rank or
           (rank == best_rank and step < best_step) then
          best, best_rank, best_step, tied = row, rank, step, false
        elseif rank == best_rank and step == best_step and row.value ~= best.value then
          tied = true
        end
      end
    end
    if best == nil then return nil, missing, bearer end
    if tied then
      self.counters.undecided = self.counters.undecided + 1
      return nil, "undecided", bearer
    end
    local how = best_rank == -1 and "owner" or "guest"
    self.counters[how .. "_wins"] = self.counters[how .. "_wins"] + 1
    return prepared.candidates[best], how, bearer
  end

  function Instance:assemble(prepared)
    self.counters.windows = self.counters.windows + 1
    local out = {
      at = prepared.at,
      diagnostics = { empty = {}, taken_by = {} },
      information = {},
    }
    local diagnostics = out.diagnostics
    for _, key in ipairs(self.order) do
      local rows = self.information[key]
      local entry, how, bearer = self:pick(key, rows, prepared)
      if entry == nil then
        self.counters.empty_slots = self.counters.empty_slots + 1
        diagnostics.empty[key] = how
        out.information[key] = { key = key, bearer = bearer,
          visibility = how == Core.OWNER_UNKNOWN and "retain" or "clear" }
      else
        out.information[key] = {
          key = key, column = entry.column, visibility = "show",
          bearer = bearer,
          value = entry.value, max = entry.max, display = entry.display,
          fraction = entry.fraction, locked = entry.locked,
          warned = entry.warned, full = entry.full,
          pinned = entry.pinned,
          raw = entry.raw,
        }
        diagnostics.taken_by[key] = how .. ":" .. entry.column
        self.counters.drawn = self.counters.drawn + 1
      end
    end
    return out
  end

  function Instance:report()
    return EngineCall.counters_of(self.counters)
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return Snapshot end)
if not __contract_ok_1 or __contract_export_1 == nil then error("50-snapshot: missing export Snapshot", 0) end
return {["Snapshot"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("50-snapshot", false))
local __exports = __module_run("50-snapshot", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["Snapshot"] = __exports["Snapshot"]
end
end
do
local __imports = {}
__imports["EngineCall"] = __module_registry["EngineCall"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("60-hud-model: imports must be a table", 0) end
local EngineCall = imports["EngineCall"]
if EngineCall == nil then error("60-hud-model: missing import EngineCall", 0) end

local HudModel = (function()
  local Core = { VERSION = "hud-model-v1" }


  local Instance = {}
  Instance.__index = Instance

  function Core.new(generated)
    local self = setmetatable({}, Instance)
    self:reset_objects()
    self.presented = {}
    for _, node in ipairs((generated or {}).nodes or {}) do
      self.presented[node.info] = true
      if node.fill_from ~= nil then self.presented[node.fill_from] = true end
    end
    local columns = (generated or {}).snapshot or {}
    self.entries = {}
    for _, rows in pairs((generated or {}).information or {}) do
      for _, row in ipairs(rows) do
        local entry = { row = row, column = row.value,
          relation = (columns[row.value] or {}).relation,
          display = row.display, reads = {} }
        self.entries[#self.entries + 1] = entry
        local function bind(target, key, name)
          if name ~= nil then
            entry.reads[#entry.reads + 1] = { target = target, key = key, name = name }
          end
        end
        entry.state = {}
        for key, name in pairs(row.display or {}) do
          if string.sub(key, -5) == "_when" then
            bind(entry.state, string.sub(key, 1, -6), name)
          end
        end
        bind(entry, "warn_level", row.warn_above)
        bind(entry, "full_level", row.full_at)
      end
    end
    self.idle_fade_seconds =
      ((generated or {}).layout or {}).style ~= nil and
      generated.layout.style.idle_fade_seconds or nil
    self.aim_settle_seconds =
      ((generated or {}).layout or {}).style ~= nil and
      generated.layout.style.aim_settle_seconds or nil
    self.aim = { rest = 0, at = nil }
    self.counters = {
      windows = 0, outputs = 0, active = 0, idle = 0, awake = 0,
      changes = 0, clock_rewinds = 0, no_value = 0, no_fraction = 0,
      no_denominator = 0, over_max = 0, locked = 0,
      bearer_turns = 0,
    }
    self.over_by = {}
    return self
  end

  function Instance:reset_objects()
    self.said = {}
  end


  function Instance:says(shape, now, awake)
    local shown = shape.visibility == "show"
    local state = self.said[shape.key]
    if state == nil then
      if not shown then return false end
      self.said[shape.key] = { value = shape.value, max = shape.max,
                               bearer = shape.bearer, at = now }
      return true
    end
    if shape.bearer ~= nil and state.bearer ~= shape.bearer then
      state.bearer, state.at = shape.bearer, now
      if shown then
        state.value = shape.value
        state.max = shape.max
      end
      self.counters.bearer_turns = self.counters.bearer_turns + 1
      return true
    end
    if shown and
       (state.value ~= shape.value or state.max ~= shape.max) then
      self.counters.changes = self.counters.changes + 1
      local speaks = state.max ~= shape.max or
                     (shape.display or {}).activity ~= "decrease" or
                     shape.value < state.value
      state.value, state.max = shape.value, shape.max
      if speaks then
        state.at = now
        return true
      end
    end
    if now < state.at then
      self.counters.clock_rewinds = self.counters.clock_rewinds + 1
      state.at = now
      return true
    end
    if shown and awake then
      state.at = now
      return true
    end
    return (now - state.at) <= self.idle_fade_seconds
  end

  function Instance:prepare_value(entry)
    if (entry.state or {}).warn then entry.warned = true end
    if entry.max == nil then return entry end
    entry.raw = entry.value
    local value = nil
    if type(entry.max) == "number" and entry.max > 0 then value = entry.value end
    if type(value) == "number" then
      if type(entry.full_level) == "number" and value >= entry.full_level then
        entry.full = true
      end
      local fraction = value / entry.max
      if fraction < 0 then fraction = 0 end
      if fraction > 1 then
        self.counters.over_max = self.counters.over_max + 1
        self.over_by[entry.column] = (self.over_by[entry.column] or 0) + 1
        fraction = 1
      end
      entry.fraction = fraction
      if type(entry.warn_level) == "number" then
        entry.warned = entry.warned == true or entry.locked == true or
                       value >= entry.warn_level
      elseif type(entry.row.warn_below) == "number" then
        entry.warned = entry.warned == true or fraction <= entry.row.warn_below
      end
    else
      self.counters.no_fraction = self.counters.no_fraction + 1
      return nil, "no-fraction"
    end
    return entry
  end

  function Instance:candidate(entry, window)
    local row = entry.row
    local cells = window.cells or {}
    local value = cells[row.value]
    if value == nil then
      self.counters.no_value = self.counters.no_value + 1
      return nil, "no-value"
    end
    if row.max ~= nil and cells[row.max] == nil then
      self.counters.no_denominator = self.counters.no_denominator + 1
      return nil, "no-denominator"
    end
    entry.value, entry.max = value, cells[row.max]
    entry.pinned = (window.pinned or {})[row.value] == true
    entry.fraction, entry.locked, entry.raw = nil, nil, nil
    entry.warned, entry.full = nil, nil
    for _, read in ipairs(entry.reads) do
      read.target[read.key] = cells[read.name]
    end
    entry.locked = entry.pinned or nil
    return self:prepare_value(entry)
  end

  function Instance:step_aim(window, now)
    local aim = self.aim
    local seconds = self.aim_settle_seconds
    local said = window.aiming
    if seconds == nil or seconds <= 0 or said == nil then
      aim.at = now
      return
    end
    if aim.at == nil or now < aim.at then
      aim.at = now
      return
    end
    local want = said ~= 0 and 0 or 1
    local step = (now - aim.at) / seconds
    aim.at = now
    if aim.rest < want then
      aim.rest = math.min(want, aim.rest + step)
    elseif aim.rest > want then
      aim.rest = math.max(want, aim.rest - step)
    end
  end

  function Instance:aim_rest()
    return self.aim.rest
  end

  function Instance:prepare(window, now)
    window = window or {}
    if type(now) ~= "number" then now = 0 end
    self:step_aim(window, now)
    local out = { candidates = {}, rejected = {}, bearers = window.bearers or {},
      at = now }
    for _, entry in ipairs(self.entries) do
      out.candidates[entry.row], out.rejected[entry.row] =
        self:candidate(entry, window)
    end
    return out
  end

  function Instance:present(assembled)
    self.counters.windows = self.counters.windows + 1
    for info, entry in pairs(assembled.information) do
      if self.presented[info] then
        if entry.visibility == "show" then
          local awake = entry.locked == true or
                        (entry.display or {}).keeps_awake == true
          entry.say = self:says(entry, assembled.at, awake)
          if awake then self.counters.awake = self.counters.awake + 1 end
          if entry.locked then self.counters.locked = self.counters.locked + 1 end
          self.counters.outputs = self.counters.outputs + 1
          local name = entry.say and "active" or "idle"
          self.counters[name] = self.counters[name] + 1
        else
          entry.say = self:says(entry, assembled.at, false)
        end
      end
    end
    return assembled
  end

  function Instance:report()
    local out = EngineCall.counters_of(self.counters)
    out.idle_fade_seconds = self.idle_fade_seconds
    for column, count in pairs(self.over_by) do
      out["over_max_" .. column] = count
    end
    return out
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return HudModel end)
if not __contract_ok_1 or __contract_export_1 == nil then error("60-hud-model: missing export HudModel", 0) end
return {["HudModel"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("60-hud-model", false))
local __exports = __module_run("60-hud-model", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["HudModel"] = __exports["HudModel"]
end
end
do
local __imports = {}
__imports["EngineCall"] = __module_registry["EngineCall"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("70-renderer: imports must be a table", 0) end
local EngineCall = imports["EngineCall"]
if EngineCall == nil then error("70-renderer: missing import EngineCall", 0) end

local Renderer = (function()
  local Core = { VERSION = "renderer-v2" }
  local Instance = {}
  Instance.__index = Instance

  function Core.new(generated)
    local self = setmetatable({}, Instance)
    local layout = generated.layout or {}
    self.places = layout.places or {}
    self.groups = layout.groups or {}
    self.nodes, self.primitives = generated.nodes or {}, layout.primitives or {}
    self.commands, self.texts, self.stacks = {}, {}, {}
    local stacked = {}
    for _, node in ipairs(self.nodes) do
      local primitive = self.primitives[node.kind]
      local place = self.places[node.place] or {}
      local alpha = node.alpha
      if alpha == nil then alpha = (layout.style or {}).alpha end
      local command = { id = node.id, key = node.key, kind = node.kind,
        place = node.place, group = node.group, alpha = alpha }
      for _, field in ipairs((primitive or {}).style or {}) do
        command[field] = node[field]
      end
      self.commands[node.key] = command
      if node.kind == "number" then self.texts[node.key] = {} end
      if primitive ~= nil and primitive.stacks and place.gap ~= nil then
        local members = stacked[node.place]
        if members == nil then
          members = {}
          stacked[node.place] = members
          self.stacks[#self.stacks + 1] = members
        end
        members[#members + 1] = node
        command.stack, command.stack_of = 1, 1
      end
    end
    self.counters = {
      frames = 0, drawn = 0, unstyled = 0, warned = 0,
    }
    for kind in pairs(self.primitives) do self.counters[kind] = 0 end
    return self
  end

  local function text_of(cached, value)
    if cached.value == value then return cached.text end
    cached.value, cached.text = value, tostring(value)
    return cached.text
  end

  local function shown(entry)
    if entry ~= nil and entry.visibility == "show" then return entry end
    return nil
  end

  local function sources(node, information)
    local entry = information[node.info]
    local resource = entry
    if node.fill_from ~= nil then
      resource = information[node.fill_from]
    end
    local warning = resource
    if node.warn_from ~= nil then warning = information[node.warn_from] end
    local frame = nil
    if node.frame_from ~= nil then frame = information[node.frame_from] end
    return entry, resource, shown(warning), shown(frame)
  end

  function Instance:draw_node(node, host, groups, entry, resource, warning, frame)
    local command = self.commands[node.key]
    local primitive = self.primitives[node.kind]
    local draw = primitive ~= nil and host[node.kind] or nil
    if draw == nil then
      self.counters.unstyled = self.counters.unstyled + 1
      return
    end
    if node.fill_from ~= nil then resource = shown(resource) end
    local warned = entry.warned == true or
      (warning ~= nil and warning.warned == true)
    command.level = groups[node.group] == true and "active" or "idle"
    command.locked = resource ~= nil and resource.locked == true
    command.tone = resource ~= nil and resource.full == true and "full" or (warned and "warn" or "normal")
    if primitive.fraction or node.fill_from ~= nil then
      local fraction = resource ~= nil and resource.fraction or nil
      if fraction ~= nil and (node.flips or {})[resource.column] then
        fraction = 1 - fraction
      end
      command.unit, command.fraction = fraction == nil, fraction
    end
    if node.kind == "icon" then
      command.name = entry.value
      command.edge = frame ~= nil and frame.value or nil
    end
    if node.kind == "number" and command.stack_of == nil then
      command.text = text_of(self.texts[node.key], entry.value)
    end
    command.requested = self.counters.frames
    self.counters[node.kind] = self.counters[node.kind] + 1
    if warned then self.counters.warned = self.counters.warned + 1 end
    draw(host, command)
    self.counters.drawn = self.counters.drawn + 1
  end

  function Instance:draw(frame, host)
    self.counters.frames = self.counters.frames + 1
    local information = frame.information
    local told, groups, activity = {}, {}, {}
    for _, node in ipairs(self.nodes) do
      local entry, resource, warning = sources(node, information)
      local command = self.commands[node.key]
      if command.stack_of ~= nil then command.stack = nil end
      if entry ~= nil then
        if entry.visibility ~= "retain" then told[node.key] = true end
        if entry.say == true or (resource ~= nil and resource.say == true) then
          activity[node.group] = true
          groups[node.group] = true
        end
        if entry.visibility == "show" then
          if warning ~= nil and warning.warned == true then
            groups[node.group] = true
          end
          if command.stack_of ~= nil then command.stack = 0 end
        end
      end
    end
    for group, rule in pairs(self.groups) do
      if rule.wake_from ~= nil and activity[rule.wake_from] == true then
        groups[group] = true
      end
    end
    for _, members in ipairs(self.stacks) do
      local count = 0
      for _, node in ipairs(members) do
        local command = self.commands[node.key]
        if command.stack ~= nil then
          count = count + 1
          command.stack = count
        end
      end
      local place = self.places[(members[1] or {}).place] or {}
      local flow, marks = nil, nil
      if place.gap ~= nil then flow, marks = {}, {} end
      for _, node in ipairs(members) do
        local command = self.commands[node.key]
        command.stack_of = count
        command.flow, command.flow_key = nil, nil
        if command.stack ~= nil then
          local value = information[node.info].value
          if node.kind == "number" then
            command.text = text_of(self.texts[node.key], value)
          end
          if flow ~= nil then
            local item = { kind = node.kind, gap = command.gap, size = command.size,
              size_by = command.size_by, font = command.font }
            if node.kind == "number" then item.text = command.text else item.name = value end
            flow[#flow + 1] = item
            marks[#marks + 1] = tostring(item.name or item.text)
          end
        end
      end
      if flow ~= nil then
        local key = table.concat(marks, "\1")
        for _, node in ipairs(members) do
          local command = self.commands[node.key]
          if command.stack ~= nil then command.flow, command.flow_key = flow, key end
        end
      end
    end
    for _, node in ipairs(self.nodes) do
      local entry, resource, warning, frame = sources(node, information)
      if entry ~= nil and entry.visibility == "show" then
        self:draw_node(node, host, groups, entry, resource, warning, frame)
      end
    end
    return told, groups
  end

  function Instance:report()
    return EngineCall.counters_of(self.counters)
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return Renderer end)
if not __contract_ok_1 or __contract_export_1 == nil then error("70-renderer: missing export Renderer", 0) end
return {["Renderer"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("70-renderer", false))
local __exports = __module_run("70-renderer", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["Renderer"] = __exports["Renderer"]
end
end
do
local __imports = {}
__imports["EngineCall"] = __module_registry["EngineCall"]
__imports["GuiHandle"] = __module_registry["GuiHandle"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("80-gui-host: imports must be a table", 0) end
local EngineCall = imports["EngineCall"]
if EngineCall == nil then error("80-gui-host: missing import EngineCall", 0) end
local GuiHandle = imports["GuiHandle"]
if GuiHandle == nil then error("80-gui-host: missing import GuiHandle", 0) end

local GuiHost = (function()
  local Core = { VERSION = "gui-host-v1" }
  local callable = EngineCall.callable

  local sr = rawget(_G, "stingray")
  local Gui = sr and rawget(sr, "Gui") or nil
  local Vector3 = sr and rawget(sr, "Vector3") or nil
  local Vector2 = sr and rawget(sr, "Vector2") or nil
  local Color = sr and rawget(sr, "Color") or nil
  local IdString64 = sr and rawget(sr, "IdString64") or nil
  local Material = sr and rawget(sr, "Material") or nil

  local DESTROY = {
    destroy_rect = function(gui, id) return Gui.destroy_rect(gui, id) end,
    destroy_triangle = function(gui, id) return Gui.destroy_triangle(gui, id) end,
    destroy_text = function(gui, id) return Gui.destroy_text(gui, id) end,
    destroy_bitmap = function(gui, id) return Gui.destroy_bitmap(gui, id) end,
  }

  local SEGMENTS = 20
  local LAYER = 3
  local DESIGN_WIDTH = 1920
  local DESIGN_HEIGHT = 1080
  local RADIUS = 120
  local FONT_SIZE = 22
  local TEXT_INK_RISE = 0.135
  local INK_SAMPLE = "0123456789"



  local TEXT_OUTLINE = 1
  local ICON_OUTLINE = 1
  local ROLE = { body = 255, ink = 190 }

  local ARC_EDGE_TOP = 2
  local function band_top(radius)
    return (radius or RADIUS) + ARC_EDGE_TOP
  end


  local UP_FROM_BOTTOM = true



  local Instance = {}
  Instance.__index = Instance

  local HEX64 = "^%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$"

  function Instance:named(value)
    if type(value) ~= "string" or value == "" then return nil end
    if not value:match(HEX64) then return value end
    if IdString64 == nil or not callable(IdString64, "from_hex") then
      return nil
    end
    local ok, packed = pcall(IdString64.from_hex, value)
    return ok and packed or nil
  end

  function Core.new(gui, options)
    local self = setmetatable({}, Instance)
    options = options or {}
    self.gui = gui
    self.generation = options.generation
    self.places = options.places or {}
    self.trace = nil
    self.drawing = nil
    local function level_row(idle)
      return {
        ["active"] = 1,
        ["idle"] = idle,
      }
    end
    self.levels = setmetatable({}, { __index = function()
      return level_row(options.idle_ratio)
    end })
    for name, row in pairs(options.groups or {}) do
      self.levels[name] = level_row(row.idle_ratio or options.idle_ratio)
    end
    self.palette = options.palette
    self.screen = nil
    self.icon_cells = options.icon_cells or {}
    self.icon_cell_shape = options.icon_cell_shape or {}
    self.cell_textures = {}
    self.aim_sway = options.aim_sway
    self.aim_sway_widget = options.aim_sway_widget
    self.sway_held = nil
    self.aim_rest_dx = options.aim_rest_dx
    self.aim_rest_dy = options.aim_rest_dy
    self.spots = options.spots or {}
    self.atlas_rows = nil
    self.material_textures = nil
    self.font_name = options.font
    self.material_name = options.material
    self.font = self:named(options.font)
    self.material = self:named(options.material)
    self.font_slot = options.font_slot
    self.font_atlas = options.font_atlas
    self.font_fallback = options.font_fallback
    self.material_fallback = options.material_fallback
    self.fell_back = false
    self.font_said = nil
    self.depth = options.depth
    self.log = options.log
    self.brackets = false
    self.icon_material_name = options.icon_material_name
    self.arc_material_name = options.arc_material_name
    self.icon_pages = options.icon_pages or {}
    self.page_slot = options.page_slot
    self.pages_ready = {}
    self.primitives = options.primitives or {}
    self.bands = {}
    self.anchors = {}
    self.font_inks = {}
    self.frame = 0
    self.counters = {
      frames = 0,
      gui_unchanged = 0, gui_updated = 0, gui_created = 0,
      gui_destroyed = 0, gui_dropped = 0,
      triangles_created = 0,
      triangles_destroyed = 0, triangles_kept = 0,
      engine_calls = 0, icon_missing = 0, unread = 0,
      generation_drops = 0, refused = 0, engine_faults = 0,
      no_anchor = 0, resolution_faults = 0, display_changes = 0,
      icon_no_cell = 0, icon_no_material = 0, icon_no_surface = 0,
      text_remade = 0, colour_faults = 0, vector_faults = 0,
      text_no_surface = 0,
      font_fell_back = 0,
      icon_no_size = 0,
      page_bound = 0, page_unbound = 0,
      cell_unnamed = 0,
      flow_unmeasured = 0,
      flow_missing = 0,
    }
    return self
  end

  function Instance:set_generation(generation, gui)
    if self.generation == generation and self.gui == gui then return end
    local dropped = 0
    for _ in pairs(self.bands) do dropped = dropped + 1 end
    self.counters.gui_dropped = self.counters.gui_dropped + dropped
    if self.generation ~= generation then
      self.counters.generation_drops = self.counters.generation_drops + 1
    end
    self.bands = {}
    for page in pairs(self.pages_ready) do self.pages_ready[page] = nil end
    for name in pairs(self.cell_textures) do self.cell_textures[name] = nil end
    self.generation = generation
    self.gui = gui
    self.screen = nil
    self.font_said = nil
  end


  function Instance:release(band)
    local name = (self.primitives[band.kind] or {}).destroy
    local fn = name ~= nil and DESTROY[name] or nil
    if fn == nil or not callable(Gui, name) then return end
    for _, id in pairs(band.ids) do
      self:engine("Gui." .. name, fn, self.gui, id)
      if name == "destroy_triangle" then
        self.counters.triangles_destroyed =
          self.counters.triangles_destroyed + 1
      end
    end
  end

  function Instance:clear_bands()
    for key, band in pairs(self.bands) do
      self:release(band)
      self.bands[key] = nil
      self.counters.gui_destroyed = self.counters.gui_destroyed + 1
    end
  end

  function Instance:measure()
    if not callable(Gui, "resolution") then return end
    local width, height = self:engine("Gui.resolution",
                                      Gui.resolution)
    if type(width) ~= "number" or type(height) ~= "number" or
       width <= 0 or height <= 0 then
      self.counters.resolution_faults = self.counters.resolution_faults + 1
      return
    end
    local across = width / DESIGN_WIDTH
    local down = height / DESIGN_HEIGHT
    local scale = (across < down and across or down)
    local now = self.screen
    if now ~= nil and now.width == width and now.height == height and
       now.scale == scale then
      return
    end
    if now ~= nil then
      self.counters.display_changes = self.counters.display_changes + 1
      self:clear_bands()
    end
    self.screen = { width = width, height = height, scale = scale }
  end

  function Instance:sized(value)
    if self.screen == nil then return value end
    return value * self.screen.scale
  end

  local function whole(value)
    if type(value) ~= "number" then return value end
    return math.floor(value + 0.5)
  end

  local function hold(value, at)
    if at == nil or math.abs(value - at) >= 1 then return whole(value) end
    return at
  end

  local function edge(name, screen, sway_x, sway_y)
    if name == "right" then return screen.width end
    if name == "top" then return screen.height end
    if name == "center_x" then return screen.width * 0.5 + sway_x end
    if name == "center_y" then return screen.height * 0.5 + sway_y end
    return 0                                    
  end

  local CORNER = {
    bottom_left = { 0, 0 }, bottom_center = { 0.5, 0 }, bottom_right = { 1, 0 },
    left_center = { 0, 0.5 }, center = { 0.5, 0.5 }, right_center = { 1, 0.5 },
    top_left = { 0, 1 }, top_center = { 0.5, 1 }, top_right = { 1, 1 },
  }

  local function widget_key(name, row)
    if row == nil then return name end
    return name .. "#" .. row
  end

  local function widget_keys(found)
    local names = found.widget
    if type(names) ~= "table" then names = { names } end
    local keys = {}
    for index = 1, #names do
      keys[index] = widget_key(names[index], found.row)
    end
    return keys
  end

  function Instance:use_widgets(boxes)
    self.widgets = boxes
  end

  function Instance:use_aim(rest)
    self.aim_rest = type(rest) == "number" and rest or nil
  end

  function Instance:crosshair_sway()
    local share, name = self.aim_sway, self.aim_sway_widget
    if type(share) ~= "number" or share == 0 or name == nil
       or self.screen == nil or self.widgets == nil then
      return 0, 0
    end
    local box = self.widgets[name]
    if box == nil or type(box.x) ~= "number" or type(box.y) ~= "number" then
      return 0, 0
    end
    local rest = type(self.aim_rest) == "number" and self.aim_rest or 0
    local live = share * (1 - rest)
    local held = self.sway_held
    if held == nil or held.screen ~= self.screen then
      held = { screen = self.screen }
      self.sway_held = held
    end
    held.x = hold(
      (box.x + (box.w or 0) * 0.5 - self.screen.width * 0.5) * live, held.x)
    held.y = hold(
      (box.y + (box.h or 0) * 0.5 - self.screen.height * 0.5) * live, held.y)
    return held.x, held.y
  end

  function Instance:spot_of(found)
    local name = found.spot
    if type(name) ~= "string" then return nil end
    return self.spots[name]
  end

  function Instance:anchor_of(place)
    local found = self.places[place]
    if found == nil then return nil, nil end
    return self:spot_of(found) or found, found
  end

  function Instance:offsets(found)
    local spot = self:spot_of(found)
    local dx, dy = found.dx or 0, found.dy or 0
    if spot ~= nil then
      dx = dx + (spot.dx or 0)
      dy = dy + (spot.dy or 0)
    end
    local rest = self.aim_rest
    local takes = spot ~= nil and spot.aim_rest == true or
                  spot == nil and found.aim_rest == true
    if type(rest) == "number" and takes then
      dx = dx + (self.aim_rest_dx or 0) * rest
      dy = dy + (self.aim_rest_dy or 0) * rest
    end
    return dx, dy
  end

  function Instance:place_box(place)
    local found = self:anchor_of(place)
    if found == nil or found.widget == nil or self.widgets == nil then
      return nil, "unread"
    end
    local position_only = found.takes == "position"
    local hidden = true
    for _, key in ipairs(widget_keys(found)) do
      local box = self.widgets[key]
      if box ~= nil and (position_only or
                         (box.shown ~= nil and box.shown > 0)) then
        return box
      end
      if box == nil or box.shown == nil then hidden = false end
    end
    return nil, hidden and "hidden" or "unread"
  end

  function Instance:place_fill(place)
    local found = self.places[place]
    if found == nil or found.fill ~= true then return nil end
    local box = self:place_box(place)
    if box == nil or type(box.w) ~= "number" or type(box.h) ~= "number" then
      return nil
    end
    return box.w, box.h
  end

  function Instance:place_zoom(place)
    local anchor = self:anchor_of(place)
    if anchor == nil then return 1 end
    local zoom = anchor.zoom
    if type(zoom) ~= "number" then return 1 end
    return zoom
  end

  function Instance:place_scale(place)
    local zoom = self:place_zoom(place)
    local box = self:place_box(place)
    if box ~= nil then return box.scale * zoom end
    if self.screen == nil then return zoom end
    return self.screen.scale * zoom
  end

  function Instance:place_alpha(place)
    local found = self:anchor_of(place)
    if found == nil or found.widget == nil then return 1 end
    if found.takes == "position" then
      return self:place_box(place) ~= nil and 1 or 0
    end
    local box = self:place_box(place)
    if box == nil then return 0 end
    if found.shown_from ~= nil then
      local lit = self.widgets ~= nil and
                  self.widgets[widget_key(found.shown_from, found.row)] or nil
      if lit == nil or lit.shown == nil then return 0 end
      return lit.shown
    end
    return box.shown
  end

  function Instance:anchor(place)
    local hit = self.anchors[place]
    if hit == nil then
      hit = {}
      self.anchors[place] = hit
    end
    if hit.frame ~= self.frame then
      hit.frame = self.frame
      hit.x, hit.y, hit.facing, hit.sweep, hit.alpha, hit.reason = self:resolve_anchor(place)
    end
    if hit.x == nil then return nil end
    return hit.x, hit.y, hit.facing, hit.sweep, hit.alpha
  end

  function Instance:pixel_seat(place)
    local x, y, _, _, alpha = self:anchor(place)
    if x == nil then return nil end
    return whole(x), whole(y), self:place_scale(place),
           alpha ~= nil and whole(alpha * 255) or nil
  end

  function Instance:resolve_anchor(place)
    local found = self.places[place]
    if found == nil or self.screen == nil then
      self.counters.no_anchor = self.counters.no_anchor + 1
      return nil
    end
    local scale = self:place_scale(place)
    local box, reason = self:place_box(place)
    if box == nil and (self:spot_of(found) or found).widget ~= nil then
      self.counters.no_anchor = self.counters.no_anchor + 1
      return nil, nil, nil, nil, nil, reason
    end
    if box ~= nil then
      local part = CORNER[(self:spot_of(found) or found).corner]
      if part == nil then
        self.counters.no_anchor = self.counters.no_anchor + 1
        return nil
      end
      local x = box.x + (box.w or 0) * part[1]
      local y = box.y + (box.h or 0) * part[2]
      local dx, dy = self:offsets(found)
      return x + dx * scale, y + dy * scale,
             found.facing, found.sweep, self:place_alpha(place)
    end
    local dx, dy = self:offsets(found)
    local spot = self:spot_of(found)
    local from_x = spot ~= nil and spot.from_x or found.from_x
    local from_up = spot ~= nil and spot.from_up or found.from_up
    local sway_x, sway_y = self:crosshair_sway()
    return edge(from_x, self.screen, sway_x, sway_y) + dx * scale,
           edge(from_up, self.screen, sway_x, sway_y) + dy * scale,
           found.facing, found.sweep, self:place_alpha(place)
  end


  local function usable(name, value)
    if name == "depth" then return type(value) == "number" end
    if name == "icon_material_name" or name == "arc_material_name" then
      return type(value) == "string" and value ~= ""
    end
    if name == "font" or name == "material" then
      if type(value) == "string" then return value ~= "" end
      return value ~= nil and not GuiHandle.dead(value)
    end
    if name == "screen" then
      return type(value) == "table" and type(value.width) == "number"
    end
    return not GuiHandle.dead(value)
  end

  function Instance:ready(kind)
    local needs = (self.primitives[kind] or {}).needs
    if needs == nil then return false end
    for index = 1, #needs do
      local name = needs[index]
      local value = self[name]
      if not usable(name, value) then
        self.counters.refused = self.counters.refused + 1
        self.refused_kinds = self.refused_kinds or {}
        self.refused_kinds[kind .. ":" .. name] =
          (self.refused_kinds[kind .. ":" .. name] or 0) + 1
        return false
      end
    end
    return true
  end

  function Instance:begin_draw(kind, place)
    self.drawing = nil
    if not self:ready(kind) then return false end
    local x, _, _, sweep = self:anchor(place)
    if x == nil then
      self.counters.refused = self.counters.refused + 1
      return false
    end
    return true, sweep
  end

  function Instance:engine(name, fn, ...)
    if self.faulted then return nil end
    self.counters.engine_calls = self.counters.engine_calls + 1
    local watched = self.log ~= nil and self.brackets == true
    if watched then
      self.log("GUI product phase=in call=" .. name ..
               " frame=" .. tostring(self.frame))
    end
    local ok, first, second = pcall(fn, ...)
    local record = self.trace ~= nil and self.drawing
    if record then
      record.calls = (record.calls or 0) + 1
      if string.find(name, "destroy", 1, true) == nil then
        record.last = ok and tostring(first) or "fault"
      end
    end
    if watched then
      self.log("GUI product phase=out call=" .. name ..
               " frame=" .. tostring(self.frame) ..
               " ok=" .. (ok and "true" or "false") ..
               " value=" .. tostring(first))
    end
    if not ok then
      self.counters.engine_faults = self.counters.engine_faults + 1
      self.faulted = true
      if self.log ~= nil then
        self.log("GUI product fault=" .. name ..
                 " why=" .. tostring(first) .. " host=disarmed")
      end
      return nil
    end
    return first, second
  end

  function Instance:watch(log, armed)
    self.log = log
    self.brackets = armed
  end


  function Instance:begin_frame()
    self.frame = self.frame + 1
    self.counters.frames = self.counters.frames + 1
    self.drawing = nil
    if self.trace ~= nil then
      for index = #self.trace, 1, -1 do self.trace[index] = nil end
    end
    self:measure()
    self:refresh_font()
    for page, ready in pairs(self.pages_ready) do
      if ready == false then self.pages_ready[page] = nil end
    end
  end

  function Instance:use_atlas(rows, textures)
    self.atlas_rows = rows
    self.material_textures = textures
  end

  local CELL_ID = "^[a-z0-9_/]+$"

  function Instance:cell_material(id, edge, curved)
    if type(id) ~= "string" or not id:match(CELL_ID) then
      self.counters.cell_unnamed = self.counters.cell_unnamed + 1
      return nil
    end
    return "mods/hd2_hud/cell_" .. id:gsub("/", "_") ..
           (curved and "_curved" or "") .. (edge and "_edge" or "")
  end

  function Instance:curved(place)
    local found = self.places[place]
    if found == nil then return false end
    if found.curve == true then return true end
    local spot = self:spot_of(found)
    return spot ~= nil and spot.curve == true
  end

  function Instance:page_material(page)
    local ready = self.pages_ready[page]
    if ready ~= nil then return ready or nil end
    local name = self.icon_pages[page]
    if name == nil then
      self.counters.page_unbound = self.counters.page_unbound + 1
      self.pages_ready[page] = false
      return nil
    end
    local bound = self:bind_texture(name, page) or nil
    self.pages_ready[page] = bound or false
    return bound
  end

  function Instance:picture_material(id, cell, picture, edge, curved)
    if picture == nil and cell.page ~= nil then
      return self:page_material(cell.page)
    end
    local name = self:cell_material(id, edge, curved)
    if name == nil then return nil end
    local texture = self.icon_material_name
    if picture ~= nil then texture = (picture:gsub("^0x", "")) end
    return self:bind_texture(name, texture)
  end

  function Instance:bound_texture(name)
    local got = self.cell_textures[name]
    if got == nil then return self.icon_material_name end
    return got
  end

  function Instance:bind_texture(name, texture)
    if self:bound_texture(name) == texture then return name end
    if self.gui == nil or not callable(Gui, "material") or
       Material == nil or not callable(Material, "set_texture") or
       self.page_slot == nil or texture == nil then
      self.counters.page_unbound = self.counters.page_unbound + 1
      return nil
    end
    local ink = self:engine("Gui.material", Gui.material, self.gui, name)
    local slot, art = self:named(self.page_slot), self:named(texture)
    if ink == nil or GuiHandle.dead(ink) or slot == nil or art == nil then
      self.counters.page_unbound = self.counters.page_unbound + 1
      return nil
    end
    self:engine("Material.set_texture", Material.set_texture, ink, slot, art)
    if self.faulted then
      self.counters.page_unbound = self.counters.page_unbound + 1
      return nil
    end
    self.cell_textures[name] = texture
    self.counters.page_bound = self.counters.page_bound + 1
    return name
  end

  function Instance:noted(x, y)
    local record = self.trace ~= nil and self.drawing
    if not record or record.x ~= nil then return end
    record.x, record.y = x, y
  end

  local SPEC_FIELDS = { "id", "place", "group", "level", "tone", "locked", "alpha", "text",
    "name", "edge", "unit", "radius", "span", "outline", "font", "align", "dy", "size", "size_by",
    "width", "height", "stack", "stack_of", "flow_key", "layer" }

  local CELL_FIELDS = { "u", "v", "du", "dv", "aspect", "page" }

  local function same_cell(before, cell)
    if before == nil or cell == nil then return before == cell end
    for _, field in ipairs(CELL_FIELDS) do
      if before[field] ~= cell[field] then return false end
    end
    return true
  end

  local function accept_cell(before, cell)
    if cell == nil then return nil end
    local mark = before or {}
    for _, field in ipairs(CELL_FIELDS) do mark[field] = cell[field] end
    return mark
  end

  local function fill_steps(kind, spec, at_scale)
    local extent = nil
    if kind == "icon" then extent = spec.size
    elseif kind == "bar" then extent = spec.width end
    if type(extent) ~= "number" or extent <= 0 then return nil end
    local steps = extent * (at_scale or 1)
    return steps > 1 and steps or 1
  end

  local function rounded(value, before, mark, steps)
    if value == before then return mark end
    if value == nil then return nil end
    if steps ~= nil then return string.format("%d", math.floor(value * steps + 0.5)) end
    return string.format("%.5f", value)
  end

  local function same_number(before, value, mark, steps)
    return before == value or rounded(value, nil, nil, steps) == mark
  end

  local function same_spec(band, spec, extra, at_x, at_y, at_scale, at_alpha, frame_cell)
    local mark = band and band.mark
    if mark == nil or not same_cell(mark.extra, extra) or
       not same_cell(mark.frame_cell, frame_cell) then return false end
    if mark.at_x ~= at_x or mark.at_y ~= at_y or
       mark.at_scale ~= at_scale or mark.at_alpha ~= at_alpha then return false end
    for _, field in ipairs(SPEC_FIELDS) do
      if mark[field] ~= spec[field] then return false end
    end
    return same_number(mark.fraction, spec.fraction, mark.rounded_fraction,
                       fill_steps(band.kind, spec, at_scale))
  end

  local function surviving_marks(marks)
    local kept = {}
    for index = 1, SEGMENTS do
      local piece = marks and marks[index]
      if piece ~= nil and piece.from == nil then kept[index] = piece end
    end
    return kept
  end

  function Instance:band_for(spec, extra, frame_cell)
    local band = self.bands[spec.key]
    if band ~= nil and band.kind ~= spec.kind then
      self:release(band)
      self.bands[spec.key] = nil
      self.counters.gui_destroyed = self.counters.gui_destroyed + 1
      band = nil
    end
    local at_x, at_y, at_scale, at_alpha = self:pixel_seat(spec.place)
    local mark = band and band.mark
    if band ~= nil and (mark == nil or mark.at_x ~= at_x or mark.at_y ~= at_y or
       mark.at_scale ~= at_scale or mark.at_alpha ~= at_alpha) then
      band.marks, band.tracks = surviving_marks(band.marks), {}
    end
    if same_spec(band, spec, extra, at_x, at_y, at_scale, at_alpha, frame_cell) then
      band.seen = self.frame
      self.counters.gui_unchanged = self.counters.gui_unchanged + 1
      self.drawing = nil
      return nil
    end
    if self.trace ~= nil then
      self.drawing = {
        id = spec.id, key = spec.key, kind = spec.kind, place = spec.place,
        alpha = spec.alpha, size = spec.size, radius = spec.radius,
        width = spec.width, height = spec.height,
        span = spec.span, font = spec.font, align = spec.align,
        text = spec.text, name = spec.name, fraction = spec.fraction,
        tone = spec.tone, level = spec.level, locked = spec.locked,
        stack = spec.stack, stack_of = spec.stack_of,
        frame = self.frame,
      }
      self.trace[#self.trace + 1] = self.drawing
    end
    if band == nil then
      band = { kind = spec.kind, ids = {}, marks = {}, tracks = {} }
      self.bands[spec.key] = band
      self.counters.gui_created = self.counters.gui_created + 1
    else
      self.counters.gui_updated = self.counters.gui_updated + 1
    end
    return band
  end

  local function same_piece(piece, from, to, spec)
    if piece == nil then return false end
    if from == nil then return piece.from == nil end
    return piece.from ~= nil and piece.level == spec.level and piece.tone == spec.tone and piece.locked == spec.locked and piece.alpha == spec.alpha
      and piece.place == spec.place and piece.radius == spec.radius
      and piece.span == spec.span
      and same_number(piece.from, from, piece.rounded_from)
      and same_number(piece.to, to, piece.rounded_to)
  end

  local function same_track(piece, spec)
    if piece == nil then return spec.outline ~= true end
    return spec.outline == true and piece.level == spec.level
      and piece.tone == spec.tone and piece.locked == spec.locked
      and piece.alpha == spec.alpha and piece.place == spec.place
      and piece.radius == spec.radius and piece.span == spec.span
  end

  local function segment_angles(index, fraction, unit, sweep)
    local start_at = -sweep * 0.5 + sweep * ((index - 1) / SEGMENTS)
    local stop_at = -sweep * 0.5 + sweep * (index / SEGMENTS)
    if unit then return start_at, stop_at end
    local lit = fraction * SEGMENTS
    if index - 1 >= lit then return nil end
    if index > lit then
      stop_at = -sweep * 0.5 + sweep * fraction
    end
    return start_at, stop_at
  end

  function Instance:point(place, angle, radius)
    local at, up, facing = self:anchor(place)
    if at == nil then return nil end
    local radians = (angle + facing) * math.pi / 180
    local x = at + math.cos(radians) * radius
    local y = up + math.sin(radians) * radius
    if not UP_FROM_BOTTOM then y = self.screen.height - y end
    if Vector3 == nil then return nil end
    self:noted(x, y)
    local ok, value = pcall(Vector3, x, self.depth, y)
    if ok then return value end
    self.counters.vector_faults = self.counters.vector_faults + 1
    return nil
  end

  function Instance:flat(place, dx, dy, snap, layer)
    local at, up = self:anchor(place)
    if at == nil then return nil end
    local y = up
    if not UP_FROM_BOTTOM then y = self.screen.height - y end
    local x = at + (dx or 0)
    y = y + (dy or 0)
    if snap then
      x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    end
    self:noted(x, y)
    if layer ~= nil then
      if Vector3 == nil then return nil end
      local ok, value = pcall(Vector3, x, y, layer)
      if ok then return value end
      self.counters.vector_faults = self.counters.vector_faults + 1
      return nil
    end
    return self:vector2(x, y)
  end

  local function vector2_x(value)
    local x = string.match(tostring(value), "^Vector2%(%s*([-%d%.]+)")
    return tonumber(x)
  end

  local function vector2_y(value)
    local y = string.match(tostring(value),
                           "^Vector2%(%s*[-%d%.]+%s*,%s*([-%d%.]+)")
    return tonumber(y)
  end

  function Instance:vector2(x, y)
    if Vector2 == nil then return nil end
    local ok, value = pcall(Vector2, x, y)
    if ok then return value end
    self.counters.vector_faults = self.counters.vector_faults + 1
    return nil
  end

  function Instance:alpha_of(spec, level)
    local state = spec.level
    if state == "idle" then
      local found = self:anchor_of(spec.place)
      if found ~= nil and found.widget ~= nil and found.takes ~= "position" then
        state = "active"
      end
    end
    return level * self.levels[spec.group][state]
  end

  function Instance:complete(band, spec, extra, frame_cell)
    local mark = band.accepted or {}
    for _, field in ipairs(SPEC_FIELDS) do mark[field] = spec[field] end
    mark.at_x, mark.at_y, mark.at_scale, mark.at_alpha =
      self:pixel_seat(spec.place)
    mark.rounded_fraction = rounded(spec.fraction, mark.fraction,
                                    mark.rounded_fraction,
                                    fill_steps(band.kind, spec, mark.at_scale))
    mark.fraction = spec.fraction
    mark.extra = accept_cell(mark.extra, extra)
    mark.frame_cell = accept_cell(mark.frame_cell, frame_cell)
    band.accepted = mark
    band.mark, band.seen = mark, self.frame
    if self.log ~= nil then
      band.presentation = {
        level = spec.level, tone = spec.tone, locked = spec.locked,
        opacity = self:alpha_of(spec, spec.alpha),
        text = spec.text, name = spec.name, fraction = spec.fraction,
        lit = band.lit,
      }
    end
  end

  function Instance:colour(spec, role)
    local base = self.palette[spec.tone][role]
    local red, green, blue = base[1], base[2], base[3]
    local alpha = self:alpha_of(spec, ROLE[role])
    local lift = self.palette[spec.tone].lift or 1
    alpha = math.floor(alpha * spec.alpha * lift * self:place_alpha(spec.place)
                       + 0.5)
    if alpha < 0 then alpha = 0 end
    if alpha > 255 then alpha = 255 end
    if Color == nil then return nil end
    local ok, value = pcall(Color, alpha, red, green, blue)
    if ok then return value end
    self.counters.colour_faults = self.counters.colour_faults + 1
    return nil
  end

  function Instance:retire(band, first, last)
    for slot = first, last do
      local old = band.ids[slot]
      if old == nil then
      elseif not callable(Gui, "destroy_triangle") then
        self.counters.triangles_kept = self.counters.triangles_kept + 1
      else
        self:engine("Gui.destroy_triangle", Gui.destroy_triangle,
                    self.gui, old)
        self.counters.triangles_destroyed = self.counters.triangles_destroyed + 1
        band.ids[slot] = nil
      end
    end
  end

  function Instance:lay(band, spec, slot, sweep, index, from, to)
    if from == nil then return nil end
    local high = band_top(spec.radius)
    local grow = self:sized(TEXT_OUTLINE)
    local out_r = self:sized(high) + grow
    local in_r = self:sized(high - spec.span) - grow
    local pad = (grow / out_r) * 180 / math.pi
    if sweep < 0 then pad = -pad end
    local head = index == 1 and pad or 0
    local tail = index == SEGMENTS and pad or 0
    local ink = self:colour(spec, "ink")
    local ra = self:point(spec.place, from - head, out_r)
    local rb = self:point(spec.place, to + tail, out_r)
    local rc = self:point(spec.place, from - head, in_r)
    local rd = self:point(spec.place, to + tail, in_r)
    local uv_out, uv_in = self:vector2(0.5, 0), self:vector2(0.5, 1)
    if ink == nil or ra == nil or rb == nil or rc == nil or rd == nil or
       uv_out == nil or uv_in == nil then
      self.counters.refused = self.counters.refused + 1
      return nil
    end
    band.ids[slot] = self:engine(
      "Gui.triangle", Gui.triangle, self.gui, ra, rb, rc, LAYER, ink,
      self.arc_material_name, uv_out, uv_out, uv_in)
    band.ids[slot + 1] = self:engine(
      "Gui.triangle", Gui.triangle, self.gui, rb, rd, rc, LAYER, ink,
      self.arc_material_name, uv_out, uv_in, uv_in)
    self.counters.triangles_created = self.counters.triangles_created + 2
    if band.ids[slot] == nil or band.ids[slot + 1] == nil then return nil end
    return { level = spec.level, tone = spec.tone, locked = spec.locked,
             alpha = spec.alpha, place = spec.place,
             radius = spec.radius, span = spec.span }
  end

  function Instance:arc(spec)
    local ready, sweep = self:begin_draw("arc", spec.place)
    if not ready or not callable(Gui, "triangle") then return end
    local band = self:band_for(spec)
    if band == nil then return end
    if self:colour(spec, "body") == nil then
      self.counters.refused = self.counters.refused + 1
      return
    end
    band.mark = nil
    for index = 1, SEGMENTS do
      local from, to = segment_angles(index, spec.fraction or 0, spec.unit,
                                      sweep)
      local lit = from ~= nil
      local at = (index - 1) * 4
      if not same_track(band.tracks[index], spec) then
        self:retire(band, at + 1, at + 2)
        band.tracks[index] = nil
        if spec.outline == true then
          local piece = self:lay(band, spec, at + 1, sweep, index,
                                 segment_angles(index, 0, true, sweep))
          if piece == nil then return end
          band.tracks[index] = piece
        end
      end
      local previous = band.marks[index]
      if not same_piece(previous, from, to, spec) then
        band.marks[index] = nil
        local raw_from, raw_to = from, to
        if not lit then
          from, to = 0, 0
        end
        local high = band_top(spec.radius)
        local outer = self:sized(high)
        local inner = self:sized(high - spec.span)
        local a = self:point(spec.place, from, outer)
        local b = self:point(spec.place, to, outer)
        local c = self:point(spec.place, from, inner)
        local d = self:point(spec.place, to, inner)
        local uv_out = self:vector2(0.5, 0)
        local uv_in = self:vector2(0.5, 1)
        local tint = self:colour(spec, "body")
        local at = (index - 1) * 4
        if tint == nil then
          self.counters.colour_faults = self.counters.colour_faults + 1
          return
        end
        if a == nil or b == nil or c == nil or d == nil or
           uv_out == nil or uv_in == nil then
          self.counters.refused = self.counters.refused + 1
          return
        end
        self:retire(band, at + 3, at + 4)
        band.ids[at + 3] = self:engine(
          "Gui.triangle", Gui.triangle, self.gui, a, b, c, LAYER, tint,
          self.arc_material_name, uv_out, uv_out, uv_in)
        band.ids[at + 4] = self:engine(
          "Gui.triangle", Gui.triangle, self.gui, b, d, c, LAYER, tint,
          self.arc_material_name, uv_out, uv_in, uv_in)
        self.counters.triangles_created =
          self.counters.triangles_created + 2
        for slot = at + 3, at + 4 do
          if band.ids[slot] == nil then return end
        end
        local piece = previous or {}
        piece.rounded_from = rounded(raw_from, piece.from, piece.rounded_from)
        piece.rounded_to = rounded(raw_to, piece.to, piece.rounded_to)
        piece.from, piece.to = raw_from, raw_to
        piece.level, piece.tone, piece.locked = spec.level, spec.tone, spec.locked
        piece.alpha = spec.alpha
        piece.place, piece.radius, piece.span = spec.place, spec.radius, spec.span
        band.marks[index] = piece
      end
    end
    if self.log ~= nil then
      local lit = 0
      for index = 1, SEGMENTS do
        local piece = band.marks[index]
        if piece ~= nil and piece.from ~= nil then lit = lit + 1 end
      end
      band.lit = lit
    end
    self:complete(band, spec)
  end

  local RING = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

  function Instance:outline(band, ring, seat, place)
    for index = 1, #RING do
      local step = RING[index]
      local where = seat(step[1] * ring, step[2] * ring)
      if where ~= nil then
        band.ids[#band.ids + 1] = place(where)
      end
    end
  end

  function Instance:use_font(row)
    if type(row) ~= "table" then
      self.font_name, self.material_name, self.font_atlas = nil, nil, nil
      return
    end
    self.font_name, self.material_name = row.font, row.material
    self.font_atlas = row.atlas
  end

  function Instance:refresh_font()
    local before = self.font
    self.font = self:named(self.font_name)
    self.material = self:named(self.material_name)
    self.fell_back = self.font == nil or self.material == nil
    if self.fell_back then
      self.counters.font_fell_back = self.counters.font_fell_back + 1
      self:say_font("unread")
    else
      self:settle_font()
    end
    if self.fell_back then
      self.font = self:named(self.font_fallback)
      self.material = self:named(self.material_fallback)
    end
    if before ~= self.font then
      for size in pairs(self.font_inks) do self.font_inks[size] = nil end
    end
  end

  function Instance:ink_atlas(ink)
    if self.font_atlas == nil or self.font_slot == nil then return true end
    if Material == nil or not callable(Material, "set_texture") then return false end
    local slot = self:named(self.font_slot)
    local atlas = self:named(self.font_atlas)
    if slot == nil or atlas == nil then return false end
    self:engine("Material.set_texture", Material.set_texture, ink, slot, atlas)
    return true
  end

  function Instance:say_font(why)
    if self.log == nil then return end
    local said = why .. "|" .. tostring(self.fell_back == true)
    if self.font_said == said then return end
    self.font_said = said
    self.log("FONT product generation=" .. tostring(self.generation) ..
             " why=" .. why ..
             " font=" .. tostring(self.font_name) ..
             " material=" .. tostring(self.material_name) ..
             " atlas=" .. tostring(self.font_atlas) ..
             " slot=" .. tostring(self.font_slot) ..
             " fell_back=" .. tostring(self.fell_back == true) ..
             " using=" .. tostring(self.fell_back == true
                                   and self.font_fallback or self.font_name))
  end

  function Instance:settle_font()
    if self.gui == nil or not callable(Gui, "material") then return end
    if type(self.material) == "string" then return end
    local ink = self:engine("Gui.material", Gui.material, self.gui, self.material)
    local bound = ink ~= nil and not GuiHandle.dead(ink)
    if bound and self:ink_atlas(ink) then
      self:say_font("bound")
      return
    end
    if self.font_fallback == nil then
      self:say_font(bound and "atlas-unfilled" or "unbound")
      return
    end
    self.counters.font_fell_back = self.counters.font_fell_back + 1
    self.fell_back = true
    self:say_font(bound and "atlas-unfilled" or "unbound")
  end

  local function picture_cell(self, alias)
    if alias == nil then return nil end
    local cell = self.icon_cells[alias]
    if cell ~= nil then return cell end
    local rows = self.atlas_rows
    local row = rows ~= nil and rows[alias] or nil
    return row, row ~= nil and alias or nil
  end

  function Instance:cell_of(alias)
    local cell, source = picture_cell(self, alias)
    if cell ~= nil then return cell, source end
    local textures = self.material_textures
    return picture_cell(self, textures ~= nil and textures[alias] or nil)
  end

  function Instance:no_picture(name)
    self.counters.icon_missing = self.counters.icon_missing + 1
    self.missing_icons = self.missing_icons or {}
    self.missing_icons[name] = (self.missing_icons[name] or 0) + 1
  end

  function Instance:cell_size(cell, key)
    local value = cell[key]
    if value ~= nil then return value end
    return (self.icon_cell_shape or {})[key]
  end

  local function picture_box(self, cell)
    return cell.u, cell.v,
           cell.u + self:cell_size(cell, "du"),
           cell.v + self:cell_size(cell, "dv")
  end

  function Instance:icon_box(alias, size, place, by)
    local cell = self:cell_of(alias)
    if cell == nil or type(size) ~= "number" then return nil end
    local pixels, tall = self:place_fill(place)
    local aspect = self:cell_size(cell, "aspect")
    if pixels == nil then
      if by == "height" and aspect ~= nil then
        tall = size * self:place_scale(place)
        pixels = tall * aspect
        return whole(pixels), whole(tall)
      end
      pixels = size * self:place_scale(place)
      tall = pixels
    end
    if aspect ~= nil then
      if pixels > tall * aspect then pixels = tall * aspect else tall = pixels / aspect end
    end
    return whole(pixels), whole(tall)
  end

  function Instance:flow_cell(item, place, along_x)
    if item.kind == "icon" then
      local wide, tall = self:icon_box(tostring(item.name), item.size, place, item.size_by)
      if wide == nil then return nil end
      local cell, down = self:place_fill(place)
      if cell == nil then
        cell = item.size * self:place_scale(place)
        down = cell
      end
      if along_x then return whole(cell), wide end
      return whole(down), tall
    end
    local ink = self:text_extent(item, along_x)
    if ink == nil then return nil end
    return ink, ink
  end

  function Instance:font_ink(size)
    if not callable(Gui, "text_extents") then return nil end
    local hit = self.font_inks[size]
    if hit ~= nil then return hit.bottom, hit.top end
    local lo, hi = self:engine("Gui.text_extents", Gui.text_extents,
                               self.gui, INK_SAMPLE, self.font, size)
    local bottom, top = vector2_y(lo), vector2_y(hi)
    if bottom == nil or top == nil then return nil end
    self.font_inks[size] = { bottom = bottom, top = top }
    return bottom, top
  end

  function Instance:text_extent(item, along_x)
    if item.kind ~= "number" or not callable(Gui, "text_extents") then return nil end
    local lo, hi = self:engine("Gui.text_extents", Gui.text_extents, self.gui,
                               item.text, self.font, self:sized(item.font or FONT_SIZE))
    if along_x then
      local left, right = vector2_x(lo), vector2_x(hi)
      return left ~= nil and right ~= nil and right - left or nil
    end
    local bottom, top = vector2_y(lo), vector2_y(hi)
    return bottom ~= nil and top ~= nil and top - bottom or nil
  end

  function Instance:flow_lost(spec)
    local place = self.places[spec.place]
    if place == nil or place.gap == nil or spec.flow ~= nil then return false end
    self.counters.flow_missing = self.counters.flow_missing + 1
    return true
  end

  function Instance:flow_lead(spec)
    local place = self.places[spec.place]
    local flow, index = spec.flow, spec.stack
    if place == nil or place.gap == nil or type(index) ~= "number" then return nil end
    local along_x = place.along == "x"
    local scale = self:place_scale(spec.place)
    local total, before, inset = 0, 0, nil
    for at, item in ipairs(flow) do
      local cell, ink = self:flow_cell(item, spec.place, along_x)
      if cell == nil then return nil end
      local gap = at > 1 and (item.gap or place.gap) * scale or 0
      if at <= index then before = before + gap end
      if at < index then before = before + cell end
      if at == index then inset = (cell - ink) * 0.5 end
      total = total + gap + cell
    end
    if inset == nil then return nil end
    before = before + inset
    local start = -total * 0.5
    if place.from == "first" then start = 0 elseif place.from == "last" then start = -total end
    if along_x then return start + before, true end
    return -(start + before), false
  end

  function Instance:number(spec)
    if not self:begin_draw("number", spec.place) or not callable(Gui, "text") then return end
    if self:flow_lost(spec) then return end
    if self:curved(spec.place) then
      self.counters.text_no_surface = self.counters.text_no_surface + 1
      return
    end
    local band = self:band_for(spec)
    if band == nil then return end
    local size = self:sized(spec.font or FONT_SIZE)
    local shift, lift = 0, 0
    local pull = 0
    if spec.align == "center" then pull = 0.5
    elseif spec.align == "right" then pull = 1 end
    local lead, along_x = nil, nil
    if spec.flow ~= nil then
      lead, along_x = self:flow_lead(spec)
      if lead == nil then
        self.counters.flow_unmeasured = self.counters.flow_unmeasured + 1
        return
      end
    end
    if callable(Gui, "text_extents") then
      local lo, hi = self:engine("Gui.text_extents", Gui.text_extents,
                                 self.gui, spec.text, self.font, size)
      local left, right = vector2_x(lo), vector2_x(hi)
      local bottom, top = vector2_y(lo), vector2_y(hi)
      if lead ~= nil and along_x and left ~= nil then
        shift = lead - left
      elseif left ~= nil and right ~= nil and pull > 0 then
        shift = -(right - left) * pull
      end
      if lead ~= nil and not along_x and top ~= nil then
        lift = lead - top
      else
        local low, high = self:font_ink(size)
        if low ~= nil and high ~= nil then
          lift = -(low + high) * 0.5 - size * TEXT_INK_RISE
        end
      end
    end
    if type(spec.dy) == "number" then
      lift = lift + spec.dy * self:place_scale(spec.place)
    end
    local function seat(dx, dy)
      return self:flat(spec.place, shift + (dx or 0), lift + (dy or 0), true, spec.layer)
    end
    local at = seat(0, 0)
    local colour = self:colour(spec, "body")
    if at == nil or colour == nil then
      self.counters.refused = self.counters.refused + 1
      return
    end
    band.mark = nil
    self:release(band)
    if callable(Gui, "destroy_text") and band.ids[1] ~= nil then
      self.counters.text_remade = self.counters.text_remade + 1
    end
    band.ids = {}
    local ring = whole(self:sized(TEXT_OUTLINE))
    if ring < 1 then ring = 1 end
    local ink = self:colour(spec, "ink")
    if ink ~= nil then
      self:outline(band, ring, seat, function(where)
        return self:engine("Gui.text", Gui.text, self.gui, spec.text,
                           self.font, size, self.material, where, ink)
      end)
    end
    band.ids[#band.ids + 1] = self:engine("Gui.text",
              Gui.text, self.gui, spec.text, self.font,
                              size, self.material, at,
                              colour)
    if #band.ids == 5 then self:complete(band, spec) end
  end

  function Instance:icon(spec)
    if not self:begin_draw("icon", spec.place) then return end
    if self:flow_lost(spec) then return end
    if type(spec.size) ~= "number" then
      self.counters.icon_no_size = self.counters.icon_no_size + 1
      return
    end
    local alias = tostring(spec.name)
    local cell, source = self:cell_of(alias)
    if cell == nil or self.icon_material_name == nil or
       not callable(Gui, "bitmap_uv") then
      self:no_picture(alias)
      if self.icon_material_name == nil then
        self.counters.icon_no_material = self.counters.icon_no_material + 1
      elseif not callable(Gui, "bitmap_uv") then
        self.counters.icon_no_surface = self.counters.icon_no_surface + 1
      else
        self.counters.icon_no_cell = self.counters.icon_no_cell + 1
      end
      return
    end
    local edge = nil
    if spec.edge ~= nil and spec.edge ~= alias then
      edge = tostring(spec.edge)
    end
    local frame, frame_source
    if edge ~= nil then frame, frame_source = self:cell_of(edge) end
    if edge ~= nil and frame == nil then
      self.counters.icon_no_cell = self.counters.icon_no_cell + 1
      self:no_picture(edge)
      return
    end
    local curved = self:curved(spec.place)
    local material = self:picture_material(spec.id, cell, source, false, curved)
    local edge_material = material
    if frame ~= nil then
      edge_material = self:picture_material(spec.id, frame, frame_source, true, curved)
    end
    if material == nil or edge_material == nil then
      self:no_picture(material == nil and alias or edge)
      return
    end
    local band = self:band_for(spec, cell, frame)
    if band == nil then return end
    if self.drawing ~= nil then
      self.drawing.page = cell.page
      self.drawing.material = material
    end

    local x0, y0, x1, y1 = picture_box(self, cell)
    local uv00 = self:vector2(x0, y0)
    local uv11 = self:vector2(x1, y1)
    local edge00, edge11 = uv00, uv11
    if frame ~= nil then
      local e0, f0, e1, f1 = picture_box(self, frame)
      edge00 = self:vector2(e0, f0)
      edge11 = self:vector2(e1, f1)
    end
    local part = spec.fraction
    if spec.unit == true or type(part) ~= "number" then part = 1 end
    if part < 0 then part = 0 elseif part > 1 then part = 1 end
    local pixels, tall_pixels = self:icon_box(alias, spec.size, spec.place, spec.size_by)
    if self.drawing ~= nil then
      self.drawing.pixels, self.drawing.tall = pixels, tall_pixels
    end
    local half, half_tall = pixels * 0.5, tall_pixels * 0.5
    local pull_x, pull_y = 0, 0
    if spec.align == "right" then pull_x = -half end
    local shift_x, shift_y = 0, 0
    if spec.flow ~= nil then
      local lead, along_x = self:flow_lead(spec)
      if lead == nil then
        self.counters.flow_unmeasured = self.counters.flow_unmeasured + 1
        return
      end
      if along_x then
        shift_x, pull_x = lead, half
      else
        shift_y, pull_y = lead, -half_tall
      end
    end
    if type(spec.dy) == "number" then
      shift_y = shift_y + spec.dy * self:place_scale(spec.place)
    end
    local function seat(dx, dy)
      return self:flat(spec.place, shift_x + pull_x + (dx or 0) - half,
                       shift_y + pull_y + (dy or 0) - half_tall, true, spec.layer)
    end
    local at = seat(0, 0)
    local size = self:vector2(pixels, tall_pixels)
    local lit00, lit = uv00, size
    if part < 1 then
      lit00 = self:vector2(x0, y0 + (1 - part) * (y1 - y0))
      lit = self:vector2(pixels, whole(tall_pixels * part))
    end
    local colour = self:colour(spec, "body")
    local ink = self:colour(spec, "ink")
    if uv00 == nil or uv11 == nil or edge00 == nil or edge11 == nil or
       at == nil or size == nil or
       lit00 == nil or lit == nil or colour == nil or ink == nil then
      self.counters.refused = self.counters.refused + 1
      return
    end
    band.mark = nil
    self:release(band)
    band.ids = {}
    local drawn = 1
    if spec.outline ~= false then
      local ring = ICON_OUTLINE
      self:outline(band, ring, seat, function(where)
        return self:engine("Gui.bitmap_uv", Gui.bitmap_uv, self.gui,
                           edge_material, edge00, edge11, where, size, ink)
      end)
      drawn = drawn + #RING
    end
    if frame ~= nil then
      band.ids[#band.ids + 1] = self:engine("Gui.bitmap_uv",
                Gui.bitmap_uv, self.gui, edge_material, edge00, edge11, at, size, colour)
      drawn = drawn + 1
    end
    band.ids[#band.ids + 1] = self:engine("Gui.bitmap_uv",
              Gui.bitmap_uv, self.gui, material, lit00, uv11, at, lit, colour)
    if #band.ids == drawn then
      self:complete(band, spec, cell, frame)
      if band.presentation ~= nil then
        band.presentation.material, band.presentation.edge_material = material, edge_material
      end
    end
  end

  function Instance:bar(spec)
    if not self:begin_draw("bar", spec.place) then return end
    if type(spec.width) ~= "number" or not (spec.width > 0 and spec.width < math.huge) or
       type(spec.height) ~= "number" or not (spec.height > 0 and spec.height < math.huge) or
       type(spec.fraction) ~= "number" or not (spec.fraction >= 0 and spec.fraction <= 1) or
       not callable(Gui, "rect") or not callable(Gui, "destroy_rect") then
      self.counters.refused = self.counters.refused + 1
      return
    end
    local scale = self:place_scale(spec.place)
    local width = whole(spec.width * scale)
    local height = whole(spec.height * scale)
    if width < 1 or height < 1 then
      self.counters.refused = self.counters.refused + 1
      return
    end
    local band = self:band_for(spec)
    if band == nil then return end
    local pieces = {}
    local edge = spec.outline and math.max(1, whole(scale)) or 0
    if edge > 0 and width - edge * 2 >= 1 and height - edge * 2 >= 1 then
      local back = self:flat(spec.place, 0, 0, true, LAYER)
      local whole_size = self:vector2(width, height)
      local ink = self:colour(spec, "ink")
      if back == nil or whole_size == nil or ink == nil then
        self.counters.refused = self.counters.refused + 1
        return
      end
      pieces[1] = { at = back, size = whole_size, colour = ink }
      local inner = whole((width - edge * 2) * spec.fraction)
      if inner > 0 then
        local at = self:flat(spec.place, edge, edge, true, LAYER)
        local size = self:vector2(inner, height - edge * 2)
        local colour = self:colour(spec, "body")
        if at == nil or size == nil or colour == nil then
          self.counters.refused = self.counters.refused + 1
          return
        end
        pieces[2] = { at = at, size = size, colour = colour }
      end
    else
      local filled = whole(width * spec.fraction)
      local offset = 0
      for _, role in ipairs({"body", "ink"}) do
        local length = role == "body" and filled or width - filled
        if length > 0 then
          local at = self:flat(spec.place, offset, 0, true, LAYER)
          local size = self:vector2(length, height)
          local colour = self:colour(spec, role)
          if at == nil or size == nil or colour == nil then
            self.counters.refused = self.counters.refused + 1
            return
          end
          pieces[#pieces + 1] = { at = at, size = size, colour = colour }
        end
        offset = offset + length
      end
    end
    band.mark = nil
    self:release(band)
    band.ids = {}
    for index, piece in ipairs(pieces) do
      band.ids[index] = self:engine("Gui.rect", Gui.rect, self.gui,
                                   piece.at, piece.size, piece.colour)
    end
    for index = 1, #pieces do
      if band.ids[index] == nil then return end
    end
    self:complete(band, spec)
  end

  function Instance:end_frame(told, groups)
    told = told or {}
    for key, band in pairs(self.bands) do
      self.drawing = nil
      if band.seen ~= self.frame then
        if told[key] then
          self:release(band)
          self.bands[key] = nil
          self.counters.gui_destroyed = self.counters.gui_destroyed + 1
        else
          local mark = band.accepted
          if mark ~= nil then
            local x, y, scale, alpha = self:pixel_seat(mark.place)
            local anchor = self.anchors[mark.place]
            if x == nil and anchor ~= nil and anchor.frame == self.frame and
               anchor.reason == "hidden" then
              if next(band.ids) ~= nil then
                self:release(band)
                band.ids, band.marks, band.tracks = {}, {}, {}
              end
              band.mark = nil
            elseif x ~= nil then
              local level = mark.level
              if groups ~= nil then
                level = groups[mark.group] == true and "active" or "idle"
              end
              local spec = { key = key, kind = band.kind, fraction = mark.fraction }
              for _, field in ipairs(SPEC_FIELDS) do spec[field] = mark[field] end
              spec.level = level
              if not same_spec(band, spec, mark.extra, x, y, scale, alpha, mark.frame_cell) then
                self[band.kind](self, spec)
              end
            end
          end
          band.unread = true
          self.counters.unread = self.counters.unread + 1
        end
      else
        band.unread = nil
      end
    end
    self.drawing = nil
  end


  function Instance:report()
    local out = EngineCall.counters_of(self.counters)
    out.bands = 0
    for _ in pairs(self.bands) do out.bands = out.bands + 1 end
    for name, count in pairs(self.refused_kinds or {}) do
      out["refused_" .. name] = count
    end
    for name, count in pairs(self.missing_icons or {}) do
      out["no_icon:" .. name] = count
    end
    return out
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return GuiHost end)
if not __contract_ok_1 or __contract_export_1 == nil then error("80-gui-host: missing export GuiHost", 0) end
return {["GuiHost"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("80-gui-host", true))
local __exports = __module_run("80-gui-host", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["GuiHost"] = __exports["GuiHost"]
end
end
do
local __imports = {}
__imports["EngineCall"] = __module_registry["EngineCall"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("85-gui-surface: imports must be a table", 0) end
local EngineCall = imports["EngineCall"]
if EngineCall == nil then error("85-gui-surface: missing import EngineCall", 0) end

local GuiSurface = (function()
  local Core = { VERSION = "gui-surface-v1" }
  local callable = EngineCall.callable
  local attempt = EngineCall.attempt
  local world_is_live = EngineCall.world_is_live

  local sr = rawget(_G, "stingray")
  local App = sr and rawget(sr, "Application") or nil
  local Gui = sr and rawget(sr, "Gui") or nil
  local Window = sr and rawget(sr, "Window") or nil
  local World = sr and rawget(sr, "World") or nil




  local function world_index(worlds, wanted)
    if type(worlds) ~= "table" or wanted == nil then return nil end
    for index = 1, #worlds do
      if worlds[index] == wanted then return index end
    end
    return nil
  end

  local function other_world(worlds, game_world)
    if type(worlds) ~= "table" then return nil end
    for index = 1, #worlds do
      local candidate = worlds[index]
      if candidate ~= nil and candidate ~= game_world then return candidate end
    end
    return nil
  end

  local Instance = {}
  Instance.__index = Instance

  function Core.new(host, options)
    local self = setmetatable({}, Instance)
    options = options or {}
    self.host = host
    self.log = options.log
    self.destroy_bracketed = false
    self.cursor_bracketed = false
    self.gui_visible = nil
    self.gui = nil
    self.world = nil
    self.generation = 0
    self.counters = {
      surface_changes = 0, gui_created = 0, gui_failed = 0,
      gui_destroyed = 0, gui_destroy_failed = 0, gui_forgotten = 0,
      overlay_created = 0, overlay_missing_windows = 0,
      cursor_reads = 0, cursor_unread = 0, visibility_changes = 0,
      visibility_failed = 0,
    }
    return self
  end

  function Instance:target(game_world, worlds)
    local overlay = other_world(worlds, game_world)
    if overlay ~= nil then return overlay end
    self.counters.overlay_missing_windows =
      self.counters.overlay_missing_windows + 1
    return nil
  end

  function Instance:sync_visibility(window)
    local show_cursor = type(Window) == "table" and
                        rawget(Window, "show_cursor") or nil
    if type(show_cursor) ~= "function" then return end
    local watched = self.log ~= nil and not self.cursor_bracketed
    if watched then
      self.log("STEP layer=surface phase=in call=Window." .. "show_cursor")
    end
    local ok, shown = pcall(show_cursor)
    if watched then
      self.log("STEP layer=surface phase=out call=Window." ..
               "show_cursor ok=" ..
               tostring(ok) .. " value=" .. tostring(shown))
      self.cursor_bracketed = true
    end
    if not ok or type(shown) ~= "boolean" then
      self.counters.cursor_unread = self.counters.cursor_unread + 1
      return
    end
    self.counters.cursor_reads = self.counters.cursor_reads + 1
    local wanted = not shown
    if wanted == self.gui_visible then return end
    if self.gui == nil or not callable(Gui, "set_visible") then
      self.counters.visibility_failed = self.counters.visibility_failed + 1
      return
    end
    local changed = pcall(Gui.set_visible, self.gui, wanted)
    if not changed then
      self.counters.visibility_failed = self.counters.visibility_failed + 1
      return
    end
    self.gui_visible = wanted
    self.counters.visibility_changes = self.counters.visibility_changes + 1
    if self.log ~= nil then
      self.log("STEP layer=surface event=visibility window=" ..
               tostring(window) .. " cursor=" .. tostring(shown) ..
               " visible=" .. tostring(wanted))
    end
  end

  function Instance:dispose(old_gui, old_world)
    if old_gui == nil then return end
    local worlds = attempt(callable(App, "worlds") and App.worlds)
    if not (world_is_live(worlds, old_world) and
            callable(World, "destroy_gui")) then
      self.counters.gui_forgotten = self.counters.gui_forgotten + 1
      return
    end
    self.host:clear_bands()
    local watched = self.log ~= nil and not self.destroy_bracketed
    if watched then
      self.log("STEP layer=surface phase=in call=World.destroy_gui")
    end
    local ok = pcall(World.destroy_gui, old_world, old_gui)
    if watched then
      self.log("STEP layer=surface phase=out call=World.destroy_gui ok=" ..
               tostring(ok))
      self.destroy_bracketed = true
    end
    if ok then
      self.counters.gui_destroyed = self.counters.gui_destroyed + 1
    else
      self.counters.gui_destroy_failed =
        self.counters.gui_destroy_failed + 1
    end
  end

  function Instance:forget()
    self:dispose(self.gui, self.world)
    self.generation = self.generation + 1
    self.host:set_generation(self.generation, nil)
    self.gui, self.world, self.gui_visible = nil, nil, nil
  end

  function Instance:ensure(game_world, worlds, window)
    local target = self:target(game_world, worlds)
    if self.gui ~= nil and self.world == target and
       world_is_live(worlds, self.world) then
      self:sync_visibility(window)
      return self.gui, target
    end

    local old_gui, old_world = self.gui, self.world
    if old_gui ~= nil and old_world ~= target then
      self.counters.surface_changes = self.counters.surface_changes + 1
    end

    self:dispose(old_gui, old_world)

    self.generation = self.generation + 1
    self.host:set_generation(self.generation, nil)
    self.gui, self.world, self.gui_visible = nil, nil, nil

    if not world_is_live(worlds, target) then
      self.counters.gui_failed = self.counters.gui_failed + 1
      return nil, target
    end

    local gui = callable(World, "create_screen_gui") and
      attempt(World.create_screen_gui, target, "scale", 1, 1) or nil
    self.gui = gui
    self.world = gui ~= nil and target or nil
    self.host:set_generation(self.generation, gui)
    if gui == nil then
      self.counters.gui_failed = self.counters.gui_failed + 1
      return nil, target
    end
    self:sync_visibility(window)
    self.counters.gui_created = self.counters.gui_created + 1
    self.counters.overlay_created = self.counters.overlay_created + 1
    if self.log ~= nil then
      self.log("STEP layer=surface event=gui-created generation=" ..
               tostring(self.generation) .. " main_index=" ..
               tostring(world_index(worlds, game_world)) ..
               " target_index=" .. tostring(world_index(worlds, target)) ..
               " world_count=" .. tostring(#worlds) ..
               " surface=full-output")
    end
    return gui, target
  end

  function Instance:report()
    return EngineCall.counters_of(self.counters)
  end

  return Core
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return GuiSurface end)
if not __contract_ok_1 or __contract_export_1 == nil then error("85-gui-surface: missing export GuiSurface", 0) end
return {["GuiSurface"]=__contract_export_1}
end
end)()
setfenv(__factory, __module_environment("85-gui-surface", true))
local __exports = __module_run("85-gui-surface", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["GuiSurface"] = __exports["GuiSurface"]
end
end
do
local __imports = {}
__imports["EngineCall"] = __module_registry["EngineCall"]
__imports["BootState"] = __module_registry["BootState"]
__imports["IdentityCore"] = __module_registry["IdentityCore"]
__imports["GeneratedCommon"] = __module_registry["GeneratedCommon"]
__imports["Fragments"] = __module_registry["Fragments"]
__imports["Door"] = __module_registry["Door"]
__imports["Provider"] = __module_registry["Provider"]
__imports["Snapshot"] = __module_registry["Snapshot"]
__imports["HudModel"] = __module_registry["HudModel"]
__imports["Renderer"] = __module_registry["Renderer"]
__imports["GuiHost"] = __module_registry["GuiHost"]
__imports["GuiSurface"] = __module_registry["GuiSurface"]
local __factory = (function()
return function(imports)
if type(imports) ~= "table" then error("90-main: imports must be a table", 0) end
local EngineCall = imports["EngineCall"]
if EngineCall == nil then error("90-main: missing import EngineCall", 0) end
local BootState = imports["BootState"]
if BootState == nil then error("90-main: missing import BootState", 0) end
local IdentityCore = imports["IdentityCore"]
if IdentityCore == nil then error("90-main: missing import IdentityCore", 0) end
local GeneratedCommon = imports["GeneratedCommon"]
if GeneratedCommon == nil then error("90-main: missing import GeneratedCommon", 0) end
local Fragments = imports["Fragments"]
if Fragments == nil then error("90-main: missing import Fragments", 0) end
local Door = imports["Door"]
if Door == nil then error("90-main: missing import Door", 0) end
local Provider = imports["Provider"]
if Provider == nil then error("90-main: missing import Provider", 0) end
local Snapshot = imports["Snapshot"]
if Snapshot == nil then error("90-main: missing import Snapshot", 0) end
local HudModel = imports["HudModel"]
if HudModel == nil then error("90-main: missing import HudModel", 0) end
local Renderer = imports["Renderer"]
if Renderer == nil then error("90-main: missing import Renderer", 0) end
local GuiHost = imports["GuiHost"]
if GuiHost == nil then error("90-main: missing import GuiHost", 0) end
local GuiSurface = imports["GuiSurface"]
if GuiSurface == nil then error("90-main: missing import GuiSurface", 0) end

local ProductMain = (function()
  local Core = { VERSION = "product-main-v1" }
  local callable = EngineCall.callable
  local attempt = EngineCall.attempt
  local world_is_live = EngineCall.world_is_live

  local sr = rawget(_G, "stingray")
  local App = sr and rawget(sr, "Application") or nil

  local function hud_off(window)
    local native = window ~= nil and window.native or nil
    local gate = native ~= nil and native.hud_gate or nil
    local cells = gate ~= nil and gate.cells or nil
    if cells == nil then return false end
    return cells.gate_run == 0 or cells.gate_ready == 0
  end

  local Instance = {}
  Instance.__index = Instance

  function Core.new(parts)
    local self = setmetatable({}, Instance)
    parts = parts or {}
    self.generated = parts.generated
    self.identity = parts.identity
    self.provider = parts.provider
    self.snapshot = parts.snapshot
    self.model = parts.model
    self.renderer = parts.renderer
    self.host = parts.host
    self.surface = parts.surface
    self.clock = parts.clock
    self.log = parts.log
    self.armed = parts.armed
    self.door = parts.door
    if self.door ~= nil then
      self.door_mirror = function(relation, entity, cells)
        if self.probe == nil then return end
        self.probe:note_cells(self.counters.windows, relation, entity, cells)
      end
    end
    self.counters = { windows = 0, resolved = 0, unknown = 0, absent = 0,
                      hud_off = 0, before_control = 0, no_session = 0 }
    return self
  end

  function Instance:scope(window)
    local session = window ~= nil and window.session or nil
    if not session then return nil end
    local worlds = attempt(callable(App, "worlds") and App.worlds)
    local world = attempt(callable(App, "main_world") and App.main_world)
    if not world_is_live(worlds, world) then return nil end
    return session, world, worlds
  end

  function Instance:now()
    if self.clock == nil then return 0 end
    local value = attempt(self.clock)
    if type(value) == "number" then return value end
    return 0
  end

  function Instance:mark(where, a, b, c)
    if self.probe == nil then return end
    self.probe:step(self.counters.windows, where, a, b, c)
  end

  function Instance:shape(resolved, window, frame, addon_requests)
    if self.probe == nil then return end
    self.probe:shape(self, resolved, window, frame, addon_requests)
  end

  function Instance:closing()
    if self.log == nil then return end
    self.log("RUN product window=" .. tostring(self.counters.windows) ..
             " at=closed " .. self:tally())
  end

  function Instance:fold(where, resolved, window)
    self.host:clear_bands()
    self:mark(where)
    self:shape(resolved, window)
    self:closing()
  end

  function Instance:update()
    self.counters.windows = self.counters.windows + 1
    if self.armed ~= nil then
      self.host:watch(self.log, self.armed(self.counters.windows))
    end
    self:mark("update")
    local window = self.provider:doors()
    if self.counters.windows == 1 then
      BootState.status(self.provider:native_refused() or "ok")
    end
    self:mark("doors")
    local session, world, worlds = self:scope(window)
    self:mark("scope")
    local shut = session == nil or hud_off(window)
    if shut then
      self.provider:skipped()
    else
      window = self.provider:read(window, self.probe ~= nil) or window
    end
    self:mark("read")
    local scope = self.identity.scope
    local resolved = self.identity:resolve(session, world, window.native)
    if self.identity.scope ~= scope then self.surface:forget() end
    if self.object_generation ~= self.identity.generation then
      self.object_generation = self.identity.generation
      self.model:reset_objects()
      if self.probe ~= nil then self.probe:reset_objects() end
    end
    if session == nil then
      self.counters.no_session = self.counters.no_session + 1
      if self.probe ~= nil then
        self.probe:scope(self, session, world, worlds, nil)
      end
      return self:fold("no-session", resolved, window)
    end
    if shut then
      self.counters.hud_off = self.counters.hud_off + 1
      return self:fold("hud-off", resolved, window)
    end
    local gui, target = self.surface:ensure(world, worlds, self.counters.windows)
    self:mark("gui", "made=", gui ~= nil)
    if self.probe ~= nil then
      self.probe:scope(self, session, world, worlds, target)
    end

    if self.identity.controlled_once ~= true then
      self.counters.before_control = self.counters.before_control + 1
      if self.probe ~= nil then self.probe:identified(self, resolved) end
      return self:fold("before-control", resolved, window)
    end

    if self.probe ~= nil then self.probe:identified(self, resolved) end
    self.counters[resolved.status] =
      (self.counters[resolved.status] or 0) + 1
    self.provider:fill(resolved, window)
    self.host:use_font(window.ui_font)
    local boxes = window.hud_boxes
    if self.door ~= nil then
      local merged = {}
      for name, box in pairs(boxes or {}) do merged[name] = box end
      boxes = self.door:frame(self.provider:door_view(window, self.host.screen, self.log,
                                                      self.counters.windows,
                                                      self.door_mirror), merged)
    end
    self.host:use_widgets(boxes)
    local atlas = (window.native or {}).atlas_index or {}
    self.host:use_atlas(atlas.rows, atlas.textures)
    self:mark("provider")
    local prepared = self.model:prepare(window, self:now())
    local assembled = self.snapshot:assemble(prepared)
    self:mark("snapshot")
    local frame = self.model:present(assembled)
    self:mark("model")
    self.host:use_aim(self.model:aim_rest())
    self.host:begin_frame()
    self:mark("host-begin")
    local told, groups = self.renderer:draw(frame, self.host)
    local addon_requests
    if self.door ~= nil then addon_requests = self.door:draw(self.host, told) end
    self:mark("renderer")
    self.host:end_frame(told, groups)
    self:shape(resolved, window, frame, addon_requests)
    self:closing()
  end
  local function append_numbers(into, counters, prefix)
    local stem = prefix ~= nil and (prefix .. ".") or ""
    for key, value in pairs(counters) do
      if type(value) == "number" and value ~= 0 and key ~= "windows" then
        into[stem .. key] = tostring(value)
      end
    end
  end

  local TALLY_FULL_EVERY = 500

  local function report_of(layer)
    if type(layer) ~= "table" or type(layer.report) ~= "function" then
      return {}
    end
    local ok, out = pcall(layer.report, layer)
    if ok and type(out) == "table" then return out end
    return {}
  end

  function Instance:tally()
    local now = {}
    append_numbers(now, self.counters)
    append_numbers(now, report_of(self.identity), "identity")
    append_numbers(now, report_of(self.provider), "provider")
    append_numbers(now, report_of(self.snapshot), "snapshot")
    append_numbers(now, report_of(self.model), "model")
    append_numbers(now, report_of(self.renderer), "renderer")
    append_numbers(now, report_of(self.surface), "surface")
    append_numbers(now, report_of(self.host), "host")
    append_numbers(now, report_of(self.door), "door")
    append_numbers(now, report_of(self.probe), "probe")
    append_numbers(now, BootState.log_state(), "log")
    local since = self.tallied
    local full = since == nil or
      (self.counters.windows - (self.tallied_at or 0)) >= TALLY_FULL_EVERY
    local names = {}
    if full then
      for name in pairs(now) do
        names[#names + 1] = name
      end
      self.tallied_at = self.counters.windows
    else
      for name, value in pairs(now) do
        if since[name] ~= value then
          names[#names + 1] = name
        end
      end
      for name in pairs(since) do
        if now[name] == nil then names[#names + 1] = "-" .. name end
      end
    end
    table.sort(names)
    local parts = { full and "tally=full" or "tally=delta" }
    for index = 1, #names do
      local name = names[index]
      if string.sub(name, 1, 1) == "-" then
        parts[#parts + 1] = name
      else
        parts[#parts + 1] = name .. "=" .. now[name]
      end
    end
    self.tallied = now
    return table.concat(parts, " ")
  end

  function Instance:report()
    return EngineCall.counters_of(self.counters)
  end

  return Core
end)()

local ProductHud = (function()
  local log = BootState.begin() and BootState.log or nil
  local generated, fragments = Fragments.merge(GeneratedCommon)
  local door = Door.new({ log = log })
  if #door.addons == 0 then door = nil
  else generated.layout = door:extend(generated.layout or {}) end
  local host = GuiHost.new(nil, {
    log = log,
    places = (generated.layout or {}).places,
    spots = (generated.layout or {}).spots,
    groups = (generated.layout or {}).groups,
    idle_ratio = ((generated.layout or {}).style or {}).idle_ratio,
    aim_rest_dx = ((generated.layout or {}).style or {}).aim_rest_dx,
    aim_rest_dy = ((generated.layout or {}).style or {}).aim_rest_dy,
    aim_sway = ((generated.layout or {}).style or {}).aim_sway,
    aim_sway_widget = ((generated.layout or {}).style or {}).aim_sway_widget,
    palette = (generated.layout or {}).palette,
    icon_cells = (generated.layout or {}).icon_cells,
    icon_cell_shape = (generated.layout or {}).icon_cell_shape,
    primitives = (generated.layout or {}).primitives,
    font_slot = "88bac99b00000000",
    font_fallback = "core/performance_hud/debug",
    material_fallback = "core/performance_hud/debug",
    depth = 0,
    icon_material_name = "mods/hd2_hud/native_icon_atlas",
    icon_pages = (generated.layout or {}).icon_pages,
    page_slot = "3aa8b87e00000000",
    arc_material_name = "mods/hd2_hud/ammo_arc_track",
  })
  local surface = GuiSurface.new(host, { log = log })
  local main = ProductMain.new({
    generated = generated,
    log = log,
    armed = BootState.brackets,
    identity = IdentityCore.new(generated.identity),
    provider = Provider.new(generated),
    snapshot = Snapshot.new(generated),
    model = HudModel.new(generated),
    renderer = Renderer.new(generated),
    surface = surface,
    host = host,
    door = door,
    clock = BootState.clock(),
  })
  if fragments.rows > 0 then BootState.install(main) end
  local node_total = #(generated.nodes or {})
  local native = generated.native or {}
  local function counted(rows)
    local total = 0
    for _ in pairs(rows or {}) do total = total + 1 end
    return total
  end
  BootState.log("RUN product wired=true relations=" ..
                tostring(#((generated.relations) or {})) ..
                " calls=" .. tostring(#((generated.calls) or {})) ..
                " native_sections=" .. tostring(counted(native)) ..
                " native_relations=" .. tostring(counted(native.relations)) ..
                " nodes=" .. tostring(node_total) ..
                " frag_axes=" .. tostring(fragments.axes) ..
                " frag_loaded=" .. tostring(fragments.loaded) ..
                " frag_absent=" .. tostring(fragments.absent) ..
                " frag_no_require=" .. tostring(fragments.no_require) ..
                " frag_not_installed=" .. tostring(fragments.not_installed) ..
                " frag_load_failed=" .. tostring(fragments.load_failed) ..
                " frag_not_found=" .. tostring(fragments.not_found) ..
                " frag_styled=" .. tostring(fragments.styled) ..
                " frag_incompatible=" .. tostring(fragments.incompatible) ..
                " frag_rows=" .. tostring(fragments.rows))
  return main
end)()

local __contract_ok_1, __contract_export_1 = pcall(function() return ProductMain end)
if not __contract_ok_1 or __contract_export_1 == nil then error("90-main: missing export ProductMain", 0) end
local __contract_ok_2, __contract_export_2 = pcall(function() return ProductHud end)
if not __contract_ok_2 or __contract_export_2 == nil then error("90-main: missing export ProductHud", 0) end
return {["ProductMain"]=__contract_export_1,["ProductHud"]=__contract_export_2}
end
end)()
setfenv(__factory, __module_environment("90-main", true))
local __exports = __module_run("90-main", __factory, __imports, __module_log)
if __exports ~= nil then
__module_registry["ProductMain"] = __exports["ProductMain"]
__module_registry["ProductHud"] = __exports["ProductHud"]
end
end
local __boot_state = __module_registry["BootState"]
if type(__boot_state) ~= "table" then return { installed = false } end
return { installed = __boot_state.result == true }
