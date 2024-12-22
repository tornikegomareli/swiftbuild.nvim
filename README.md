# swiftbuiuld.nvim

Simple Neovim plugin for Swift build commands.

## Features
- `:SwiftBuild` or `:sb` - Build the Swift project
- `:SwiftRun` or `:sr` - Run the Swift project
- `:SwiftTest` or `:st` - Run tests
- `:SwiftClean` or `:sc` - Clean build artifacts

## Installation

Using lazy.nvim:
```lua
{
  "tornikegomareli/swift.nvim",
  config = function()
    require("swift").setup()
  end
}
