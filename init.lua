require('impatient')
require('impatient').enable_profile()
require("penvim.set")
require("penvim.remap")
require("penvim.colors")
require("penvim.telescope")
require("penvim.undotree")
require("penvim.trouble")
require("penvim.lsp").diagnostics()
require("penvim.lsp").completions()

function R(name)
    require("plenary.reload").reload_module(name)
end

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
