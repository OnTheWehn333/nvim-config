local set = vim.keymap.set

--From the GOAT Prime
set("n", "<leader>ex", vim.cmd.Ex, { desc = 'Go into Ex'})

set("v", "J", ":m '>+1<CR>gv=gv", { desc = 'Move Selected Down' })
set("v", "K", ":m '<-2<CR>gv=gv", { desc = 'Move Selected Up' })

set("n", "Y", "yg$", { desc = 'Select to the end of the line' })
set("n", "J", "mzJ`z", { desc = 'Join the line below but keep the cursor in place'})
set("n", "<C-u>", "<C-u>zz", { desc = 'Jump up the page and keep cursor centered'})
set("n", "<C-d>", "<C-d>zz", { desc = 'Jump down the page and keep cursor centered'})
set("n", "G", "Gzz", { desc = 'Jump to end of page and keep cursor centered'})
set("n", "n", "nzzzv", { desc = 'Navigate find forward and keep cursor centered'})
set("n", "N", "Nzzzv", { desc = 'Navigate find backward and keep cursor centered'})

set("x", "<leader>p", "\"_dP", { desc = 'Delete into void, so buffer is preserved'})


set("n", "<leader>y", "\"+y", { desc = 'Copy into system clipboard'})
set("v", "<leader>y", "\"+y", { desc = 'Copy into system clipboard'})
set("n", "<leader>Y", "\"+Y", { desc = 'Copy into system clipboard'})

set("n", "<leader>d", "\"_d", { desc = 'Delete into void buffer'})
set("v", "<leader>d", "\"_d", { desc = 'Delete into void buffer'})

set("i", "<C-c>", "<Esc>", { desc = 'Some bullshit for Making <C-c> work exacly like <Esc>'})

set("n", "Q", "<nop>")
set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = 'Quick List \'c\' Next'})
set("n", "<C-k>", "<cmd>cprev<CR>zz", { desc = 'Quick List \'c\' Prev'})
set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = 'Quick List \'l\' Next'})
set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = 'Quick List \'l\' Prev'})

set("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace all words under the current one'})
set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = 'Make file executable' })

