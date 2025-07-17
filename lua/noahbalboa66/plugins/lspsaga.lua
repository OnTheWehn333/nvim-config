return {
	"nvimdev/lspsaga.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- optional
		"nvim-tree/nvim-web-devicons", -- optional
	},
	config = function()
		require("lspsaga").setup({ lightbulb = {} })

		vim.keymap.set("n", "<leader>lc", "<cmd>Lspsaga code_action<cr>", { desc = "Code Action" })
		vim.keymap.set("n", "<leader>lo", "<cmd>Lspsaga outline<cr>", { desc = "Outline" })
		vim.keymap.set("n", "<leader>lr", "<cmd>Lspsaga rename<cr>", { desc = "Rename" })
		vim.keymap.set("n", "<leader>ld", "<cmd>Lspsaga goto_definition<cr>", { desc = "GoTo Definition" })
		vim.keymap.set("n", "<leader>lg", "<cmd>Lspsaga goto_type_definition<cr>", { desc = "GoTo Type Definition" })
		vim.keymap.set("n", "<leader>lf", "<cmd>Lspsaga finder<cr>", { desc = "Lsp Finder" })
		vim.keymap.set("n", "<leader>lp", "<cmd>Lspsaga peek_definition<cr>", { desc = "Peek Definition" })
		vim.keymap.set("n", "<leader>lk", "<cmd>Lspsaga peek_type_definition<cr>", { desc = "Peek Type Definition" })
		vim.keymap.set("n", "<leader>ls", "<cmd>Lspsaga signature_help<cr>", { desc = "Signature Help" })
		vim.keymap.set(
			"n",
			"<leader>lw",
			"<cmd>Lspsaga show_workspace_diagnostics<cr>",
			{ desc = "Show Workspace Diagnostics" }
		)
		vim.keymap.set("n", "<leader>lb", "<cmd>Lspsaga show_buf_diagnostics<cr>", { desc = "Show Buffer Diagnostics" })
		vim.keymap.set("n", "<leader>ll", "<cmd>Lspsaga show_line_diagnostics<cr>", { desc = "Show Line Diagnostics" })
		vim.keymap.set(
			"n",
			"<leader>lu",
			"<cmd>Lspsaga show_cursor_diagnostics<cr>",
			{ desc = "Show Cursor Diagnostics" }
		)
		vim.keymap.set("n", "<leader>l[", "<cmd>Lspsaga diagnostic_jump_prev<cr>", { desc = "Previous Diagnostic" })
		vim.keymap.set("n", "<leader>l]", "<cmd>Lspsaga diagnostic_jump_next<cr>", { desc = "Next Diagnostic" })
		vim.keymap.set("n", "<leader>lh", "<cmd>Lspsaga hover_doc<cr>", { desc = "Hover Documentation" })
		vim.keymap.set("n", "<leader>lI", "<cmd>Lspsaga incoming_calls<cr>", { desc = "Incoming Calls" })
		vim.keymap.set("n", "<leader>lO", "<cmd>Lspsaga outgoing_calls<cr>", { desc = "Outgoing Calls" })
		vim.keymap.set("n", "<leader>lt", "<cmd>Lspsaga term_toggle<cr>", { desc = "Toggle Terminal" })
	end,
}
