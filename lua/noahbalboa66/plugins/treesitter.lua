local treesitter_languages = {
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
	"jsonnet",
	"graphql",
	"kotlin",
	"hcl",
	"terraform",
	"regex",
	"markdown",
	"markdown_inline",
	"diff",
}

local treesitter_filetypes = {
	"nix",
	"c",
	"cpp",
	"cs",
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
	"sh",
	"bash",
	"xml",
	"http",
	"json",
	"graphql",
	"kotlin",
	"hcl",
	"terraform",
	"markdown",
	"diff",
	"jsonnet",
	"libsonnet",
}

return {
	-- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	dependencies = {
		{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
	},
	build = function()
		if vim.fn.executable("tree-sitter") == 1 then
			require("nvim-treesitter").install(treesitter_languages):wait(300000)
		else
			vim.notify("tree-sitter CLI is required to install nvim-treesitter parsers", vim.log.levels.WARN)
		end
	end,
	config = function()
		local ts = require("nvim-treesitter")

		ts.setup()

		vim.api.nvim_create_autocmd("FileType", {
			pattern = treesitter_filetypes,
			callback = function()
				-- Highlighting is provided by Neovim on 0.12+.
				pcall(vim.treesitter.start)

				-- Indentation is provided by nvim-treesitter's 0.12+ API.
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})

		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
			},
			move = {
				set_jumps = true,
			},
		})

		local select = require("nvim-treesitter-textobjects.select")
		vim.keymap.set({ "x", "o" }, "aa", function()
			select.select_textobject("@parameter.outer", "textobjects")
		end, { desc = "Select outer parameter" })
		vim.keymap.set({ "x", "o" }, "ia", function()
			select.select_textobject("@parameter.inner", "textobjects")
		end, { desc = "Select inner parameter" })
		vim.keymap.set({ "x", "o" }, "af", function()
			select.select_textobject("@function.outer", "textobjects")
		end, { desc = "Select outer function" })
		vim.keymap.set({ "x", "o" }, "if", function()
			select.select_textobject("@function.inner", "textobjects")
		end, { desc = "Select inner function" })
		vim.keymap.set({ "x", "o" }, "ac", function()
			select.select_textobject("@class.outer", "textobjects")
		end, { desc = "Select outer class" })
		vim.keymap.set({ "x", "o" }, "ic", function()
			select.select_textobject("@class.inner", "textobjects")
		end, { desc = "Select inner class" })

		local move = require("nvim-treesitter-textobjects.move")
		vim.keymap.set({ "n", "x", "o" }, "]]", function()
			move.goto_next_start("@function.outer", "textobjects")
		end, { desc = "Next function start" })
		vim.keymap.set({ "n", "x", "o" }, "]m", function()
			move.goto_next_start("@class.outer", "textobjects")
		end, { desc = "Next class start" })
		vim.keymap.set({ "n", "x", "o" }, "][", function()
			move.goto_next_end("@function.outer", "textobjects")
		end, { desc = "Next function end" })
		vim.keymap.set({ "n", "x", "o" }, "]M", function()
			move.goto_next_end("@class.outer", "textobjects")
		end, { desc = "Next class end" })
		vim.keymap.set({ "n", "x", "o" }, "[[", function()
			move.goto_previous_start("@function.outer", "textobjects")
		end, { desc = "Previous function start" })
		vim.keymap.set({ "n", "x", "o" }, "[m", function()
			move.goto_previous_start("@class.outer", "textobjects")
		end, { desc = "Previous class start" })
		vim.keymap.set({ "n", "x", "o" }, "[]", function()
			move.goto_previous_end("@function.outer", "textobjects")
		end, { desc = "Previous function end" })
		vim.keymap.set({ "n", "x", "o" }, "[M", function()
			move.goto_previous_end("@class.outer", "textobjects")
		end, { desc = "Previous class end" })

		local swap = require("nvim-treesitter-textobjects.swap")
		vim.keymap.set("n", "<leader>a", function()
			swap.swap_next("@parameter.inner")
		end, { desc = "Swap next parameter" })
		vim.keymap.set("n", "<leader>A", function()
			swap.swap_previous("@parameter.inner")
		end, { desc = "Swap previous parameter" })
	end,
}
