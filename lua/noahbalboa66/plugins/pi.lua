local pi_root_options = {
	-- Parent folders whose immediate children can be picked as Pi roots with
	-- :PiRoots / <leader>pl. Add more parent folders here as needed.
	parents = {
		"~/ObsidianVaults/4V2/Workflows",
	},
}

local function default_root()
	local bufname = vim.api.nvim_buf_get_name(0)
	local start = bufname ~= "" and vim.fs.dirname(bufname) or vim.fn.getcwd()
	return vim.fs.root(start, { ".git", "flake.nix", "package.json", "pyproject.toml", "Cargo.toml", "go.mod" })
		or vim.fn.getcwd()
end

local function normalize_dir(path)
	if not path or path == "" then
		return nil
	end
	path = vim.fn.expand(path)
	path = vim.fs.normalize(path)
	if vim.fn.isdirectory(path) ~= 1 then
		vim.notify("Pi root does not exist: " .. path, vim.log.levels.ERROR)
		return nil
	end
	return path
end

local pi_filetypes = {
	["pi-chat-history"] = true,
	["pi-chat-prompt"] = true,
	["pi-chat-attachments"] = true,
}

local function tab_pi_root()
	return vim.t.pi_root or default_root()
end

local function set_win_cwd(win, root)
	local current_win = vim.api.nvim_get_current_win()
	if not vim.api.nvim_win_is_valid(win) then
		return
	end

	vim.api.nvim_set_current_win(win)
	vim.cmd("lcd " .. vim.fn.fnameescape(root))
	if vim.api.nvim_win_is_valid(current_win) then
		vim.api.nvim_set_current_win(current_win)
	end
end

local function sync_pi_window_cwds(root)
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		if pi_filetypes[vim.bo[buf].filetype] then
			set_win_cwd(win, root)
		end
	end
end

local function with_pi_cwd(fn)
	local root = normalize_dir(tab_pi_root())
	if not root then
		return
	end

	local original_win = vim.api.nvim_get_current_win()
	local restore_win = original_win
	local original_cwd = vim.fn.getcwd()

	set_win_cwd(original_win, root)
	local ok, err = pcall(fn, root)
	restore_win = vim.api.nvim_get_current_win()

	if vim.api.nvim_win_is_valid(original_win) then
		vim.api.nvim_set_current_win(original_win)
		vim.cmd("lcd " .. vim.fn.fnameescape(original_cwd))
	end
	if vim.api.nvim_win_is_valid(restore_win) then
		vim.api.nvim_set_current_win(restore_win)
	end

	sync_pi_window_cwds(root)

	if not ok then
		error(err)
	end
end

local function show_pi(opts)
	opts = opts or {}
	with_pi_cwd(function()
		require("pi").show(opts)
	end)
end

local function toggle_pi(opts)
	opts = opts or {}
	with_pi_cwd(function()
		require("pi").toggle(opts)
	end)
end

local function focus_pi_prompt_insert(opts)
	show_pi(opts)
	vim.schedule(function()
		vim.cmd("startinsert")
	end)
end

local function setup_compact_pi_tools()
	local tools = require("pi.ui.chat.tools")
	if tools._noah_compact_blocks then
		return
	end

	-- pi.nvim does not currently expose tool collapse thresholds as options.
	-- Treat every non-inline tool as a compact block while preserving its
	-- built-in <Tab> expansion behavior.
	local get_renderer = tools.get_renderer
	tools.get_renderer = function(tool_name)
		local renderer = get_renderer(tool_name)
		if not renderer.inline then
			renderer.input_visible = 0
			renderer.output_visible = 0
		end
		return renderer
	end

	local build_collapsed_view = tools.build_collapsed_view
	tools.build_collapsed_view = function(
		input_lines,
		output_lines,
		has_output,
		input_visible,
		output_visible,
		max_width
	)
		if input_visible == 0 and output_visible == 0 then
			local detail_count = #input_lines + #output_lines
			local suffix = detail_count == 1 and " detail line" or " detail lines"
			return { " … " .. detail_count .. suffix }, { "summary" }
		end
		return build_collapsed_view(input_lines, output_lines, has_output, input_visible, output_visible, max_width)
	end

	tools._noah_compact_blocks = true
end

