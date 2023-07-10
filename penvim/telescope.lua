local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>r', builtin.find_files, { desc = "Find files" })
vim.keymap.set('n', '<leader>f', builtin.git_files, { desc = "Find git files" })
vim.keymap.set('n', '<leader>/', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep string" })
vim.keymap.set('n', '<leader>vh', builtin.help_tags, { desc = "Help tags" })

