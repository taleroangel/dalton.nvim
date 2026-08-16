--- @package Utilities for executing atoms

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
	local cmd = (type(atom.cmd) == "string") and { vim.o.shell, vim.o.shellcmdflag, atom.cmd } or atom.cmd
	---@cast cmd string[]
	local cwd = atom.cwd and vim.fs.normalize(atom.cwd) or vim.fn.getcwd()
	atom.env = (atom.env ~= nil) and atom.env or {}
	local env = vim.tbl_extend("force", vim.fn.environ(), atom.env)
	-- Measure time
	local stime, delta = vim.uv.now(), 0
	-- Create process (sync/blocking)
	---@type boolean, vim.SystemObj|string
	local success, obj = pcall(vim.system, cmd, { cwd = cwd, env = env }, function(obj)
		delta = vim.uv.now() - stime
		if obj.code ~= 0 or obj.signal ~= 0 then
			on_failure(delta, obj.code, (obj.stderr or obj.stdout or ""))
		else
			on_success(delta, obj.stdout)
		end
	end)
	--- Show error
	if not success then
		---@cast obj string
		on_error(obj)
	end
end

return exec
