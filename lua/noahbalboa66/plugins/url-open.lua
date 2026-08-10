return {
	"sontungexpt/url-open",
	event = "VeryLazy",
	cmd = "URLOpenUnderCursor",
	opts = {
		deep_pattern = true,
	},
	config = function(_, opts)
		local status_ok, url_open = pcall(require, "url-open")
		if not status_ok then
			return
		end
		url_open.setup(opts)
		vim.keymap.set("n", "gx", "<esc>:URLOpenUnderCursor<cr>", { desc = "Open URL under cursor" })
	end,
}
