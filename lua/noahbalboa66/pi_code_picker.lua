local M = {}

local filetype_aliases = {
	bash = "sh",
	["c++"] = "cpp",
	console = "text",
	csharp = "cs",
	cs = "cs",
	javascript = "javascript",
	js = "javascript",
	jsx = "javascriptreact",
	markdown = "markdown",
	md = "markdown",
	plaintext = "text",
	python = "python",
	py = "python",
	ruby = "ruby",
	rb = "ruby",
	rust = "rust",
	rs = "rust",
	shell = "sh",
	sh = "sh",
	text = "text",
	tsx = "typescriptreact",
	typescript = "typescript",
	ts = "typescript",
	yaml = "yaml",
	yml = "yaml",
}

local function language_from_info(info)
	info = vim.trim(info or "")
	local language = info:match("^([^%s]+)") or "text"
	language = language:match("^{%s*%.([%w_+%-]+)") or language
	language = language:gsub("^[{.]", ""):gsub("[},].*$", "")
	language = language:match("^([%w_+%-%.]+)") or "text"
	return language:lower()
end

local function fence_start(line)
	local indent, marker, info = line:match("^(%s*)(`+)(.*)$")
	if not marker then
		indent, marker, info = line:match("^(%s*)(~+)(.*)$")
	end
	if not marker or #indent > 3 or indent:find("\t", 1, true) or #marker < 3 then
		return nil
	end
	if marker:sub(1, 1) == "`" and info:find("`", 1, true) then
		return nil
	end
	return marker:sub(1, 1), #marker, info
end

local function fence_end(line, marker_char, marker_length)
	local indent, marker = line:match("^(%s*)(`+)%s*$")
	if marker_char == "~" then
		indent, marker = line:match("^(%s*)(~+)%s*$")
	end
	return marker ~= nil and #indent <= 3 and not indent:find("\t", 1, true) and #marker >= marker_length
end

