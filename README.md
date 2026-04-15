# dalton.nvim

A very simple task runner for Neovim.

while _overseer.nvim_ is undoubtedly the gold standard for task runners in Neovim,
its often more than I need. I wanted a task runner that was dead simple and I also
wanted it to be designed around `.nvim.lua` (because I use that a lot for project
configuration). I looked at a few existing options, but decided to build my own.
It was the perfect excuse to finally write my first Neovim plugin.

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "taleroangel/dalton.nvim",
    config = function()
        -- Configurations
    end
}
```

## 🚀 Getting Started

### Atoms (Individual Tasks)

```lua
local dalton = require("dalton")

-- Shortcut: string command
dalton.atom("build", "cmake --build build")

-- Detailed: table definition
dalton.atom("test", {
    cmd = "ctest",
    cwd = "./build",
    desc = "Run project tests",
    ft = { "cpp", "c" }
})

-- Aliases: Maybe atom is not that easy to remember?
dalton.unit("build", "cmake --build build")
dalton.task("build", "cmake --build build")
```

### Compounds (Multi-step Tasks)

```lua
-- Shortcut: list of atoms
dalton.compound("all", { "build", "test" })

-- Detailed: table definition
dalton.compound("release", {
    steps = { "build", "test", "deploy" },
    bail = true -- Stop if any step fails
})

-- Aliases: Compound is not that easy to remember?
dalton.composite("all", { "build", "test" })
dalton.task("all", { "build", "test" })
```

Notice that `dalton.task` can be use for both _Atoms_ and _Compounds_, this
function will automatically detect which you're trying to declare.

### Batch Definition

```lua
dalton.add({
    fmt = "stylua .",
    lint = "selene .",
    check = { "fmt", "lint" } -- Automatically detected as a Compound
})
```

### Global Tasks
This is an example of creating global tasks inside `lazy.nvim`

```lua
{
    "taleroangel/dalton.nvim",
    config = function()
        -- Create global configurations
        require("dalton").add({
            cbuild = {
                desc = "Build project with CMake"
                cmd = "cmake --build build",
                ft = { "c", "cpp" }
            },
            rbuild = {
                desc = "Build project with Cargo"
                cmd = "cargo build",
                ft = { "rust" }
            }
        })
    end
}

```

### Project-Local Tasks (`.nvim.lua`)
Define tasks specific to your project by creating a `.nvim.lua` file in your root directory:

```lua
local dalton = require("dalton")

dalton.add({
    -- Atomic tasks
    build = "cmake --build build",
    test = { cmd = "ctest", cwd = "./build" },
   
    -- Compound
    all = { "build", "test" },
    
    -- Task with environment variables
    debug = { 
        cmd = "./build/app", 
        env = { DEBUG = "1" },
        desc = "Run app with debug logs"
    }
})
```

> [!TIP]
> Ensure `vim.o.exrc = true` in your global `init.lua` to enable local configuration files.

## 🛠 Usage

- **Run a task**: `:lua require("dalton").run("build")` or `:Dalton run build`
- **Pick a task**: `:lua require("dalton").pick()` or `:Dalton pick`
- **Filter by filetype**: `:lua require("dalton").pick("ft")`

## 📖 Documentation

For full details on the API and configuration, see `:help dalton.txt`.

### Acknowledgements

Very good alternatives that didn't quite fit my needs, but might fit yours. 

- **[overseer.nvim](https://github.com/stevearc/overseer.nvim)**: A fully-featured task runner based on templates
- **[launchpad.nvim](https://github.com/hongzio/launchpad.nvim)**: File-based run and debug configurations runner
- **[nvimlaunch](https://github.com/hadishahpuri/nvimlaunch)**: File-based shell command manager

## 📚️ What's next?
[ ] Allow tasks to run on project startup (`auto` flag)
[ ] [nvim-dap](https://github.com/mfussenegger/nvim-dap) _preLaunchTask_ support.
