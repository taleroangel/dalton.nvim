--- Dalton task runner
---
--- Atoms and Compounds can be defined globally via `setup()`, or locally
--- per-project inside a `.nvim.lua` (exrc) file.
---
---@class dalton
---@see dalton.Atom
---@see dalton.Compound
local M = {}

--- Default properties for setup
--- @type dalton.Opts
local DEFAULT_OPTS = {
    atoms = {},
    compounds = {},
}

--- Configure intial properties and global Atoms and Compounds.
--- You don't need to call this function for the plugin to work properly.
---
--- @param opts dalton.Opts Plugin configuration, will be merged with defaults
function M.setup(opts)
    local o = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts or {})
    local tasks = vim.tbl_extend("error", o.atoms, o.compounds)
    require("dalton._tasks").replace(tasks)
end

--- Default parameters for a task (either Atom or Compound)
--- @type dalton.Task
local TASK_DEFAULTS = {
    ft = nil,
    desc = nil,
    verbose = false,
}

--- Create a new atom.
--- You can also use alias `unit`
---
--- Using the same name of an already existing task (either an Atom or a Compound)
--- will override it
---
--- @param name string Unique identifier for the atom (shared with compounds)
--- @param def dalton.Atom Atom definition
function M.atom(name, def)
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
--- @param name string Unique identifier for the compound (shared with atoms)
--- @param def dalton.Compound Compound definition
function M.compound(name, def)
    def = vim.tbl_extend("keep", def, TASK_DEFAULTS)
    def = vim.tbl_extend("keep", def, COMPOUND_DEFAULTS)
    require("dalton._tasks").append(name, def)
end

--- Alias for `compound`
M.composite = M.compound

--- Create many atoms or compounds at once, the function will automatically
--- detect if an item is an atom or a compound.
---
--- @param def dalton.list
---     A list of Atoms (and, or) Compounds, keyed by name.
function M.add(def)
    for k, v in pairs(def) do
        def[k] = vim.tbl_extend("keep", v, TASK_DEFAULTS)
        if (require("dalton._filter").is_compound(v)) then
            def[k] = vim.tbl_extend("keep", def, COMPOUND_DEFAULTS)
        end
    end
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
        return require("dalton._filter").filter_for_mode(task, mode)
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

    local filters = require("dalton._filter")
    local ui = require("dalton._ui")

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
            end
        end
        -- Show results
        if (not err) then
            local delta = vim.uv.now() - stime
            ui.compound_success(name, delta, #task.steps)
        end
    end
end

return M
