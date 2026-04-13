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

--- Default parameters for a task (either Atom or Compound)
--- @type dalton.Task
local TASK_DEFAULTS = {
    ft = nil,
    desc = nil,
    verbose = false,
}

--- Default parameters for a Compound
local COMPOUND_DEFAULTS = {
    bail = true,
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
    local tasks = require("dalton._tasks").list()
    local filters = require("dalton._filter")
    ---@diagnostic disable-next-line: redefined-local
    local mode = mode or "default"

    --- Function to use to validate entries based on pick mode
    --- @type fun(v: dalton.Task): boolean
    local validator = ({
        default = function(v)
            return filters.has_ft(v, nil) or filters.has_ft(v, vim.bo.ft)
        end,
        atom = function(v)
            return (filters.has_ft(v, nil) or filters.has_ft(v, vim.bo.ft)) and filters.is_atom(v)
        end,
        compound = function(v)
            return (filters.has_ft(v, nil) or filters.has_ft(v, vim.bo.ft)) and filters.is_compound(v)
        end,
        ft = function(v)
            return filters.has_ft(v, vim.bo.ft)
        end,
        all = function(_)
            return true
        end,

    })[mode]

    --- Filter entries using validator
    return require("dalton._utils").tbl_kfilter(tasks, function(_, task)
        return validator(task)
    end)
end

--- Default options for run
--- @type dalton.run.Opts
local RUN_DEFAULTS = {
    verbose = false
}

--- Execute a task (either an Atom or a Compound) given it's name
---
--- @param tname string Unique identifier for the task
--- @param opts dalton.run.Opts? Run options
function M.run(tname, opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, RUN_DEFAULTS)
    ---@cast opts dalton.run.Opts

    -- Get task and check that it exists
    local task = require("dalton._tasks").get(tname)
    if (task == nil) then
        error("No such task `" .. tname .. "`")
    end

    local ui = require("dalton._ui")
    --- Wraper for running atoms
    --- @type fun(key: string, atom: dalton.Atom): boolean, vim.SystemCompleted|string
    local atom_run = function(key, atom)
        if (opts.verbose) then ui.task_notify(key) end
        local stime = vim.uv.now()
        -- Actual process execution
        --- @type boolean, vim.SystemCompleted|string
        local success, obj = pcall(require("dalton._exec").exec, atom)
        -- Compute time and show results
        local delta = vim.uv.now() - stime
        if (not success) then
            ---@cast obj string
            ui.atom_error(key, delta, obj)
        elseif ((obj.code ~= 0) or (obj.signal ~= 0)) then
            ui.atom_failure(key, delta, obj.code, obj.stderr)
        else
            ui.atom_success(key, delta, (opts.verbose and obj.stdout or nil))
        end

        return success, obj
    end

    -- Run the actual atom
    local filters = require("dalton._filter")
    if (filters.is_atom(task)) then
        ---@cast task dalton.Atom
        atom_run(tname, task)
    elseif (filters.is_compound(task)) then
        ---@cast task dalton.Compound
        if (opts.verbose) then ui.task_notify(tname) end
        local success = true
        local stime = vim.uv.now()
        -- For each Atom in steps (important to keep it in order)
        for _, aname in ipairs(task.steps) do
            -- Get task and cast it to Atom
            local atom = require("dalton._tasks").get(aname)
            ---@cast atom dalton.Atom
            if (atom == nil or (not filters.is_atom(atom))) then
                error("Compound `" .. tname .. "` references an invalid task `" .. aname .. "`")
            end
            -- Run single atom
            local atom_success, obj = atom_run(aname, atom)
            if ((not atom_success) or (task.bail and (obj.code ~= 0 or obj.signal ~= 0))) then
                local delta = vim.uv.now() - stime
                ui.compound_bail(tname, delta, aname)
                success = false
                break
            end
        end
        -- Show results
        local delta = vim.uv.now() - stime
        if (success) then
            ui.compound_success(tname, delta, #task.steps)
        end
    end
end

return M
