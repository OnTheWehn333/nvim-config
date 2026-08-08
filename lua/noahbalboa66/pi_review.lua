local M = {}

local ns = vim.api.nvim_create_namespace("pi-review-mentions")
local list_ns = vim.api.nvim_create_namespace("code-review-list")
local marks = {}
local sequence = 0
local config = {
	categories = {
		{ id = "note", label = "Note", icon = "•", color = "#a78bfa", description = "Review note" },
	},
}
local categories_by_id = {}
local list = {
	buf = nil,
	source_win = nil,
	row_marks = {},
	selected = {},
	show_archived = false,
}

local function default_root()
	local bufname = vim.api.nvim_buf_get_name(0)
	local start = bufname ~= "" and vim.fs.dirname(bufname) or vim.fn.getcwd()
	return vim.fs.root(start, { ".git", "flake.nix", "package.json", "pyproject.toml", "Cargo.toml", "go.mod" })
		or vim.fn.getcwd()
end

local function root()
	return vim.fs.normalize(vim.t.pi_root or default_root())
end

local function store_paths()
	local slug = root():gsub("^/", ""):gsub("[^%w%._%-]+", "--")
	local agent_dir = vim.env.PI_CODING_AGENT_DIR or vim.fn.expand("~/.pi/agent")
	local base = vim.fs.joinpath(agent_dir, "reviews", slug)
	return base .. ".json", base .. ".md"
end

local function legacy_store_path()
	local slug = root():gsub("^/", ""):gsub("[^%w%._%-]+", "--")
	return vim.fs.joinpath(vim.fn.stdpath("data"), "pi", "reviews", slug .. ".json")
end

local function mark_line(mark)
	if mark.extmark_id and vim.api.nvim_buf_is_valid(mark.buf) then
		local extmark = vim.api.nvim_buf_get_extmark_by_id(mark.buf, ns, mark.extmark_id, {})
		if extmark and extmark[1] then
			return extmark[1] + 1
		end
	end
	return mark.start_line or 1
end

local function mark_end_line(mark)
	if mark.end_extmark_id and vim.api.nvim_buf_is_valid(mark.buf) then
		local extmark = vim.api.nvim_buf_get_extmark_by_id(mark.buf, ns, mark.end_extmark_id, {})
		if extmark and extmark[1] then
			return extmark[1] + 1
		end
	end
	return mark.end_line or mark_line(mark)
end

local function category(mark)
	return categories_by_id[mark.category] or categories_by_id.note or config.categories[1]
end

local function category_text(mark)
	local item = category(mark)
	return item and ((item.icon or "") .. " " .. (item.label or item.id)) or "Review"
end

local function category_hl(mark)
	local item = category(mark)
	return item and ("CodeReviewCategory" .. item.id:gsub("[^%w]", "")) or "CodeReviewMark"
end

local function comment_summary(note)
	if not note or note == "" then
		return ""
	end
	local first = note:match("[^\n]+") or ""
	return #first < #note and (first .. " …") or first
end

