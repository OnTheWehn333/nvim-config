return {
    "iabdelkareem/csharp.nvim",
    dependencies = {
        "williamboman/mason.nvim", -- Required, automatically installs omnisharp
        "mfussenegger/nvim-dap",
        "Tastyep/structlog.nvim",  -- Optional, but highly recommended for debugging
    },
    config = function()
        require("csharp").setup()
        vim.keymap.set('n', '<leader>rr', require("csharp").run_project, { desc = "Run csharp project" })
        vim.keymap.set('n', '<leader>rd', require("csharp").debug_project, { desc = "Debug csharp project" })

        -- Configure nvim-dap
        local dap = require('dap')
        dap.set_log_level('DEBUG')

        dap.adapters.coreclr = {
            type = 'executable',
            command = 'netcoredbg',
            args = { '--interpreter=vscode' }
        }

        dap.configurations.cs = {
            {
                type = 'coreclr',
                name = 'launch - netcoredbg',
                request = 'launch',
                program = function()
                    return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/net6.0/', 'file')
                end,
            },
        }

        -- Optional: Add more keybindings for debugging
        vim.keymap.set('n', '<F5>', dap.continue, { desc = "Continue Debugging" })
        vim.keymap.set('n', '<F9>', dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
        vim.keymap.set('n', '<F10>', dap.step_over, { desc = "Step Over" })
        vim.keymap.set('n', '<F11>', dap.step_into, { desc = "Step Into" })
    end
}
