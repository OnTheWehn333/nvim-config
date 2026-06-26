return {
	"mfussenegger/nvim-dap",
	config = function()
		local dap = require("dap")

		dap.adapters.ruby = function(callback, config)
			if config.request == "attach" then
				callback({
					type = "server",
					host = config.host or "127.0.0.1",
					port = config.port or 38698,
				})
				return
			end

			local args = {
				"-n",
				"-i",
				"--open",
				"--port",
				"${port}",
				"-c",
				"--",
				config.command or "ruby",
			}
			vim.list_extend(args, config.command_args or { "${file}" })

			callback({
				type = "server",
				host = "127.0.0.1",
				port = "${port}",
				executable = {
					command = "rdbg",
					args = args,
				},
			})
		end

		dap.configurations.ruby = {
			{
				type = "ruby",
				request = "launch",
				name = "Debug current Ruby file",
				command = "ruby",
				command_args = { "${file}" },
			},
			{
				type = "ruby",
				request = "launch",
				name = "Debug Rails server",
				command = "bundle",
				command_args = { "exec", "rails", "server" },
			},
			{
				type = "ruby",
				request = "attach",
				name = "Attach to rdbg",
				host = "127.0.0.1",
				port = function()
					return tonumber(vim.fn.input("rdbg port: ", "38698")) or 38698
				end,
			},
		}
	end,
}
