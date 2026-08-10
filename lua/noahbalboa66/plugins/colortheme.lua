return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		style = "moon",
		terminal_colors = true,
		styles = {
			comments = { italic = true },
			keywords = { italic = true },
			functions = { bold = true },
			floats = "transparent",
			sidebars = "transparent",
		},
		on_highlights = function(hl, c)
			hl.WinSeparator = { fg = c.blue7 }
			hl.CursorLine = { bg = require("tokyonight.util").blend(c.bg_highlight, 0.5, c.bg) }
			hl.CursorLineNr = { fg = c.orange, bold = true }
			hl.LineNr = { fg = c.dark5 }
			hl.FoldColumn = { fg = c.dark5, bg = c.none }
			hl.Folded = { fg = c.comment, bg = c.none }
			hl.UfoFoldedBg = { fg = c.fg_dark, bg = c.none }
			hl.UfoFoldedFg = { fg = c.fg_dark }
			hl.UfoFoldedEllipsis = { fg = c.comment, italic = true }
			hl.DiagnosticVirtualTextError = { fg = c.error, bg = c.none }
			hl.DiagnosticVirtualTextWarn = { fg = c.warning, bg = c.none }
			hl.DiagnosticVirtualTextInfo = { fg = c.info, bg = c.none }
			hl.DiagnosticVirtualTextHint = { fg = c.hint, bg = c.none }
		end,
	},
	config = function(_, opts)
		require("tokyonight").setup(opts)
		vim.cmd.colorscheme("tokyonight-moon")

		local transparent = true
		local transparent_groups = {
			"Normal",
			"NormalFloat",
			"FloatBorder",
			"SignColumn",
			"StatusLine",
			"StatusLineNC",
			"TabLine",
			"TabLineFill",
			"WinBar",
			"WinBarNC",
		}

		local function apply_transparency()
			for _, group in ipairs(transparent_groups) do
				local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
				highlight.bg = transparent and nil or highlight.bg
				vim.api.nvim_set_hl(0, group, highlight)
			end
		end

		apply_transparency()
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("NoahFancyColors", { clear = true }),
			callback = apply_transparency,
		})

		vim.api.nvim_create_user_command("ToggleTransparency", function()
			transparent = not transparent
			vim.cmd.colorscheme(vim.g.colors_name)
			vim.notify("Transparency " .. (transparent and "enabled" or "disabled"), vim.log.levels.INFO)
		end, { desc = "Toggle transparent background" })
	end,
}
