--- @package
--- Helper functions to validate/cast Atoms and Compounds
local M = {}

--- Check if a value is an Atom (+valid)
--- @param task dalton.any
--- @return boolean
---     True if value is an Atom
function M.is_atom(task)
    return (type(task) == "table") and (task.cmd ~= nil)
end

--- Check if a value is a valid Atom in simple form
--- @param task dalton.any
--- @return boolean
---     True if value is a simple Atom
function M.is_atom_shortcut(task)
    return type(task) == "string"
end

--- Cast a AtomShortcut to an Atom
--- @param v dalton.AtomShortcut
--- @return dalton.Atom
function M.to_atom(v)
    assert(M.is_atom_shortcut(v), "Invalid Atom shortcut")
    return { cmd = v }
end

--- Check if a value is a Compound (+valid)
--- @param task dalton.any
--- @return boolean
---     True if value is a Compound
function M.is_compound(task)
    return (type(task) == "table") and (task.steps ~= nil)
end

--- Check if a value is a valid Compound in simple form
--- @param task dalton.any
--- @return boolean
---     True if value is a simple Compound
function M.is_compound_shortcut(task)
    if (type(task) ~= "table" or not vim.islist(task)) then
        return false
    end
    ---@cast task table
    for _, v in ipairs(task) do
        if (type(v) ~= "string") then
            return false
        end
    end
    return true
end

--- Cast CompoundShortcut to Compound
--- @param v dalton.CompoundShortcut
--- @return dalton.Compound
function M.to_compound(v)
    assert(M.is_compound_shortcut(v), "Invalid Compound shortcut")
    return { steps = v }
end

--- Check if Atom or a Compound matches a particular filetype
--- @param task dalton.Atom|dalton.Compound
--- @param ft string? Filetype to match, use nil match tasks without a filetype
--- @return boolean
---     Task matches given filetype
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

--- Check if a task is compatible with the current buffer's filetype
---
--- @param task dalton.Atom|dalton.Compound
--- @return boolean
---     Task is valid for the current buffer
function M.is_valid_for_current_buffer(task)
    return M.has_ft(task, nil) or M.has_ft(task, vim.bo.ft)
end

--- Filter task given a particular mode
---
--- @param task dalton.Atom|dalton.Compound
--- @param mode dalton.type.pick
--- @return boolean
---     Task is valid for the given mode
function M.is_valid_for_mode(task, mode)
    return ({
        default = function(v)
            return M.is_valid_for_current_buffer(v)
        end,
        atom = function(v)
            return M.is_valid_for_current_buffer(v) and M.is_atom(v)
        end,
        compound = function(v)
            return M.is_valid_for_current_buffer(v) and M.is_compound(v)
        end,
        ft = function(v)
            return M.has_ft(v, vim.bo.ft)
        end,
        all = function(_)
            return true
        end,
    })[mode](task)
end

return M
