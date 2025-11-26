-- ~/.config/nvim/lua/noahbalboa66/telekasten_snacks.lua
local M = {}
local NOTES_DIR = vim.fn.expand("~/notes")

local function open_file(path)
	vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.pick_note()
	require("snacks.picker").files({
		cwd = NOTES_DIR,
		on_submit = function(item)
			if item and item.filename then
				open_file(item.filename)
			end
		end,
	})
end

function M.grep_notes()
	require("snacks.picker").grep({
		cwd = NOTES_DIR,
		on_submit = function(item)
			if item and item.filename then
				open_file(item.filename)
				if item.lnum then
					vim.api.nvim_win_set_cursor(0, { item.lnum, 0 })
				end
			end
		end,
	})
end

return M
