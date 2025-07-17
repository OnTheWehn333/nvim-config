return {
	"rcarriga/nvim-dap-ui",
	dependencies = { "mfussenegger/nvim-dap", "theHamsta/nvim-dap-virtual-text", "nvim-neotest/nvim-nio" },
	config = function()
		require("dapui").setup()
		local dap = require("dap")
		local ui = require("dapui")
		dap.set_log_level("DEBUG")

		vim.keymap.set("n", "<leader>gb", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
		vim.keymap.set("n", "<leader>gc", dap.continue, { desc = "Continue Debugging" })
		vim.keymap.set("n", "<leader>gi", dap.step_into, { desc = "Step Into" })
		vim.keymap.set("n", "<leader>go", dap.step_over, { desc = "Step Over" })
		vim.keymap.set("n", "<leader>gu", dap.step_out, { desc = "Step Out" })

		vim.keymap.set("n", "<leader>g?", function()
			require("dapui").eval(nil, { enter = true })
		end, { desc = "Eval" })

		dap.listeners.before.attach.dapui_config = function()
			ui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			ui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			ui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			ui.close()
		end
	end,
}
