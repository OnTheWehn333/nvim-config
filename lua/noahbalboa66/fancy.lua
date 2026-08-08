local M = {}

local function shell_lines(cmd)
	local output = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		return {}
	end
	return output
end

local function git_root()
	local root = shell_lines({ "git", "rev-parse", "--show-toplevel" })[1]
	if root and root ~= "" then
		return root
	end
	return vim.loop.cwd()
end

local function diagnostic_count(severity)
	return #vim.diagnostic.get(0, { severity = severity })
end

local function lsp_summary()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return "none"
	end

	local names = vim.tbl_map(function(client)
		return client.name
	end, clients)
	table.sort(names)
	return table.concat(names, ", ")
end

function M.code_pulse()
	local root = git_root()
	local branch = shell_lines({ "git", "-C", root, "branch", "--show-current" })[1] or "detached"
	local changed = #shell_lines({ "git", "-C", root, "status", "--short" })
	local plugins = 0
	pcall(function()
		plugins = #vim.tbl_keys(require("lazy.core.config").plugins)
	end)

	local lines = {
		"╭────────────────────────────────────────────╮",
		"│              ✦  CODE PULSE  ✦              │",
		"╰────────────────────────────────────────────╯",
		"",
		("  󰊢 branch      %s"):format(branch ~= "" and branch or "detached"),
		("  󰜄 changed     %d file%s"):format(changed, changed == 1 and "" or "s"),
		("  󰒲 plugins     %d loaded"):format(plugins),
		("   lsp         %s"):format(lsp_summary()),
		("   errors      %d"):format(diagnostic_count(vim.diagnostic.severity.ERROR)),
		("   warnings    %d"):format(diagnostic_count(vim.diagnostic.severity.WARN)),
		"",
		"  Press q or <Esc> to close.",
	}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "noah-code-pulse"

	local width = 48
	local height = #lines
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " 󱐋 glow engine ",
		title_pos = "center",
	})

	vim.wo[win].cursorline = true
	vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
end

function M.setup()
	vim.api.nvim_create_user_command("CodePulse", M.code_pulse, { desc = "Show a fancy project/code status popup" })
	vim.keymap.set("n", "<leader>cp", M.code_pulse, { desc = "Code pulse" })
	vim.keymap.set("n", "<leader>uT", "<cmd>ToggleTransparency<CR>", { desc = "Toggle transparency" })
end

return M
