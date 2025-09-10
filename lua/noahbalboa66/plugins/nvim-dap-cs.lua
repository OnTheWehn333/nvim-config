return {
	"nicholasmata/nvim-dap-cs",
	dependencies = { "mfussenegger/nvim-dap" },
	config = function()
		require("dap-cs").setup()
		
		-- Also register netcoredbg adapter for neotest-vstest
		local dap = require("dap")
		dap.adapters.netcoredbg = {
			type = "executable",
			command = "/home/noahbalboa66/.local/share/nvim/mason/bin/netcoredbg",
			args = { "--interpreter=vscode" }
		}
	end,
}
