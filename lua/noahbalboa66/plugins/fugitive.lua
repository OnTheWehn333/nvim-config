return {
    'tpope/vim-fugitive',
    config = function()
        vim.keymap.set("n", "<leader>gs", "<cmd>:tab Git<CR>", { desc = 'Git Status' });
        vim.keymap.set("n", "<leader>gF", ":Git fetch", { desc = 'Git Fetch' });
        -- TODO: Try adding -u for setting upstream for the branch
        vim.keymap.set("n", "<leader>gpn", ":Git -c push.default=current push", { desc = 'Git Push New branch' });
    end
}
