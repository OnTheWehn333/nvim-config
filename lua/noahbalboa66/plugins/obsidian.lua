return {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    --   "BufReadPre path/to/my-vault/**.md",
    --   "BufNewFile path/to/my-vault/**.md",
    -- },
    dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",

        -- see below for full list of optional dependencies 👇
    },
    config = function()
        require('obsidian').setup(
            {
                workspaces = {
                    {
                        name = "personal",
                        path = "~/4Vault",
                    },
                },
                -- see below for full list of options 👇
                attachments = {
                    img_folder = "attachments"
                }
            }
        )
        vim.keymap.set("n", "<leader>nc", ":ObsidianNew ", { desc = 'Create a new Obsidian Note' })
    end
}
