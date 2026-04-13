local M = {}

--- Run an atom
--- Wrapper around `vim.system`
---
--- @param atom dalton.Atom
--- @return vim.SystemCompleted
function M.exec(atom)
    -- Split cmd into a list of arguments
    ---@diagnostic disable-next-line: param-type-mismatch
    local cmd = (type(atom.cmd) == "string") and { "sh", "-c", atom.cmd } or atom.cmd
    ---@cast cmd string[]
    return vim.system(cmd, {
            cwd = atom.cwd and vim.fs.normalize(atom.cwd) or vim.fn.getcwd(),
            env = atom.env and vim.tbl_extend("force", vim.fn.environ(), atom.env) or nil,
        }, nil)
        :wait()
end

return M
