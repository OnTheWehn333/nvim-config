return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	config = function()
		local logo = [[

	███╗   ██╗██╗   ██╗██╗███╗   ███╗
	████╗  ██║██║   ██║██║████╗ ████║
	██╔██╗ ██║██║   ██║██║██╔████╔██║
	██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
	██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
	╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝

		      ✦ code fast • break less • ship fancy ✦
		]]

		require("dashboard").setup({
			theme = "doom",
			config = {
				header = vim.split(logo, "\n"),
				center = {
					{ icon = "  ", desc = "Find file", key = "f", action = "lua Snacks.picker.files()" },
					{ icon = "󰱼  ", desc = "Smart picker", key = "space", action = "lua Snacks.picker.smart()" },
					{ icon = "󰈞  ", desc = "Live grep", key = "g", action = "lua Snacks.picker.grep()" },
					{ icon = "  ", desc = "Recent files", key = "r", action = "lua Snacks.picker.recent()" },
					{ icon = "󰊢  ", desc = "Git status", key = "s", action = "lua Snacks.picker.git_status()" },
					{ icon = "󰒲  ", desc = "Lazy plugins", key = "l", action = "Lazy" },
					{ icon = "  ", desc = "Quit", key = "q", action = "qa" },
				},
				footer = function()
					local plugins = #vim.tbl_keys(require("lazy.core.config").plugins)
					return {
						("󱐋 %d plugins loaded into the glow engine"):format(plugins),
						"",
						"╭────────────────────────────────────────────╮",
						"│  status: aesthetically operational         │",
						"╰────────────────────────────────────────────╯",
					}
				end,
			},
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
