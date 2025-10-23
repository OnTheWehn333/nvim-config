return {
	{
		"Zeioth/compiler.nvim",
		cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo", "CompilerStop" },
		dependencies = { "stevearc/overseer.nvim" },
		opts = {},
		keys = {
			{ "<leader>cr", "<cmd>CompilerOpen<cr>", desc = "Compiler run" },
			{ "<leader>cR", "<cmd>CompilerStop<cr><cmd>CompilerRedo<cr>", desc = "Compiler redo" },
			{ "<leader>co", "<cmd>CompilerToggleResults<cr>", desc = "Compiler toggle output" },
		},
	},
	{
		"stevearc/overseer.nvim",
		-- Pinned to the version suggested in compiler.nvim README for stability
		commit = "6271cab7ccc4ca840faa93f54440ffae3a3918bd",
		cmd = {
			"CompilerOpen",
			"CompilerToggleResults",
			"CompilerRedo",
			"OverseerOpen",
			"OverseerToggle",
			"OverseerRun",
		},
		opts = {
			task_list = {
				direction = "bottom",
				min_height = 25,
				max_height = 25,
				default_detail = 1,
			},
		},
	},
}

