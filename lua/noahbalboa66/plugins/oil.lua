return {
	"stevearc/oil.nvim",
	-- Optional dependencies
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		vim.keymap.set("n", "<leader>o", ":Oil<cr>", { desc = "Toggle Oil" })

		local function yank_to_clipboard(text, desc)
			vim.fn.setreg("+", text)
			vim.fn.setreg('"', text)
			vim.notify(desc .. ": " .. text)
		end

		require("oil").setup({
			keymaps = {
				["yp"] = {
					callback = function()
						local oil = require("oil")
						local dir = oil.get_current_dir()
						local entry = oil.get_cursor_entry()

						if not dir or not entry then
							vim.notify("No Oil entry under cursor", vim.log.levels.WARN)
							return
						end

						local path = dir .. entry.name
						if dir:sub(-1) ~= "/" then
							path = dir .. "/" .. entry.name
						end

						yank_to_clipboard(path, "Yanked path")
					end,
					desc = "Yank absolute path",
				},
				["yd"] = {
					callback = function()
						local dir = require("oil").get_current_dir()

						if not dir then
							vim.notify("No Oil directory", vim.log.levels.WARN)
							return
						end

						yank_to_clipboard(dir, "Yanked directory")
					end,
					desc = "Yank absolute directory",
				},
			},
		})
	end,
}
