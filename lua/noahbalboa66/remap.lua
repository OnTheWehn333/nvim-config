local set = vim.keymap.set

--From the GOAT Primeagen
set("n", "<leader>ex", vim.cmd.Ex, { desc = "Go into Ex" })

set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move Selected Down" })
set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move Selected Up" })

set("n", "Y", "yg$", { desc = "Select to the end of the line" })
set("n", "J", "mzJ`z", { desc = "Join the line below but keep the cursor in place" })
set("n", "<C-u>", "<C-u>", { desc = "Jump up the page and keep cursor centered" })
set("n", "<C-d>", "<C-d>", { desc = "Jump down the page and keep cursor centered" })
set("n", "G", "Gzz", { desc = "Jump to end of page and keep cursor centered" })
set("n", "n", "nzzzv", { desc = "Navigate find forward and keep cursor centered" })
set("n", "N", "Nzzzv", { desc = "Navigate find backward and keep cursor centered" })

set("x", "<leader>p", '"_dP', { desc = "Delete into void, so buffer is preserved" })

set("n", "<leader>y", '"+y', { desc = "Copy into system clipboard" })
set("v", "<leader>y", '"+y', { desc = "Copy into system clipboard" })
set("n", "<leader>Y", '"+Y', { desc = "Copy into system clipboard" })

set("n", "<leader>d", '"_d', { desc = "Delete into void buffer" })
set("v", "<leader>d", '"_d', { desc = "Delete into void buffer" })

set("i", "<C-c>", vim.cmd.stopinsert, { desc = "Exit insert mode without closing UI" })

set("n", "Q", "<nop>", { desc = "Disable Ex mode" })
set("n", "<leader>Q", "<cmd>qa<CR>", { desc = "Quit all windows" })
set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Open tmux sessionizer" })

set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Quick List 'c' Next" })
set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Quick List 'c' Prev" })
set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Quick List 'l' Next" })
set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Quick List 'l' Prev" })

set(
	"n",
	"<leader>rw",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Replace all words under the current one" }
)
set("n", "<leader>xf", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" })

set("n", "<leader>wh", function()
	local total_height = vim.o.lines
	local current_height = vim.api.nvim_win_get_height(0)
	local isSmall = (current_height <= math.floor(total_height * 0.5))
	if isSmall then
		vim.cmd("resize " .. math.floor(total_height * 0.75))
	else
		vim.cmd("resize " .. math.floor(total_height * 0.25))
	end
end, { desc = "toggle resize to 1/4:3/4 vertically" })

set("n", "<leader>h=", function()
	local total_height = vim.o.lines
	vim.cmd("resize " .. math.floor(total_height * 0.5))
end, { desc = "resize to 1/2 vertically" })

set("n", "<leader>wv", function()
	local total_width = vim.o.columns
	local current_width = vim.api.nvim_win_get_width(0)
	local isSmall = (current_width <= math.floor(total_width * 0.5))
	if isSmall then
		vim.cmd("vertical resize " .. math.floor(total_width * 0.75))
	else
		vim.cmd("vertical resize " .. math.floor(total_width * 0.25))
	end
end, { desc = "toggle resize to 1/4:3/4 horizontally" })

set("n", "<leader>w=", function()
	local total_width = vim.o.columns
	vim.cmd("vertical resize " .. math.floor(total_width * 0.5))
end, { desc = "resize to 1/2 horizontally" })
-- /^([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6})*$/
