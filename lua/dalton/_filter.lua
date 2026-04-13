--- @package
local M = {}

--- Check if a value is an Atom (+valid)
--- @param task dalton.atom|dalton.compound
--- @return boolean
---     True if value is an Atom
function M.is_atom(task)
    return task.cmd ~= nil
end

--- Check if a value is a Compound (+valid)
--- @param task dalton.atom|dalton.compound
--- @return boolean
---     True if value is a Compound
function M.is_compound(task)
    return task.steps ~= nil
end

--- Check if Atom or a Compound matches a particular filetype
--- @param task dalton.atom|dalton.compound
--- @param ft string? Filetype to match, use nil match tasks without a filetype
function M.has_ft(task, ft)
    ---@type (string|string[])?
    local taskft = task.ft
    if (ft == nil) then
        return task.ft == nil
    elseif (type(taskft) == "table") then
        ---@cast taskft string[]
        return vim.list_contains(taskft, ft)
    elseif (type(taskft) == "string") then
        return task.ft == ft
    end
    return false
end

return M
