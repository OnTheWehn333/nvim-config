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

		local function macro_recording_status()
			local reg = vim.fn.reg_recording()
			if reg == "" then
				return ""
			end
			return "󰑋 REC @" .. reg
		end

		local function lsp_clients()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				return "󰒲 no lsp"
			end

			local names = vim.tbl_map(function(client)
				return client.name
			end, clients)
			table.sort(names)
			return " " .. table.concat(names, ",")
		end

		local function glow_clock()
			return "󰥔 " .. os.date("%H:%M")
		end

		local function pi_attention_count()
			local attention = package.loaded["pi.attention"]
			return attention and attention.count(0) or 0
		end

		local function pi_attention_status()
			return "󰵚 ASK " .. pi_attention_count()
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = { "PiAttentionRequested", "PiQuestionChanged" },
			callback = function()
				require("lualine").refresh()
			end,
			desc = "Refresh lualine for Pi attention",
		})

		require("lualine").setup({
			options = {
				theme = "tokyonight",
				globalstatus = true,
				component_separators = { left = "│", right = "│" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { { "mode", icon = "" } },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { Harpoonline.format, { "filename", path = 1 }, macro_recording_status },
				lualine_x = {
					{
						pi_attention_status,
						cond = function()
							return pi_attention_count() > 0
						end,
						color = { fg = "#1a1b26", bg = "#ff9e64", gui = "bold" },
					},
					lsp_clients,
					"encoding",
					"fileformat",
					"filetype",
					glow_clock,
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
		})
	end,
}
