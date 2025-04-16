return {
    'tpope/vim-fugitive',
    config = function()
        require("telescope").load_extension("git_file_history")
    end
}
