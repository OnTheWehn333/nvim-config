return {
	"tommcdo/vim-lion",
	config = function()
		vim.keymap.set("n", "gl", "<Plug>LionRight", { desc = "Align right" })
		vim.keymap.set("x", "gl", "<Plug>VLionRight", { desc = "Align selection right" })
		vim.keymap.set("n", "gL", "<Plug>LionLeft", { desc = "Align left" })
		vim.keymap.set("x", "gL", "<Plug>VLionLeft", { desc = "Align selection left" })
	end,
}
