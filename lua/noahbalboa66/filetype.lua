vim.filetype.add({
	extension = {
		fga = "yaml",
		gotmpl = "gotmpl",
		libsonnet = "libsonnet",
	},
})

-- Review notes keep a distinct filetype so plugins can target them while using
-- Markdown syntax and parser behavior.
vim.treesitter.language.register("markdown", "review-comment")

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
	pattern = { "text", "markdown", "review-comment" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.spelllang = { "en_us" }
	end,
})
