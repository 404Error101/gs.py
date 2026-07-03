-- Standard Library Loader
local Std = {
    _VERSION = "1.0.0",
    _NAME = "Standard Library for Lua"
}

-- Auto-load submodules
function Std.require(name)
    local path = "./std/" .. name:gsub("%.", "/") .. ".lua"
    local f = io.open(path, "r")
    if f then
        f:close()
        return require("./std/" .. name:gsub("%.", "/"))
    end
    return nil
end

return Std