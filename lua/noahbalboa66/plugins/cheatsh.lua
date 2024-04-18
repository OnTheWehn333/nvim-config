return {
    'RishabhRD/nvim-cheat.sh',
    dependencies = {
        'RishabhRD/popfix'
    },
    config = function()
        vim.keymap.set('n', '<leader>cs', '<cmd>Cheat<cr>', { desc = "Lookup cheatsheet" })
        vim.keymap.set('n', '<leader>cc', '<cmd>CheatWithoutComments<cr>',
            { desc = "Lookup cheatsheet without comments" })
    end
}
