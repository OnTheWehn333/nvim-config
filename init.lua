vim.g.mapleader = " "
vim.g.terminal_emulator = "zsh"

vim.g.clipboard = "osc52"

local function osc52_copy(reg)
	return function(lines)
		local s = table.concat(lines, "\n")
		local b64 = vim.base64.encode(s)
		local osc = string.format("\x1b]52;%s;%s\x07", reg == "*" and "p" or "c", b64)
		if vim.env.TMUX then
			io.stdout:write("\x1bPtmux;\x1b" .. osc .. "\x1b\\")
		else
			io.stdout:write(osc)
		end
	end
end
vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = osc52_copy("+"),
		["*"] = osc52_copy("*"),
	},
	paste = {
		["+"] = function()
			return { vim.fn.getreg("+", true, true), vim.fn.getregtype("+") }
		end,
		["*"] = function()
			return { vim.fn.getreg("*", true, true), vim.fn.getregtype("*") }
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
