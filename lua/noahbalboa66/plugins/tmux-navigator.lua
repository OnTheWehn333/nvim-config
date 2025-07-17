return {
	"christoomey/vim-tmux-navigator",
	config = function()
		-- Disable the default mappings provided by vim-tmux-navigator
		vim.g.tmux_navigator_no_mappings = 1

		-- Custom mappings using Ctrl + Arrow keys for navigation
		vim.keymap.set("n", "<C-Up>", ":TmuxNavigateUp<CR>", { silent = true })
		vim.keymap.set("n", "<C-Down>", ":TmuxNavigateDown<CR>", { silent = true })
		vim.keymap.set("n", "<C-Left>", ":TmuxNavigateLeft<CR>", { silent = true })
		vim.keymap.set("n", "<C-Right>", ":TmuxNavigateRight<CR>", { silent = true })
	end,
	lazy = false,
	event = "VeryLazy",
}
