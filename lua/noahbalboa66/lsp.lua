-- LSP base setup

-- Capabilities
local capabilities = require("blink.cmp").get_lsp_capabilities()
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

local function on_attach(client, bufnr)
	local function map(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
	end

	-- Neovim provides the standard K, gr*, gO, [d, ]d, and insert-mode
	-- <C-s> mappings. Keep only additions that are specific to this config.
	map("n", "<leader>vd", vim.diagnostic.open_float, "Diagnostics float")

	if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, bufnr) then
		map("n", "<leader>li", function()
			local filter = { bufnr = bufnr }
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
		end, "Toggle inlay hints")
	end

	if client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, bufnr) then
		vim.lsp.codelens.enable(true, { bufnr = bufnr })
		map("n", "<leader>lL", function()
			local filter = { bufnr = bufnr }
			vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled(filter), filter)
		end, "Toggle code lens")
	end
end

vim.diagnostic.config({
	severity_sort = true,
	update_in_insert = false,
	virtual_text = {
		spacing = 2,
		source = "if_many",
	},
	float = {
		border = "rounded",
		source = "if_many",
	},
})

vim.lsp.config("*", {
	capabilities = capabilities,
	on_attach = on_attach,
})

vim.lsp.config("ruby_lsp", {
	init_options = {
		formatter = "auto",
	},
})

-- Language-server executables are supplied by Nix and discovered through PATH.
-- Roslyn is enabled by roslyn.nvim rather than this list.
vim.lsp.enable({
	"bashls",
	"gopls",
	"jdtls",
	"jsonls",
	"jsonnet_ls",
	"lua_ls",
	"nil_ls",
	"ruby_lsp",
	"vtsls",
})

vim.lsp.config("roslyn", {
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

vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	once = true,
	callback = function()
		local ok, noice_progress = pcall(require, "noice.lsp.progress")
		if not ok or type(noice_progress.progress) ~= "function" or noice_progress._noah_guarded then
			return
		end

		local orig = noice_progress.progress

		noice_progress.progress = function(data)
			local params = data and (data.params or data.result)
			if type(params) ~= "table" then
				return
			end

			local token = params.token
			local value = params.value

			if token == nil or type(value) ~= "table" or type(value.kind) ~= "string" then
				return
			end

			return orig(data)
		end

		noice_progress._noah_guarded = true
	end,
})
