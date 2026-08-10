return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	ft = { "markdown", "review-comment", "pi-chat-history" },
	config = function()
		require("render-markdown").setup({
			file_types = { "markdown", "review-comment", "pi-chat-history" },
		})
	end,
}
