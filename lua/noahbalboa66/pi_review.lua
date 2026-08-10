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

local function category_item_hl(item)
	return item and ("CodeReviewCategory" .. item.id:gsub("[^%w]", "")) or "CodeReviewMark"
end

local function format_category_item(item, supports_chunks)
	local icon = item.icon and item.icon ~= "" and (item.icon .. " ") or ""
	local label = item.label or item.id or "Review"
	local description = item.description and item.description ~= "" and ("  —  " .. item.description) or ""
	if supports_chunks then
		return {
			{ icon .. label, category_item_hl(item) },
			{ description, "CodeReviewMuted" },
		}
	end
	return icon .. label .. description
end

local function format_issue_item(mark, supports_chunks)
	local label = category_text(mark)
	local id = " #" .. mark.id
	local note = mark.note and mark.note ~= "" and ("  —  " .. mark.note) or ""
	if supports_chunks then
		return {
			{ label, category_hl(mark) },
			{ id, "CodeReviewId" },
			{ note, "CodeReviewMuted" },
		}
	end
	return label .. id .. note
end

local function comment_summary(note)
	if not note or note == "" then
		return ""
	end
	local first = note:match("[^\n]+") or ""
	return #first < #note and (first .. " …") or first
end

local function setup_highlights()
	local function hl_color(group, attr, fallback)
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
		local value = ok and hl[attr] or nil
		return value and string.format("#%06x", value) or fallback
	end

	local normal_fg = hl_color("Normal", "fg", "#d1d5db")
	local muted = hl_color("Comment", "fg", "#6b7280")
	local alt_bg = hl_color("CursorLine", "bg", hl_color("StatusLine", "bg", "#1f2937"))

	vim.api.nvim_set_hl(0, "CodeReviewFloat", { fg = normal_fg, bg = "NONE" })
	vim.api.nvim_set_hl(0, "CodeReviewBorder", { fg = "#c084fc", bg = "NONE" })
	vim.api.nvim_set_hl(0, "CodeReviewTitle", { fg = "#c084fc", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewCursorLine", { bg = alt_bg })
	vim.api.nvim_set_hl(0, "CodeReviewSelectedLine", { bg = alt_bg })
	vim.api.nvim_set_hl(0, "CodeReviewMark", { fg = "#fb923c", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewOpen", { fg = "#fbbf24", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewFixed", { fg = "#34d399", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewSelected", { fg = "#60a5fa", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewFileIcon", { fg = "#c084fc", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewFile", { fg = "#22d3ee", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewId", { fg = "#fb923c", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewLine", { fg = "#60a5fa" })
	vim.api.nvim_set_hl(0, "CodeReviewNote", { fg = normal_fg })
	vim.api.nvim_set_hl(0, "CodeReviewMuted", { fg = muted })
	vim.api.nvim_set_hl(0, "CodeReviewArchived", { fg = muted, italic = true })
	vim.api.nvim_set_hl(0, "CodeReviewKey", { fg = "#c084fc", bold = true })
	vim.api.nvim_set_hl(0, "CodeReviewHint", { fg = muted })
	for _, item in ipairs(config.categories) do
		local group = "CodeReviewCategory" .. item.id:gsub("[^%w]", "")
		vim.api.nvim_set_hl(0, group, { fg = item.color or normal_fg, bold = true })
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
	-- Use a normal, named buffer and assign its filetype only after the float is
	-- visible. FileType consumers (completion, Treesitter, render-markdown, and
	-- language servers) can then attach exactly as they do to a regular editor.
	local buf = vim.api.nvim_create_buf(false, false)
	local lines = vim.split(opts.default or "", "\n", { plain = true })
	if #lines == 0 then
		lines = { "" }
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	local virtual_name = string.format("review-%s-%d.md", opts.id or "new", buf)
	vim.api.nvim_buf_set_name(buf, vim.fs.joinpath(root(), ".pi-review-comments", virtual_name))

	local category_position
	local selected_category = type(opts.category) == "string" and categories_by_id[opts.category] or opts.category
	if opts.category_editable and #config.categories > 0 then
		for index, item in ipairs(config.categories) do
			if item == selected_category or (selected_category and item.id == selected_category.id) then
				category_position = index
				break
			end
		end
		category_position = category_position or 1
		selected_category = config.categories[category_position]
	end

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
		zindex = opts.zindex or 70,
	})
	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	vim.bo[buf].filetype = "review-comment"
	vim.bo[buf].syntax = "markdown"
	vim.bo[buf].modified = false

	local function update_winbar()
		if not vim.api.nvim_win_is_valid(win) then
			return
		end
		local category_label = ""
		if category_position and selected_category then
			category_label = string.format(
				"   <C-p>/<C-n> category: %s %s",
				selected_category.icon or "",
				selected_category.label or selected_category.id
			)
		end
		vim.wo[win].winbar =
			string.format("%%#Comment#  <C-s> save   <C-c> cancel%s", category_label:gsub("%%", "%%%%"))
	end

	local function cycle_category(offset)
		if not category_position then
			return
		end
		category_position = ((category_position - 1 + offset) % #config.categories) + 1
		selected_category = config.categories[category_position]
		update_winbar()
	end

	update_winbar()

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
			callback(value, selected_category)
		end
	end
	local function save_comment()
		local value = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
		vim.bo[buf].modified = false
		close(vim.trim(value))
	end

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = save_comment,
		desc = "Save the review comment without creating its virtual Markdown file",
	})
	vim.keymap.set({ "n", "i" }, "<C-s>", save_comment, { buffer = buf, silent = true, desc = "Save review issue" })
	vim.keymap.set({ "n", "i" }, "<C-n>", function()
		cycle_category(1)
	end, { buffer = buf, silent = true, desc = "Next review category" })
	vim.keymap.set({ "n", "i" }, "<C-p>", function()
		cycle_category(-1)
	end, { buffer = buf, silent = true, desc = "Previous review category" })
	vim.keymap.set("n", "q", function()
		close(nil)
	end, { buffer = buf, silent = true, desc = "Cancel review edit" })
	vim.keymap.set({ "n", "i" }, "<C-c>", function()
		close(nil)
	end, { buffer = buf, silent = true, desc = "Cancel review edit" })

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
		kind = "pi_review_category",
		format_item = format_category_item,
	}, function(selected_category)
		if not selected_category then
			return
		end
		open_comment_editor({
			title = "Add review issue",
			id = sequence + 1,
			category = selected_category,
			category_editable = true,
		}, function(note, edited_category)
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end

			local final_category = edited_category or selected_category
			local mark = add_mark(buf, start_line, end_line, note, final_category.id)
			if needs_snapshot then
				mark.snapshot = snapshot_buffer(buf, start_line, end_line)
				save()
			end
			vim.notify(final_category.label .. " review #" .. mark.id .. " added", vim.log.levels.INFO)
		end)
	end)
