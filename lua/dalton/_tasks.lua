--- Global list of tasks (both Atoms and Compounds)
--- @type dalton.list
local g_tasks = {}

--- @package
local M = {}

--- Replace all tasks
--- @param items dalton.list
function M.replace(items)
    g_tasks = vim.deepcopy(items)
end

--- Get a particular task
--- @param name string
--- @return dalton.Atom|dalton.Compound|nil
function M.get(name)
    -- Copy value instead of passing reference
    return vim.deepcopy(g_tasks[name])
end

--- Append one item
--- @param name string
--- @param def dalton.Atom|dalton.Compound
function M.append(name, def)
    g_tasks[name] = def
end

--- Append many items
--- @param def dalton.list
function M.extend(def)
    g_tasks = vim.tbl_deep_extend("force", g_tasks, def)
end

--- Delete one entry
--- @param name string
function M.delete(name)
    g_tasks[name] = nil
end

--- List all tasks
--- @return dalton.list
function M.list()
    return vim.deepcopy(g_tasks)
end

return M
