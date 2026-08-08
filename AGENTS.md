# AGENTS.md — Project Handover

## Purpose

This document is the official handover for the Neovim configuration repository maintained by the previous engineer. It is intended to help new maintainers quickly understand, run, and extend the configuration.

> NOTE: If an older AGENTS.md existed, this file replaces conflicting sections while preserving any non-conflicting historical notes elsewhere in the repo.

---

## High-level overview

- This repo contains a personal Neovim configuration built with Lua and Lazy.nvim as the plugin manager.
- Primary goals: fast startup, modular plugin configs, robust LSP and formatting integrations, and ergonomic keymaps.
- Owner: noahbalboa66 (local config style; user-specific tweaks are expected).

---

## Repository layout (important files and directories)

- init.lua — main entry that bootstraps the config.
- CLAUDE.md — developer guidance and common commands for working with this repo.
- lazy-lock.json — exact pinned plugin versions managed by Lazy.nvim.
- lua/noahbalboa66/ — main Lua configuration namespace (plugins, lsp, remap, opts, utils, etc.).
- snippets/ — user snippets used by snippet engines (contains cs.json, sql.json, etc.).
- snippets/package.json, http.json — additional snippet files.
- AGENTS.md — (this file) handover and maintenance notes.

Note: Some files may be in the root or under lua/noahbalboa66 depending on the module.

---

## Prerequisites and environment

- Neovim: Use a recent stable Neovim (recommend >= 0.9; 0.10+ ideal). Verify via `nvim --version`.
- Shell: zsh is the main shell used in terminal integration.
- Lua: Bundled with Neovim; no separate installation required.
- Optional: Git and GitHub CLI (`gh`) if you interact with the repository remote or create PRs.

---

## First-time setup (bootstrap)

1. Clone the repo into your Neovim config directory (if using XDG defaults):
   - ~/.config/nvim or set $XDG_CONFIG_HOME.
2. Start Neovim. Lazy.nvim will prompt to install plugins automatically (or run `:Lazy sync`).
3. Run `:checkhealth lazy` and `:checkhealth vim.lsp`.
4. Install language servers and developer tools through the Nix/Home Manager configuration; Mason is not used.
5. Run formatting as needed; Conform is configured for format-on-save (see `lua/noahbalboa66/plugins/conform.lua`).

Helpful commands:

- `:Lazy` — open plugin manager UI.
- `:Lazy sync` — sync and install plugin changes.
- `:LspInfo` — view attached LSP servers in the current buffer.
- `:checkhealth vim.lsp` — inspect enabled LSP configurations and health.

---

## Plugin management

- Lazy.nvim is the single source of plugin declarations and lazy-loading configuration.
- `lazy-lock.json` pins plugin versions. To update plugins:
  1. Edit plugin lists under `lua/noahbalboa66/plugins/`.
  2. Run `:Lazy sync` and review `lazy-lock.json` changes.
  3. Commit both config changes and lockfile changes together.

Conventions for adding a plugin:

- Add a module under `lua/noahbalboa66/plugins/` named meaningfully (e.g., `telescope.lua`).
- Export plugin specification using the repo's established pattern (see existing plugin files).
- Keep plugin-specific keymaps and setup local to the plugin file when possible.

---

## Language Server Protocol (LSP) and formatters

- LSP servers are configured in `lua/noahbalboa66/lsp.lua` with `vim.lsp.config()` and `vim.lsp.enable()`.
- Language-server and formatter executables are provided by Nix/PATH; Mason is not used.
- Roslyn is the sole C# language server; do not enable OmniSharp concurrently.
- Native LSP owns contextual actions, while Snacks owns picker/list workflows.
- Formatters are handled via Conform and language-specific formatters are chained where appropriate (e.g., Python: isort -> Black).
- Common LSP commands: `:LspInfo`, `:checkhealth vim.lsp`, and `:LspRestart`.

---

## Keybindings and UX

- Leader key is `space` (" ").
- Common custom mappings are defined in `lua/noahbalboa66/remap.lua`.
- Window and buffer utilities, Harpoon integration, and Telescope bindings are present. Check `remap.lua` for specifics.

---

## Utilities and helper modules

- `lua/noahbalboa66/utils.lua` contains shared helpers (git root detection, project utilities, etc.).
- Autocommands and filetype-specific config are located under `filetype.lua` and plugin modules.

