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
	ensure_installed = { "lua_ls", "jsonls", "nil_ls" },
})
local pid = vim.fn.getpid()
--TODO: I think this is broken on mac, don't hardcode and find a better way to get omnisharp bin.
-- local omnisharp_bin = "/home/noahbalboa66/.local/share/nvim/mason/packages/omnisharp/OmniSharp" -- Replace with your actual path

-- vim.lsp.config("omnisharp", {
-- 	cmd = { omnisharp_bin, "--languageserver", "--hostPID", tostring(pid) },
-- })

vim.lsp.config("roslyn", {
	on_attach = function()
		print("This will run when the server attaches!")
	end,
	settings = {
		["csharp|background_analysis"] = {
			dotnet_analyzer_diagnostics_scope = "fullSolution",
			dotnet_compiler_diagnostics_scope = "fullSolution",
		},
		["csharp|inlay_hints"] = {
			csharp_enable_inlay_hints_for_implicit_object_creation = true,
			csharp_enable_inlay_hints_for_implicit_variable_types = true,
			csharp_enable_inlay_hints_for_lambda_parameter_types = true,
			dotnet_enable_inlay_hints_for_indexer_parameters = true,
			dotnet_enable_inlay_hints_for_literal_parameters = true,
			dotnet_enable_inlay_hints_for_object_creation_parameters = true,
			dotnet_enable_inlay_hints_for_other_parameters = true,
			dotnet_enable_inlay_hints_for_parameters = true,
			dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
			dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
			dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
		},
		["csharp|symbol_search"] = {
			dotnet_search_reference_assemblies = true,
		},
		["csharp|completion"] = {
			dotnet_show_name_completion_suggestions = true,
			dotnet_show_completion_items_from_unimported_namespaces = true,
			dotnet_provide_regex_completions = true,
		},
		["csharp|code_lens"] = {
			dotnet_enable_references_code_lens = true,
		},
	},
})

vim.lsp.config("ts_ls", {
	on_attach = function(client, bufnr)
		-- Disable tsserver's formatting capabilities
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
})
