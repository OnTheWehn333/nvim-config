return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
    end,
    opts = {
        vim.keymap.set("n", "<leader>w", "<cmd>:WhichKey<CR>", { desc = 'Open Which Key' })
    }
}
