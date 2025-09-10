return {
	{
		"saghen/blink.cmp",
		lazy = false,
		dependencies = {
			"rafamadriz/friendly-snippets",
			"Kaiser-Yang/blink-cmp-avante",
		},
		version = "v0.*",
		opts = {
			keymap = {
				preset = "default",
				["<C-h>"] = { "accept", "fallback" },
				["<C-t>"] = { "select_prev", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-l>"] = { "show", "show_documentation", "hide_documentation" },
			},
			appearance = {
				use_nvim_cmp_as_default = true,

				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				providers = {
					dadbod = {
						name = "Dadbod",
						module = "vim_dadbod_completion.blink",
					},
					snippets = {
						opts = {
							search_paths = { vim.fn.stdpath("config") .. "/snippets" },
						},
					},
					avante = {
						name = "Avante",
						module = "blink-cmp-avante",
						opts = {},
					},
					-- avante_commands = {
					-- 	name = "AvanteCmd",
					-- 	module = "blink-cmp-avante",
					-- 	score_offset = 90, -- show at a higher priority than lsp
					-- 	opts = {},
					-- },
					-- avante_files = {
					-- 	name = "AvanteFile",
					-- 	module = "blink-cmp-avante",
					-- 	score_offset = 100, -- show at a higher priority than lsp
					-- 	opts = {},
					-- },
					-- avante_mentions = {
					-- 	name = "AvanteMention",
					-- 	module = "blink-cmp-avante",
					-- 	score_offset = 1000, -- show at a higher priority than lsp
					-- 	opts = {},
					-- },
				},
				per_filetype = {
					sql = { "dadbod", "buffer", "snippets" },
				},
			},
			cmdline = {
				keymap = { preset = "inherit" },
				completion = { menu = { auto_show = true } },
			},
			completion = {
				accept = {
					auto_brackets = {
						enabled = true,
					},
				},
				menu = {
					draw = {
						treesitter = { "lsp" },
					},
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
				},
			},
			signature = {
				enabled = true,
			},
		},
		opts_extend = { "sources.default" },
	},
}
