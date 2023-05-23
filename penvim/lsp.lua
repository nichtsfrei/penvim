local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

local capabilities = vim.tbl_extend('keep', vim.lsp.protocol
    .make_client_capabilities(),
    cmp_nvim_lsp.default_capabilities());

local rt = require('rust-tools')
rt.setup({
    server = {
        capabilities = capabilities,
        standalone = false,
        on_attach = function(_, bufnr)
            -- Hover actions
            vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
            -- Code action groups
            vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
            --vim.keymap.set("n", "<Leader>vce", , {buffer = bufnr })
            vim.keymap.set("n", "<leader>vce", "<cmd>lua require'rust-tools'.expand_macro.expand_macro()<CR>");
        end,
        settings = {
            ["rust-analyzer"] = {
                checkOnSave = {
                    command = "clippy"
                },
            }
        }
    },
    tools = {
        autoSetHints = true,
        inlay_hints = {
            auto = true,
            only_current_line = false,
            show_parameter_hints = true
        },
        runnables = { use_telescope = true }
    }
})

require('crates').setup {}

local null_ls = require("null-ls")

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics
local codeactions = null_ls.builtins.code_actions

null_ls.setup {
    debug = false,
    sources = {
        -- formatting.lua_format,
        formatting.alejandra, -- for nix
        formatting.prismaFmt, -- for node prisma db orm
        formatting.prettier.with {

            -- extra_args = {
            --     "--use-tabs", "--single-quote", "--jsx-single-quote"
            -- },
            -- Disable markdown because formatting on save conflicts in weird ways
            -- with the taskwiki (roam-task) stuff.
            filetypes = {
                "javascript", "javascriptreact", "typescript",
                "typescriptreact", "vue", "scss", "less", "html", "css",
                "json", "jsonc", "yaml", "graphql", "handlebars", "svelte"
            },
            disabled_filetypes = { "markdown" }
        }, diagnostics.eslint_d.with {
        args = {
            "-f", "json", "--stdin", "--stdin-filename", "$FILENAME"
        }
    },                                            -- diagnostics.vale,
        codeactions.eslint_d, codeactions.statix, -- for nix
        diagnostics.statix,                       -- for nix
        null_ls.builtins.hover.dictionary, codeactions.shellcheck,
        diagnostics.shellcheck
        -- removed formatting.rustfmt since rust_analyzer seems to do the same thing
    },
}

require("lsp-format").setup {}

local servers = { 'clangd', 'pyright', 'svelte', 'bashls' }
for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup { capabilities = capabilities }
end

require 'lspsaga'.init_lsp_saga({
    use_diagnostic_virtual_text = true,
    code_action_prompt = {
        enable = true,
        sign = false,
        sign_priority = 20,
        virtual_text = true
    }
})


lspconfig.lua_ls.setup {
    capabilities = capabilities,
    filetypes = { "lua" },
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT'
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { 'vim', "string", "require" }
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = { enable = false },
            completion = { enable = true, callSnippet = "Replace" }
        }
    }
}

local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
        ['<C-d>'] = cmp.mapping.scroll_docs(4),  -- Down
        -- C-b (back) C-f (forward) for snippet placeholder navigation.
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        },
        ['<C-N>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<C-P>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
    }),
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    },
}

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
        vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>f', function()
            vim.lsp.buf.format { async = true }
        end, opts)
    end,
})
