return {
    'junegunn/gv.vim',
    dependencies = {
        'tpope/vim-fugitive'
    },
    config = function()
        vim.keymap.set("n", "<leader>gh", ":GV<cr>", { desc = "[G]it Commit [H]istory" })
    end

}