local function setup_pi_highlights()
	local function hl_color(group, attr, fallback)
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
		local value = ok and hl[attr] or nil
		return value and string.format("#%06x", value) or fallback
	end

	local normal_bg = hl_color("Normal", "bg", "#111827")
	local normal_fg = hl_color("Normal", "fg", "#d1d5db")
	local alt_bg = hl_color("CursorLine", "bg", hl_color("StatusLine", "bg", normal_bg))

	local palette = {
		bg = normal_bg,
		bg_alt = alt_bg,
		fg = normal_fg,
		muted = hl_color("Comment", "fg", "#6b7280"),
		blue = "#60a5fa",
		cyan = "#22d3ee",
		green = "#34d399",
		yellow = "#fbbf24",
		orange = "#fb923c",
		red = "#f87171",
		purple = "#c084fc",
		pink = "#f472b6",
	}

	local groups = {
		PiFloat = { bg = "NONE", fg = palette.fg },
		PiFloatBorder = { fg = palette.purple, bg = "NONE" },
		PiDialogTitle = { fg = palette.purple, bold = true },
		PiQuestionHeading = { fg = palette.cyan, bold = true },
		PiQuestionLabel = { fg = palette.purple, bold = true },
		PiQuestionSelected = { fg = palette.cyan, bg = palette.bg_alt, bold = true },
		PiQuestionConfirmed = { fg = palette.green, bg = palette.bg_alt, bold = true },
		PiQuestionContext = { fg = palette.fg, bg = palette.bg_alt },
		PiQuestionContextBorder = { fg = palette.muted, bg = "NONE" },
		PiQuestionHint = { fg = palette.muted, bg = palette.bg_alt, italic = true },

		PiChatHistoryWinbar = { bg = palette.bg_alt },
		PiChatHistoryWinbarTitle = { fg = palette.bg, bg = palette.cyan, bold = true },
		PiChatPromptWinbar = { bg = palette.bg_alt },
		PiChatPromptWinbarTitle = { fg = palette.bg, bg = palette.purple, bold = true },
		PiChatPromptWinbarAttentionTitle = { fg = palette.bg, bg = palette.orange, bold = true },
		PiChatAttachmentsWinbar = { bg = palette.bg_alt },
		PiChatAttachmentsWinbarTitle = { fg = palette.bg, bg = palette.green, bold = true },
		PiChatHistoryFloatTitle = { fg = palette.bg, bg = palette.cyan, bold = true },
		PiChatPromptFloatTitle = { fg = palette.bg, bg = palette.purple, bold = true },
		PiChatPromptFloatAttentionTitle = { fg = palette.bg, bg = palette.orange, bold = true },
		PiChatAttachmentsFloatTitle = { fg = palette.bg, bg = palette.green, bold = true },

		PiUserMessageLabel = { fg = palette.bg, bg = palette.blue, bold = true },
		PiAgentResponseLabel = { fg = palette.bg, bg = palette.green, bold = true },
		PiDebugLabel = { fg = palette.bg, bg = palette.muted, bold = true },
		PiStartupLabel = { fg = palette.bg, bg = palette.purple, bold = true },
		PiStartupErrorLabel = { fg = palette.bg, bg = palette.red, bold = true },
		PiCompactionLabel = { fg = palette.bg, bg = palette.yellow, bold = true },
		PiMessageDateTime = { fg = palette.muted, italic = true },
		PiMessageQueueTag = { fg = palette.orange, bold = true },
		PiMessageAttachments = { fg = palette.cyan },
		PiPendingQueueLabel = { fg = palette.orange, bold = true },
		PiPendingQueueText = { fg = palette.yellow },
		PiThinking = { fg = palette.purple, italic = true },
		PiMention = { fg = palette.cyan, bg = palette.bg_alt, bold = true },
		PiCommand = { fg = palette.pink, bold = true },
		PiWelcome = { fg = palette.green, bold = true },
		PiWelcomeHint = { fg = palette.muted, italic = true },
		PiBusy = { fg = palette.yellow, bold = true },
		PiBusyTime = { fg = palette.orange },
		PiWarning = { fg = palette.yellow, bold = true },
		PiError = { fg = palette.red, bold = true },
		PiDebug = { fg = palette.muted },

		PiToolBorder = { fg = palette.purple },
		PiToolHeader = { fg = palette.cyan, bold = true },
		PiToolCall = { fg = palette.blue },
		PiToolOutput = { fg = palette.fg },
		PiToolStatus = { fg = palette.green, bold = true },
		PiToolCollapsed = { fg = palette.muted, italic = true },
		PiToolError = { fg = palette.red },
		PiTableBorder = { fg = palette.purple },
		PiTableHeader = { fg = palette.yellow, bold = true },
		PiDiffLineNr = { fg = palette.muted },

		PiAttachmentIcon = { fg = palette.green },
		PiAttachmentFilename = { fg = palette.cyan, bold = true },
	}

	for group, hl in pairs(groups) do
		vim.api.nvim_set_hl(0, group, hl)
	end
end

