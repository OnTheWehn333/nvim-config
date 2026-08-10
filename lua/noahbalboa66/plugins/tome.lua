return {
	"laktak/tome",
	init = function()
		-- Tome's default <leader>p mapping conflicts with the Pi <leader>p...
		-- prefix group, causing a bare Space-p pause to send the current line to
		-- a tmux/zsh pane. Disable defaults and bind Tome under <leader>T instead.
		vim.g.tome_no_mappings = 1
	end,
	cmd = { "TomePlayBook", "TomeScratchPad", "TomeScratchPadOnly" },
	keys = {
		{ "<leader>Tp", "<Plug>(TomePlayLine)", desc = "Tome: play line" },
		{ "<leader>TP", "<Plug>(TomePlayParagraph)", desc = "Tome: play paragraph" },
		{ "<leader>Tp", "<Plug>(TomePlaySelection)", mode = "x", desc = "Tome: play selection" },
	},
}
