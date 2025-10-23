return {
	"Wansmer/treesj",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = "VeryLazy",
	config = function()
		require("treesj").setup({
			use_default_keymaps = false,
			langs = {
				c_sharp = require("treesj.langs.utils").merge_preset(require("treesj.langs.java"), {}),
			},
		})
	end,
	keys = {
		{
			"<leader>ct",
			function()
				require("treesj").toggle()
			end,
			desc = "Toggle Split/Join",
		},
	},
}
