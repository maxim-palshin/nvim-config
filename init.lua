-- Установка lazy.nvim
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

-- Настройки для C++
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = true
vim.opt.cinoptions = ":0,l1,t0,(0"

-- Включение относительной нумерации строк
vim.opt.relativenumber = true
vim.opt.number = true

-- Настройка системного буфера обмена
vim.opt.clipboard = "unnamedplus"

-- Настройка <leader>
vim.g.mapleader = " "

-- Плагины
require("lazy").setup({
  -- Автодополнение
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "terryma/vim-multiple-cursors"
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
          ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
          ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
          ["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
          ["<C-e>"] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
          }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ["<Up>"] = cmp.mapping.select_prev_item(),
          ["<Down>"] = cmp.mapping.select_next_item(),
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline("/", {
        sources = {
          { name = "buffer" },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.clangd.setup{}
      lspconfig.ccls.setup{}
      lspconfig.pyright.setup{}
      lspconfig.r_language_server.setup{}
    end
  },

  -- Форматирование
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.clang_format,
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.styler,
        },
        on_attach = function(client, bufnr)
          if client.resolved_capabilities and client.resolved_capabilities.document_formatting then
            vim.cmd([[
              augroup Format
                autocmd! * <buffer>
                autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
              augroup END
            ]])
          end
        end,
      })

      -- Сочетания клавиш для форматирования
      vim.api.nvim_set_keymap('n', '<leader>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('v', '<leader>f', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', { noremap = true, silent = true })
    end
  },

  -- CMake
  {
    "Civitasv/cmake-tools.nvim",
    config = function()
      require("cmake-tools").setup {
        cmake_command = "cmake", -- this is used to specify cmake command path
        cmake_use_preset = true,
        cmake_regenerate_on_save = true, -- auto generate when save CMakeLists.txt
        cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" }, -- this will be passed when invoke `CMakeGenerate`
        cmake_build_options = {}, -- this will be passed when invoke `CMakeBuild`
        cmake_build_directory = function()
          if vim.fn.has("win32") == 1 then
            return "out\\${variant:buildType}"
          end
          return "out/${variant:buildType}"
        end, -- this is used to specify generate directory for cmake, allows macro expansion, can be a string or a function returning the string, relative to cwd.
        cmake_soft_link_compile_commands = true, -- this will automatically make a soft link from compile commands file to project root dir
        cmake_compile_commands_from_lsp = false, -- this will automatically set compile commands file location using lsp, to use it, please set `cmake_soft_link_compile_commands` to false
        cmake_kits_path = nil, -- this is used to specify global cmake kits path, see CMakeKits for detailed usage
        cmake_variants_message = {
          short = { show = true }, -- whether to show short message
          long = { show = true, max_length = 40 }, -- whether to show long message
        },
        cmake_dap_configuration = { -- debug settings for cmake
          name = "cpp",
          type = "codelldb",
          request = "launch",
          stopOnEntry = false,
          runInTerminal = true,
          console = "integratedTerminal",
        },
        cmake_executor = { -- executor to use
          name = "quickfix", -- name of the executor
          opts = {}, -- the options the executor will get, possible values depend on the executor type. See `default_opts` for possible values.
          default_opts = { -- a list of default and possible values for executors
            quickfix = {
              show = "always", -- "always", "only_on_error"
              position = "belowright", -- "vertical", "horizontal", "leftabove", "aboveleft", "rightbelow", "belowright", "topleft", "botright", use `:h vertical` for example to see help on them
              size = 10,
              encoding = "utf-8", -- if encoding is not "utf-8", it will be converted to "utf-8" using `vim.fn.iconv`
              auto_close_when_success = true, -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
            },
            toggleterm = {
              direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
              close_on_exit = false, -- whether close the terminal when exit
              auto_scroll = true, -- whether auto scroll to the bottom
              singleton = true, -- single instance, autocloses the opened one, if present
            },
            overseer = {
              new_task_opts = {
                strategy = {
                  "toggleterm",
                  direction = "horizontal",
                  autos_croll = true,
                  quit_on_exit = "success"
                }
              }, -- options to pass into the `overseer.new_task` command
              on_new_task = function(task)
                require("overseer").open(
                  { enter = false, direction = "right" }
                )
              end,   -- a function that gets overseer.Task when it is created, before calling `task:start`
            },
            terminal = {
              name = "Main Terminal",
              prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
              split_direction = "horizontal", -- "horizontal", "vertical"
              split_size = 11,

              -- Window handling
              single_terminal_per_instance = true, -- Single viewport, multiple windows
              single_terminal_per_tab = true, -- Single viewport per tab
              keep_terminal_static_location = true, -- Static location of the viewport if available

              -- Running Tasks
              start_insert = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
              focus = false, -- Focus on terminal when cmake task is launched.
              do_not_add_newline = false, -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
            }, -- terminal executor uses the values in cmake_terminal
          },
        },
        cmake_runner = { -- runner to use
          name = "terminal", -- name of the runner
          opts = {}, -- the options the runner will get, possible values depend on the runner type. See `default_opts` for possible values.
          default_opts = { -- a list of default and possible values for runners
            quickfix = {
              show = "always", -- "always", "only_on_error"
              position = "belowright", -- "bottom", "top"
              size = 10,
              encoding = "utf-8",
              auto_close_when_success = true, -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
            },
            toggleterm = {
              direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
              close_on_exit = false, -- whether close the terminal when exit
              auto_scroll = true, -- whether auto scroll to the bottom
              singleton = true, -- single instance, autocloses the opened one, if present
            },
            overseer = {
              new_task_opts = {
                strategy = {
                  "toggleterm",
                  direction = "horizontal",
                  autos_croll = true,
                  quit_on_exit = "success"
                }
              }, -- options to pass into the `overseer.new_task` command
              on_new_task = function(task)
              end,   -- a function that gets overseer.Task when it is created, before calling `task:start`
            },
            terminal = {
              name = "Main Terminal",
              prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
              split_direction = "horizontal", -- "horizontal", "vertical"
              split_size = 11,

              -- Window handling
              single_terminal_per_instance = true, -- Single viewport, multiple windows
              single_terminal_per_tab = true, -- Single viewport per tab
              keep_terminal_static_location = true, -- Static location of the viewport if available

              -- Running Tasks
              start_insert = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
              focus = false, -- Focus on terminal when cmake task is launched.
              do_not_add_newline = false, -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
            },
          },
        },
        cmake_notifications = {
          runner = { enabled = true },
          executor = { enabled = true },
          spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, -- icons used for progress display
          refresh_rate_ms = 100, -- how often to iterate icons
        },
        cmake_virtual_text_support = true, -- Show the target related to current file using virtual text (at right corner)
      }
    end
  },

  -- Git
  {
    "tpope/vim-fugitive",
  },
  {
    "airblade/vim-gitgutter",
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end
  },

  -- Файловый менеджер
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = true,
        },
      })
    end
  },

  -- Статусная строка
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          icons_enabled = true,
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {},
          always_divide_middle = true,
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        extensions = {}
      })
    end
  },

  -- Цветовая схема
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- mocha, macchiato, frappe, latte
        background = {
          light = "latte",
          dark = "mocha",
        },
        transparent_background = false,
        show_end_of_buffer = false,
        term_colors = false,
        dim_inactive = {
          enabled = false,
          shade = "dark",
          percentage = 0.15,
        },
        no_italic = false,
        no_bold = false,
        styles = {
          comments = { "italic" },
          conditionals = { "italic" },
          loops = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        color_overrides = {},
        custom_highlights = {},
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          telescope = true,
          notify = false,
          mini = false,
        },
      })
      vim.cmd("colorscheme catppuccin")
    end
  },

  -- Сниппеты
  {
    "L3MON4D3/LuaSnip",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end
  },

  -- Автоматическое создание тегов
  {
    "ludovicchabant/vim-gutentags",
    config = function()
    end
  },

  -- Поиск и навигация
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
            },
          },
        },
      })
    end
  },

  -- Подсветка синтаксиса
  {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query", "python", "r", "cmake" },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      })
    end
  },

  -- Уведомления
  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup({
        background_colour = "#000000",
      })
    end
  },

  -- Автоматическое закрытие скобок
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup{}
    end
  },

  -- Строка буферов
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers", -- set to "tabs" to only show tabpages instead
          numbers = "none", -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
          close_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
          right_mouse_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
          left_mouse_command = "buffer %d", -- can be a string | function, see "Mouse actions"
          middle_mouse_command = nil, -- can be a string | function, see "Mouse actions"
          indicator = {
            icon = '▎', -- this should be omitted if indicator style is not 'icon'
            style = 'icon',
          },
          buffer_close_icon = '',
          modified_icon = '●',
          close_icon = '',
          left_trunc_marker = '',
          right_trunc_marker = '',
          max_name_length = 30,
          max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
          truncate_names = true, -- whether or not tab names should be truncated
          tab_size = 21,
          diagnostics = false, -- | "nvim_lsp" | "coc",
          diagnostics_update_in_insert = false,
          offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_close_icon = true,
          show_tab_indicators = true,
          persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
          separator_style = "thin", -- | "thick" | "thin" | { 'any', 'any' },
          enforce_regular_tabs = true,
          always_show_bufferline = true,
          sort_by = 'id',
        },
      })
    end
  },

  -- Подсказки по горячим клавишам
  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").setup {}
    end
  },

  -- Терминал
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = '1',
        start_insert = true,
        persist_size = true,
        direction = 'float',
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = 'curved',
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          }
        }
      })

      -- Сочетания клавиш для открытия терминала
      vim.api.nvim_set_keymap('n', '<leader>t', '<cmd>ToggleTerm<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('t', '<esc>', [[<C-\><C-n>]], { noremap = true, silent = true })
    end
  },

  -- Comment.nvim
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end
  },
})



-- Сочетания клавиш для nvim-dap-ui
vim.api.nvim_set_keymap('n', '<leader>du', '<cmd>lua require("dapui").toggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>de', '<cmd>lua require("dapui").eval()<CR>', { noremap = true, silent = true })

-- Включение подсветки синтаксиса
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")
