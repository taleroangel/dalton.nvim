---@class dalton
local M = {}

--- Configure and initialize the plugin
--- @param opts dalton.opts Plugin configuration, will be merged with defaults
function M.setup(opts)
end

--- Create a new unit (atom)
--- @param name string Unique identifier for the atom
--- @param def dalton.atom Definition
function M.atom(name, def)
end

--- Alias for `atom`
M.unit = M.atom

return M