local function switch_root(path, opts)
	opts = opts or {}

	local function apply(root)
		root = normalize_dir(root)
		if not root then
			return
		end

		-- pi.nvim scopes sessions/processes to cwd at process start. Keep that
		-- cwd local to Pi windows instead of changing the tab/window used for code.
		vim.t.pi_root = root
		pcall(require("pi").stop)
		sync_pi_window_cwds(root)
		vim.api.nvim_exec_autocmds("User", { pattern = "PiRootChanged" })
		vim.notify("Pi root: " .. root, vim.log.levels.INFO)

		if opts.open then
			show_pi({ layout = opts.layout or "side" })
		end
	end

	if path and path ~= "" then
		apply(path)
		return
	end

	vim.ui.input({ prompt = "Pi root: ", default = default_root(), completion = "dir" }, apply)
end

local function configured_root_parents()
	local parents = {}
	for _, parent in ipairs(pi_root_options.parents or {}) do
		parent = normalize_dir(parent)
		if parent then
			parents[#parents + 1] = parent
		end
	end
	return parents
end

local function child_dirs(base)
	base = normalize_dir(base)
	if not base then
		return {}
	end

	local dirs = {}
	local scan = vim.uv.fs_scandir(base)
	if not scan then
		return dirs
	end

	while true do
		local name, kind = vim.uv.fs_scandir_next(scan)
		if not name then
			break
		end
		if kind == "directory" and not name:match("^%.") then
			dirs[#dirs + 1] = vim.fs.joinpath(base, name)
		end
	end

	table.sort(dirs)
	return dirs
end

local function select_root_from_folder(base, opts)
	opts = opts or {}

	local function select_from(parent)
		parent = normalize_dir(parent)
		if not parent then
			return
		end

		local dirs = child_dirs(parent)
		if #dirs == 0 then
			vim.notify("No child folders found in: " .. parent, vim.log.levels.WARN)
			return
		end

		vim.ui.select(dirs, {
			prompt = "Pi root under " .. parent,
			format_item = function(item)
				return vim.fn.fnamemodify(item, ":t") .. "  " .. item
			end,
		}, function(choice)
			if choice then
				switch_root(choice, opts)
			end
		end)
	end

	if base and base ~= "" then
		select_from(base)
		return
	end

	local parents = configured_root_parents()
	if #parents == 1 then
		select_from(parents[1])
		return
	end

	if #parents > 1 then
		vim.ui.select(parents, {
			prompt = "List Pi roots under:",
			format_item = function(item)
				return vim.fn.fnamemodify(item, ":~")
			end,
		}, function(parent)
			if parent then
				select_from(parent)
			end
		end)
		return
	end

	vim.ui.input({
		prompt = "List Pi roots under: ",
		default = vim.env.PI_ROOTS_DIR or vim.fs.dirname(default_root()),
		completion = "dir",
	}, select_from)
end

return {
	"alex35mil/pi.nvim",

	-- Optional: required only for `:PiPasteImage` (clipboard image paste).
	dependencies = { "HakonHarnes/img-clip.nvim", "folke/snacks.nvim" },

	cmd = {
		"Pi",
		"PiContinue",
		"PiResume",
		"PiToggleChat",
		"PiToggleLayout",
		"PiAbort",
		"PiStop",
		"PiAttention",
		"PiNewSession",
		"PiCompact",
		"PiSessionName",
		"PiToggleDebug",
		"PiSendMention",
		"PiCode",
		"PiRoot",
		"PiRoots",
	},

	keys = {
		{
			"<leader>pt",
			function()
				toggle_pi()
			end,
			desc = "Pi: toggle chat",
		},
		{
			"<leader>pi",
			function()
				focus_pi_prompt_insert()
			end,
			desc = "Pi: focus prompt (insert)",
		},
		{
			"<leader>po",
			function()
				local pi = require("pi")
				show_pi()

				-- Pi schedules prompt focus and insert mode while opening. Move to
				-- history on the following UI turn so this wins in both layouts.
				vim.schedule(function()
					pi.focus_chat_history()
					vim.schedule(function()
						pi.focus_chat_history()
						vim.cmd("stopinsert")
					end)
				end)
			end,
			desc = "Pi: focus output (normal)",
		},
		{
			"<leader>pf",
			function()
				show_pi({ layout = "float" })
			end,
			desc = "Pi: float chat",
		},
		{
			"<leader>ps",
			function()
				show_pi({ layout = "side" })
			end,
			desc = "Pi: side chat",
		},
		{ "<leader>pn", "<cmd>PiNewSession<cr>", desc = "Pi: new session" },
		{ "<leader>pc", "<cmd>PiContinue<cr>", desc = "Pi: continue cwd session" },
		{ "<leader>pR", "<cmd>PiResume<cr>", desc = "Pi: resume cwd session" },
		{ "<leader>pr", "<cmd>PiRoot<cr>", desc = "Pi: switch tab root" },
		{ "<leader>pl", "<cmd>PiRoots<cr>", desc = "Pi: list roots in folder" },
		{
			"<leader>pg",
			function()
				switch_root(default_root(), { open = true })
			end,
			desc = "Pi: use project root",
		},
		{
			"<leader>pa",
			function()
				if not require("noahbalboa66.pi_question_dialog").toggle() then
					require("pi.attention").open_next_for_tab(0)
				end
			end,
			desc = "Pi: toggle current session question / attention",
		},
		{
			"<leader>pb",
			function()
				require("pi").toggle_history_blocks()
			end,
			desc = "Pi: toggle history blocks",
		},
		{
			"<leader>pv",
			function()
				require("noahbalboa66.pi_code_picker").pick()
			end,
			desc = "Pi: pick fenced code",
		},
		{ "<leader>pS", "<cmd>PiStop<cr>", desc = "Pi: stop" },
	},

	config = function()
		local pi = require("pi")
		setup_compact_pi_tools()

		local ask_user_extension = vim.fs.joinpath(vim.fn.stdpath("config"), "pi-extensions", "ask-user.ts")

		pi.setup({
			cli = {
				bin = "pi",
				args = {
					"--provider",
					"openai-codex",
					"--model",
					"gpt-5.6-sol",
					"--thinking",
					"high",
					-- The installed rich-form extension uses ctx.ui.custom(), which
					-- cannot be displayed through Pi's RPC mode. Use the local
					-- built-in-dialog tool so questions participate in attention.
					"--exclude-tools",
					"ask_user_question",
					"--extension",
					ask_user_extension,
				},
			},
			models = {
				{ match = "gpt-5.6-sol", exact = true },
			},
			panels = {
				history = { title = " 󰚩 π Chat " },
				prompt = { title = " 󰘧 Prompt " },
				attachments = { title = "  Attachments " },
			},
			labels = {
				user_message = "  You ",
				agent_response = " 󰚩 Pi ",
				system_error = "  Error ",
				tool = "  Tool ",
				tool_success = "  Done ",
				tool_failure = "  Failed ",
				steer_message = "  Steer ",
				follow_up_message = "  Follow-up ",
				thinking = " 󰟶 Thinking ",
				compaction = " 󰏗 Summary ",
				attachment = "  ",
				attachments = "  Attachments ",
				error = "  ",
			},
			layout = {
				default = "side",
				side = {
					position = "right",
					width = 90,
				},
				float = {
					width = 0.72,
					height = 0.82,
					border = "rounded",
				},
			},
			expand_startup_details = false,
			attention = {
				auto_open_on_prompt_focus = true,
				notify_on_completion = true,
			},
			statusline = {
				components = {
					attention = { counter = true },
				},
			},
			diff = {
				keymap_hints = "dialog",
			},
			dialog = {
				border = "rounded",
			},
			zen = {
				keys = {
					toggle = { "<M-z>", modes = { "n", "i" } },
					exit = { "q", modes = { "n" } },
				},
			},
		})

		require("noahbalboa66.pi_question_dialog").setup()
		vim.api.nvim_create_user_command("PiCode", function()
			require("noahbalboa66.pi_code_picker").pick()
		end, { desc = "Pick fenced code blocks from the active Pi conversation" })
		setup_pi_highlights()
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = setup_pi_highlights,
			desc = "Reapply colorful pi.nvim highlights",
		})

		local Prompt = require("pi.ui.chat.prompt")
		Prompt.focus = function(self, cb)
			local win = self:win()
			if not win then
				return
			end
			vim.api.nvim_set_current_win(win)
			if cb then
				vim.schedule(cb)
			end
		end

		vim.api.nvim_create_autocmd("FileType", {
			pattern = vim.tbl_keys(pi_filetypes),
			callback = function(event)
				local root = normalize_dir(tab_pi_root())
				if root then
					set_win_cwd(vim.fn.bufwinid(event.buf), root)
				end
			end,
		})

		vim.api.nvim_create_user_command("PiRoot", function(args)
			switch_root(args.args, { open = args.bang })
		end, {
			nargs = "?",
			bang = true,
			complete = "dir",
			desc = "Switch this tab's cwd/root for pi.nvim; use ! to reopen Pi afterward",
		})

		vim.api.nvim_create_user_command("PiRoots", function(args)
			select_root_from_folder(args.args, { open = args.bang })
		end, {
			nargs = "?",
			bang = true,
			complete = "dir",
			desc = "Pick a Pi root from child folders of a parent folder; use ! to reopen Pi afterward",
		})
	end,
}
