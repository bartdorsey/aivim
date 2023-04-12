-- Install Packer if it's not already installed
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({ "git", "clone", "https://github.com/wbthomason/packer.nvim", install_path })
    vim.api.nvim_command("packadd packer.nvim")
end

-- Set the leader key to space
vim.g.mapleader = ' '

-- Enable mouse support in all modes
vim.o.mouse = 'a'

-- Use relative line numbers
vim.wo.number = true
vim.wo.relativenumber = true

-- Ignore case when searching
vim.o.ignorecase = true
vim.o.smartcase = true

-- Use the system clipboard for copy/paste operations
vim.o.clipboard = 'unnamedplus'

-- Set the tab size to 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- Enable syntax highlighting
vim.cmd [[syntax on]]

-- Configure Packer
require("packer").startup(function()
    use("neovim/nvim-lspconfig")
    use("ray-x/lsp_signature.nvim")
    use("jose-elias-alvarez/null-ls.nvim")
    use("folke/lua-dev.nvim")
    use("nvim-treesitter/nvim-treesitter")
    use("williamboman/mason.nvim")
    use 'folke/tokyonight.nvim'
    use {
        'nvim-telescope/telescope.nvim',

        requires = { { 'nvim-lua/plenary.nvim' } }
    }
    -- Install 'nvim-cmp' with 'packer'
    use { 'hrsh7th/nvim-cmp', requires = {
        { 'hrsh7th/vim-vsnip' },
        { 'hrsh7th/cmp-buffer' },
        { 'hrsh7th/cmp-path' },
        { 'hrsh7th/cmp-nvim-lsp' }
    }
    }
    use 'L3MON4D3/LuaSnip'
    use 'onsails/lspkind-nvim'
    use 'windwp/nvim-autopairs'
end)

-- Configure the color scheme
vim.cmd([[colorscheme tokyonight]])

-- Set the theme variant (optional)
vim.g.tokyonight_style = "storm"

-- Set the transparency (optional)
vim.g.tokyonight_transparent = true

-- Enable the plugin for specific file types (optional)
vim.cmd([[autocmd FileType markdown,tex lua require('tokyonight').colorscheme()]])

-- Load the Mason plugin
require('mason').setup({
    -- Specify the default delimiter for Mason blocks
    delimiter = '@',
    -- Specify the filetypes that should be recognized as Mason files
    filetypes = { 'html.mason', 'tt' },
    -- Specify whether or not to highlight the delimiter
    highlight_delimiter = true,
    -- Specify the key mappings for Mason commands
    mappings = {
        compile = '<Leader>mc',
        execute = '<Leader>mx',
        open_perl = '<Leader>mo',
        close_perl = '<Leader>mc',
        toggle_perl = '<Leader>mt',
    },
})

-- Load nvim-treesitter
require('nvim-treesitter.configs').setup({
    -- Ensure that treesitter is installed (optional)
    ensure_installed = {
        'javascript',
        'typescript',
        'python',
        'lua',
        'rust'
    },
    -- Enable the parsers that you want to use
    highlight = {
        enable = true, -- this enables highlighting for all parsers
    },
    indent = {
        enable = true -- this enables indentation for all parsers
    },
    -- List of language that will be disabled
    ignore_install = {},
})


local lspconfig = require("lspconfig")
local lsp_signature = require("lsp_signature")
local null_ls = require("null-ls")
local luadev = require("lua-dev").setup({
    lspconfig = {
        cmd = { "/usr/bin/lua-language-server" },
    },
})