end

local function is_floating_window(win)
	if not win or not vim.api.nvim_win_is_valid(win) then
		return false
	end
	return vim.api.nvim_win_get_config(win).relative ~= ""
end

local function is_source_window(win)
	if not win or not vim.api.nvim_win_is_valid(win) or is_floating_window(win) then
		return false
	end
	local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
	return not ft:match("^pi%-") and ft ~= "review-list"
end

local function preferred_source_window(current_win)
	if is_source_window(current_win) then
		return current_win
	end
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if is_source_window(win) then
			return win
		end
	end
	return nil
end

local function hide_floating_pi()
	pcall(function()
		local session = require("pi.sessions.manager").get()
		if session and session.chat:is_visible() and session.chat:layout() == "float" then
			session.chat:hide()
		end
	end)
end

local function close_floating_review_list()
	if not list.buf or not vim.api.nvim_buf_is_valid(list.buf) then
		return
	end
	local win = vim.fn.bufwinid(list.buf)
	if win ~= -1 and is_floating_window(win) then
		vim.api.nvim_win_close(win, true)
	end
end

local function jump(mark)
	if not mark or not vim.api.nvim_buf_is_valid(mark.buf) then
		return
	end

	local current_win = vim.api.nvim_get_current_win()
	local destination = vim.api.nvim_get_current_buf() == list.buf and list.source_win or current_win

	-- A floating review list or Pi chat would otherwise cover the destination.
	-- Side layouts remain visible and navigation uses the normal source window.
	close_floating_review_list()
	hide_floating_pi()

	if not is_source_window(destination) then
		destination = preferred_source_window(vim.api.nvim_get_current_win())
	end
	if not destination then
		vim.notify("No source window available for the review issue", vim.log.levels.WARN)
		return
	end

	vim.api.nvim_set_current_win(destination)
	vim.api.nvim_win_set_buf(destination, mark.buf)
	vim.api.nvim_win_set_cursor(destination, { mark_line(mark), 0 })
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

