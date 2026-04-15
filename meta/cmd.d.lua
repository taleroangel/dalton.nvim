--- @meta dalton.cmd

--- @class (exact) dalton.cmd.Subcommand
--- @field impl function
---     Subcommand implementation, each subcommand defines its parameters,
---     but all of the parameters must be strings, casting has to be handled
---     in impl
--- @field completion (fun(cmdline: string, arglead: string, cursorpos: number): string[])?
---     Completion callback
---     @see vim.api.nvim_create_user_command
