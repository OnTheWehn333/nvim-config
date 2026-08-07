return {
	"nicholasmata/nvim-dap-cs",
	dependencies = { "mfussenegger/nvim-dap" },
	config = function()
		require("dap-cs").setup()

		-- Also register the netcoredbg adapter for neotest-vstest.
		local netcoredbg = vim.fn.exepath("netcoredbg")
		if netcoredbg == "" then
			vim.notify("netcoredbg was not found in PATH; C# debugging is unavailable", vim.log.levels.WARN)
			return
		end

		local dap = require("dap")
		dap.adapters.netcoredbg = {
			type = "executable",
			command = netcoredbg,
			args = { "--interpreter=vscode" },
		}
	end,
}
