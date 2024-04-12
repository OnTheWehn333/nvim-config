return {
    'stevearc/oil.nvim',
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        vim.keymap.set("n", "<leader>o", ":Oil<cr>", { desc = "Toggle Oil" });
        require("oil").setup();
    end
}
