return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        require("nvim-tree").setup({
            view = {
                width = 30
            }
        })

        vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<cr>", { desc = "Toggle Nvim Tree" });
    end

}
