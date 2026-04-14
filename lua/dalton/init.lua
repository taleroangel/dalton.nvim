--- Dalton task runner
---
--- Atoms and Compounds can be defined globally via `setup()`, or locally
--- per-project inside a `.nvim.lua` (exrc) file.
---
---@class dalton
---@see dalton.Atom
---@see dalton.Compound
local M = {}

--- Default parameters for a task (either Atom or Compound)
--- @type dalton.Task
local TASK_DEFAULTS = {
    desc = nil,
    ft = nil,
}

--- Create a new atom.
--- You can also use alias `unit`
---
--- You can either define an Atom using the `dalton.Atom` type
---     > dalton.atom("build", { cmd = { "cmake", "--build", "build" } })
---
--- Or just by using its cmd string (shortcut)
---     > dalton.atom("build", "cmake --build build")
---
--- Using the same name of an already existing Atom will override it
---
--- @param name string Unique identifier for the atom (shared with compounds)
--- @param def dalton.Atom|dalton.AtomShortcut Atom definition
function M.atom(name, def)
    local helper = require("dalton._helper")
    if (helper.is_atom_shortcut(def)) then
        ---@cast def dalton.AtomShortcut
        def = helper.to_atom(def)
    end
    assert(helper.is_atom(def), "`" .. name .. "` is not a valid Atom")
    ---@cast def dalton.Atom
    def = vim.tbl_extend("keep", def, TASK_DEFAULTS)
    require("dalton._tasks").append(name, def)
end

--- Alias for `atom`
M.unit = M.atom

--- Default parameters for a Compound
local COMPOUND_DEFAULTS = {
    bail = true,
}

--- Create a new compound
--- You can also use alias `composite`
---
--- You can either define a Compound using the `dalton.Compound` type
---     > dalton.compound("open", { steps = { "build", "copy", "run" } })
---
--- Or just by using a list of steps (shortcut)
---     > dalton.compound("open", { "build", "copy", "run" })
---
--- Using the same name of an already existing task Compound will override it
---
--- @param name string Unique identifier for the Compound (shared with atoms)
--- @param def dalton.Compound|dalton.CompoundShortcut Compound definition
function M.compound(name, def)
    local helper = require("dalton._helper")
    if (helper.is_compound_shortcut(def)) then
        ---@cast def dalton.CompoundShortcut
        def = helper.to_compound(def)
    end
   assert(helper.is_compound(def), "`" .. name .. "` is not a valid Compound")
    ---@cast def dalton.Compound
    def = vim.tbl_extend("keep", def, TASK_DEFAULTS)
    def = vim.tbl_extend("keep", def, COMPOUND_DEFAULTS)
    require("dalton._tasks").append(name, def)
end

--- Alias for `compound`
M.composite = M.compound

--- Create either an Atom or a Compound, automatically detect what
--- you're trying to declare
---
--- i.e
---     > dalton.task("build", "cmake --build build") -- Atom (shortcut)
---     > dalton.task("run", { cmd = "ctest", cwd = "./build" }) -- Atom
---     > dalton.task("test", { "build", "run" }) -- Compound (shortcut)
---
--- @param name string Unique identifier
--- @param def dalton.any Atom, Compound or their shortcut variants
function M.task(name, def)
    local helper = require("dalton._helper")
    if (helper.is_atom_shortcut(def)) then
        ---@cast def dalton.AtomShortcut
        def = helper.to_atom(def)
    elseif (helper.is_compound_shortcut(def)) then
        ---@cast def dalton.CompoundShortcut
        def = helper.to_compound(def)
    end

    -- Delegate
    if (helper.is_atom(def)) then
        ---@cast def dalton.Atom
        return M.atom(name, def)
    elseif (helper.is_compound(def)) then
        ---@cast def dalton.Compound
        return M.compound(name, def)
    else
        error("Invalid task `" .. name .. "`. Neither an Atom nor a Composite")
    end
end

