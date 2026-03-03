vim.g.mapleader = " "
vim.g.terminal_emulator = "zsh"

-- OSC 52 clipboard: "+y yanks to host clipboard via terminal escape sequences
-- Paste from host clipboard with Ctrl+Shift+V / Cmd+V (terminal handles it)
vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = require("vim.ui.clipboard.osc52").copy("+"),
		["*"] = require("vim.ui.clipboard.osc52").copy("*"),
	},
	paste = {
		["+"] = function()
			return vim.fn.getreg("+", true, true)
		end,
		["*"] = function()
			return vim.fn.getreg("*", true, true)
		end,
	},
}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- lazyvim stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("noahbalboa66.plugins")
require("noahbalboa66")
