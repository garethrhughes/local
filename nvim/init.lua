local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system(
        {"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", -- latest stable release
         lazypath})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup {{
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        require("nvim-tree").setup {}
    end
}, {
    'romgrk/barbar.nvim',
    dependencies = {'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
    'nvim-tree/nvim-web-devicons' -- OPTIONAL: for file icons
    },
    init = function()
        vim.g.barbar_auto_setup = false
    end,
    opts = {
        minimum_padding = 1,
        sidebar_filetypes = {
            NvimTree = true
        }
    },
    version = '^1.0.0' -- optional: only update when a new 1.x version is released:set number:set number
}, {
    'akinsho/bufferline.nvim',
    dependencies = {'nvim-tree/nvim-web-devicons'}
}, -- Colorscheme
{'folke/tokyonight.nvim'}, -- Hop (Better Navigation)
{
    "phaazon/hop.nvim",
    lazy = true
}, -- Lualine
{
    'nvim-lualine/lualine.nvim',
    dependencies = {'nvim-tree/nvim-web-devicons'}
}, -- Which-key
{
    'folke/which-key.nvim',
    lazy = true
}, 

-- {
--     'nvim-telescope/telescope.nvim',
--     tag = '0.1.4',
--     dependencies = {'nvim-lua/plenary.nvim'}
-- }, 

    {
    "nvim-telescope/telescope.nvim",
    dependencies = {'nvim-lua/plenary.nvim'}
  },

  -- add telescope-fzf-native
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
      end,
    },
  },

{
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x'
}, {'williamboman/mason.nvim'}, {'williamboman/mason-lspconfig.nvim'}, {'neovim/nvim-lspconfig'}, {
    'hrsh7th/nvim-cmp',
    dependencies = {{
        "roobert/tailwindcss-colorizer-cmp.nvim",
        config = true
    }},
    opts = function(_, opts)
        -- original LazyVim kind icon formatter
        opts.formatting = {
          fomat = require("tailwindcss-colorizer-cmp").formatter
        }
      end,
}, {'hrsh7th/cmp-nvim-lsp'}, {'L3MON4D3/LuaSnip'}, {
    "NvChad/nvim-colorizer.lua",
    opts = {
        user_default_options = {
            tailwind = true
        }
    }
}, {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function () 
      local configs = require("nvim-treesitter.configs")

      configs.setup({
          ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "elixir", "heex", "javascript", "html" },
          sync_install = false,
          highlight = { enable = true },
          indent = { enable = true },  
        })
    end
 }
}

vim.opt.termguicolors = true
vim.cmd 'colorscheme tokyonight-night'
vim.cmd 'set number'
vim.cmd 'set tabstop=2'
vim.cmd 'set shiftwidth=2'
vim.cmd 'set expandtab'
vim.cmd 'set smartindent'

require "nvim-tree-config"
require "whichkey"
require('lualine').setup()

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.find_files, {})
vim.keymap.set('n', '<C-f>', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

local lsp_zero = require('lsp-zero')
lsp_zero.extend_lspconfig()

lsp_zero.on_attach(function(client, bufnr)
    lsp_zero.default_keymaps({
        buffer = bufnr
    })
end)

require('mason').setup({})
require('mason-lspconfig').setup({
    handlers = {lsp_zero.default_setup}
})

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()
cmp.setup({
    mapping = cmp.mapping.preset.insert({
        -- `Enter` key to confirm completion
        ['<CR>'] = cmp.mapping.confirm({
            select = false
        }),

        -- Ctrl+Space to trigger completion menu
        ['<C-Space>'] = cmp.mapping.complete(),

        -- Navigate between snippet placeholder
        ['<C-f>'] = cmp_action.luasnip_jump_forward(),
        ['<C-b>'] = cmp_action.luasnip_jump_backward(),

        -- Scroll up and down in the completion documentation
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4)
    })
})

require('telescope').setup {
    extensions = {
      fzf = {
        fuzzy = true,                    -- false will only do exact matching
        override_generic_sorter = true,  -- override the generic sorter
        override_file_sorter = true,     -- override the file sorter
        case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                         -- the default case_mode is "smart_case"
      }
    }
  }

local nvim_lsp = require'lspconfig'

nvim_lsp.intelephense.setup({
    settings = {
        intelephense = {
            stubs = { 
                "wordpress",
                "acf-pro",
                "wordpress-globals",
                "wp-cli",
                "standard",
                "superglobals"
            },
            files = {
                maxSize = 5000000;
            };
        };
    }
});
