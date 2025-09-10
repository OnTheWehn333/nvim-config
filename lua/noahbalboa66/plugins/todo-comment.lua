return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		vim.keymap.set("n", "<leader>st", function()
			Snacks.picker.todo_comments()
		end, { desc = "Open Todo Snacks" }),
	},
}
