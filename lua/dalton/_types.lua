--- @meta

--- @class (abstract) dalton.task Common fields to both `atoms` and `compounds`
--- @field desc string? Task description
--- @field ft (string[]|string)? Restrict and Atom/Compound to the given filetypes

--- @class dalton.atom: dalton.task
---     An Atom is the fundamental unit of work (an unit task).
---     It represents a single, named, executable task - a command or function
---     that does exactly one thing.
--- @field cmd string|string[] Command to run, or a list of arguments
--- @field cwd string? Working directory, defaults to the project root
--- @field env table<string, string>? Environment variables as key-value pairs

--- @class dalton.compound: dalton.task
---     A Compound is an ordered composition of Atoms (a composite task).
---     It represents a multi-step workflow where each step is a
---     reference to a named Atom.
--- @field steps string[] Ordered list of Atom names to execute sequentially
--- @field bail boolean? Abort on first failure, defaults to true

--- @class dalton.opts
---     Global configuration for Dalton.
---     Atoms and Compounds defined here are available across all projects
---     and filetypes, unless scoped with the `ft` field.
--- @field atoms table<string, dalton.atom>? Global Atom definitions, keyed by name
--- @field compounds table<string, dalton.compound>? Global Compound definitions, keyed by name

--- @alias dalton.list table<string, dalton.atom|dalton.compound>
---     List of tasks associated by their name

--- @alias dalton.type "atom"|"compound"
---     Atom or Compound type string

--- @alias dalton.type.pick
---| "default" Show available tasks for current buffer
---| "atom" Show all available atoms for current buffer
---| "compound" Show all available compounds for current buffer
---| "ft" Show only tasks with current buffer's filetype
---| "all" Show every registered task, even if not available
