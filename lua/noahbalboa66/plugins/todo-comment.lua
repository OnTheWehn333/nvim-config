return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
	-- TODO: Replace the todo telescope with a snacks. https://github.com/folke/todo-comments.nvim/pull/345
	opts = {
		vim.keymap.set("n", "<leader>st", "<cmd>:TodoTelescope<CR>", { desc = "Open Todo Telescope" }),
	},
}
