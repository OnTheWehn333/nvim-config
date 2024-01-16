return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    opts = {
        vim.keymap.set("n", "<leader>st", "<cmd>:TodoTelescope<CR>", { desc = 'Open Todo Telescope' })
    }
}
