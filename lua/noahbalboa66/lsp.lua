-- LSP base setup

local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")

-- Capabilities
local capabilities = require("blink.cmp").get_lsp_capabilities()

-- Format on save
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local function lsp_format_on_save(bufnr)
	vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		buffer = bufnr,
		callback = function(args)
			require("conform").format({ bufnr = args.buf })
		end,
	})
end

-- on_attach
local function on_attach(client, bufnr)
	local function map(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
	end

	-- map("n", "gd", vim.lsp.buf.definition, "Go to definition")
	map("n", "K", vim.lsp.buf.hover, "Hover")
	-- map("n", "<leader>vws", vim.lsp.buf.declaration, "Go to declaration")
	-- map("n", "<leader>vtd", vim.lsp.buf.type_definition, "Type definition")
	map("n", "<leader>vca", vim.lsp.buf.code_action, "Code action")
	-- map("n", "<leader>vrr", vim.lsp.buf.references, "References")
	map("n", "<leader>vrn", vim.lsp.buf.rename, "Rename")
	map("i", "<C-h>", vim.lsp.buf.signature_help, "Signature help")
	map("n", "[d", vim.diagnostic.goto_next, "Next diagnostic")
	map("n", "]d", vim.diagnostic.goto_prev, "Prev diagnostic")
	map("n", "<leader>vd", vim.diagnostic.open_float, "Diagnostics float")

	lsp_format_on_save(bufnr)
end

vim.lsp.config("*", {
	capabilities = capabilities,
	on_attach = on_attach,
})
-- Mason setup
mason.setup()
mason_lspconfig.setup({
	ensure_installed = { "lua_ls", "jsonls", "omnisharp", "nil_ls" },
})
local pid = vim.fn.getpid()
--TODO: I think this is broken on mac, don't hardcode and find a better way to get omnisharp bin.
local omnisharp_bin = "/home/noahbalboa66/.local/share/nvim/mason/packages/omnisharp/OmniSharp" -- Replace with your actual path

vim.lsp.config("omnisharp", {
	cmd = { omnisharp_bin, "--languageserver", "--hostPID", tostring(pid) },
})

vim.lsp.config("ts_ls", {
	on_attach = function(client, bufnr)
		-- Disable tsserver's formatting capabilities
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
})
