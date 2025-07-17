return {
	"RishabhRD/nvim-cheat.sh",
	dependencies = {
		"RishabhRD/popfix",
	},
	config = function()
		vim.keymap.set("n", "<leader>cc", "<cmd>Cheat<cr>", { desc = "Lookup cheatsheet" })
	end,
}
