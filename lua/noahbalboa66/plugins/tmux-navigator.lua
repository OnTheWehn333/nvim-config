return {
	"christoomey/vim-tmux-navigator",
	init = function()
		-- Disable the default mappings provided by vim-tmux-navigator
		vim.g.tmux_navigator_no_mappings = 1
	end,
	config = function()
		-- Custom mappings using Ctrl + Arrow keys for navigation
		vim.keymap.set("n", "<C-Up>", ":TmuxNavigateUp<CR>", { silent = true, desc = "Navigate to pane above" })
		vim.keymap.set("n", "<C-Down>", ":TmuxNavigateDown<CR>", { silent = true, desc = "Navigate to pane below" })
		vim.keymap.set("n", "<C-Left>", ":TmuxNavigateLeft<CR>", { silent = true, desc = "Navigate to pane left" })
		vim.keymap.set("n", "<C-Right>", ":TmuxNavigateRight<CR>", { silent = true, desc = "Navigate to pane right" })
	end,
	lazy = false,
	event = "VeryLazy",
}
