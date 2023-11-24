local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system(
        {
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable", -- latest stable release
            lazypath
        }
    )
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup {
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {"nvim-tree/nvim-web-devicons"},
        config = function()
            require("nvim-tree").setup {
                filters = {
                    dotfiles = false,
                    git_clean = false,
                    no_buffer = false,
                    exclude = {"logs"},
                    custom = {".git"}
                },
                update_focused_file = {
                    enable = true,
                    update_cwd = true,
                    update_root = true
                },
                view = {
                  width = 30
                },
                renderer = {
                    --root_folder_label = false,
                    root_folder_modifier = ":t",
                    -- These icons are visible when you install web-devicons
                    icons = {
                        glyphs = {
                            default = "",
                            symlink = "",
                            folder = {
                                arrow_open = "",
                                arrow_closed = "",
                                default = "",
                                open = "",
                                empty = "",
                                empty_open = "",
                                symlink = "",
                                symlink_open = ""
                            },
                            git = {
                                unstaged = "",
                                staged = "S",
                                unmerged = "",
                                renamed = "➜",
                                untracked = "U",
                                deleted = "",
                                ignored = "◌"
                            }
                        }
                    }
                }
            }
        end
    },
    {
        "akinsho/bufferline.nvim",
        dependencies = 'nvim-tree/nvim-web-devicons'
    },
    {
        "akinsho/bufferline.nvim",
        dependencies = {"nvim-tree/nvim-web-devicons"}
    },
    {"folke/tokyonight.nvim"},
    {
        "phaazon/hop.nvim",
        lazy = true
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {"nvim-tree/nvim-web-devicons"},
    },
    {
        "folke/which-key.nvim",
        lazy = true
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {"nvim-lua/plenary.nvim"}
    },
    {
        "telescope.nvim",
        dependencies = {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            config = function()
                require("telescope").load_extension("fzf")
            end
        }
    },
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v3.x"
    },
    {"williamboman/mason.nvim"},
    {"williamboman/mason-lspconfig.nvim"},
    {"neovim/nvim-lspconfig"},
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            {
                "roobert/tailwindcss-colorizer-cmp.nvim",
                config = true
            }
        },
        opts = function(_, opts)
            opts.formatting = {
                fomat = require("tailwindcss-colorizer-cmp").formatter
            }
        end
    },
    {"hrsh7th/cmp-nvim-lsp"},
    {"L3MON4D3/LuaSnip"},
    {
        "NvChad/nvim-colorizer.lua",
        opts = {
            user_default_options = {
                tailwind = true
            }
        }
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")

            configs.setup(
                {
                    ensure_installed = {"c", "lua", "vim", "vimdoc", "query", "elixir", "heex", "javascript", "html"},
                    sync_install = false,
                    highlight = {enable = true},
                    indent = {enable = true}
                }
            )
        end
    },
    {"rebelot/kanagawa.nvim", name = "kanagawa"},
}

vim.opt.termguicolors = true
vim.cmd "colorscheme kanagawa"
vim.cmd "set number"
vim.cmd "set tabstop=2"
vim.cmd "set shiftwidth=2"
vim.cmd "set expandtab"
vim.cmd "set smartindent"
vim.cmd "set clipboard=unnamedplus"
vim.cmd "set fillchars+=vert:\\ "

require "whichkey"
require("lualine").setup {
  options = {
    globalstatus = true
  },
}

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<C-p>", builtin.find_files, {})
vim.keymap.set("n", "<C-f>", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

local lsp_zero = require("lsp-zero")
lsp_zero.extend_lspconfig()

lsp_zero.on_attach(
    function(client, bufnr)
        lsp_zero.default_keymaps(
            {
                buffer = bufnr
            }
        )
    end
)

require("mason").setup({})
require("mason-lspconfig").setup(
    {
        handlers = {lsp_zero.default_setup}
    }
)

local cmp = require("cmp")
local cmp_action = require("lsp-zero").cmp_action()
cmp.setup(
    {
        mapping = cmp.mapping.preset.insert(
            {
                -- `Enter` key to confirm completion
                ["<CR>"] = cmp.mapping.confirm(
                    {
                        select = false
                    }
                ),
                -- Ctrl+Space to trigger completion menu
                ["<C-Space>"] = cmp.mapping.complete(),
                -- Navigate between snippet placeholder
                ["<C-f>"] = cmp_action.luasnip_jump_forward(),
                ["<C-b>"] = cmp_action.luasnip_jump_backward(),
                -- Scroll up and down in the completion documentation
                ["<C-u>"] = cmp.mapping.scroll_docs(-4),
                ["<C-d>"] = cmp.mapping.scroll_docs(4)
            }
        )
    }
)

require("telescope").setup {
    extensions = {
        fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case" -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
        }
    }
}

local nvim_lsp = require "lspconfig"
nvim_lsp.intelephense.setup(
    {
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
                    maxSize = 5000000
                }
            }
        }
    }
)

require("bufferline").setup {
    highlights = {
        fill = {
            bg = "#1f1f28"
        }
    },
    options= {
        always_show_bufferline = true,
        middle_mouse_command = "bdelete! %d",
        offsets = {
            {
                filetype = "NvimTree",
                text = "",
                padding = 1,
                highlight = "Directory",
                text_align = "left"
            },
        },
    }
}
