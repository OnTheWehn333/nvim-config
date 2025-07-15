# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Plugin Management
- **Install/Update Plugins**: `:Lazy` - Opens Lazy.nvim plugin manager interface
- **Sync Plugins**: `:Lazy sync` - Updates and cleans plugins according to lazy-lock.json
- **Check Plugin Health**: `:checkhealth lazy` - Verifies plugin installation status

### LSP and Language Servers
- **Install Language Servers**: `:Mason` - Opens Mason interface to install/manage LSP servers
- **LSP Info**: `:LspInfo` - Shows attached LSP servers for current buffer
- **Format Code**: `<leader>f` - Manual formatting with Conform, or `<leader>vf` for LSP formatting

### Development Tools
- **File Navigation**: 
  - `<leader>sf` - Search files with Telescope
  - `<leader>sg` - Live grep search
  - `<leader>gf` - Git files search
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
    ├── telescope.lua     # Fuzzy finder and search
    ├── harpoon.lua      # Quick file navigation
    ├── mason.lua        # LSP server management
    ├── conform.lua      # Code formatting
    ├── avante.lua       # AI coding assistant
    └── [40+ other plugins]
```

### Core Plugin Ecosystem
1. **Search & Navigation**: Telescope (fuzzy finder) + Harpoon (quick access) + Oil (file explorer)
2. **LSP Stack**: Mason (server management) → LSPConfig → nvim-cmp (completion)
3. **Code Quality**: Conform (formatting) + LSP (diagnostics) + Treesitter (syntax)
4. **Git Integration**: Gitsigns + Fugitive + LazyGit + Diffview + Octo (GitHub)
5. **AI Tools**: Avante (AI assistant) + Copilot (suggestions)

### Language Support
- **Lua**: stylua formatter, lua_ls LSP server
- **Python**: isort + black formatters  
- **JavaScript/TypeScript**: ts_ls LSP (formatting disabled, relies on external tools)
- **C#**: OmniSharp LSP, csharpier formatter, DAP debugging support
- **Go**: go.nvim plugin with full toolchain integration
- **YAML**: Dedicated plugin for Kubernetes/Docker workflows

### Key Integration Patterns
- **Shared Dependencies**: plenary.nvim used across multiple plugins
- **Extension System**: Telescope acts as platform with fzf, git-history, trouble extensions
- **Utility Functions**: Custom git root finding and project detection in utils.lua
- **Cross-Plugin Communication**: Trouble integrates with Telescope for error navigation

### Development Workflow Features
- **Format-on-Save**: Automatic formatting with 500ms timeout via Conform
- **LSP Integration**: Jump to definition, hover, diagnostics, code actions
- **Git Workflow**: Stage hunks, blame, branch management, GitHub PR integration
- **Project Navigation**: Git root detection, recent files, fuzzy search
- **AI Assistance**: Code generation and explanation via Avante with image support

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
- **Custom LSP Setup**: Uses vim.lsp.config() with manual OmniSharp path configuration
- **Format Chain**: Some languages use multiple formatters in sequence (Python: isort → black)
- **Git Root Detection**: Custom functions in utils.lua for project-aware commands
- **Image Support**: Avante plugin includes image clipboard integration for AI interactions