--- Create many atoms or compounds at once, the function will automatically
--- detect if an item is an Atom or a Compound.
---
--- i.e
---     dalton.add({
---         -- Creating an Atom with argument list
---         setup = { cmd = { "cmake", "-S.", "-Bbuild", "-DDEBUG=1" } },
---         -- Creating an Atom with cmd string and working directory
---         test = { cmd = "ctest", cwd = "./build" },
---         -- Creating an Atom (shortcut)
---         build = "cmake --build build",
---         -- Creating a Compound
---         validate = { steps = { "setup", "test" } },
---         -- Creating a Compound (shortcut)
---         compile = { "setup", "build" }
---     })
---
--- @param def dalton.list.any
---     A list of Atoms (and, or) Compounds, keyed by name.
function M.add(def)
    local helper = require("dalton._helper")
    for k, v in pairs(def) do
        -- Expand shortcuts
        if (helper.is_atom_shortcut(v)) then
            ---@cast v dalton.AtomShortcut
            v = helper.to_atom(v)
        elseif (helper.is_compound_shortcut(v)) then
            ---@cast v dalton.CompoundShortcut
            v = helper.to_compound(v)
        end
        assert(helper.is_atom(v) or helper.is_compound(v), "Invalid entry `" .. k .. "`, neither an Atom nor a Compound")
        ---@cast v dalton.Atom|dalton.Compound
        v = vim.tbl_extend("keep", v, TASK_DEFAULTS)
        if (helper.is_compound(v)) then
            ---@cast v dalton.Compound
            v = vim.tbl_extend("keep", v, COMPOUND_DEFAULTS)
        end
        -- Apply changes
        def[k] = v
    end
    ---@cast def dalton.list
    require("dalton._tasks").extend(def)
end

--- Delete a task by its name
--- @param name string Atom or Compound unique name
function M.delete(name)
    require("dalton._tasks").delete(name)
end

--- Get a list of available tasks (both atoms and compounds)
---
--- @param mode dalton.type.pick?
---     Choose which tasks are going to be shown, if nil use 'default'
--- @return dalton.list
---     List of Atoms (and, or) Compounds, keyed by name.
function M.list(mode)
    mode = mode or "default"
    local tasks = require("dalton._tasks").list()
    --- Filter entries using validator
    return require("dalton._utils").tbl_kfilter(tasks, function(_, task)
        return require("dalton._helper").is_valid_for_mode(task, mode)
    end)
end

--- Default options for run
--- @type dalton.run.Opts
local RUN_DEFAULTS = {
    verbose = false
}

--- Run a single Atom
--- @param name string Atom name
--- @param atom dalton.Atom Atom definition
--- @param verbose boolean Show STDOUT output
--- @return boolean success If Atom executed correctly
local function run_atom(name, atom, verbose)
    local exec = require("dalton._exec").exec
    local ui = require("dalton._ui")
    if (verbose) then ui.task_notify(name) end

    -- Run atom
    local success, time, obj = exec(atom)
    local fail = (not success) or (obj.code ~= 0) or (obj.signal ~= 0)

    if (not success) then
        ---@cast obj string
        ui.atom_error(name, time, obj)
    elseif (fail) then
        ui.atom_failure(name, time, obj.code, obj.stderr)
    else
        ui.atom_success(name, time, (verbose and obj.stdout or nil))
    end
    return (not fail)
end

--- Execute a task (either an Atom or a Compound) given it's name
---
--- @param name string Unique identifier for the task
--- @param opts dalton.run.Opts? Run options
function M.run(name, opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, RUN_DEFAULTS)
    ---@cast opts dalton.run.Opts

    -- Get task and check that it exists
    local task = require("dalton._tasks").get(name)
    if (task == nil) then
        error("No such task `" .. name .. "`")
    end

    local filters = require("dalton._helper")
    local ui = require("dalton._ui")

    -- Create coroutine to avoid blocking the UI
    local co = coroutine.create(function()
        -- Run the actual atom
        if (filters.is_atom(task)) then
            ---@cast task dalton.Atom
            run_atom(name, task, opts.verbose)
        elseif (filters.is_compound(task)) then
            ---@cast task dalton.Compound
            local err = false
            local stime = vim.uv.now()
            -- For each Atom in steps (important to keep it in order)
            for _, atom_name in ipairs(task.steps) do
                -- Get task and cast it to Atom
                local atom = require("dalton._tasks").get(atom_name)
                ---@cast atom dalton.Atom
                if (atom == nil or (not filters.is_atom(atom))) then
                    error("Compound `" .. name .. "` references an invalid task `" .. atom_name .. "`")
                end
                -- Run single atom
                local success = run_atom(atom_name, atom, opts.verbose)
                if ((not success) and task.bail) then
                    local delta = vim.uv.now() - stime
                    ui.compound_failure(name, delta, atom_name)
                    break -- Stop execution
                end
            end
            -- Show results
            if (not err) then
                local delta = vim.uv.now() - stime
                ui.compound_success(name, delta, #task.steps)
            end
        end
    end)

    -- Init coroutine and check errors
    local success, err = coroutine.resume(co)
    if (not success) then
        error(err)
    end
end

return M