---@param markdown string
---@return table[]
function M.extract_fences(markdown)
	local lines = vim.split(markdown or "", "\n", { plain = true })
	local blocks = {}
	local current = nil

	for _, line in ipairs(lines) do
		if current then
			if fence_end(line, current.marker_char, current.marker_length) then
				current.code = table.concat(current.lines, "\n")
				current.line_count = #current.lines
				current.lines = nil
				current.marker_char = nil
				current.marker_length = nil
				blocks[#blocks + 1] = current
				current = nil
			else
				current.lines[#current.lines + 1] = line
			end
		else
			local marker_char, marker_length, info = fence_start(line)
			if marker_char then
				current = {
					language = language_from_info(info),
					info = vim.trim(info or ""),
					marker_char = marker_char,
					marker_length = marker_length,
					lines = {},
				}
			end
		end
	end

	return blocks
end

local function text_parts(message)
	if type(message.content) == "string" then
		return { message.content }
	end
	if type(message.content) ~= "table" then
		return {}
	end

	local parts = {}
	for _, part in ipairs(message.content) do
		if type(part) == "string" then
			parts[#parts + 1] = part
		elseif type(part) == "table" and part.type == "text" and type(part.text) == "string" then
			parts[#parts + 1] = part.text
		end
	end
	return parts
end

local function summary(code)
	for line in (code .. "\n"):gmatch("(.-)\n") do
		line = vim.trim(line):gsub("%s+", " ")
		if line ~= "" then
			if vim.fn.strchars(line) > 90 then
				return vim.fn.strcharpart(line, 0, 89) .. "…"
			end
			return line
		end
	end
	return "(empty code block)"
end

local function timestamp_text(timestamp)
	if type(timestamp) == "number" then
		return os.date("%b %d %H:%M", math.floor(timestamp / 1000))
	end
	if type(timestamp) == "string" then
		local date, time = timestamp:match("^(%d%d%d%d%-%d%d%-%d%d)T(%d%d:%d%d)")
		if date then
			return date .. " " .. time
		end
	end
	return "unknown time"
end

local function snippets_from_messages(messages)
	local snippets = {}
	for message_index = #messages, 1, -1 do
		local message = messages[message_index]
		if type(message) == "table" and message.role == "assistant" then
			local message_blocks = {}
			for _, text in ipairs(text_parts(message)) do
				vim.list_extend(message_blocks, M.extract_fences(text))
			end
			for block_index = #message_blocks, 1, -1 do
				local block = message_blocks[block_index]
				block.timestamp = message.timestamp
				block.provider = message.provider
				block.model = message.model
				block.block_index = block_index
				snippets[#snippets + 1] = block
			end
		end
	end
	return snippets
end

local function active_branch(entries, leaf_id)
	local by_id = {}
	for _, entry in ipairs(entries) do
		if type(entry) == "table" and entry.id then
			by_id[entry.id] = entry
		end
	end

	local branch = {}
	local entry = by_id[leaf_id]
	local seen = {}
	while entry and not seen[entry.id] do
		seen[entry.id] = true
		table.insert(branch, 1, entry)
		entry = entry.parentId and by_id[entry.parentId] or nil
	end
	return branch
end

local function snippets_from_entries(entries, leaf_id)
	local messages = {}
	for _, entry in ipairs(active_branch(entries, leaf_id)) do
		if entry.type == "message" and type(entry.message) == "table" then
			local message = vim.deepcopy(entry.message)
			message.timestamp = message.timestamp or entry.timestamp
			messages[#messages + 1] = message
		end
	end
	return snippets_from_messages(messages)
end

local function filetype(language)
	return filetype_aliases[language] or language
end

local function picker_items(snippets)
	local items = {}
	for index, snippet in ipairs(snippets) do
		local ft = filetype(snippet.language)
		local model = snippet.model or "unknown model"
		items[#items + 1] = {
			idx = index,
			text = table.concat({ snippet.language, snippet.info, model, snippet.code }, " "),
			code = snippet.code,
			language = snippet.language,
			ft = ft,
			line_count = snippet.line_count,
			summary = summary(snippet.code),
			when = timestamp_text(snippet.timestamp),
			model = model,
			provider = snippet.provider,
			block_index = snippet.block_index,
			preview = {
				text = snippet.code,
				ft = ft,
				loc = false,
			},
		}
	end
	return items
end

local function show_picker(snippets)
	if #snippets == 0 then
		vim.notify("No fenced code blocks in the active Pi conversation", vim.log.levels.INFO)
		return
	end

	local items = picker_items(snippets)
	Snacks.picker({
		title = "Pi Code",
		focus = "list",
		on_show = function(picker)
			vim.cmd("stopinsert")
			picker:focus("list", { show = true })
		end,
		layout = {
			layout = {
				box = "horizontal",
				width = 0.65,
				min_width = 80,
				height = 0.55,
				{
					box = "vertical",
					border = true,
					title = "{title} {live} {flags}",
					{ win = "input", height = 1, border = "bottom" },
					{ win = "list", border = "none" },
				},
				{ win = "preview", title = "{preview:Code}", border = true, width = 0.55 },
			},
		},
		finder = function()
			return items
		end,
		format = function(item)
			return {
				{ string.format("%-13s", "[" .. item.language .. "]"), "Special" },
				{ item.summary },
			}
		end,
		preview = function(ctx)
			Snacks.picker.preview.preview(ctx)
			ctx.preview:set_title("Code [" .. ctx.item.language .. "]")
		end,
		confirm = "focus_code_preview",
		actions = {
			focus_code_preview = function(picker)
				vim.cmd("stopinsert")
				picker:focus("preview", { show = true })
			end,
			yank_code = function(picker, item)
				if item then
					vim.fn.setreg('"', item.code, "v")
				end
				picker:close()
			end,
			yank_preview_selection = function(picker)
				local mode = vim.fn.mode()
				local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
				vim.fn.setreg('"', lines, mode)
				picker:close()
			end,
		},
		win = {
			list = {
				keys = {
					["y"] = "yank_code",
				},
			},
			preview = {
				keys = {
					["<c-h>"] = "focus_list",
					["y"] = { "yank_preview_selection", mode = "x" },
				},
			},
		},
	})
end

local function request_messages(session, reason)
	session.rpc:send({ type = "get_messages" }, function(response)
		vim.schedule(function()
			if not response.success then
				vim.notify(reason or response.error or "Failed to read Pi messages", vim.log.levels.ERROR)
				return
			end
			show_picker(snippets_from_messages((response.data or {}).messages or {}))
		end)
	end)
end

function M.pick()
	local ok, manager = pcall(require, "pi.sessions.manager")
	local session = ok and manager.get() or nil
	if not session or not session.rpc:is_running() then
		vim.notify("No active Pi session in this tab", vim.log.levels.WARN)
		return
	end

	local sent = session.rpc:send({ type = "get_entries" }, function(response)
		vim.schedule(function()
			if response.success then
				local data = response.data or {}
				show_picker(snippets_from_entries(data.entries or {}, data.leafId))
			else
				request_messages(session, response.error)
			end
		end)
	end)
	if not sent then
		vim.notify("Failed to request the active Pi conversation", vim.log.levels.ERROR)
	end
end

M._snippets_from_entries = snippets_from_entries
M._snippets_from_messages = snippets_from_messages

return M
