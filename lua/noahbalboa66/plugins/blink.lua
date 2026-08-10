return {
	{
		"saghen/blink.cmp",
		lazy = false,
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		version = "1.*",
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
					pi = {
						name = "Pi",
						module = "pi.completion.blink",
					},
					dadbod = {
						name = "Dadbod",
						module = "vim_dadbod_completion.blink",
					},
					snippets = {
						opts = {
							search_paths = { vim.fn.stdpath("config") .. "/snippets" },
							extended_filetypes = {
								["review-comment"] = { "markdown" },
							},
						},
					},
					cmdline = {
						enabled = function()
							return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
						end,
					},
				},
				per_filetype = {
					sql = { "dadbod", "buffer", "snippets" },
					["pi-chat-prompt"] = { "pi" },
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
