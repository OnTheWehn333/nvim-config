local lsp_zero = require('lsp-zero')
local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
local lsp_format_on_save = function(bufnr)
    vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = augroup,
        buffer = bufnr,
        callback = function()
            vim.lsp.buf.format()
        end,
    })
end

lsp_zero.on_attach(function(client, bufnr)
    local function set(mode, keys, action, description)
        local opts = { buffer = bufnr, remap = false, desc = description }
        vim.keymap.set(mode, keys, action, opts)
    end

    set("n", "gd", function() vim.lsp.buf.definition() end, 'Go To Definition')
    set("n", "K", function() vim.lsp.buf.hover() end, 'Hover')
    set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, 'Workspace Symbol')
    set("n", "<leader>vtd", function() vim.lsp.buf.type_definition() end, 'Type Definition')
    set("n", "<leader>vd", function() vim.diagnostic.open_float() end, 'Open Float')
    set("n", "[d", function() vim.diagnostic.goto_next() end, 'Go To Next')
    set("n", "]d", function() vim.diagnostic.goto_prev() end, 'Go To Prev')
    set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, 'Code Action')
    set("n", "<leader>vrr", function() vim.lsp.buf.references() end, 'References')
    set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, 'Rename')
    set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, 'Signature Help')

    lsp_format_on_save(bufnr)
end)

require('mason').setup({})
require('mason-lspconfig').setup({
    ensure_installed = { 'rust_analyzer' },
    handlers = {
        lsp_zero.default_setup,
        lua_ls = function()
            local lua_opts = lsp_zero.nvim_lua_ls()
            require('lspconfig').lua_ls.setup(lua_opts)
        end,
    }
})

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup.filetype({ "sql" }, {
    sources = {
        { name = "vim-dadbod-completion" },
        { name = "buffer" }
    }
})

cmp.setup({
    sources = {
        { name = 'path' },
        { name = 'nvim_lsp' },
        { name = 'nvim_lua' },
        -- { name = 'copilot' },
        { name = 'luasnip', keyword_length = 2 },
        { name = 'buffer',  keyword_length = 3 },
    },
    formatting = lsp_zero.cmp_format(),
    mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
    }),
})
