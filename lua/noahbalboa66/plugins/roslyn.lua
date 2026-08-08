return {
	"seblyng/roslyn.nvim",
	---@module 'roslyn.config'
	---@type RoslynNvimConfig
	opts = {
		-- Neovim's watcher can report ENOENT for Roslyn's temporary project files.
		-- Let Roslyn watch the workspace itself instead.
		filewatching = "roslyn",
	},
}
