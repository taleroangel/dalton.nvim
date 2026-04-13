--- @package
local M = {}

--- Check if a value is an Atom (+valid)
--- @param task dalton.Atom|dalton.Compound
--- @return boolean
---     True if value is an Atom
function M.is_atom(task)
    return task.cmd ~= nil
end

--- Check if a value is a Compound (+valid)
--- @param task dalton.Atom|dalton.Compound
--- @return boolean
---     True if value is a Compound
function M.is_compound(task)
    return task.steps ~= nil
end

--- Check if Atom or a Compound matches a particular filetype
--- @param task dalton.Atom|dalton.Compound
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

--- Check if a task is compatible with the current buffer's filetype
---
--- @param task dalton.Atom|dalton.Compound
function M.is_valid_for_current_buffer(task)
    return M.has_ft(task, nil) or M.has_ft(task, vim.bo.ft)
end

--- Filter tasks given a particular mode
---
--- @param task dalton.Atom|dalton.Compound
--- @param mode dalton.type.pick
function M.filter_for_mode(task, mode)
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
