return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		vim.cmd.colorscheme("tokyonight-moon")

		for _, group in ipairs({ "Normal", "NormalFloat" }) do
			local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
			highlight.bg = nil
			vim.api.nvim_set_hl(0, group, highlight)
		end
	end,
}
