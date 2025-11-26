return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	ft = { "markdown", "telekasten" },
	config = function()
		require("render-markdown").setup({
			file_types = { "markdown", "telekasten" },
		})
	end,
}
