return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	ft = { "markdown", "pi-chat-history" },
	config = function()
		require("render-markdown").setup({
			file_types = { "markdown", "pi-chat-history" },
		})
	end,
}
