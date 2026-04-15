-- Register commands
vim.api.nvim_create_user_command(
    "Dalton",
    require("dalton._vim.cmd").command,
    {
        nargs = "+",
        desc = "Run/manage Dalton tasks",
        complete = require("dalton._vim.cmd").completion,
    }
)
