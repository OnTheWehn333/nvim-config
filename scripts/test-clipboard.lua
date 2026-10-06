-- Run from the repository root: nvim --headless -u NONE -l scripts/test-clipboard.lua
local cases = {
	{ name = "local", env = {} },
	{ name = "SSH terminal", env = { SSH_TTY = "/dev/pts/1" }, remote = true },
	{ name = "SSH connection", env = { SSH_CONNECTION = "test" }, remote = true },
	{ name = "WSL without SSH variables", env = { WSL_DISTRO_NAME = "NixOS" }, remote = true },
}

-- Capture terminal output without changing the real clipboard.
local emitted = {}
vim.api.nvim_ui_send = function(sequence)
	table.insert(emitted, sequence)
end

for _, case in ipairs(cases) do
	for _, key in ipairs({ "SSH_TTY", "SSH_CONNECTION", "WSL_DISTRO_NAME" }) do
		vim.env[key] = case.env[key]
	end
	vim.g.clipboard = nil
	dofile("lua/noahbalboa66/opts.lua")

	if case.remote then
		assert(type(vim.g.clipboard) == "table", case.name .. ": missing clipboard override")
		assert(vim.fn["provider#clipboard#Executable"]() == "OSC 52", case.name .. ": wrong provider")
		for reg, selection in pairs({ ["+"] = "c", ["*"] = "p" }) do
			emitted = {}
			vim.fn.setreg(reg, "akkala clipboard test", "v")
			local expected = "\027]52;" .. selection .. ";" .. vim.base64.encode("akkala clipboard test") .. "\027\\"
			assert(#emitted == 1 and emitted[1] == expected, case.name .. ": register did not emit OSC 52")
		end
	else
		assert(vim.g.clipboard == nil, "local clipboard provider must stay automatic")
	end
	print("PASS: " .. case.name)
end
