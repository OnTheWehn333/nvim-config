return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons", "abeldekat/harpoonline", version = "*" },
	config = function()
		local Harpoonline = require("harpoonline")
		Harpoonline.setup({
			on_update = function()
				require("lualine").refresh()
			end,
		})

		local lualine_c = { Harpoonline.format, "filename" }
		local lualine_x = {
			"encoding",
			"fileformat",
			"filetype",
		}
		require("lualine").setup({
			options = { theme = "palenight" },
			sections = { lualine_c = lualine_c, lualine_x = lualine_x },
		})
	end,
}
