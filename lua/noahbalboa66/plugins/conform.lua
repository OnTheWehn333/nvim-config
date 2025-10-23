return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			-- Customize or remove this keymap to your liking
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	-- This will provide type hinting with LuaLS
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			cs = { "csharpier" },
			nix = { "alejandra" },
			javascript = {},
			typescript = {},
			yaml = { "yamlfmt" },
			xml = { "xmlformatter" },
			-- http = { "kulala-fmt" },
		},
		-- Set default options
		default_format_opts = {
			lsp_format = "fallback",
		},
		-- Set up format-on-save
		format_on_save = { timeout_ms = 500 },
		-- Customize formatters
		formatters = {
			shfmt = {
				prepend_args = { "-i", "2" },
			},
			alejandra = {},
			-- kulala = {
			-- 	command = "kulala-fmt",
			-- 	args = { "format", "$FILENAME" },
			-- 	stdin = false,
			-- },
			log_level = vim.log.levels.DEBUG,
			csharpier = {
				command = "csharpier",
				args = {
					"format", -- the sub-command
					"--stdin-path",
					"$FILENAME", -- give it the file name (for config/ignore)
					"--write-stdout", -- don’t overwrite on disk, pipe formatted code back
				},
			},
		},
	},
	init = function()
		-- If you want the formatexpr, here is the place to set it
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
