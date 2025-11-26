return {
	-- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	build = ":TSUpdate",
	config = function()
		vim.defer_fn(function()
			require("nvim-treesitter.configs").setup({
				-- Add languages to be installed here that you want installed for treesitter
				ensure_installed = {
					"nix",
					"c",
					"cpp",
					"c_sharp",
					"go",
					"lua",
					"python",
					"rust",
					"tsx",
					"javascript",
					"typescript",
					"sql",
					"vimdoc",
					"vim",
					"bash",
					"xml",
					"http",
					"json",
					"graphql",
					"kotlin",
					"hcl",
					"terraform",
					"regex",
					"markdown",
					"markdown_inline",
					"diff",
				},

				-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
				auto_install = false,

				highlight = { enable = true },
				indent = { enable = true },
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<C-a>",
						node_incremental = "<C-a>",
						scope_incremental = "<C-b>",
						node_decremental = "<C-l>",
					},
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["aa"] = "@parameter.outer",
							["ia"] = "@parameter.inner",
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
					move = {
						enable = true,
						set_jumps = true, -- whether to set jumps in the jumplist
						goto_next_start = {
							["]m"] = "@function.outer",
							["]]"] = "@class.outer",
						},
						goto_next_end = {
							["]M"] = "@function.outer",
							["]["] = "@class.outer",
						},
						goto_previous_start = {
							["[m"] = "@function.outer",
							["[["] = "@class.outer",
						},
						goto_previous_end = {
							["[M"] = "@function.outer",
							["[]"] = "@class.outer",
						},
					},
					swap = {
						enable = true,
						swap_next = {
							["<leader>a"] = "@parameter.inner",
						},
						swap_previous = {
							["<leader>A"] = "@parameter.inner",
						},
					},
				},
			})
			local parser_configs = require("nvim-treesitter.parsers").get_parser_configs()

			parser_configs.lua_patterns = {
				install_info = {
					url = "https://github.com/OXY2DEV/tree-sitter-lua_patterns",
					files = { "src/parser.c" },
					branch = "main",
				},
			}
		end, 0)
	end,
}
