return {
	"chrisgrieser/nvim-scissors",
	dependencies = "folke/snacks.nvim",
	config = function()
		require("scissors").setup({
			snippetDir = vim.fn.stdpath("config") .. "/snippets",
			snippetSelection = {
				picker = "snacks",
			},
		})

		vim.keymap.set({ "n", "x" }, "<leader>sna", function()
			require("scissors").addNewSnippet()
		end, { desc = "Add new snippet" })
		vim.keymap.set("n", "<leader>sne", function()
			require("scissors").editSnippet()
		end, { desc = "Edit snippet" })
	end,
}
