vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Explorer" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "move selected block down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "move selected block down" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join line below, separate by ws" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Move down half a page, keep crsr pos" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Move up half a page, keep crsr pos" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Move to next match, keep crsr pos" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Move to prev match, keep crsr pos" })

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over selected text" })

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Copy entire buffer to system clipboard" })

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to unnamed register" })

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Prev location" })
