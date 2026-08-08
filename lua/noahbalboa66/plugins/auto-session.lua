return {
	"rmagatti/auto-session",
	lazy = false,
	init = function()
		vim.opt.sessionoptions:append("localoptions")
	end,

	---enables autocomplete for opts
	---@module "auto-session"
	---@type AutoSession.Config
	opts = {
		suppressed_dirs = { "~/", "~/projects", "~/downloads", "/" },
		-- log_level = 'debug',
	},
}
