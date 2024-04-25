return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = {
        'nvim-lua/plenary.nvim',
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            -- NOTE: If you are having trouble with this installation,
            --       refer to the README for telescope-fzf-native for more instructions.
            build = 'make',
            cond = function()
                return vim.fn.executable 'make' == 1
            end,
        },

    },
    -- TODO: Get only_cwd to work
    extensions = {
        recent_files = {
            only_cwd = true,
        }
    },
    config = function()
        pcall(require('telescope').load_extension, 'fzf')
        require("telescope").load_extension("recent_files")
        local trouble = require("trouble.providers.telescope")

        local set = vim.keymap.set
        -- Telescope
        vim.api.nvim_create_user_command('LiveGrepGitRoot', require('noahbalboa66.utils').live_grep_git_root, {})

        -- See `:help telescope.builtin`
        set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
        set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
        set('n', '<leader>/', function()
            -- You can pass additional configuration to telescope to change theme, layout, etc.
            require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                winblend = 10,
                previewer = false,
            })
        end, { desc = '[/] Fuzzily search in current buffer' })

        set('n', '<leader>so', require('noahbalboa66.utils').telescope_live_grep_open_files,
            { desc = '[S]earch [O]pen Files' })
        set('n', '<leader>ss', require('telescope.builtin').builtin, { desc = '[S]earch [S]elect Telescope' })
        set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'search [G]it [F]iles' })
        set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
        set('n', '<leader>sF', function()
            require('telescope.builtin').find_files({ no_ignore = true, hidden = true })
        end, { desc = '[S]earch hidden and ignored [F]iles' })
        vim.keymap.set("n", "<leader>sT", trouble.open_with_trouble, { desc = 'Open Trouble with Telescope' })
        set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
        set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
        set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
        set('n', '<leader>sG', ':LiveGrepGitRoot<cr>', { desc = '[S]earch by [G]rep on Git Root' })
        set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
        set('n', '<leader>sc', require('telescope.builtin').resume, { desc = '[S]earch [C]ontinue' })
        set('n', '<leader>sr', require('telescope').extensions.recent_files.pick, { desc = '[S]earch [R]ecent' })
    end
}
