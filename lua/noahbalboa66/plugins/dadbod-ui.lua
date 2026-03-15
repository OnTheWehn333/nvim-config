return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		-- Bridge DBUI saved connections into vim.g.dbs so dadbod-grip can read them
		local dbui_conn_file = vim.fn.expand(vim.g.db_ui_save_location or "~/.local/share/db_ui")
			.. "/connections.json"
		if vim.fn.filereadable(dbui_conn_file) == 1 then
			local raw = table.concat(vim.fn.readfile(dbui_conn_file), "\n")
			local ok, data = pcall(vim.fn.json_decode, raw)
			if ok and type(data) == "table" then
				vim.g.dbs = data
			end
		end

		-- Your DBUI configuration
		vim.g.db_ui_use_nerd_fonts = 1
		vim.g.db_ui_table_helpers = {
			postgresql = {
				Count = 'select count(*) from "{table}"',
				Delete = '--drop table "{table}"',
				Truncate = '--truncate table "{table}"',
			},
		}
		vim.g.db_ui_execute_on_save = 0
	end,
}
