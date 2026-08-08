return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	cmd = "Obsidian",
	dependencies = {
		"folke/snacks.nvim",
	},
	keys = {
		{ "<leader>nn", "<cmd>Obsidian quick_switch<cr>", desc = "Notes: find note" },
		{ "<leader>ns", "<cmd>Obsidian search<cr>", desc = "Notes: search" },
		{ "<leader>nd", "<cmd>Obsidian today<cr>", desc = "Notes: today" },
		{ "<leader>nnn", "<cmd>Obsidian new<cr>", desc = "Notes: new note" },
		{ "<leader>nb", "<cmd>Obsidian backlinks<cr>", desc = "Notes: backlinks" },
		{ "<leader>no", "<cmd>Obsidian open<cr>", desc = "Notes: open in Obsidian" },
		{ "<leader>nt", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Notes: toggle checkbox" },
	},
	---@module "obsidian"
	---@type obsidian.config
	opts = {
		legacy_commands = false,
		workspaces = {
			{
				name = "4V2",
				path = "~/ObsidianVaults/4V2",
			},
		},
		picker = {
			name = "snacks.picker",
		},
		frontmatter = {
			enabled = false,
		},
		ui = {
			enable = false,
		},
		statusline = {
			enabled = false,
		},
		footer = {
			enabled = false,
		},
	},
}
