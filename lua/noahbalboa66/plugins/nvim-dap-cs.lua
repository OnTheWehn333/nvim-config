return {
	"nicholasmata/nvim-dap-cs",
	dependencies = { "mfussenegger/nvim-dap" },
	config = function()
		require("dap-cs").setup()
	end,
}