local function select_over_review_list(items, opts, callback)
	local list_win = list.buf and vim.fn.bufwinid(list.buf) or -1
	local original_zindex
	if list_win ~= -1 and is_floating_window(list_win) then
		original_zindex = vim.api.nvim_win_get_config(list_win).zindex or 50
		vim.api.nvim_win_set_config(list_win, { zindex = 40 })
	end

	local function restore_list()
		if original_zindex and vim.api.nvim_win_is_valid(list_win) then
			vim.api.nvim_win_set_config(list_win, { zindex = original_zindex })
		end
	end

	local ok, err = pcall(vim.ui.select, items, opts, function(choice, index)
		restore_list()
		callback(choice, index)
	end)
	if not ok then
		restore_list()
		error(err)
	end
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

	select_over_review_list({ "Archive", "Cancel" }, {
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

	local function show_help()
		vim.notify(
			table.concat({
				"<CR>      Jump to issue",
				"<Space>   Select issue",
				"x         Toggle fixed",
				"e         Edit comment and category",
				"t         Change category only",
				"a / u     Archive / restore",
				"A / F     Archive all / all fixed",
				"i         Show archived",
				"y         Copy open issues for AI",
				"r         Refresh",
				"q         Close",
			}, "\n"),
			vim.log.levels.INFO,
			{ title = "Code Review keys" }
		)
	end

	map("n", "<CR>", jump_from_list, "Review: jump to issue")
	map("n", "?", show_help, "Review: show key help")
	map("n", "g?", show_help, "Review: show key help")
	map({ "n", "x" }, "<Space>", toggle_list_selection, "Review: select issue")
	map({ "n", "x" }, "x", function()
		apply_list_action(function(mark)
			mark.resolved = not mark.resolved
			render(mark)
		end)
	end, "Review: toggle selected completion")
	map("n", "e", function()
		M.edit_comment()
	end, "Review: edit issue")
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

	local lines = {}
	local row_decorations = {}
	local selected_rows = {}
	list.row_marks = {}

	local function add_decorated_line(chunks)
		local parts = {}
		local spans = {}
		local col = 0
		for _, chunk in ipairs(chunks) do
			local text, hl = chunk[1], chunk[2]
			parts[#parts + 1] = text
			if hl and text ~= "" then
				spans[#spans + 1] = { start_col = col, end_col = col + #text, hl = hl }
			end
			col = col + #text
		end
		lines[#lines + 1] = table.concat(parts)
		row_decorations[#lines] = spans
		return #lines
	end

	local current_file
	for _, mark in ipairs(visible_list_marks()) do
		local file = list_file_name(mark)
		if file ~= current_file then
			if current_file then
				lines[#lines + 1] = ""
			end
			current_file = file
			add_decorated_line({
				{ "  ▾  ", "CodeReviewFileIcon" },
				{ file, "CodeReviewFile" },
			})
		end

		local is_selected = list.selected[mark.id] == true
		local status = mark.archived and "ARCH " or (mark.resolved and "FIXED" or "OPEN ")
		local status_hl = mark.archived and "CodeReviewArchived"
			or (mark.resolved and "CodeReviewFixed" or "CodeReviewOpen")
		local start_line = mark_line(mark)
		local end_line = mark_end_line(mark)
		local range = end_line ~= start_line and (start_line .. "-" .. end_line) or tostring(start_line)
		local note = comment_summary(mark.note)
		note = note ~= "" and note or "(no comment)"
		local category_label = category_text(mark)
		local category_padding = string.rep(" ", math.max(1, 18 - vim.fn.strdisplaywidth(category_label)))
		local archived_hl = mark.archived and "CodeReviewArchived" or nil
		local row = add_decorated_line({
			{ "  ", nil },
			{ is_selected and "●" or " ", is_selected and "CodeReviewSelected" or nil },
			{ "  ", nil },
			{ status, status_hl },
			{ "  ", nil },
			{ category_label, archived_hl or category_hl(mark) },
			{ category_padding, nil },
			{ "#" .. mark.id, archived_hl or "CodeReviewId" },
			{ "  L" .. range, archived_hl or "CodeReviewLine" },
			{ "  " .. note, archived_hl or "CodeReviewNote" },
		})
		list.row_marks[row] = mark
		selected_rows[row] = is_selected
	end
	if #lines == 0 then
		add_decorated_line({
			{
				list.show_archived and "  No review issues"
					or "  No active review issues — press i to include archived",
				"CodeReviewHint",
			},
		})
	end

	local cursor = 1
	local win = vim.fn.bufwinid(list.buf)
	if win ~= -1 and is_floating_window(win) then
		vim.api.nvim_win_set_config(win, {
			title = {
				{ " 󰚩 Code Review ", "CodeReviewTitle" },
				{ "· ", "CodeReviewMuted" },
				{ tostring(open_count), "CodeReviewOpen" },
				{ " open · ", "CodeReviewMuted" },
				{ tostring(fixed_count), "CodeReviewFixed" },
				{ " fixed · ", "CodeReviewMuted" },
				{ tostring(archived_count), "CodeReviewArchived" },
				{ " archived ", "CodeReviewMuted" },
			},
			title_pos = "center",
			footer = {
				{ " ↵ ", "CodeReviewKey" },
				{ "jump · ", "CodeReviewHint" },
				{ "Space ", "CodeReviewKey" },
				{ "select · ", "CodeReviewHint" },
				{ "x ", "CodeReviewKey" },
				{ "fixed · ", "CodeReviewHint" },
				{ "e ", "CodeReviewKey" },
				{ "edit · ", "CodeReviewHint" },
				{ "? ", "CodeReviewKey" },
				{ "help · ", "CodeReviewHint" },
				{ "q ", "CodeReviewKey" },
				{ "close ", "CodeReviewHint" },
			},
			footer_pos = "center",
		})
	end
	if win ~= -1 then
		cursor = vim.api.nvim_win_get_cursor(win)[1]
	end
	vim.bo[list.buf].modifiable = true
	vim.api.nvim_buf_set_lines(list.buf, 0, -1, false, lines)
	vim.bo[list.buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(list.buf, list_ns, 0, -1)
	for row, spans in pairs(row_decorations) do
		if selected_rows[row] then
			vim.api.nvim_buf_set_extmark(list.buf, list_ns, row - 1, 0, {
				line_hl_group = "CodeReviewSelectedLine",
				priority = 90,
			})
		end
		for _, span in ipairs(spans) do
			vim.api.nvim_buf_set_extmark(list.buf, list_ns, row - 1, span.start_col, {
				end_col = span.end_col,
				hl_group = span.hl,
				hl_mode = "combine",
				priority = 110,
			})
		end
	end
	if win ~= -1 then
		vim.api.nvim_win_set_cursor(win, { math.min(cursor, #lines), 0 })
	end
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
	else
		if current_win ~= win then
			list.source_win = preferred_source_window(current_win)
		end
		vim.api.nvim_set_current_win(win)
	end
	vim.wo[win].winhighlight = table.concat({
		"NormalFloat:CodeReviewFloat",
		"FloatBorder:CodeReviewBorder",
		"FloatTitle:CodeReviewTitle",
		"CursorLine:CodeReviewCursorLine",
	}, ",")
	vim.wo[win].cursorline = true
	vim.wo[win].wrap = false
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
		kind = "pi_review_issue",
		format_item = format_issue_item,
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
			title = "Edit review #" .. mark.id,
			id = mark.id,
			default = mark.note or "",
			category = category(mark),
			category_editable = true,
		}, function(note, edited_category)
			mark.note = note
			if edited_category then
				mark.category = edited_category.id
			end
			render(mark)
			save()
			render_list()
			vim.notify("Review #" .. mark.id .. " updated", vim.log.levels.INFO)
		end)
	end)
end

local function pick_category(targets)
	if #targets == 0 then
		vim.notify("No review issues selected", vim.log.levels.INFO)
		return
	end
	select_over_review_list(config.categories, {
		prompt = "Change review category",
		kind = "pi_review_category",
		format_item = format_category_item,
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
		local category_word = #targets == 1 and "category" or "categories"
		vim.notify(
			"Changed " .. #targets .. " review issue " .. category_word .. " to " .. selected_category.label,
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
	vim.api.nvim_create_user_command("ReviewEdit", M.edit_comment, { desc = "Edit review issue at cursor" })
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
