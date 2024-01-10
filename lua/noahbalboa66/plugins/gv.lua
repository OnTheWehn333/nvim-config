return {
    'junegunn/gv.vim',
    dependencies = {
        'tpope/vim-fugitive'
    },
    config = function()
        vim.keymap.set("n", "<leader>gl", ":GV<cr>", { desc = "Look at Git Commit Histor" })
    end

}
