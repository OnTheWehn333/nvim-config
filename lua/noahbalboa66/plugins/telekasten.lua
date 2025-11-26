return {
	"nvim-telekasten/telekasten.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		local tk = require("telekasten")
		local snacks_tk = require("noahbalboa66.telekasten_snacks")

		tk.setup({
			home = vim.fn.expand("~/programming_notes"),
			dailies = "~/programming_notes/daily",
			weeklies = "~/programming_notes/weekly",
			template_new_note = "~/programming_notes/templates/default.md",
		})

		local map = vim.keymap.set

		-- 🧠 Snacks-based pickers
		map("n", "<leader>nn", snacks_tk.pick_note, { desc = "Notes: find note (Snacks)" })
		map("n", "<leader>ns", snacks_tk.grep_notes, { desc = "Notes: search in notes (Snacks)" })

		-- 🗓️ Core Telekasten functions
		map("n", "<leader>nd", function()
			tk.goto_today()
		end, { desc = "Notes: today's note" })
		map("n", "<leader>nw", function()
			tk.goto_thisweek()
		end, { desc = "Notes: weekly note" })
		map("n", "<leader>nnn", function()
			tk.new_note()
		end, { desc = "Notes: new note" })
		map("n", "<leader>nb", function()
			tk.show_backlinks()
		end, { desc = "Notes: show backlinks" })
		map("n", "<leader>nt", function()
			tk.toggle_todo()
		end, { desc = "Notes: toggle todo" })
	end,
}
