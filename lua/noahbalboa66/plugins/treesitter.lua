local treesitter_languages = {
	"nix",
	"c",
	"cpp",
	"c_sharp",
	"go",
	"lua",
	"python",
	"ruby",
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
	"ruby",
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
	"review-comment",
	"pi-chat-history",
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
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")

		ts.setup()
		ts.install(treesitter_languages)

		local treesitter_group = vim.api.nvim_create_augroup("Noahbalboa66Treesitter", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = treesitter_group,
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

		-- Remove previous mappings when this config is reloaded in a running session.
		for _, lhs in ipairs({ "<C-Space>", "]v", "<CR>" }) do
			for _, mode in ipairs({ "n", "x" }) do
				pcall(vim.keymap.del, mode, lhs)
			end
		end

		local function select_parent()
			vim.treesitter.select("parent", vim.v.count1)
		end

		vim.keymap.set("n", "]v", select_parent, { desc = "Start Tree-sitter selection" })
		vim.keymap.set("x", "<CR>", select_parent, { desc = "Expand Tree-sitter selection" })
		vim.keymap.set("x", "<BS>", function()
			vim.treesitter.select("child", vim.v.count1)
		end, { desc = "Shrink Tree-sitter selection" })

		vim.api.nvim_create_user_command("TreesitterReload", function()
			vim.cmd("Lazy reload nvim-treesitter")
		end, { desc = "Reload the Tree-sitter configuration", force = true })

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
