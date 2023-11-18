local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)


require("lazy").setup {
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  },
  {
    'romgrk/barbar.nvim',
      dependencies = {
        'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
        'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
      },
      init = function() vim.g.barbar_auto_setup = false end,
      opts = {
        minimum_padding = 1,
        sidebar_filetypes = {
          NvimTree = true,
        }
      },
      version = '^1.0.0', -- optional: only update when a new 1.x version is released:set number:set number
  },
  {
    'akinsho/bufferline.nvim',
    dependencies = {
        'nvim-tree/nvim-web-devicons'
    },
  },

  -- Colorscheme
  {
      'folke/tokyonight.nvim',
  },

  -- Hop (Better Navigation)
  {
      "phaazon/hop.nvim",
      lazy = true,
  },


  -- Lualine
  {
      'nvim-lualine/lualine.nvim',
      dependencies = {
          'nvim-tree/nvim-web-devicons'
      },
  },

  -- Which-key
  {
      'folke/which-key.nvim',
      lazy = true,
  },

  {
    'neovim/nvim-lspconfig',
    lazy = true,
  },

  {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
    dependencies = { 'nvim-lua/plenary.nvim' }
  }, 
}

vim.opt.termguicolors = true
vim.cmd 'colorscheme tokyonight-night' 
vim.cmd 'set number'

require "nvim-tree-config"
require "whichkey"
require('lualine').setup()
require "lsp"

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
