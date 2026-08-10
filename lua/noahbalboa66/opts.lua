vim.opt.guicursor = ""

vim.opt.mouse = "a"

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "140"

local window_focus_group = vim.api.nvim_create_augroup("WindowFocus", { clear = true })

local function is_source_window(win)
	if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_config(win).relative ~= "" then
		return false
	end
	local buf = vim.api.nvim_win_get_buf(win)
	return vim.bo[buf].buftype == "" and not vim.bo[buf].filetype:match("^pi%-")
end

local function restore_source_gutter(win)
	if not is_source_window(win) then
		return
	end
	-- Pi windows intentionally hide their gutter. Splits created from Pi can
	-- inherit those local options, and auto-session can then persist them.
	vim.wo[win].number = true
	vim.wo[win].relativenumber = true
	vim.wo[win].signcolumn = "yes"
end

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	group = window_focus_group,
	callback = function()
		local win = vim.api.nvim_get_current_win()
		restore_source_gutter(win)
		if is_source_window(win) then
			vim.wo[win].cursorline = true
		end
	end,
})

vim.api.nvim_create_autocmd("SessionLoadPost", {
	group = window_focus_group,
	callback = function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			restore_source_gutter(win)
		end
	end,
})

vim.api.nvim_create_autocmd("WinLeave", {
	group = window_focus_group,
	callback = function()
		local win = vim.api.nvim_get_current_win()
		if is_source_window(win) then
			vim.wo[win].cursorline = false
		end
	end,
})

restore_source_gutter(vim.api.nvim_get_current_win())
vim.wo.cursorline = true

vim.cmd(":command! -nargs=* W w")
