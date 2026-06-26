; Disable legacy nvim-treesitter markdown injections on Neovim 0.12.
; The old `#set-lang-from-info-string!` directive can receive a non-node value
; and trip `vim.treesitter.get_node_text()` with `attempt to call method 'range'`.
; Remove this override after migrating off legacy nvim-treesitter modules.
