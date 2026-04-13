local M = {}

--- Additional parameters for notificacionts
local NOTIFICATION_PARAMS = {
    title = "Dalton.nvim",
    ft = "markdown",        -- folke/snacks.nvim (snacks.notify)
    on_open = function(win) -- rcarriga/nvim-notify
        local bufnr = vim.api.nvim_win_get_buf(win)
        vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
    end
}

--- Notify a task just started
--- @param name string Task name
function M.task_notify(name)
    vim.notify("Task `" .. name .. "` started", vim.log.levels.INFO, NOTIFICATION_PARAMS)
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
        NOTIFICATION_PARAMS
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
        NOTIFICATION_PARAMS
    )
end

--- Notify an Atom failed (not the command itself but the actual `vim.system` call)
--- @param name string Atom name
--- @param time number Time it took the process to finish (in ms)
--- @param error string Error thrown by lua
function M.atom_error(name, time, error)
    vim.notify(
        ("Atom `" .. name .. "` failed. (Took " .. time .. "ms)\n:" .. error),
        vim.log.levels.ERROR,
        NOTIFICATION_PARAMS
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
        NOTIFICATION_PARAMS
    )
end

--- Notify Compound failure
--- @param name string Compound name
--- @param time number Time it took the process to finish (in ms)
--- @param atom string Failed atom name
function M.compound_bail(name, time, atom)
    vim.notify(
        ("Compound `" .. name .. "` failed at atom `" .. atom .. "`. (Took " .. time .. "ms)"),
        vim.log.levels.ERROR,
        NOTIFICATION_PARAMS
    )
end

return M