-- Define custom handlers for hover, signature help and completion
local on_attach = function(client, bufnr)
    lsp_signature.on_attach({
        bind = true, -- This is mandatory, otherwise border config won't get registered.
        handler_opts = {
            border = "single",
        },
    })

    -- Setup buffer local mappings for LSP
    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    local opts = { noremap = true, silent = true }

    buf_set_keymap("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    buf_set_keymap("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
    buf_set_keymap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
    buf_set_keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    buf_set_keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    buf_set_keymap("n", "<space>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
    buf_set_keymap("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    buf_set_keymap("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    buf_set_keymap("n", "<leader>ff", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

    -- Enable completion triggered by <C-Space>
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Enable null-ls formatting and linting
    null_ls.setup({
        sources = {
            null_ls.builtins.formatting.prettier,
            null_ls.builtins.formatting.stylua,
            null_ls.builtins.diagnostics.eslint_d,
            null_ls.builtins.diagnostics.flake8,
            null_ls.builtins.diagnostics.rustfmt,
            null_ls.builtins.diagnostics.mypy,
        },
        on_attach = function(client)
            require("lspconfig").util.buffer_on_attach(client)
        end,
    })

    -- Enable Lua LSP if the current buffer is a Lua file
    if vim.bo.filetype == "lua" then
        require("lspconfig").sumneko_lua.setup(luadev)
    end
end

-- Enable LSP servers for JavaScript, TypeScript, Rust, and Python
lspconfig.tsserver.setup({ on_attach })

lspconfig.rust_analyzer.setup({ on_attach })

lspconfig.pyright.setup({
    on_attach = function(client, bufnr)
        on_attach(client, bufnr)

        -- Enable Jedi Language Server for Python
        client.resolved_capabilities.hover = true
        client.resolved_capabilities.document_formatting = false
        client.resolved_capabilities.document_range_formatting = false
        client.resolved_capabilities.document_symbol = false
        client.resolved_capabilities.code_lens = false
        client.resolved_capabilities.workspace_symbol = false

        lspconfig.jedi_language_server.setup({
            on_attach = function(client)
                require("lspconfig").util.buffer_on_attach(client)
            end,
        })
    end,
})

-- Load Telescope
local telescope = require('telescope')

-- Set the default file sorting to be ascending based on modification time
telescope.setup {
    defaults = {
        sorting_strategy = "ascending",
        file_sorter = require("telescope.sorters").get_fuzzy_file,
        file_ignore_patterns = { "%.git/.*", "node_modules/.*" },
        prompt_prefix = "> ",
        selection_caret = "> ",
        layout_strategy = "flex",
        layout_config = {
            prompt_position = "top",
            horizontal = {
                width = { padding = 0.1 },
                preview_width = 0.6,
            },
            vertical = {
                width = { padding = 0.05 },
                preview_height = 0.5,
            },
        },
    },
}

-- Add mappings
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap('n', '<leader>ff', '<cmd>Telescope find_files<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>fb', '<cmd>Telescope buffers<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', opts)

-- Configure 'nvim-cmp'
local cmp = require('cmp')
local lspconfig = require('lspconfig')

cmp.setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'path' },
    },
    mapping = {
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    },
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
    formatting = {
        format = function(entry, vim_item)
            vim_item.kind = require('lspkind').presets.default[vim_item.kind]
            vim_item.menu = ({
                nvim_lsp = '[LSP]',
                luasnip = '[Snip]',
                buffer = '[Buf]',
                path = '[Path]',
            })[entry.source.name]
            return vim_item
        end,
    },
    completion = {
        completeopt = 'menu,menuone,noinsert',
    },
    preselect = cmp.PreselectMode.None,
    documentation = {
        border = 'single',
    },
})

-- Configure 'nvim-cmp' for use with 'nvim-lspconfig'
lspconfig.util.completion_item_kind = {
    '   (Text) ',
    '   (Method)',
    '   (Function)',
    '   (Constructor)',
    ' ﴲ  (Field)',
    '[] (Variable)',
    '   (Class)',
    ' ﰮ  (Interface)',
    '   (Module)',
    ' 襁 (Property)',
    '   (Unit)',
    '   (Value)',
    ' 練 (Enum)',
    '   (Keyword)',
    '   (Snippet)',
    '   (Color)',
    '   (File)',
    '   (Reference)',
    '   (Folder)',
    '   (EnumMember)',
    ' ﲀ  (Constant)',
    ' ﳤ  (Struct)',
    '   (Event)',
    '   (Operator)',
    '   (TypeParameter)',
}


-- Configure 'nvim-lspconfig' for 'lua-language-server'
lspconfig.sumneko_lua.setup({
    cmd = { 'lua-language-server' },
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
                path = vim.split(package.path, ';'),
            },
            diagnostics = {
                globals = { 'vim' },
            },
            workspace = {
                library = {
                    [vim.fn.expand('$VIMRUNTIME/lua')] = true,
                    [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
                },
            },
        },
    },
})

-- Configure 'nvim-lspconfig' for other languages as desired
lspconfig.javascript.setup({})
lspconfig.typescript.setup({})
lspconfig.html.setup({})
lspconfig.cssls.setup({})

-- Configure 'nvim-lspconfig' for 'efm-langserver'
lspconfig.efm.setup({
    init_options = { documentFormatting = true },
    filetypes = { "lua" },
    settings = {
        rootMarkers = { ".git/" },
        languages = {
            lua = {
                { formatCommand = "lua-format -i", formatStdin = true },
            },
        },
    },
})

-- Configure 'vim-vsnip' for use with 'nvim-cmp'
local luasnip = require('luasnip')
cmp.snippets = luasnip.snippets

-- Configure 'lspkind-nvim' for symbol icons in 'nvim-cmp'
require('lspkind').init({
    mode = "text",
    preset = 'default',
})

-- Set up 'luasnip' for snippet management
require('luasnip/loaders/from_vscode').lazy_load()

-- Automatically close brackets and quotes
require('nvim-autopairs').setup()

require('nvim-autopairs.completion.cmp').setup({
  map_cr = true,
  map_complete = true,
  auto_select = true,
})

-- Use <Tab> and <S-Tab> to navigate through popup menu
-- Use <Tab> to select completion and insert matching pair
-- Use <S-Tab> to select completion and move to the next item
local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local cmp_select_next_item = function()
    if cmp.visible() then
        cmp.select_next_item()
    else
        t '<Tab>'
    end
end

local cmp_select_prev_item = function()
    if cmp.visible() then
        cmp.select_prev_item()
    else
        t '<S-Tab>'
    end
end

vim.api.nvim_set_keymap('i', '<Tab>', 'v:lua.cmp_select_next_item()', { expr = true, noremap = true })
vim.api.nvim_set_keymap('i', '<S-Tab>', 'v:lua.cmp_select_prev_item()', { expr = true, noremap = true })

-- Use <C-Space> to trigger completion
vim.api.nvim_set_keymap('i', '<C-Space>', 'cmp#complete()', { noremap = true, silent = true, expr = true })
