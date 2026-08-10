local review = require("noahbalboa66.pi_review")

return {
	name = "pi-review.nvim",
	dir = vim.fn.stdpath("config"),
	dependencies = { "alex35mil/pi.nvim" },
	event = "VeryLazy",
	opts = {
		-- Categories are persisted as review metadata and included in AI copies.
		categories = {
			{
				id = "question",
				label = "Question",
				icon = "?",
				color = "#60a5fa",
				description = "Needs clarification or a design decision",
			},
			{
				id = "note",
				label = "Note",
				icon = "•",
				color = "#a78bfa",
				description = "Context the implementer should preserve",
			},
			{
				id = "warning",
				label = "Warning",
				icon = "!",
				color = "#fbbf24",
				description = "Risk, edge case, or surprising behavior",
			},
			{
				id = "bug",
				label = "Bug",
				icon = "",
				color = "#f87171",
				description = "Incorrect behavior that should be fixed",
			},
			{
				id = "security",
				label = "Security",
				icon = "󰒃",
				color = "#fb7185",
				description = "Security, privacy, trust, or validation concern",
			},
			{
				id = "performance",
				label = "Performance",
				icon = "󰓅",
				color = "#fb923c",
				description = "Latency, allocation, query, or scaling concern",
			},
			{
				id = "refactor",
				label = "Refactor",
				icon = "󰑓",
				color = "#22d3ee",
				description = "Maintainability or architecture improvement",
			},
			{
				id = "test",
				label = "Test",
				icon = "󰙨",
				color = "#34d399",
				description = "Missing or incorrect test coverage",
			},
			{
				id = "docs",
				label = "Documentation",
				icon = "󰈙",
				color = "#c084fc",
				description = "Missing, stale, or misleading documentation",
			},
			{
				id = "blocker",
				label = "Blocker",
				icon = "󰀦",
				color = "#ef4444",
				description = "Must be addressed before completion or merge",
			},
		},
	},
	keys = {
		{ "<leader>pm", review.mention, mode = { "n", "v" }, desc = "Pi: mention file/selection in prompt" },
		{ "<leader>ra", review.add, mode = { "n", "v" }, desc = "Review: add issue" },
		{
			"]r",
			function()
				review.jump(1)
			end,
			desc = "Review: next issue",
		},
		{
			"[r",
			function()
				review.jump(-1)
			end,
			desc = "Review: previous issue",
		},
		{ "<leader>rl", review.select, desc = "Review: list issues" },
		{ "<leader>rq", review.quickfix, desc = "Review: issues quickfix" },
		{ "<leader>re", review.edit_comment, desc = "Review: edit issue" },
		{ "<leader>rt", review.change_category, desc = "Review: change type" },
		{ "<leader>rx", review.toggle_fixed, desc = "Review: toggle issue fixed" },
		{ "<leader>ry", review.copy_open_for_ai, desc = "Review: copy open issues for AI" },
		{
			"<leader>rv",
			function()
				review.open_store("markdown")
			end,
			desc = "Review: open portable review",
		},
	},
	config = function(_, opts)
		review.setup(opts)
	end,
}
