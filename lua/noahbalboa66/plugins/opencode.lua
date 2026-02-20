return {
	"NickvanDyke/opencode.nvim",
	dependencies = {
		-- Recommended for `ask()` and `select()`.
		-- Required for `snacks` provider.
		---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
		{ "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
	},
	config = function()
		---@type opencode.Opts
		vim.g.opencode_opts = {
			-- Your configuration, if any
		}

		-- Required for `opts.events.reload`.
		vim.o.autoread = true
	end,
	-- stylua: ignore
	keys = {
		{ "<leader>at", function() require("opencode").toggle() end, desc = "Toggle embedded opencode" },
		{ "<leader>aa", function() require("opencode").ask() end, desc = "Ask opencode", mode = "n" },
		{ "<leader>aa", function() require("opencode").ask("@selection: ") end, desc = "Ask opencode about selection", mode = "v" },
		{ "<leader>ap", function() require("opencode").select_prompt() end, desc = "Select prompt", mode = { "n", "v" } },
		{ "<leader>an", function() require("opencode").command("session_new") end, desc = "New session" },
		{ "<leader>ay", function() require("opencode").command("messages_copy") end, desc = "Copy last message" },
		{ "<S-C-u>", function() require("opencode").command("messages_half_page_up") end, desc = "Scroll messages up" },
		{ "<S-C-d>", function() require("opencode").command("messages_half_page_down") end, desc = "Scroll messages down" },
	},
}
