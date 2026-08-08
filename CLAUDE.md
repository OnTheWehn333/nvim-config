# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Plugin Management

- **Install/Update Plugins**: `:Lazy` - Opens Lazy.nvim plugin manager interface
- **Sync Plugins**: `:Lazy sync` - Updates and cleans plugins according to lazy-lock.json
- **Check Plugin Health**: `:checkhealth lazy` - Verifies plugin installation status

### LSP and Language Servers

- **Install Language Servers**: Add executables to the Nix/Home Manager configuration; Mason is not used
- **LSP Info**: `:LspInfo` - Shows attached LSP servers for the current buffer
- **LSP Health**: `:checkhealth vim.lsp` - Checks enabled configurations and active clients
- **Format Code**: `<leader>f` - Manual formatting with Conform

### Development Tools

- **File Navigation**:
  - `<leader>sf` - Search files with Snacks
  - `<leader>sg` - Live grep with Snacks
  - `<leader>sG` - Search Git files with Snacks
- **Quick File Access**:
  - `<leader>ha` - Add file to Harpoon
  - `<leader>hm` - Harpoon quick menu
  - `<C-h>`, `<C-t>`, `<C-n>`, `<C-s>` - Jump to Harpoon files 1-4
- **Git Operations**: `<leader>gg` - LazyGit interface

## Configuration Architecture

### Plugin Management System

- **Plugin Manager**: Lazy.nvim with lazy loading and dependency management
- **Lock File**: `lazy-lock.json` pins exact plugin versions for reproducibility
- **Plugin Loading**: Event-driven loading via `require("lazy").setup('noahbalboa66.plugins')`

### Configuration Structure

```
lua/noahbalboa66/
├── init.lua          # Main module loader
├── opts.lua          # Vim options and settings
├── remap.lua         # Key mappings and bindings
├── lsp.lua           # LSP configuration and setup
├── filetype.lua      # Filetype-specific settings
├── utils.lua         # Shared utility functions
└── plugins/          # Individual plugin configurations
    ├── snacks.lua       # Pickers, explorer, notifications, and utilities
    ├── harpoon.lua      # Quick file navigation
    ├── lspconfig.lua    # nvim-lspconfig plugin declaration
    ├── conform.lua      # Code formatting
    ├── roslyn.lua       # C# Roslyn integration
    └── [40+ other plugins]
```

### Core Plugin Ecosystem

1. **Search & Navigation**: Snacks pickers/explorer + Harpoon + Oil
2. **LSP Stack**: Nix-provided binaries → native LSP/nvim-lspconfig → Blink completion
3. **Code Quality**: Conform formatting + native LSP diagnostics + Treesitter syntax
4. **Git Integration**: Gitsigns + Fugitive + LazyGit + Diffview + Octo (GitHub)
5. **AI Tools**: Pi coding-agent chat/review workflows + opencode integration

### Language Support

- **Lua**: lua_ls + StyLua
- **Python**: isort + Black formatters; no Python LSP is currently enabled
- **JavaScript/TypeScript**: vtsls; formatting falls back to LSP unless a formatter is added
- **C#**: Roslyn + CSharpier + netcoredbg; do not enable OmniSharp
- **Go**: gopls is owned by the core LSP config; go.nvim provides additional commands/tooling
- **Java**: jdtls from Nix/PATH
- **YAML**: yaml.nvim uses Snacks; yamlfmt formats files, but yamlls is not currently enabled

### Key Integration Patterns

- **LSP UI**: Native LSP owns contextual actions; Snacks owns list/search/preview workflows
- **LSP Navigation**: Snacks handles definitions, references, implementations, symbols, diagnostics, and call hierarchy
- **Word References**: Snacks Words owns LSP document highlighting
- **Utility Functions**: Shared project helpers live in utils.lua

### Development Workflow Features

- **Format-on-Save**: Automatic formatting with 500ms timeout via Conform
- **LSP Integration**: Jump to definition, hover, diagnostics, code actions
- **Git Workflow**: Stage hunks, blame, branch management, GitHub PR integration
- **Project Navigation**: Git root detection, recent files, fuzzy search
- **AI Assistance**: Pi provides project-scoped chat and review workflows; opencode provides additional agent integration

### Configuration Management

- **Leader Key**: Space (`" "`) for most custom commands
- **Window Management**: Custom resize functions for split management
- **Tmux Integration**: Seamless navigation between Neovim and tmux panes
- **Terminal Integration**: Uses 'zsh' as terminal emulator

### Performance Optimizations

- **Lazy Loading**: Plugins load on specific events (VeryLazy, BufWritePre, etc.)
- **Bigfile Handling**: Special plugin to disable features for large files
- **UFO Folding**: Enhanced code folding for better navigation
- **Undotree**: Persistent undo with dedicated undo directory

### Special Considerations

- **LSP Setup**: Uses Neovim's modern `vim.lsp.config()`/`vim.lsp.enable()` APIs
- **Dependency Ownership**: Language servers, formatters, debuggers, and runtimes come from Nix/PATH, not Mason
- **C#**: roslyn.nvim enables Roslyn; running OmniSharp concurrently causes duplicate clients
- **Format Chain**: Some languages use multiple formatters in sequence (Python: isort → Black)
- **Git Root Detection**: Custom functions in utils.lua support project-aware commands