---

## Snippets

- Snippet files are in `snippets/`. Keep JSON snippet files organized by language.
- If adding snippets, ensure your snippet engine (e.g., luasnip) is configured to load this directory.

---

## Development workflow

- Edit Lua modules under `lua/noahbalboa66/` and reload Neovim or source minimal config.
- Use `:luafile %` for quickly reloading a Lua file in an open Neovim session when testing.
- Test plugin additions by restarting Neovim or using `:Lazy sync` and observing any errors on startup.

Best practices:

- Make small, testable changes and keep commits focused (one feature or fix per commit).
- When changing plugin behavior, update the README or CLAUDE.md with a short note if the change affects daily workflow.

---

## Troubleshooting and common issues

- If Neovim fails to start or shows module errors, run `nvim --clean` to start with no plugins and reproduce the issue.
- Use `:checkhealth` to identify missing system dependencies.
- If LSP servers fail to start, verify the executable is present in Neovim's Nix-provided `PATH`, rebuild the Home Manager configuration if needed, and restart Neovim.
- If a plugin update breaks config, revert `lazy-lock.json` and plugin changes until a fix is made.

---

## Testing and linting

- Build/lint/test commands:
  - Format Lua: `stylua .` (formats entire repo)
  - Lint Lua: `luacheck .` (if installed)
  - Run a single test: this repo has no automated test framework; to run a single Lua test, use `busted path/to/test.lua` after adding `busted` tests.
  - Quick smoke: `nvim --clean -u init.lua` to start with this config.

- This repo is primarily configuration files (Lua). Use `stylua` for formatting Lua where configured.
- If you add scripts or tools, include lint/typecheck commands in CLAUDE.md or README.

---

## Code style & agent rules

- Formatting: use `stylua` with default config; run on save or CI.
- Imports/modules: follow `lua/noahbalboa66/*.lua` namespace; require using relative names (e.g. `require("noahbalboa66.utils")`).
- Types: prefer clear runtime checks; annotate intent with comments (Lua has no types here).
- Naming: use snake_case for files and functions, camelCase for local variables where consistent; module table names use the module basename.
- Error handling: return nil, err for failures; avoid throwing unless fatal; log via `vim.notify` for user-visible errors.
- Tests: place busted tests under `spec/` following `describe`/`it` style.
- Commits: include focused message and update `lazy-lock.json` when changing plugins.

## How to add a new maintainer or update this handover

- Edit this AGENTS.md, add a short changelog entry at the bottom with date and author.
- Keep CLAUDE.md updated with common commands and any new developer-facing scripts.

---

## Contact and resources

- Existing maintainer: noahbalboa66 (local-ish config; no centralized team contact listed).
- Useful links:
  - Lazy.nvim docs
  - Conform/stylua docs
  - Neovim LSP documentation

---

## Changelog (handover entries)

- 2025-08-07 — Initial handover created and saved as AGENTS.md.
- 2025-08-07 — Removed Telescope configuration: renamed lua/noahbalboa66/plugins/telescope.lua to lua/noahbalboa66/plugins/telescope.lua.bak, replaced lua/noahbalboa66/plugins/telescope.lua and lua/noahbalboa66/plugins/recent-files.lua with minimal plugin specs (return {}), and removed Telescope-only helpers from lua/noahbalboa66/utils.lua.
- 2025-08-08 — Deleted telescope backup and empty plugin files: lua/noahbalboa66/plugins/telescope.lua.bak and lua/noahbalboa66/plugins/telescope.lua were removed from the repo.
- 2026-08-07 — Consolidated LSP UX around native Neovim and Snacks, removed Lspsaga/Trouble/Mason/Telescope, made Nix the tool provider, and standardized modern LSP mappings and capabilities.

---

## Appendix: quick commands

- Bootstrap plugins: `nvim` (then `:Lazy sync`)
- Update plugins: `:Lazy sync` (commit lazy-lock.json)
- Install LSP tools: add packages to the Nix/Home Manager configuration and rebuild
- View LSP: `:LspInfo`
- Check LSP health: `:checkhealth vim.lsp`

---

---

## Agent rules

- Cursor rules: none detected in `.cursor/rules/` or `.cursorrules`.
- GitHub Copilot rules: none detected in `.github/copilot-instructions.md`.

End of AGENTS.md
