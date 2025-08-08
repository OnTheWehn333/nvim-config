return {
	"pwntester/octo.nvim",
	requires = {
		"nvim-lua/plenary.nvim",
		-- TODO: switch to snacks for picker
		"nvim-telescope/telescope.nvim",
		-- OR 'ibhagwan/fzf-lua',
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("octo").setup()
	end,
}
