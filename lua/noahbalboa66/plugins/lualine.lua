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

		-- Macro recording status function
		local function macro_recording_status()
			local reg = vim.fn.reg_recording()
			if reg == "" then
				return ""
			end
			return "recording @" .. reg
		end

		local lualine_c = { Harpoonline.format, "filename", macro_recording_status }
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
