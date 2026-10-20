local import = (function(...)
local native_require = require
local shared = ...
local modules, loaded = {}, {}
