--- @package Utilities for executing atoms

--- Wrap a command in a system shell call
---
--- @param cmd string
--- @return string[] Argument list
local function wrap_system_shell(cmd)
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
--- @param atom dalton.Atom Atom to run
--- @param on_success fun(time: number, stdout: string) Callback for process return success
--- @param on_failure fun(time: number, code: number, stderr: string) Callback for exec success but process failure
--- @param on_error fun(what: string) Callback for exec error (not the process itself)
local function exec(atom, on_success, on_failure, on_error)
    -- Split cmd into a list of arguments
    ---@diagnostic disable-next-line: param-type-mismatch
    local cmd = (type(atom.cmd) == "string") and wrap_system_shell(atom.cmd) or atom.cmd
    ---@cast cmd string[]
    local cwd = atom.cwd and vim.fs.normalize(atom.cwd) or vim.fn.getcwd()
    local env = atom.env and vim.tbl_extend("force", vim.fn.environ(), atom.env) or nil
    -- Measure time
    local stime = vim.uv.now()
    local delta
    -- Create process (sync/blocking)
    ---@type boolean, vim.SystemObj|string
    local success, obj = pcall(vim.system, cmd, { cwd = cwd, env = env }, function(obj)
        delta = vim.uv.now() - stime
        if (obj.code ~= 0 or obj.signal ~= 0) then
            on_failure(delta, obj.code, (obj.stderr or obj.stdout or ""))
        else
            on_success(delta, obj.stdout)
        end
    end)
    --- Show error
    if (not success) then
        ---@cast obj string
        on_error(obj)
    end
end

return exec
