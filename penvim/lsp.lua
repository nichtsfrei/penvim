-- This is a mega file. Rather than make each plugin have its own config file,
-- which is how I managed my packer-based nvim config prior to Nix, I'm
-- putting everything in here in sections and themed functions. It just makes it
-- easier for me to quickly update things and it's cleaner when there's
-- interdependencies between plugins. We'll see how it goes.
local M = {}

--local signs = require("pennvim.signs")

----------------------- DIAGNOSTICS --------------------------------
M.diagnostics = function()
    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

    require("trouble").setup {
        group = true, -- group results by file
        icons = true,
        auto_preview = true,
        signs = {
            error = "E",
            warning = "W",
            hint = "H",
            information = "I",
            other = "?"
        }
    }


    require "fidget".setup {} -- shows status of lsp clients as they issue updates
    vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = {
            focusable = false,
            style = "minimal",
            border = "rounded",
            source = "always",
            header = "",
            prefix = ""
        }
    })
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover,
        { border = "rounded" })

    vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

    local function attached(client, bufnr)
        client.server_capabilities.documentFormattingProvider = true
        client.server_capabilities.documentRangeFormattingProvider = true
        require("lsp-format").on_attach(client)

        print("LSP attached " .. client.name)

        vim.api.nvim_buf_set_option(bufnr, "formatexpr",
            "v:lua.vim.lsp.formatexpr()")
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
        vim.api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.vim.lsp.tagfunc")
    end

    -- LSP stuff - minimal with defaults for now
    local null_ls = require("null-ls")

    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    local formatting = null_ls.builtins.formatting
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
    local diagnostics = null_ls.builtins.diagnostics
    local codeactions = null_ls.builtins.code_actions

    require("lsp-format").setup {}

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
        on_attach = attached
    }
    local lspconfig = require("lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local capabilities = vim.tbl_extend('keep', vim.lsp.protocol
        .make_client_capabilities(),
        cmp_nvim_lsp.default_capabilities());

    require('rust-tools').setup({
        server = {
            on_attach = attached,
            capabilities = capabilities,
            standalone = false
        },
        tools = {
            autoSetHints = true,
            inlay_hints = { auto = true, only_current_line = true },
            runnables = { use_telescope = true }
        }
    })
    require('crates').setup {}
    lspconfig.lua_ls.setup {
        on_attach = attached,
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

    local servers = { 'clangd', 'pyright', 'svelte', 'bashls', 'nil_ls' }
    for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup { capabilities = capabilities }
    end


    lspconfig.jsonls.setup {
        on_attach = attached,
        settings = {
            json = {
                schemas = require('schemastore').json.schemas(),
                validate = { enable = true }
            }
        },
        setup = {
            commands = {
                Format = {
                    function()
                        vim.lsp.buf.range_formatting({}, { 0, 0 },
                            { vim.fn.line "$", 0 })
                    end
                }
            }
        },
        capabilities = capabilities
    }

    require 'lspsaga'.init_lsp_saga({
        use_diagnostic_virtual_text = true,
        code_action_prompt = {
            enable = true,
            sign = false,
            sign_priority = 20,
            virtual_text = true
        }
    })
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
end -- Diagnostics setup

----------------------- COMPLETIONS --------------------------------
-- cmp, luasnip
M.completions = function()
    require("luasnip/loaders/from_vscode").lazy_load()
    local luasnip = require("luasnip")
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

    cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = 'buffer' } }
    })
    cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = 'path' } }, {
            { name = 'cmdline', option = { ignore_cmds = { 'Man', '!' } } }
        })
    })
end

return M
