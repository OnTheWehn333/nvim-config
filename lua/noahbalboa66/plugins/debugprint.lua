return {
    "andrewferrier/debugprint.nvim",
    dependencies = {
        "echasnovski/mini.nvim",          -- Needed to enable :ToggleCommentDebugPrints for NeoVim <= 0.9
        "nvim-treesitter/nvim-treesitter" -- Needed to enable treesitter for NeoVim 0.8
    },
    opts = {
        keymaps = {
            normal = {
                toggle_comment_debug_prints = "g?a",
                delete_debug_prints = "g?d",
            },
        },
    },
    -- Remove the following line to use development versions,
    -- not just the formal releases
}
