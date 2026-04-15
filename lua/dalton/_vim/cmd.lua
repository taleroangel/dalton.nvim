--- @package Utilities for managing commands
local M = {}

--- List of subcommands
--- @type table<string, dalton.cmd.Subcommand>
local commands = {
    --- Run a command given its name
    run = {
        --- @param name string Name of the command to run
        impl = function(name)
            -- Opts not supported using command
            require("dalton").run(name, {})
        end,
        completion = function(_1, _2, _3)

        end,
    },
    --- Pick a task to run
    pick = {
        impl = function()
            require("dalton").pick()
        end,
        completion = nil,
    },
}

--- Main command entry-point
--- This command should parse args and delegate to subcommands
---
--- @param opts vim.api.keyset.create_user_command.command_args
function M.command(opts)
    -- Get command arguments
    local args = opts.fargs
    if (not args and #args < 1) then
        error("No subcommand was provided")
    end

    -- Get subcommand, check if it exists
    local subcommand = commands[args[1]]
    if (not subcommand) then
        error("No such command `Dalton " .. args[1] .. "`")
    end

    -- Delegate to subcommand, and pass arguments
    subcommand.impl((table.unpack or unpack)(args, 2))
end

--- Command completion callback
function M.completion(arglead, cmdline, cursorpos)
    local args = vim.split(cmdline, "%s+", { trimempty = true })
    local n = #args

    -- Complete subcommands
    
    
    -- Delegate completion to subcommand
end

return M
