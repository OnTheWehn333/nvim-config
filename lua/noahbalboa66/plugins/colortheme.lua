return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		vim.cmd.colorscheme 'tokyonight-moon'
		vim.api.nvim_set_hl(0, "Normal", { bg = "None" })
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = "None" })
	end
}

