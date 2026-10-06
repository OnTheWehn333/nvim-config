-- Run from the repository root: nvim --headless -u NONE -l scripts/test-pi-review.lua
vim.opt.rtp:prepend(vim.fn.getcwd())

local temp = vim.fn.tempname()
vim.fn.mkdir(temp .. "/agent/reviews", "p")
vim.env.PI_CODING_AGENT_DIR = temp .. "/agent"
vim.t.pi_root = temp

local review = require("noahbalboa66.pi_review")
review.setup()
local ns = vim.api.nvim_create_namespace("pi-review-mentions")
local failures = 0
local cases = {
	{ name = "valid range", start_line = 1, end_line = 2, extmarks = 2, cursor = 1 },
	{ name = "valid last line", start_line = 2, end_line = 2, extmarks = 1, cursor = 2 },
	{ name = "stale start", start_line = 62, end_line = 62, extmarks = 0, cursor = 2 },
	{ name = "stale end", start_line = 1, end_line = 62, extmarks = 0, cursor = 1 },
	{ name = "past last line", start_line = 3, end_line = 3, extmarks = 0, cursor = 2 },
	{ name = "negative line", start_line = -1, end_line = -1, extmarks = 0, cursor = 1 },
	{ name = "reversed range", start_line = 2, end_line = 1, extmarks = 0, cursor = 2 },
	{ name = "empty file", start_line = 62, end_line = 62, extmarks = 0, cursor = 1, empty = true },
	{ name = "short snapshot", start_line = 62, end_line = 62, extmarks = 0, cursor = 2, snapshot = true },
	{ name = "archived stale range", start_line = 62, end_line = 62, extmarks = 0, archived = true },
}

for index, case in ipairs(cases) do
	local ok, err = pcall(function()
		local project = temp .. "/case-" .. index
		vim.fn.mkdir(project, "p")
		vim.t.pi_root = project
		local source = project .. "/source.cs"
		local snapshot = case.snapshot and (project .. "/snapshot.md") or nil
		vim.fn.writefile(case.empty and {} or { "// first line", "// second line" }, snapshot or source)
		local slug = project:gsub("^/", ""):gsub("[^%w%._%-]+", "--")
		local store = temp .. "/agent/reviews/" .. slug .. ".json"
		local issue = {
			id = index,
			path = source,
			snapshot = snapshot,
			start_line = case.start_line,
			end_line = case.end_line,
			note = "Keep this review note",
			archived = case.archived,
		}
		vim.fn.writefile({ vim.json.encode({ issues = { issue } }) }, store)

		-- Check both startup's loader and the root-switch autocmd.
		for pass = 1, 2 do
			if pass == 1 then
				review.load()
			else
				vim.v.errmsg = ""
				vim.api.nvim_exec_autocmds("User", { pattern = "PiRootChanged" })
				assert(vim.v.errmsg == "", vim.v.errmsg)
			end
			local buf = vim.fn.bufnr(snapshot or source)
			local annotations = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
			assert(#annotations == case.extmarks, "unexpected inline annotation count")
			local saved = vim.json.decode(table.concat(vim.fn.readfile(store), "\n")).issues[1]
			for _, key in ipairs({ "path", "snapshot", "start_line", "end_line", "note", "archived" }) do
				assert(saved[key] == issue[key], "changed saved " .. key)
			end
			if not case.archived then
				review.jump(1)
				assert(vim.api.nvim_get_current_buf() == buf, "jump opened the wrong buffer")
				assert(vim.api.nvim_win_get_cursor(0)[1] == case.cursor, "jump used the wrong line")
			end
		end
	end)
	if ok then
		print("PASS: " .. case.name)
	else
		failures = failures + 1
		print("FAIL: " .. case.name .. ": " .. tostring(err))
	end
end

vim.fn.delete(temp, "rf")
vim.cmd(failures == 0 and "qa!" or "cquit 1")
