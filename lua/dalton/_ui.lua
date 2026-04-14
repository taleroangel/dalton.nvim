local M = {}

--- Show a picker for a given list of tasks
---
--- @param tasks dalton.list
--- @param on_pick fun(name: string|nil)
---     Callback function with picked value (or nil if user canceled operation)
function M.pick(tasks, on_pick)
    vim.ui.select(vim.iter(tasks):totable(), {
        prompt = "Choose a Task to run",
        format_item = function(item)
            local name, def = (table.unpack or unpack)(item)
            ---@cast name string
            ---@cast def dalton.Task
            return name .. (def.desc and (": " .. def.desc) or "")
        end
    }, function(item)
        on_pick((item ~= nil) and item[1] or nil)
    end)
end

--- Additional parameters for notificacionts
--- @return table
local NOTIFICATION_PARAMS = function()
    return {
        id = vim.uv.now(), -- Assign unique timestamp
        title = "Dalton.nvim",
        ft = "markdown",   -- folke/snacks.nvim (snacks.notify)
    }
end

--- Notify a task just started
--- @param name string Task name
function M.task_notify(name)
    vim.notify("Task `" .. name .. "` started", vim.log.levels.INFO, NOTIFICATION_PARAMS())
end

--- Notify Atom success
--- @param name string Atom name
--- @param time number Time it took the process to finish (in ms)
--- @param stdout string? Command output, nil to avoid output
function M.atom_success(name, time, stdout)
    vim.notify(
        ("Atom `" .. name .. "` finished successfully. (Took " .. time .. "ms)\n") ..
        (stdout or ""),
        vim.log.levels.INFO,
        NOTIFICATION_PARAMS()
    )
end

--- Notify Atom failure
--- @param name string Atom name
--- @param time number Time it took the process to finish (in ms)
--- @param code number Exit code
--- @param stderr string STDERR output of the process to show as an error
function M.atom_failure(name, time, code, stderr)
    vim.notify(
        ("Atom `" .. name .. "` failed with code (" .. code .. "). (Took " .. time .. "ms)\n" .. stderr),
        vim.log.levels.ERROR,
        NOTIFICATION_PARAMS()
    )
end

--- Notify an Atom failed (not the command itself but the actual `vim.system` call)
--- @param name string Atom name
--- @param error string Error thrown by lua
function M.atom_error(name, error)
    vim.notify(
        ("Atom `" .. name .. "` failed.\n" .. error),
        vim.log.levels.ERROR,
        NOTIFICATION_PARAMS()
    )
end

--- Notify Compound success
--- @param name string Compound name
--- @param time number Time it took the process to finish (in ms)
--- @param steps number Number of steps
function M.compound_success(name, time, steps)
    vim.notify(
        ("Compound `" .. name .. "` finished successfully after " .. steps .. " steps. (Took " .. time .. "ms)"),
        vim.log.levels.INFO,
        NOTIFICATION_PARAMS()
    )
end

--- Notify Compound failure
--- @param name string Compound name
--- @param time number Time it took the process to finish (in ms)
--- @param atom string Failed atom name
function M.compound_failure(name, time, atom)
    vim.notify(
        ("Compound `" .. name .. "` failed at atom `" .. atom .. "`. (Took " .. time .. "ms)"),
        vim.log.levels.ERROR,
        NOTIFICATION_PARAMS()
    )
end

return M
