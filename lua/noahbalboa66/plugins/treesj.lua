return {
	"Wansmer/treesj",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = "VeryLazy",
	config = function()
		local lang_utils = require("treesj.langs.utils")

		require("treesj").setup({
			use_default_keymaps = false,
			langs = {
				c_sharp = {
					argument_list = lang_utils.set_preset_for_args(),
					parameter_list = lang_utils.set_preset_for_args(),
					formal_parameters = lang_utils.set_preset_for_args(),
					block = lang_utils.set_preset_for_statement(),
					array_creation_expression = lang_utils.set_preset_for_list(),
					initializer_expression = lang_utils.set_preset_for_list(),
					anonymous_object_creation_expression = lang_utils.set_preset_for_dict(),
					object_creation_expression = {
						target_nodes = { "argument_list", "initializer_expression" },
					},
					if_statement = {
						target_nodes = { "block" },
					},
					method_declaration = {
						target_nodes = { "block", "parameter_list" },
					},
					constructor_declaration = {
						target_nodes = { "block", "parameter_list" },
					},
				},
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
