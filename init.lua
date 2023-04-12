-- Install Packer if it's not already installed
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
	vim.fn.system({ "git", "clone", "https://github.com/wbthomason/packer.nvim", install_path })
	vim.api.nvim_command("packadd packer.nvim")
end

-- Configure Packer
require("packer").startup(function()
	use("neovim/nvim-lspconfig")
	use("ray-x/lsp_signature.nvim")
	use("jose-elias-alvarez/null-ls.nvim")
	use("folke/lua-dev.nvim")
	use("nvim-treesitter/nvim-treesitter")
	use("williamboman/mason.nvim")
	use 'folke/tokyonight.nvim'
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
  ignore_install = { },
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
