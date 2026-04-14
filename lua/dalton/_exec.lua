--- @package Module for handling command execution
local M = {}

--- Wrap a command in a system shell call
---
--- @param cmd string
--- @return string[] Argument list
local function wrap_for_shell(cmd)
    return {
        -- Shell command
        vim.o.shell,
        -- Command argument (-c or Unix, /c on Windows cmd or -Command on Windows Powershell)
        ({
            ["Linux"] = "-c",
            ["Darwin"] = "-c",
            ["Windows_NT"] = (vim.o.shell:find("pwsh") or vim.o.shell:find("powershell")) and "-Command" or "/c",
        })[vim.uv.os_uname().sysname],
        -- The actual command to be executed
        cmd
    }
end

--- Run an atom
--- Wrapper around `vim.system`
---
--- Call this from a coroutine
---
--- @param atom dalton.Atom
--- @return boolean success, number time, vim.SystemCompleted|string results
---     If 'success'is false, 'results' contains a string with the error
---     message, `vim.SystemCompleted` is returned otherwise
function M.exec(atom)
    -- Split cmd into a list of arguments
    ---@diagnostic disable-next-line: param-type-mismatch
    local cmd = (type(atom.cmd) == "string") and wrap_for_shell(atom.cmd) or atom.cmd
    ---@cast cmd string[]
    local cwd = atom.cwd and vim.fs.normalize(atom.cwd) or vim.fn.getcwd()
    local env = atom.env and vim.tbl_extend("force", vim.fn.environ(), atom.env) or nil

    -- Call execution, measure time
    local stime = vim.uv.now()
    local success, result = pcall(function()
        -- Create process (sync/blocking)
        return vim.system(cmd, { cwd = cwd, env = env, }, nil):wait()
    end)
    local delta = vim.uv.now() - stime

    return success, delta, result
end

return M
