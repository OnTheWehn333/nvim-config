vim.filetype.add({
	extension = {
		fga = "yaml",
	},
})

-- Register markdown parser for telekasten filetype
vim.treesitter.language.register("markdown", "telekasten")

-- Filetype-specific settings
vim.api.nvim_create_autocmd("FileType", {
	pattern = "nix",
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "text", "markdown", "telekasten" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.spelllang = { "en_us" }
	end,
})
