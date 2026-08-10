local M = {}

local PAYLOAD_PREFIX = "pi.nvim:ask-user:"
local selection_ns = vim.api.nvim_create_namespace("pi-question-selection")
local decoration_ns = vim.api.nvim_create_namespace("pi-question-decoration")
local answer_placeholder_ns = vim.api.nvim_create_namespace("pi-question-answer-placeholder")
local context_placeholder_ns = vim.api.nvim_create_namespace("pi-question-context-placeholder")
local active_questions = {}

local function decode_payload(message)
	if type(message) ~= "string" or message:sub(1, #PAYLOAD_PREFIX) ~= PAYLOAD_PREFIX then
		return nil
	end
	local ok, payload = pcall(vim.json.decode, message:sub(#PAYLOAD_PREFIX + 1))
	if not ok or type(payload) ~= "table" or type(payload.question) ~= "string" then
		return nil
	end
	return payload
end

local function wrap_text(text, width)
	local wrapped = {}
	for _, paragraph in ipairs(vim.split(text, "\n", { plain = true })) do
		if paragraph == "" then
			wrapped[#wrapped + 1] = ""
		else
			local line = ""
			for word in paragraph:gmatch("%S+") do
				local candidate = line == "" and word or (line .. " " .. word)
				if line ~= "" and vim.fn.strdisplaywidth(candidate) > width then
					wrapped[#wrapped + 1] = line
					line = word
				else
					line = candidate
				end
			end
			wrapped[#wrapped + 1] = line
		end
	end
	return wrapped
end

local function buffer_text(buf)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return ""
	end
	return vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
end

local function refresh_indicators(tab)
	vim.schedule(function()
		pcall(vim.cmd, "redrawstatus!")
		pcall(vim.cmd, "redrawtabline")
		local ok, manager = pcall(require, "pi.sessions.manager")
		if ok then
			for _, session in ipairs(manager.list()) do
				if session.tab == tab then
					pcall(function()
						session.chat:render_statusline()
						session.chat:refresh_prompt_attention()
					end)
				end
			end
		end
		pcall(vim.api.nvim_exec_autocmds, "User", {
			pattern = "PiQuestionChanged",
			modeline = false,
			data = { tab = tab },
		})
	end)
end

local function open_question(payload, options, callback)
	local question_tab = vim.api.nvim_get_current_tabpage()
	local was_insert = vim.fn.mode():match("^i") ~= nil
	local is_choices = payload.kind ~= "freeform"
	local multiple = is_choices and payload.multiple == true
	local multiline = not is_choices and payload.multiline == true
	local editor_height = vim.o.lines - vim.o.cmdheight
	local width_cap = math.max(1, vim.o.columns - 6)
	local width = math.min(math.max(60, math.floor(vim.o.columns * 0.72)), width_cap)
	local content_width = math.max(20, width - 10)

	local lines = { "    󰋗  Question", "" }
	for _, line in ipairs(wrap_text(payload.question, content_width)) do
		lines[#lines + 1] = "    " .. line
	end
	lines[#lines + 1] = ""

	local answer_label_row
	local answer_area_start
	local option_start
	if is_choices then
		lines[#lines + 1] = multiple and "    󰄬  Suggested answers (optional — choose one or more)"
			or "    󰄬  Suggested answers (optional — choose one)"
		answer_label_row = #lines - 1
		option_start = #lines + 1
		for _, option in ipairs(options) do
			lines[#lines + 1] = "        " .. option
		end
	else
		lines[#lines + 1] = "    󰄬  Answer"
		answer_label_row = #lines - 1
		answer_area_start = #lines + 1
		for _ = 1, (multiline and 7 or 4) do
			lines[#lines + 1] = ""
		end
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = "    󰦨  Context or custom response (optional)"
	local context_label_row = #lines - 1
	local context_area_start = #lines + 1
	for _ = 1, 6 do
		lines[#lines + 1] = ""
	end

	local outer_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(outer_buf, 0, -1, false, lines)
	vim.bo[outer_buf].buftype = "nofile"
	vim.bo[outer_buf].bufhidden = "hide"
	vim.bo[outer_buf].swapfile = false
	vim.bo[outer_buf].filetype = "pi-question-dialog"
	vim.bo[outer_buf].modifiable = false

	local height_cap = math.max(1, editor_height - 4)
	local max_height = math.max(1, math.min(math.floor(editor_height * 0.82), height_cap))
	local height = math.max(1, math.min(#lines, max_height))
	local footer = is_choices and " Space select · Tab context · ^S send · Esc normal/hide · q hide "
		or " Tab switch · ^S send · Esc normal/hide · q hide "
	local outer_win

	local function open_outer_window()
		outer_win = vim.api.nvim_open_win(outer_buf, true, {
			relative = "editor",
			row = math.max(0, math.floor((editor_height - height) / 2)),
			col = math.max(0, math.floor((vim.o.columns - width) / 2)),
			width = width,
			height = height,
			style = "minimal",
			border = "rounded",
			title = " 󰚩  Pi needs your input ",
			title_pos = "center",
			footer = footer,
			footer_pos = "center",
		})
		vim.wo[outer_win].winhighlight = require("pi.ui.highlights").DIALOG_WINHIGHLIGHT
		vim.wo[outer_win].signcolumn = "yes"
		vim.wo[outer_win].cursorline = false
		vim.wo[outer_win].wrap = true
		vim.wo[outer_win].linebreak = true
		vim.wo[outer_win].breakindent = true
	end

	local return_win = vim.api.nvim_get_current_win()
	open_outer_window()

	vim.api.nvim_buf_add_highlight(outer_buf, decoration_ns, "PiQuestionHeading", 0, 0, -1)
	vim.api.nvim_buf_add_highlight(outer_buf, decoration_ns, "PiQuestionLabel", answer_label_row, 0, -1)
	vim.api.nvim_buf_add_highlight(outer_buf, decoration_ns, "PiQuestionLabel", context_label_row, 0, -1)

	local function open_input_window(buf, row, window_height)
		local win = vim.api.nvim_open_win(buf, false, {
			relative = "win",
			win = outer_win,
			row = row - 1,
			col = 3,
			width = math.max(20, width - 8),
			height = window_height,
			style = "minimal",
			border = "rounded",
			zindex = 70,
		})
		vim.wo[win].winhighlight = table.concat({
			"NormalFloat:PiQuestionContext",
			"FloatBorder:PiQuestionContextBorder",
		}, ",")
		vim.wo[win].wrap = true
		vim.wo[win].linebreak = true
		vim.wo[win].breakindent = true
		vim.wo[win].scrolloff = 0
		return win
	end

	local function create_input_window(row, window_height, filetype)
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].bufhidden = "hide"
		vim.bo[buf].swapfile = false
		vim.bo[buf].filetype = filetype
		return buf, open_input_window(buf, row, window_height)
	end

	local answer_buf, answer_win
	if not is_choices then
		answer_buf, answer_win = create_input_window(answer_area_start, multiline and 5 or 1, "pi-question-answer")
	end
	local context_buf, context_win = create_input_window(context_area_start, 3, "pi-question-context")

	local hovered = 1
	local chosen = {}
	local state = "visible"
	local focus_target = is_choices and "options" or "answer"
	local question_state

	local function update_placeholder(buf, namespace, placeholder)
		if not buf or not vim.api.nvim_buf_is_valid(buf) then
			return
		end
		vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
		if buffer_text(buf) == "" then
			vim.api.nvim_buf_set_extmark(buf, namespace, 0, 0, {
				virt_text = { { " " .. placeholder, "PiQuestionHint" } },
				virt_text_pos = "overlay",
				strict = false,
			})
		end
	end

	local function update_placeholders()
		if answer_buf then
			update_placeholder(answer_buf, answer_placeholder_ns, payload.placeholder or "Type your answer")
		end
		update_placeholder(context_buf, context_placeholder_ns, "Add context, a custom response, or leave blank")
	end

	local function render_choices()
		if not is_choices or not vim.api.nvim_buf_is_valid(outer_buf) then
			return
		end
		vim.api.nvim_buf_clear_namespace(outer_buf, selection_ns, 0, -1)
		for index = 1, #options do
			local is_hovered = index == hovered
			local is_chosen = chosen[index] == true
			if is_hovered or is_chosen then
				local row = option_start + index - 2
				vim.api.nvim_buf_set_extmark(outer_buf, selection_ns, row, 0, {
					line_hl_group = is_chosen and "PiQuestionConfirmed" or "PiQuestionSelected",
					sign_text = is_chosen and "✓" or "▸",
					sign_hl_group = is_chosen and "PiQuestionConfirmed" or "PiDialogSelected",
				})
			end
		end
	end

	local function close_windows()
		local windows = { context_win }
		if answer_win then
			windows[#windows + 1] = answer_win
		end
		windows[#windows + 1] = outer_win
		for _, win in ipairs(windows) do
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end
	end

	local function close(value)
		if state == "finished" then
			return
		end
		state = "finished"
		if active_questions[question_tab] == question_state then
			active_questions[question_tab] = nil
			refresh_indicators(question_tab)
		end
		vim.cmd("stopinsert")
		close_windows()
		local buffers = { context_buf }
		if answer_buf then
			buffers[#buffers + 1] = answer_buf
		end
		buffers[#buffers + 1] = outer_buf
		for _, buf in ipairs(buffers) do
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end
		vim.schedule(function()
			callback(value)
			if was_insert then
				vim.cmd("startinsert")
			end
		end)
	end

	local function submit()
		local context = buffer_text(context_buf)
		local answers = {}
		if is_choices then
			for index, option in ipairs(options) do
				if chosen[index] then
					answers[#answers + 1] = option
				end
			end
			if #answers == 0 and context == "" then
				vim.notify(
					"Choose an answer or enter context before sending",
					vim.log.levels.WARN,
					{ title = "Pi question" }
				)
				return
			end
			close(vim.json.encode({ answers = answers, context = context }))
		else
			local answer = buffer_text(answer_buf)
			if answer == "" and context == "" then
				vim.notify("Enter an answer or context before sending", vim.log.levels.WARN, { title = "Pi question" })
				return
			end
			close(vim.json.encode({ answer = answer, context = context }))
		end
	end

	local function focus_input(win, target)
		if not win or not vim.api.nvim_win_is_valid(win) then
			return
		end
		focus_target = target
		vim.api.nvim_set_current_win(win)
		local buf = vim.api.nvim_win_get_buf(win)
		local input_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local row = math.max(1, #input_lines)
		local line = input_lines[row] or ""
		vim.api.nvim_win_set_cursor(win, { row, #line })
		vim.cmd("startinsert!")
	end

	local function focus_options()
		focus_target = "options"
		vim.cmd("stopinsert")
		vim.api.nvim_set_current_win(outer_win)
		vim.api.nvim_win_set_cursor(outer_win, { option_start + hovered - 1, 0 })
		render_choices()
	end

	local function focus_answer()
		focus_input(answer_win, "answer")
	end

	local function focus_context()
		focus_input(context_win, "context")
	end

	local function restore_focus()
		if focus_target == "context" then
			focus_context()
		elseif focus_target == "answer" then
			focus_answer()
		else
			focus_options()
		end
	end

	local watch_windows

	local function hide()
		if state ~= "visible" then
			return false
		end
		state = "hidden"
		vim.cmd("stopinsert")
		close_windows()
		if return_win and vim.api.nvim_win_is_valid(return_win) then
			vim.api.nvim_set_current_win(return_win)
		end
		return true
	end

	local function show()
		if state ~= "hidden" then
			return false
		end
		return_win = vim.api.nvim_get_current_win()
		open_outer_window()
		if answer_buf then
			answer_win = open_input_window(answer_buf, answer_area_start, multiline and 5 or 1)
		end
		context_win = open_input_window(context_buf, context_area_start, 3)
		state = "visible"
		update_placeholders()
		render_choices()
		watch_windows()
		vim.schedule(function()
			if state == "visible" then
				restore_focus()
			end
		end)
		return true
	end

	local function move(delta)
		hovered = math.max(1, math.min(#options, hovered + delta))
		vim.api.nvim_win_set_cursor(outer_win, { option_start + hovered - 1, 0 })
		render_choices()
	end

	local function choose_hovered()
		if multiple then
			chosen[hovered] = not chosen[hovered] or nil
		elseif chosen[hovered] then
			chosen = {}
		else
			chosen = { [hovered] = true }
		end
		render_choices()
	end

	local function insert_newline(win, buf)
		local cursor = vim.api.nvim_win_get_cursor(win)
		local row, col = cursor[1], cursor[2]
		local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
		vim.api.nvim_buf_set_lines(buf, row - 1, row, false, {
			line:sub(1, col),
			line:sub(col + 1),
		})
		vim.api.nvim_win_set_cursor(win, { row + 1, 0 })
	end

	local function map(buf, mode, key, action, desc)
		vim.keymap.set(mode, key, action, { buffer = buf, silent = true, nowait = true, desc = desc })
	end

	if is_choices then
		map(outer_buf, "n", "<Tab>", focus_context, "Question: edit context")
		map(outer_buf, "n", "<CR>", function()
			choose_hovered()
			if not multiple then
				focus_context()
			end
		end, "Question: select answer")
		map(outer_buf, "n", "<Space>", choose_hovered, "Question: toggle answer")
		map(outer_buf, "n", "i", focus_context, "Question: edit context")
		map(outer_buf, "n", "a", focus_context, "Question: edit context")
		map(outer_buf, "n", "j", function()
			move(1)
		end, "Question: next answer")
		map(outer_buf, "n", "<Down>", function()
			move(1)
		end, "Question: next answer")
		map(outer_buf, "n", "k", function()
			move(-1)
		end, "Question: previous answer")
		map(outer_buf, "n", "<Up>", function()
			move(-1)
		end, "Question: previous answer")
		for index = 1, math.min(#options, 9) do
			map(outer_buf, "n", tostring(index), function()
				hovered = index
				choose_hovered()
				if not multiple then
					focus_context()
				end
			end, "Question: toggle answer " .. index)
		end
		map(context_buf, { "n", "i" }, "<Tab>", focus_options, "Question: choose answer")
	else
		map(answer_buf, { "n", "i" }, "<Tab>", focus_context, "Question: edit context")
		map(context_buf, { "n", "i" }, "<Tab>", focus_answer, "Question: edit answer")
		if not multiline then
			map(answer_buf, "i", "<CR>", focus_context, "Question: confirm answer")
			map(answer_buf, "n", "<CR>", focus_context, "Question: confirm answer")
		end
		map(answer_buf, "i", "<S-CR>", function()
			insert_newline(answer_win, answer_buf)
		end, "Question: new answer line")
	end

	for _, buf in ipairs({ outer_buf, context_buf, answer_buf }) do
		if buf then
			map(buf, { "n", "i" }, "<C-s>", submit, "Question: submit")
			map(buf, "n", "q", hide, "Question: hide")
		end
	end
	map(outer_buf, "n", "<Esc>", hide, "Question: hide")
	map(context_buf, "i", "<CR>", submit, "Question: submit")
	map(context_buf, "n", "<CR>", submit, "Question: submit")
	map(context_buf, "i", "<S-CR>", function()
		insert_newline(context_win, context_buf)
	end, "Question: new context line")
	map(context_buf, "n", "<Esc>", hide, "Question: hide")
	if answer_buf then
		map(answer_buf, "n", "<Esc>", hide, "Question: hide")
	end

	for _, buf in ipairs({ context_buf, answer_buf }) do
		if buf then
			vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
				buffer = buf,
				callback = update_placeholders,
			})
		end
	end
	watch_windows = function()
		local watched_windows = { tostring(outer_win), tostring(context_win) }
		if answer_win then
			watched_windows[#watched_windows + 1] = tostring(answer_win)
		end
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = watched_windows,
			once = true,
			callback = function()
				if state == "visible" then
					hide()
				end
			end,
		})
	end

	question_state = {
		hide = hide,
		show = show,
		is_visible = function()
			return state == "visible"
		end,
	}
	active_questions[question_tab] = question_state
	refresh_indicators(question_tab)
	watch_windows()
	update_placeholders()
	render_choices()
	vim.schedule(function()
		if not vim.api.nvim_win_is_valid(outer_win) then
			return
		end
		if is_choices then
			focus_options()
		else
			focus_answer()
		end
	end)
end

local function resolve_tab(tab)
	if tab == nil or tab == 0 then
		return vim.api.nvim_get_current_tabpage()
	end
	return tab
end

function M.count(tab)
	return active_questions[resolve_tab(tab)] and 1 or 0
end

function M.total_count()
	local count = 0
	for tab in pairs(active_questions) do
		if vim.api.nvim_tabpage_is_valid(tab) then
			count = count + 1
		end
	end
	return count
end

function M.has_pending(tab)
	return M.count(tab) > 0
end

local function current_question()
	return active_questions[resolve_tab(0)]
end

function M.toggle()
	local question = current_question()
	if not question then
		return false
	end
	if question.is_visible() then
		question.hide()
	else
		question.show()
	end
	return true
end

function M.show()
	local question = current_question()
	return question ~= nil and question.show() or false
end

function M.hide()
	local question = current_question()
	return question ~= nil and question.hide() or false
end

function M.setup()
	local attention = require("pi.attention")
	local base_count = attention._noah_question_base_count or attention.count
	local base_total_count = attention._noah_question_base_total_count or attention.total_count
	attention._noah_question_base_count = base_count
	attention._noah_question_base_total_count = base_total_count
	attention.count = function(tab)
		return base_count(tab) + M.count(tab)
	end
	attention.total_count = function()
		return base_total_count() + M.total_count()
	end

	local dialog = require("pi.ui.dialog")
	local select = dialog._noah_question_base_select or dialog.select
	dialog._noah_question_base_select = select
	dialog.select = function(opts, callback)
		local payload = decode_payload(opts.message)
		if payload and type(opts.options) == "table" and #opts.options > 0 then
			open_question(payload, opts.options, callback)
			return
		end
		select(opts, callback)
	end
	dialog._noah_combined_question = true
end

return M
