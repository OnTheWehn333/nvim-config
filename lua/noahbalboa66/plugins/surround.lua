return {
	"kylechui/nvim-surround",
	version = "*", -- Use for stability; omit to use `main` branch for the latest features
	event = "VeryLazy",
	init = function()
		vim.g.nvim_surround_no_mappings = true
	end,
	config = function()
		require("nvim-surround").setup({})

		vim.keymap.set("i", "<C-g>z", "<Plug>(nvim-surround-insert)", { desc = "Add surround (insert)" })
		vim.keymap.set("i", "<C-g>Z", "<Plug>(nvim-surround-insert-line)", { desc = "Add surround line (insert)" })
		vim.keymap.set("n", "yz", "<Plug>(nvim-surround-normal)", { desc = "Add surround" })
		vim.keymap.set("n", "yzz", "<Plug>(nvim-surround-normal-cur)", { desc = "Add surround current line" })
		vim.keymap.set("n", "yZ", "<Plug>(nvim-surround-normal-line)", { desc = "Add surround line" })
		vim.keymap.set("n", "yZZ", "<Plug>(nvim-surround-normal-cur-line)", { desc = "Add surround current line on new lines" })
		vim.keymap.set("x", "Z", "<Plug>(nvim-surround-visual)", { desc = "Add surround to selection" })
		vim.keymap.set("x", "gZ", "<Plug>(nvim-surround-visual-line)", { desc = "Add surround to selection on new lines" })
		vim.keymap.set("n", "dz", "<Plug>(nvim-surround-delete)", { desc = "Delete surround" })
		vim.keymap.set("n", "cz", "<Plug>(nvim-surround-change)", { desc = "Change surround" })
		vim.keymap.set("n", "cZ", "<Plug>(nvim-surround-change-line)", { desc = "Change surround on new lines" })
	end,
}