local function setup_highlights()
	vim.api.nvim_set_hl(0, "CodeReviewMark", { fg = "#fb923c", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewFixed", { fg = "#34d399", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewSelected", { fg = "#60a5fa", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewFile", { fg = "#c084fc", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewArchived", { fg = "#6b7280", italic = true })
	for _, item in ipairs(config.categories) do
		local group = "CodeReviewCategory" .. item.id:gsub("[^%w]", "")
		vim.api.nvim_set_hl(0, group, { fg = item.color or "#d1d5db", bold = true })
	end
end

local function save()
	local persisted = {}
	local markdown = {
		"# Code review",
		"",
		"Project: `" .. root() .. "`",
		"",
		"| Status | Category | ID | Location | Note | Created | Snapshot |",
		"| --- | --- | ---: | --- | --- | --- | --- |",
	}

	for _, mark in ipairs(marks) do
		local line = mark_line(mark)
		persisted[#persisted + 1] = {
			id = mark.id,
			path = mark.path,
			start_line = line,
			end_line = mark_end_line(mark),
			category = mark.category,
			note = mark.note,
			snapshot = mark.snapshot,
			resolved = mark.resolved,
			archived = mark.archived,
			created_at = mark.created_at,
		}

		local location = (mark.path and mark.path ~= "" and mark.path or "[unsaved buffer]") .. ":" .. line
		local snapshot = mark.snapshot and ("`" .. mark.snapshot .. "`") or ""
		markdown[#markdown + 1] = table
			.concat({
				mark.archived and "archived" or (mark.resolved and "fixed" or "open"),
				category_text(mark),
				tostring(mark.id),
				"`" .. location .. "`",
				(mark.note or ""):gsub("\n", "<br>"):gsub("|", "\\|"),
				mark.created_at or "",
				snapshot,
			}, " | ")
			:gsub("^", "| ")
			:gsub("$", " |")
	end

	local json_path, markdown_path = store_paths()
	vim.fn.mkdir(vim.fs.dirname(json_path), "p")
	vim.fn.writefile({
		vim.json.encode({
			version = 1,
			project = root(),
			categories = config.categories,
			issues = persisted,
		}),
	}, json_path)
	vim.fn.writefile(markdown, markdown_path)
end

local function render(mark)
	if type(mark.buf) ~= "number" or not vim.api.nvim_buf_is_valid(mark.buf) then
		return
	end

	if mark.extmark_id then
		mark.start_line = mark_line(mark)
		mark.end_line = mark_end_line(mark)
		pcall(vim.api.nvim_buf_del_extmark, mark.buf, ns, mark.extmark_id)
		if mark.end_extmark_id then
			pcall(vim.api.nvim_buf_del_extmark, mark.buf, ns, mark.end_extmark_id)
		end
	end

	mark.extmark_id = nil
	mark.end_extmark_id = nil
	if mark.archived then
		return
	end

	local line = math.max((mark.start_line or 1) - 1, 0)
	local range = mark.end_line and mark.end_line ~= mark.start_line and (mark.start_line .. "-" .. mark.end_line)
		or tostring(mark.start_line)
	local summary = comment_summary(mark.note)
	local note = summary ~= "" and (": " .. summary) or ""
	local label = category_text(mark)
	local text = mark.resolved and ("  ✓ " .. label .. " #" .. mark.id .. note)
		or ("  󰚩 " .. label .. " #" .. mark.id .. " L" .. range .. note)
	local hl = mark.resolved and "CodeReviewFixed" or category_hl(mark)

	mark.extmark_id = vim.api.nvim_buf_set_extmark(mark.buf, ns, line, 0, {
		virt_text = { { text, hl } },
		virt_text_pos = "eol",
		sign_text = mark.resolved and "✓" or "󰚩",
		sign_hl_group = hl,
		number_hl_group = hl,
	})
	if mark.end_line and mark.end_line > mark.start_line then
		mark.end_extmark_id = vim.api.nvim_buf_set_extmark(mark.buf, ns, mark.end_line - 1, 0, {})
	else
		mark.end_extmark_id = nil
	end
end

local function add_mark(buf, start_line, end_line, note, category_id)
	sequence = sequence + 1
	start_line = start_line or vim.api.nvim_win_get_cursor(0)[1]
	end_line = end_line or start_line

	local mark = {
		id = sequence,
		buf = buf,
		path = vim.api.nvim_buf_get_name(buf),
		start_line = start_line,
		end_line = end_line,
		category = category_id or "note",
		note = note,
		resolved = false,
		created_at = os.date("%Y-%m-%d %H:%M:%S"),
	}
	marks[#marks + 1] = mark
	render(mark)
	save()
	return mark
end

local function valid_marks(include_archived)
	local result = {}
	for _, mark in ipairs(marks) do
		if
			type(mark.buf) == "number"
			and vim.api.nvim_buf_is_valid(mark.buf)
			and (include_archived or not mark.archived)
		then
			result[#result + 1] = mark
		end
	end
	table.sort(result, function(a, b)
		local a_path = a.path or ""
		local b_path = b.path or ""
		if a_path == b_path then
			return mark_line(a) < mark_line(b)
		end
		return a_path < b_path
	end)
	return result
end

local function visual_line_range()
	local mode = vim.fn.mode()
	if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
		return nil, nil
	end

	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	vim.cmd("normal! \27")
	return start_line, end_line
end

local function snapshot_buffer(buf, start_line, end_line)
	local name = vim.api.nvim_buf_get_name(buf)
	local label = name ~= "" and name or ("[No Name buffer " .. buf .. "]")
	start_line = start_line or 1
	end_line = end_line or vim.api.nvim_buf_line_count(buf)

	local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
	local snapshot_dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "pi", "buffer-snapshots")
	vim.fn.mkdir(snapshot_dir, "p")

	local safe_label = label:gsub("^/", ""):gsub("[^%w%._%-]+", "-")
	if safe_label == "" then
		safe_label = "buffer-" .. buf
	end
	local path = vim.fs.joinpath(snapshot_dir, safe_label .. ".md")
	local contents = {
		"# Unsaved Neovim buffer snapshot",
		"",
		"- Source: " .. label,
		"- Buffer: " .. buf,
		"- Lines: " .. start_line .. "-" .. end_line,
		"- Captured: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
		"```" .. (vim.bo[buf].filetype or ""),
	}
	vim.list_extend(contents, lines)
	vim.list_extend(contents, { "```", "" })
	vim.fn.writefile(contents, path)
	return path
end

local function open_comment_editor(opts, callback)
	opts = opts or {}
	local buf = vim.api.nvim_create_buf(false, true)
	local lines = vim.split(opts.default or "", "\n", { plain = true })
	if #lines == 0 then
		lines = { "" }
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "markdown"

	local width = math.min(math.max(60, math.floor(vim.o.columns * 0.65)), vim.o.columns - 4)
	local height = math.min(math.max(10, #lines + 4), math.max(4, vim.o.lines - 6))
	local row = math.floor((vim.o.lines - height) / 2) - 1
	local col = math.floor((vim.o.columns - width) / 2)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.max(row, 0),
		col = math.max(col, 0),
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = " " .. (opts.title or "Review comment") .. " ",
		title_pos = "center",
	})
	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	vim.wo[win].winbar = "%#Comment#  <C-s> save   <C-c> cancel"

	local finished = false
	local function close(value)
		if finished then
			return
		end
		finished = true
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		if value ~= nil then
			callback(value)
		end
	end
	local function save_comment()
		local value = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
		close(vim.trim(value))
	end

	vim.keymap.set({ "n", "i" }, "<C-s>", save_comment, { buffer = buf, silent = true, desc = "Save review comment" })
	vim.keymap.set("n", "q", function()
		close(nil)
	end, { buffer = buf, silent = true, desc = "Cancel review comment" })
	vim.keymap.set({ "n", "i" }, "<C-c>", function()
		close(nil)
	end, { buffer = buf, silent = true, desc = "Cancel review comment" })

	vim.api.nvim_win_set_cursor(win, { #lines, #(lines[#lines] or "") })
	vim.cmd("startinsert!")
end

local function with_pi_cwd(fn)
	local original_win = vim.api.nvim_get_current_win()
	local original_cwd = vim.fn.getcwd()
	vim.cmd("lcd " .. vim.fn.fnameescape(root()))
	local ok, err = pcall(fn)
	local restore_win = vim.api.nvim_get_current_win()

	if vim.api.nvim_win_is_valid(original_win) then
		vim.api.nvim_set_current_win(original_win)
		vim.cmd("lcd " .. vim.fn.fnameescape(original_cwd))
	end
	if vim.api.nvim_win_is_valid(restore_win) then
		vim.api.nvim_set_current_win(restore_win)
	end
	if not ok then
		error(err)
	end
end

function M.mention()
	local buf = vim.api.nvim_get_current_buf()
	local start_line, end_line = visual_line_range()
	local path = vim.api.nvim_buf_get_name(buf)
	local needs_snapshot = path == "" or vim.bo[buf].modified

	with_pi_cwd(function()
		if needs_snapshot then
			local snapshot = snapshot_buffer(buf, start_line, end_line)
			require("pi").send_mention({ path = snapshot }, { focus = true })
			vim.notify("Unsaved buffer snapshot mentioned in Pi", vim.log.levels.INFO)
		elseif start_line and end_line then
			require("pi").send_mention({ path = path, start_line = start_line, end_line = end_line }, { focus = true })
		else
			require("pi").send_mention({ path = path }, { focus = true })
		end
	end)
end

function M.add()
	local buf = vim.api.nvim_get_current_buf()
	local start_line, end_line = visual_line_range()
	local needs_snapshot = vim.api.nvim_buf_get_name(buf) == "" or vim.bo[buf].modified

	vim.ui.select(config.categories, {
		prompt = "Review category",
		format_item = function(item)
			return (item.icon or "") .. " " .. item.label .. " — " .. (item.description or "")
		end,
	}, function(selected_category)
		if not selected_category then
			return
		end
		open_comment_editor({ title = selected_category.label .. " comment" }, function(note)
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end

			local mark = add_mark(buf, start_line, end_line, note, selected_category.id)
			if needs_snapshot then
				mark.snapshot = snapshot_buffer(buf, start_line, end_line)
				save()
			end
			vim.notify(selected_category.label .. " review #" .. mark.id .. " added", vim.log.levels.INFO)
		end)
	end)
end

local function jump(mark)
	if not mark or not vim.api.nvim_buf_is_valid(mark.buf) then
		return
	end
	vim.api.nvim_set_current_buf(mark.buf)
	vim.api.nvim_win_set_cursor(0, { mark_line(mark), 0 })
	vim.cmd("normal! zz")
end

function M.jump(direction)
	local available = valid_marks()
	if #available == 0 then
		vim.notify("No review issues", vim.log.levels.INFO)
		return
	end

	local current_buf = vim.api.nvim_get_current_buf()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local fallback = direction == 1 and available[1] or available[#available]
	for i = 1, #available do
		local mark = direction == 1 and available[i] or available[#available - i + 1]
		local line = mark_line(mark)
		if
			mark.buf ~= current_buf
			or (direction == 1 and line > current_line)
			or (direction == -1 and line < current_line)
		then
			jump(mark)
			return
		end
	end
	jump(fallback)
end

local function list_file_name(mark)
	if not mark.path or mark.path == "" then
		return "[unsaved buffer " .. tostring(mark.buf or "?") .. "]"
	end
	local project_root = root()
	if mark.path:sub(1, #project_root + 1) == project_root .. "/" then
		return mark.path:sub(#project_root + 2)
	end
	return vim.fn.fnamemodify(mark.path, ":~")
end

local function visible_list_marks()
	local result = {}
	for _, mark in ipairs(marks) do
		if list.show_archived or not mark.archived then
			result[#result + 1] = mark
		end
	end
	table.sort(result, function(a, b)
		local a_name = list_file_name(a)
		local b_name = list_file_name(b)
		if a_name == b_name then
			return mark_line(a) < mark_line(b)
		end
		return a_name < b_name
	end)
	return result
end

local render_list

local function list_rows()
	local first = vim.api.nvim_win_get_cursor(0)[1]
	local last = first
	local mode = vim.fn.mode()
	local visual = mode == "v" or mode == "V" or mode == "\22"
	if visual then
		first = vim.fn.line("v")
		last = vim.fn.line(".")
		if first > last then
			first, last = last, first
		end
		vim.cmd("normal! \27")
	end
	return first, last, visual
end

local function marks_on_rows(first, last)
	local result = {}
	local seen = {}
	for row = first, last do
		local mark = list.row_marks[row]
		if mark and not seen[mark.id] then
			seen[mark.id] = true
			result[#result + 1] = mark
		end
	end
	return result
end

local function selected_marks()
	local result = {}
	for _, mark in ipairs(marks) do
		if list.selected[mark.id] then
			result[#result + 1] = mark
		end
	end
	return result
end

local function action_marks()
	local first, last, visual = list_rows()
	if visual then
		return marks_on_rows(first, last)
	end
	local selected = selected_marks()
	if #selected > 0 then
		return selected
	end
	return marks_on_rows(first, last)
end

local function apply_list_action(action)
	local targets = action_marks()
	if #targets == 0 then
		vim.notify("No review issues selected", vim.log.levels.INFO)
		return
	end
	for _, mark in ipairs(targets) do
		action(mark)
	end
	list.selected = {}
	save()
	render_list()
end

local function toggle_list_selection()
	local first, last = list_rows()
	for _, mark in ipairs(marks_on_rows(first, last)) do
		list.selected[mark.id] = not list.selected[mark.id] or nil
	end
	render_list()
end

local function jump_from_list()
	local mark = list.row_marks[vim.api.nvim_win_get_cursor(0)[1]]
	if not mark then
		return
	end
	if list.source_win and vim.api.nvim_win_is_valid(list.source_win) then
		vim.api.nvim_set_current_win(list.source_win)
	end
	jump(mark)
end

local function confirm_archive(filter, label)
	local targets = {}
	for _, mark in ipairs(marks) do
		if not mark.archived and filter(mark) then
			targets[#targets + 1] = mark
		end
	end
	if #targets == 0 then
		vim.notify("No matching review issues to archive", vim.log.levels.INFO)
		return
	end

	vim.ui.select({ "Archive", "Cancel" }, {
		prompt = "Archive " .. #targets .. " " .. label .. "?",
	}, function(choice)
		if choice ~= "Archive" then
			return
		end
		for _, mark in ipairs(targets) do
			mark.archived = true
			render(mark)
		end
		list.selected = {}
		save()
		render_list()
	end)
end

local function setup_list_buffer(buf)
	local function map(modes, key, action, desc)
		vim.keymap.set(modes, key, action, { buffer = buf, silent = true, desc = desc })
	end

	map("n", "<CR>", jump_from_list, "Review: jump to issue")
	map({ "n", "x" }, "<Space>", toggle_list_selection, "Review: select issue")
	map({ "n", "x" }, "x", function()
		apply_list_action(function(mark)
			mark.resolved = not mark.resolved
			render(mark)
		end)
	end, "Review: toggle selected completion")
	map("n", "e", function()
		M.edit_comment()
	end, "Review: edit comment")
	map({ "n", "x" }, "t", function()
		M.change_category()
	end, "Review: change selected category")
	map({ "n", "x" }, "a", function()
		apply_list_action(function(mark)
			mark.archived = true
			render(mark)
		end)
	end, "Review: archive selected")
	map({ "n", "x" }, "u", function()
		apply_list_action(function(mark)
			mark.archived = false
			render(mark)
		end)
	end, "Review: restore selected")
	map("n", "A", function()
		confirm_archive(function()
			return true
		end, "active review issues")
	end, "Review: archive all")
	map("n", "F", function()
		confirm_archive(function(mark)
			return mark.resolved
		end, "completed review issues")
	end, "Review: archive all completed")
	map("n", "i", function()
		list.show_archived = not list.show_archived
		render_list()
	end, "Review: toggle archived issues")
	map("n", "y", function()
		M.copy_open_for_ai()
	end, "Review: copy open issues for AI")
	map("n", "r", render_list, "Review: refresh list")
	map("n", "q", function()
		vim.api.nvim_win_close(0, true)
	end, "Review: close list")
end

render_list = function()
	if not list.buf or not vim.api.nvim_buf_is_valid(list.buf) then
		return
	end

	local open_count, fixed_count, archived_count = 0, 0, 0
	for _, mark in ipairs(marks) do
		if mark.archived then
			archived_count = archived_count + 1
		elseif mark.resolved then
			fixed_count = fixed_count + 1
		else
			open_count = open_count + 1
		end
	end

	local lines = {
		string.format("Code Review  %d open  %d fixed  %d archived", open_count, fixed_count, archived_count),
		"<CR> jump  <Space> select  x complete  e comment  t type  a archive  u restore  A all  F fixed  i archived  y copy  q close",
		"",
	}
	local file_rows = {}
	list.row_marks = {}
	local current_file
	for _, mark in ipairs(visible_list_marks()) do
		local file = list_file_name(mark)
		if file ~= current_file then
			if current_file then
				lines[#lines + 1] = ""
			end
			current_file = file
			lines[#lines + 1] = "▾ " .. file
			file_rows[#file_rows + 1] = #lines
		end

		local selected = list.selected[mark.id] and "●" or " "
		local status = mark.archived and "A" or (mark.resolved and "✓" or " ")
		local start_line = mark_line(mark)
		local end_line = mark_end_line(mark)
		local range = end_line ~= start_line and (start_line .. "-" .. end_line) or tostring(start_line)
		local note = mark.note and mark.note ~= "" and mark.note or "(no comment)"
		lines[#lines + 1] =
			string.format(" %s [%s] %-16s #%d L%s  %s", selected, status, category_text(mark), mark.id, range, note)
		list.row_marks[#lines] = mark
	end
	if #lines == 3 then
		lines[#lines + 1] = list.show_archived and "No review issues"
			or "No active review issues (press i for archived)"
	end

	local cursor = 1
	local win = vim.fn.bufwinid(list.buf)
	if win ~= -1 then
		cursor = vim.api.nvim_win_get_cursor(win)[1]
	end
	vim.bo[list.buf].modifiable = true
	vim.api.nvim_buf_set_lines(list.buf, 0, -1, false, lines)
	vim.bo[list.buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(list.buf, list_ns, 0, -1)
	vim.api.nvim_buf_add_highlight(list.buf, list_ns, "Title", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(list.buf, list_ns, "Comment", 1, 0, -1)
	for _, row in ipairs(file_rows) do
		vim.api.nvim_buf_add_highlight(list.buf, list_ns, "CodeReviewFile", row - 1, 0, -1)
	end
	for row, mark in pairs(list.row_marks) do
		local hl = list.selected[mark.id] and "CodeReviewSelected"
			or (mark.archived and "CodeReviewArchived" or (mark.resolved and "CodeReviewFixed" or category_hl(mark)))
		vim.api.nvim_buf_add_highlight(list.buf, list_ns, hl, row - 1, 0, -1)
	end
	if win ~= -1 then
		vim.api.nvim_win_set_cursor(win, { math.min(cursor, #lines), 0 })
	end
end

local function preferred_source_window(current_win)
	local current_ft = vim.bo[vim.api.nvim_win_get_buf(current_win)].filetype
	if not current_ft:match("^pi%-") and current_ft ~= "review-list" then
		return current_win
	end
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
		if not ft:match("^pi%-") and ft ~= "review-list" then
			return win
		end
	end
	return current_win
end

local function repair_pi_prompt_height()
	pcall(function()
		local session = require("pi.sessions.manager").get()
		if session and session.chat and session.chat._prompt then
			session.chat._prompt:resize()
		end
	end)
end

function M.select()
	local current_win = vim.api.nvim_get_current_win()
	if not list.buf or not vim.api.nvim_buf_is_valid(list.buf) then
		list.buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(list.buf, "review://issues")
		vim.bo[list.buf].buftype = "nofile"
		vim.bo[list.buf].bufhidden = "wipe"
		vim.bo[list.buf].swapfile = false
		vim.bo[list.buf].filetype = "review-list"
		setup_list_buffer(list.buf)
	end

	local win = vim.fn.bufwinid(list.buf)
	if win == -1 then
		list.source_win = preferred_source_window(current_win)
		repair_pi_prompt_height()
		local width = math.max(1, math.min(math.floor(vim.o.columns * 0.82), vim.o.columns - 4))
		local height = math.max(1, math.min(math.floor(vim.o.lines * 0.72), vim.o.lines - 4))
		win = vim.api.nvim_open_win(list.buf, true, {
			relative = "editor",
			row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
			col = math.max(0, math.floor((vim.o.columns - width) / 2)),
			width = width,
			height = height,
			style = "minimal",
			border = "rounded",
			title = " Code Review ",
			title_pos = "center",
			zindex = 60,
		})
		vim.wo[win].cursorline = true
		vim.wo[win].wrap = false
	else
		if current_win ~= win then
			list.source_win = preferred_source_window(current_win)
		end
		vim.api.nvim_set_current_win(win)
	end
	render_list()
end

function M.quickfix()
	local items = {}
	for _, mark in ipairs(valid_marks()) do
		items[#items + 1] = {
			bufnr = mark.buf,
			lnum = mark_line(mark),
			col = 1,
			text = (mark.resolved and "✓" or "󰚩")
				.. " "
				.. category_text(mark)
				.. " #"
				.. mark.id
				.. (mark.note and mark.note ~= "" and (": " .. mark.note) or ""),
		}
	end
	vim.fn.setqflist({}, " ", { title = "Review issues", items = items })
	vim.cmd("copen")
end

local function native_clipboard_command()
	if vim.fn.executable("pbcopy") == 1 then
		return { "pbcopy" }
	end
	if vim.fn.executable("wl-copy") == 1 then
		return { "wl-copy", "--type", "text/plain" }
	end
	if vim.fn.executable("xclip") == 1 then
		return { "xclip", "-selection", "clipboard" }
	end
	if vim.fn.executable("xsel") == 1 then
		return { "xsel", "--clipboard", "--input" }
	end
	return nil
end

local function copy_text(text, description)
	text = text:gsub("%z", "")
	-- Keep an immediate Neovim-local copy without invoking the OSC52 provider.
	vim.fn.setreg('"', text)

	local function fallback()
		-- OSC52 has terminal-dependent payload limits. Only use it for reasonably
		-- small copies; preserve larger payloads in a file instead of truncating.
		if #text <= 60000 then
			vim.fn.setreg("+", text)
			vim.notify(description .. " via OSC52 (" .. #text .. " bytes)", vim.log.levels.INFO)
			return
		end

		local path = vim.fs.joinpath(vim.fn.stdpath("cache"), "pi", "open-review-issues.md")
		vim.fn.mkdir(vim.fs.dirname(path), "p")
		vim.fn.writefile(vim.split(text, "\n", { plain = true }), path)
		vim.notify("Clipboard payload too large for OSC52; wrote " .. path, vim.log.levels.WARN)
	end

	local command = native_clipboard_command()
	if not command then
		fallback()
		return
	end

	vim.system(command, { stdin = text, text = true, timeout = 5000 }, function(result)
		vim.schedule(function()
			if result.code == 0 then
				vim.notify(description .. " (" .. #text .. " bytes)", vim.log.levels.INFO)
			else
				vim.notify(
					"Native clipboard failed; trying fallback: " .. (result.stderr or "unknown error"),
					vim.log.levels.WARN
				)
				fallback()
			end
		end)
	end)
end

function M.copy_open_for_ai()
	local open = {}
	for _, mark in ipairs(marks) do
		if not mark.archived and not mark.resolved then
			open[#open + 1] = mark
		end
	end
	table.sort(open, function(a, b)
		local a_name = list_file_name(a)
		local b_name = list_file_name(b)
		if a_name == b_name then
			return mark_line(a) < mark_line(b)
		end
		return a_name < b_name
	end)
	if #open == 0 then
		vim.notify("No open review issues to copy", vim.log.levels.INFO)
		return
	end

	local lines = {
		"# Open code review issues",
		"",
		"Project root: `" .. root() .. "`",
		"",
		"Address each issue below. Preserve the issue IDs in your response so fixes can be verified and closed.",
	}
	local current_file
	for _, mark in ipairs(open) do
		local file = list_file_name(mark)
		if file ~= current_file then
			current_file = file
			lines[#lines + 1] = ""
			lines[#lines + 1] = "## " .. file
		end

		local start_line = mark_line(mark)
		local end_line = mark_end_line(mark)
		local range = end_line ~= start_line and (start_line .. "-" .. end_line) or tostring(start_line)
		lines[#lines + 1] = string.format(
			"- **%s** `#%d` — `%s:%s`",
			category_text(mark),
			mark.id,
			mark.path and mark.path ~= "" and mark.path or (mark.snapshot or "[unsaved buffer]"),
			range
		)
		local comment_lines = vim.split(mark.note and mark.note ~= "" and mark.note or "No comment provided", "\n", {
			plain = true,
		})
		for index, comment_line in ipairs(comment_lines) do
			lines[#lines + 1] = (index == 1 and "  - Comment: " or "    ") .. comment_line
		end
	end

	local text = table.concat(lines, "\n")
	copy_text(text, "Copied " .. #open .. " open review issues for AI")
end

function M.archive_all(fixed_only)
	confirm_archive(function(mark)
		return not fixed_only or mark.resolved
	end, fixed_only and "completed review issues" or "active review issues")
end

local function source_cursor_candidates()
	local buf = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local exact = {}
	local containing = {}
	for _, mark in ipairs(valid_marks()) do
		if mark.buf == buf then
			local start_line = mark_line(mark)
			if line == start_line then
				exact[#exact + 1] = mark
			elseif line > start_line and line <= mark_end_line(mark) then
				containing[#containing + 1] = mark
			end
		end
	end
	return #exact > 0 and exact or containing
end

local function choose_issue(candidates, prompt, callback)
	if #candidates == 0 then
		vim.notify("No review issue at the cursor", vim.log.levels.INFO)
		return
	end
	if #candidates == 1 then
		callback(candidates[1])
		return
	end
	vim.ui.select(candidates, {
		prompt = prompt,
		format_item = function(mark)
			return category_text(mark)
				.. " #"
				.. mark.id
				.. (mark.note and mark.note ~= "" and (" — " .. mark.note) or "")
		end,
	}, function(mark)
		if mark then
			callback(mark)
		end
	end)
end

function M.edit_comment()
	local candidates
	if list.buf and vim.api.nvim_get_current_buf() == list.buf then
		local mark = list.row_marks[vim.api.nvim_win_get_cursor(0)[1]]
		candidates = mark and { mark } or {}
	else
		candidates = source_cursor_candidates()
	end

	choose_issue(candidates, "Edit which review issue?", function(mark)
		open_comment_editor({
			title = "Edit " .. category_text(mark) .. " #" .. mark.id,
			default = mark.note or "",
		}, function(note)
			mark.note = note
			render(mark)
			save()
			render_list()
			vim.notify("Review #" .. mark.id .. " comment updated", vim.log.levels.INFO)
		end)
	end)
end

local function pick_category(targets)
	if #targets == 0 then
		vim.notify("No review issues selected", vim.log.levels.INFO)
		return
	end
	vim.ui.select(config.categories, {
		prompt = "Change review category",
		format_item = function(item)
			return (item.icon or "") .. " " .. item.label .. " — " .. (item.description or "")
		end,
	}, function(selected_category)
		if not selected_category then
			return
		end
		for _, mark in ipairs(targets) do
			mark.category = selected_category.id
			render(mark)
		end
		list.selected = {}
		save()
		render_list()
		vim.notify(
			"Changed " .. #targets .. " review issue type(s) to " .. selected_category.label,
			vim.log.levels.INFO
		)
	end)
end

function M.change_category()
	if list.buf and vim.api.nvim_get_current_buf() == list.buf then
		pick_category(action_marks())
		return
	end

	local candidates = source_cursor_candidates()
	choose_issue(candidates, "Change type for which review issue?", function(mark)
		pick_category({ mark })
	end)
end

local function toggle_mark(mark)
	mark.resolved = not mark.resolved
	render(mark)
	save()
	vim.notify("Review #" .. mark.id .. (mark.resolved and " fixed" or " reopened"), vim.log.levels.INFO)
end

function M.toggle_fixed()
	local candidates
	if list.buf and vim.api.nvim_get_current_buf() == list.buf then
		local selected = selected_marks()
		if #selected > 0 then
			for _, mark in ipairs(selected) do
				mark.resolved = not mark.resolved
				render(mark)
			end
			list.selected = {}
			save()
			render_list()
			return
		end
		local mark = list.row_marks[vim.api.nvim_win_get_cursor(0)[1]]
		candidates = mark and { mark } or {}
	else
		candidates = source_cursor_candidates()
	end
	choose_issue(candidates, "Toggle which review issue?", toggle_mark)
end

function M.load()
	for _, mark in ipairs(marks) do
		if type(mark.buf) == "number" and vim.api.nvim_buf_is_valid(mark.buf) then
			vim.api.nvim_buf_clear_namespace(mark.buf, ns, 0, -1)
		end
	end
	marks = {}

	local json_path = store_paths()
	if vim.fn.filereadable(json_path) ~= 1 then
		local legacy = legacy_store_path()
		if vim.fn.filereadable(legacy) == 1 then
			vim.fn.mkdir(vim.fs.dirname(json_path), "p")
			vim.fn.writefile(vim.fn.readfile(legacy), json_path)
		else
			return
		end
	end

	local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(json_path), "\n"))
	if not ok or type(decoded) ~= "table" then
		vim.notify("Could not read Pi review store: " .. json_path, vim.log.levels.WARN)
		return
	end

	if decoded.issues then
		for _, item in ipairs(decoded.categories or {}) do
			if item.id and not categories_by_id[item.id] then
				config.categories[#config.categories + 1] = item
				categories_by_id[item.id] = item
			end
		end
		decoded = decoded.issues
		setup_highlights()
	end

	for _, item in ipairs(decoded) do
		item.category = item.category or "note"
		local source = item.path and item.path ~= "" and item.path or nil
		if not source or vim.fn.filereadable(source) ~= 1 then
			source = item.snapshot and vim.fn.filereadable(item.snapshot) == 1 and item.snapshot or nil
		end

		local buf
		if source then
			buf = vim.fn.bufadd(source)
			vim.fn.bufload(buf)
		end

		sequence = math.max(sequence, item.id or 0)
		local mark = vim.tbl_extend("force", item, { buf = buf })
		marks[#marks + 1] = mark
		if buf then
			render(mark)
		end
	end
	save()
end

function M.open_store(format)
	local json_path, markdown_path = store_paths()
	vim.cmd("edit " .. vim.fn.fnameescape(format == "json" and json_path or markdown_path))
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	categories_by_id = {}
	for _, item in ipairs(config.categories) do
		if item.id then
			categories_by_id[item.id] = item
		end
	end
	setup_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })
	vim.api.nvim_create_autocmd("User", { pattern = "PiRootChanged", callback = M.load })

	vim.api.nvim_create_user_command("ReviewAdd", M.add, { desc = "Add a review issue at the cursor or selection" })
	vim.api.nvim_create_user_command("ReviewNext", function()
		M.jump(1)
	end, { desc = "Jump to next review issue" })
	vim.api.nvim_create_user_command("ReviewPrev", function()
		M.jump(-1)
	end, { desc = "Jump to previous review issue" })
	vim.api.nvim_create_user_command("ReviewList", M.select, { desc = "Open grouped review issue list" })
	vim.api.nvim_create_user_command("ReviewQuickfix", M.quickfix, { desc = "Open review issues in quickfix" })
	vim.api.nvim_create_user_command("ReviewEdit", M.edit_comment, { desc = "Edit review comment at cursor" })
	vim.api.nvim_create_user_command("ReviewType", M.change_category, { desc = "Change review category at cursor" })
	vim.api.nvim_create_user_command("ReviewFixed", M.toggle_fixed, { desc = "Toggle review issue fixed" })
	vim.api.nvim_create_user_command(
		"ReviewCopyOpen",
		M.copy_open_for_ai,
		{ desc = "Copy open issues and comments for AI" }
	)
	vim.api.nvim_create_user_command("ReviewArchiveAll", function()
		M.archive_all(false)
	end, { desc = "Archive all active review issues" })
	vim.api.nvim_create_user_command("ReviewArchiveFixed", function()
		M.archive_all(true)
	end, { desc = "Archive all completed review issues" })
	vim.api.nvim_create_user_command("ReviewStore", function()
		M.open_store("markdown")
	end, { desc = "Open portable review Markdown" })
	vim.api.nvim_create_user_command("ReviewJson", function()
		M.open_store("json")
	end, { desc = "Open review JSON metadata" })

	M.load()
end

return M
