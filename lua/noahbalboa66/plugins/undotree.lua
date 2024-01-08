return {
    'mbbill/undotree',
    config = function() 
        vim.keymap.set("n", "<leader>u", ':UndotreeToggle<cr> <C-w>h', { desc = 'Undotree'})
    end
}
