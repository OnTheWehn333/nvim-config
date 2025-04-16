return {
    --     "ggandor/leap.nvim",
    --     config = function()
    --         require('leap').create_default_mappings()
    --         vim.keymap.set({ 'n', 'x', 'o' }, 'ga', function()
    --             require('leap.treesitter').select()
    --         end)
    --         vim.keymap.set({ 'n', 'o' }, 'gS', function()
    --             require('leap').remote()
    --         end)
    --     end
}
