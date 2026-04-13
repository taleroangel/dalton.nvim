--- @meta

--- @class (abstract) dalton.Task Common fields to both `atoms` and `compounds`
--- @field desc string? Task description
--- @field ft (string[]|string)? Restrict and Atom/Compound to the given filetypes

--- @class dalton.Atom: dalton.Task
---     An Atom is the fundamental unit of work (an unit task).
---     It represents a single, named, executable task - a command or function
---     that does exactly one thing.
--- @field cmd string[]|string
---     List of command arguments (prefered) or a string with the full command.
---     If a string is provided, the command is wrapped around the system shell
--- @field cwd string? Working directory, defaults to the project root
--- @field env table<string, string|number>? Environment variables as key-value pairs

--- @class dalton.Compound: dalton.Task
---     A Compound is an ordered composition of Atoms (a composite task).
---     It represents a multi-step workflow where each step is a
---     reference to a named Atom.
--- @field steps string[]
---     Ordered list of Atom names to execute sequentially, the Atoms must
---     exist when the Compound is ran, you can define not yet existant Atoms.
--- @field bail boolean? Abort on first failure, defaults to true

--- @class dalton.Opts
---     Global configuration for Dalton.
---     Atoms and Compounds defined here are available across all projects
---     and filetypes, unless scoped with the `ft` field.
--- @field atoms table<string, dalton.Atom>? Global Atom definitions, keyed by name
--- @field compounds table<string, dalton.Compound>? Global Compound definitions, keyed by name

--- @alias dalton.list table<string, dalton.Atom|dalton.Compound>
---     List of tasks associated by their name

--- @alias dalton.type "atom"|"compound"
---     Atom or Compound type string

--- @alias dalton.type.pick
---| "default" Show available tasks for current buffer
---| "atom" Show all available atoms for current buffer
---| "compound" Show all available compounds for current buffer
---| "ft" Show only tasks with current buffer's filetype
---| "all" Show every registered task, even if not available

--- @class dalton.run.Opts Run options
--- @field verbose boolean? Show command execution notifications and output, defaults to false.
