--- Dalton task runner
---
--- `atoms` and `compounds` can be defined globally via `setup()`, or locally
--- per-project inside a `.nvim.lua` (exrc) file.
---
---@class dalton
---@see dalton.atom
---@see dalton.compound
local M = {}

--- Default properties for setup
--- @type dalton.opts
local DEFAULT_OPTS = {
    atoms = {},
    compounds = {},
}

--- Configure intial properties and global Atoms and Compounds.
--- You don't need to call this function for the plugin to work properly.
---
--- @param opts dalton.opts Plugin configuration, will be merged with defaults
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
--- @param def dalton.atom Atom definition
function M.atom(name, def)
    require("dalton._tasks").append(name, def)
end

--- Alias for `atom`
M.unit = M.atom

--- Create a new compound
--- You can also use alias `composite`
---
--- @param name string Unique identifier for the compound (shared with atoms)
--- @param def dalton.compound Compound definition
function M.compound(name, def)
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

--- Execute a task (either an `atom` or a `compound`) given it's name
---
--- @param name string Unique identifier for the task
function M.run(name)

end

return M
