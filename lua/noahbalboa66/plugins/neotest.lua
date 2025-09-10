return {
	{
		"Nsidorenco/neotest-vstest",
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			local neotest = require("neotest")
			neotest.setup({
				adapters = {
					require("neotest-vstest"),
				},
			})
			-- Run the test under the cursor
			vim.keymap.set("n", "<leader>tr", function()
				neotest.run.run()
			end, { desc = "Run nearest test" })

			-- Run the file’s tests
			vim.keymap.set("n", "<leader>tf", function()
				neotest.run.run(vim.fn.expand("%"))
			end, { desc = "Run file tests" })

			-- Debug the file’s tests
			vim.keymap.set("n", "<leader>td", function()
				neotest.run.run({ strategy = "dap" })
			end, { desc = "Run file tests" })

			-- Open output
			vim.keymap.set("n", "<leader>to", function()
				neotest.output_panel.toggle()
			end, { desc = "Toggle test output" })

			-- Open output
			vim.keymap.set("n", "<leader>ts", function()
				neotest.summary.toggle()
			end, { desc = "Toggle test summary" })
		end,
	},
}
