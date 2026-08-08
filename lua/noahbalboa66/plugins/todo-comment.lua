return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {},
	keys = {
		{
			"<leader>st",
			function()
				Snacks.picker.todo_comments()
			end,
			desc = "Open Todo Snacks",
		},
	},
}
