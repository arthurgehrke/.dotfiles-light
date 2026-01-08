--GENERAL SETTINGS
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = true

local options = { noremap = true, silent = true }

vim.opt.clipboard = { 'unnamedplus' }
vim.o.ruler = true
vim.opt.cursorline = true
vim.opt.undolevels = 10000
vim.opt.history = 1000
vim.opt.wrap = false
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true

local undodir = os.getenv("HOME") .. "/.config/nvim/undodir"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.list = true
vim.opt.listchars = "eol:.,tab:>-,trail:~,extends:>,precedes:<"
vim.opt.swapfile = false
vim.opt.hlsearch = not vim.o.hlsearch
vim.opt.history = 1000
vim.opt.showcmd = false
vim.opt.infercase = true
vim.opt.expandtab = true
vim.opt.scrolloff = 5
vim.opt.sidescroll = 1 
vim.opt.sidescrolloff = 10
vim.opt.termguicolors = true

if vim.fn.has('nvim-0.10') == 1 then
  vim.opt.smoothscroll = true
end

local function augroup(name)
  return vim.api.nvim_create_augroup('lazyvim_' .. name, { clear = true })
end

vim.api.nvim_create_autocmd('BufEnter', { command = [[set formatoptions-=cro]] })

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  group = augroup('auto_create_dir'),
  callback = function(event)
    if event.match:match('^%w%w+:[\\/][\\/]') then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

local filetypes = {
  { ext = '*.json', type = 'json' },
  { ext = '*.py', type = 'python' },
  { ext = '*.lua', type = 'lua' },
  { ext = '*.md', type = 'markdown' },
  { ext = '*.js', type = 'javascript' },
  { ext = '*.ts', type = 'typescript' },
  { ext = '*.html', type = 'html' },
  { ext = '*.css', type = 'css' },
  { ext = '*.sh', type = 'sh' },
  { ext = '*.go', type = 'go' },
  { ext = '*.rs', type = 'rust' },
}

for _, ft in ipairs(filetypes) do
  vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = ft.ext,
    command = 'set filetype=' .. ft.type,
  })
end

vim.keymap.set('i', 'jj', '<Esc>', options)
vim.keymap.set('i', 'jk', '<Esc>', options)
vim.keymap.set('n', 'sh', '<C-w>h', options)
vim.keymap.set('n', 'sj', '<C-w>j', options)
vim.keymap.set('n', 'sk', '<C-w>k', options)
vim.keymap.set('n', 'sl', '<C-w>l', options)
vim.keymap.set('v', '<', '<gv', options)
vim.keymap.set('v', '>', '>gv', options)
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', options)
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', options)
vim.keymap.set('x', 'p', function()
  return 'pgv"' .. vim.v.register .. 'y'
end, { remap = false, expr = true })
vim.keymap.set('n', '<C-j>', ':set paste<CR>m`o<Esc>``:set nopaste<CR>', options)
vim.keymap.set('n', '<C-k>', ':set paste<CR>m`O<Esc>``:set nopaste<CR>', options)
vim.keymap.set('n', 'gvd', ':vsplit<CR><cmd>lua vim.lsp.buf.definition()<CR>', options)
vim.keymap.set('n', 'gsd', ':sp<CR><cmd>lua vim.lsp.buf.definition()<CR>', options)
vim.cmd([[autocmd cursormoved * set nohlsearch]])
vim.keymap.set('n', 'n', 'n:set hlsearch<cr>', { noremap = true, silent = true })
vim.keymap.set('n', 'N', 'N:set hlsearch<cr>', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, ';', 'getcharsearch().forward ? \',\' : \';\'', { expr = true })
vim.keymap.set({ 'n', 'v' }, '\'', 'getcharsearch().forward ? \';\' : \',\'', { expr = true })

--LAZY.NVIM BOOTSTRAP
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    build = ':MasonUpdate',
    opts_extend = { 'ensure_installed' },
    opts = {
      ensure_installed = {
        'stylua',
        'shfmt',
      },
    },
    config = function(_, opts)
      require('mason').setup(opts)
      local mr = require('mason-registry')
      mr:on('package:install:success', function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require('lazy.core.handler.event').trigger({
            event = 'FileType',
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'eslint', 'ts_ls', 'angularls', 'html' },
      })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'saghen/blink.cmp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)

          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

          map('gca', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

          local function client_supports_method(client, method, bufnr)
            if vim.fn.has('nvim-0.11') == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

         if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })
   local capabilities = require('blink.cmp').get_lsp_capabilities()
      local util = require('lspconfig/util')
      local servers = {
        gopls = {
          capabilities = capabilities,
          cmd = { 'gopls' },
          filetypes = { 'go', 'gomod', 'gowork', 'gotmpl',  },
          root_dir = util.root_pattern('go.work', 'go.mod', '.git'),
          settings = {
            gopls = {
              completeUnimported = true,
              usePlaceholders = true,
              analyses = {
                unusedparams = true,
              },
            },
          },
        },
        -- pyright = {},
        rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        ts_ls = {
          capabilities = capabilities,
        },
        vue_ls = {},
        eslint = {},
        --

        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      local ensure_installed = vim.tbl_keys(servers or {})

      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
      require('mason-lspconfig').setup({
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      })
    end,
  },
    { 'numToStr/Comment.nvim', opts = {} },
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },
   {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        theme = 'onedark',
        component_separators = '|',
        section_separators = '',
      },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      {
        '<leader>ee',
        '<cmd>NvimTreeToggle<CR>',
        desc = '[E]xplorer Op[E]n',
      },
      {
        '<leader>f',
        '<cmd>NvimTreeFindFileToggle<CR>',
        desc = '[E]xplorer on [F]ile',
      },
      {
        '<leader>ec',
        '<cmd>NvimTreeCollapse<CR>',
        desc = '[E]xplorer [C]ollapse',
      },
    },
    config = function()
      -- Define custom on_attach function to handle keymaps
      local function my_on_attach(bufnr)
        local api = require "nvim-tree.api"

        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        vim.keymap.set('n', '<C-d>', api.tree.change_root_to_node, opts('CD'))
        vim.keymap.set('n', '<C-e>', api.node.open.replace_tree_buffer, opts('Open: In Place'))
        vim.keymap.set('n', '<C-k>', api.node.show_info_popup, opts('Info'))
        vim.keymap.set('n', '<C-v>', api.node.open.vertical, opts('Open: Vertical Split'))
        vim.keymap.set('n', '<C-s>', api.node.open.horizontal, opts('Open: Horizontal Split'))
        vim.keymap.set('n', '<BS>', api.node.navigate.parent_close, opts('Close Directory'))
        vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))
        vim.keymap.set('n', '.', api.node.run.cmd, opts('Run Command'))
        vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts('Up'))
        vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
        vim.keymap.set('n', 'c', api.fs.copy.node, opts('Copy'))
        vim.keymap.set('n', 'C', api.tree.toggle_git_clean_filter, opts('Toggle Git Clean'))
        vim.keymap.set('n', '[c', api.node.navigate.git.prev, opts('Prev Git'))
        vim.keymap.set('n', ']c', api.node.navigate.git.next, opts('Next Git'))
        vim.keymap.set('n', 'd', api.fs.remove, opts('Delete'))
        vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
        vim.keymap.set('n', 'E', api.tree.expand_all, opts('Expand All'))
        vim.keymap.set('n', ']e', api.node.navigate.diagnostics.next, opts('Next Diagnostic'))
        vim.keymap.set('n', '[e', api.node.navigate.diagnostics.prev, opts('Prev Diagnostic'))
        vim.keymap.set('n', 'F', api.live_filter.clear, opts('Clean Filter'))
        vim.keymap.set('n', 'f', api.live_filter.start, opts('Filter'))
        vim.keymap.set('n', 'g?', api.tree.toggle_help, opts('Help'))
        vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
        vim.keymap.set('n', 'H', api.tree.toggle_hidden_filter, opts('Toggle Dotfiles'))
        vim.keymap.set('n', 'I', api.tree.toggle_gitignore_filter, opts('Toggle Git Ignore'))
        vim.keymap.set('n', 'J', api.node.navigate.sibling.last, opts('Last Sibling'))
        vim.keymap.set('n', 'K', api.node.navigate.sibling.first, opts('First Sibling'))
        vim.keymap.set('n', 'o', api.node.open.edit, opts('Open'))
        vim.keymap.set('n', 'O', api.node.open.no_window_picker, opts('Open: No Window Picker'))
        vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))
        vim.keymap.set('n', 'P', api.node.navigate.parent, opts('Parent Directory'))
        vim.keymap.set('n', 'q', api.tree.close, opts('Close'))
        vim.keymap.set('n', 'r', api.fs.rename, opts('Rename'))
        vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
        vim.keymap.set('n', 'S', api.tree.search_node, opts('Search'))
        vim.keymap.set('n', 'U', api.tree.toggle_custom_filter, opts('Toggle Hidden'))
        vim.keymap.set('n', 'W', api.tree.collapse_all, opts('Collapse'))
        vim.keymap.set('n', 'x', api.fs.cut, opts('Cut'))
        vim.keymap.set('n', 'y', api.fs.copy.filename, opts('Copy Name'))
        vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts('Copy Relative Path'))
      end

      local signcolumn_width = 7
      local min_buffer_width = 110 + signcolumn_width
      local total_dual_panel_cols = min_buffer_width * 2 + 1
      local min_sidebar_width = 10
      local max_sidebar_width = 32

      vim.cmd([[hi NvimTreeNormal guibg=NONE ctermbg=NONE]])

      local get_sidebar_cols = function()
        local neovim_cols = vim.o.columns
        local sidebar_cols = neovim_cols - min_buffer_width - 1
        if total_dual_panel_cols < (neovim_cols - min_sidebar_width) then
          sidebar_cols = neovim_cols - total_dual_panel_cols - 1
        end
        if sidebar_cols < min_sidebar_width then
          sidebar_cols = min_sidebar_width
        end
        if sidebar_cols > max_sidebar_width then
          sidebar_cols = max_sidebar_width
        end
        return sidebar_cols
      end

      require("nvim-tree").setup({
        on_attach = my_on_attach, 
        hijack_unnamed_buffer_when_opening = true,
        sync_root_with_cwd = false,
        auto_reload_on_write = true,
        reload_on_bufenter = true,
        disable_netrw = true,
        hijack_netrw = true,
        prefer_startup_root = true,
        open_on_tab = false,
        update_cwd = false, -- updates the root directory of the tree on `DirChanged` (when your run `:cd` usually)
        diagnostics = {
          enable = false,
          show_on_dirs = false,
          show_on_open_dirs = true,
          debounce_delay = 50,
          severity = {
            min = vim.diagnostic.severity.HINT,
            max = vim.diagnostic.severity.ERROR,
          },
          icons = {
            hint = '󰮥',
            info = '󰋼',
            warning = '',
            error = '',
          },
        },
        modified = {
          enable = false,
          show_on_dirs = true,
          show_on_open_dirs = true,
        },
        update_focused_file = { -- update the focused file on `BufEnter`, un-collapses the folders recursively until it finds the file
          enable = false,
          update_cwd = false,
          update_root = {
            enable = true,
            ignore_list = { '.git', 'node_modules', '.cache' },
          },
          ignore_list = {},
        },
        git = {
          enable = true,
          ignore = false,
          show_on_dirs = true,
          show_on_open_dirs = true,
          timeout = 400,
        },
        filesystem_watchers = {
          enable = true,
          debounce_delay = 15,
          ignore_dirs = {
            'node_modules',
          },
        },
        renderer = {
          add_trailing = false,
          hidden_display = 'none',
          highlight_modified = 'none',
          highlight_opened_files = 'none',
          highlight_diagnostics = 'none',
          highlight_git = 'none',
          symlink_destination = false,
          indent_width = 3,
          indent_markers = {
            enable = false,
            inline_arrows = true,
            icons = {
              corner = '└',
              edge = '│',
              item = '│',
              bottom = '─',
              none = ' ',
            },
          },
          icons = {
            web_devicons = {
              file = {
                enable = true,
                -- color = false,
              },
              folder = {
                enable = false,
                color = true,
              },
            },
            git_placement = 'before',
            modified_placement = 'after',
            padding = ' ',
            diagnostics_placement = 'signcolumn',
            symlink_arrow = ' ➛ ',
            webdev_colors = true,
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
              modified = true,
              diagnostics = false,
              bookmarks = false,
              hidden = false,
            },
            glyphs = {
              default = '',
              symlink = '',
              bookmark = '󰆤',
              modified = '●',
              folder = {
                arrow_closed = '▸',
                arrow_open = '▾',
                default = '',
                empty = '',
                empty_open = '',
                open = '',
                symlink = '',
                symlink_open = '',
              },
              git = {
                unstaged = '',
                staged = '✓',
                unmerged = '',
                renamed = '󰑃',
                untracked = '󰛄',
                deleted = '',
                ignored = '',
              },
            },
          },
        },
        view = {
          centralize_selection = false,
          cursorline = true,
          preserve_window_proportions = false,
          debounce_delay = 15,
          relativenumber = false,
          adaptive_size = true,
          number = false,
          signcolumn = 'auto',
          width = get_sidebar_cols(),
          float = {
            enable = false,
          },
        },
        filters = {
          git_ignored = false,
          dotfiles = false,
          git_clean = false,
          no_buffer = false,
          custom = {
            '^.git$',
            '^node_modules$',
            '^dist$',
            '^.eslintcache$',
            '^.next$',
            '.DS_Store',
            'tmp',
            -- 'logs',
          },
        },
        log = {
          enable = false,
          truncate = false,
          types = {
            all = false,
            config = false,
            copy_paste = false,
            diagnostics = false,
            git = false,
            profile = false,
          },
        },
        live_filter = {
          prefix = '[FILTER]: ',
          always_show_folders = true,
        },
        actions = {
          expand_all = {
            max_folder_discovery = 50,
            exclude = {},
          },
          use_system_clipboard = true,
          change_dir = {
            enable = true,
            global = false,
            restrict_above_cwd = false,
          },
          open_file = {
            quit_on_open = true,
            eject = true,
            resize_window = false,
            window_picker = {
              enable = false,
              picker = 'default',
              chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
              exclude = {
                filetype = { 'notify', 'packer', 'qf', 'diff', 'fugitive', 'fugitiveblame', 'lazy' },
                buftype = { 'nofile', 'terminal', 'help', 'diff' },
              },
            },
          },
          remove_file = {
            close_window = false,
          },
        },
        hijack_directories = {
          enable = true,
          auto_open = true,
        },
      })
    end,
  },
 {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'master',  -- NOTE: Use master for backwards compatibility.
    -- NOTE: this causes error on main
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    opts = {
      ensure_installed = ensure_installed,
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    -- NOTE: this causes error on main
    config = function(_, opts)
      -- require('config.treesitter').setup(opts)
      require('nvim-treesitter.configs').setup(opts)
    end,
  },

   { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        'mm',
        function()
          require('conform').format({ async = false, lsp_fallback = true, timeout_ms = 1000 })
        end,
        desc = 'Format buffer',
      },
    },
    opts = {
      notify_on_error = true,
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        sh = { 'shfmt', 'shellharden', 'beautysh', stop_after_first = true },
      },
    },
  },
 {
  'eddyekofo94/gruvbox-flat.nvim',
  priority = 1000,
  enabled = true,
  lazy = false,
  config = function()
    vim.cmd([[colorscheme gruvbox-flat]])
  end,
},
  {
  'luukvbaal/nnn.nvim',
  lazy = false,
  enabled = true,
  keys = {
    {
      '<leader>n',
      function()
        local activeFilePath = vim.api.nvim_buf_get_name(0)
        vim.api.nvim_command(string.format('NnnPicker %s', activeFilePath))
      end,
      mode = { 'n' },
      desc = 'Open NNN',
    },
  },
  config = function()
    local signcolumn_width = 7
    local min_buffer_width = 110 + signcolumn_width
    local total_dual_panel_cols = min_buffer_width * 2 + 1
    local min_sidebar_width = 10
    local max_sidebar_width = 32

    local nnn = require('nnn')
    local builtin = require('nnn').builtin

    local get_sidebar_cols = function()
      local neovim_cols = vim.o.columns
      local sidebar_cols = neovim_cols - min_buffer_width - 1
      if total_dual_panel_cols < (neovim_cols - min_sidebar_width) then
        sidebar_cols = neovim_cols - total_dual_panel_cols - 1
      end
      if sidebar_cols < min_sidebar_width then
        sidebar_cols = min_sidebar_width
      end
      if sidebar_cols > max_sidebar_width then
        sidebar_cols = max_sidebar_width
      end
      return sidebar_cols
    end

    nnn.setup({
      explorer = {
        width = get_sidebar_cols(),
        side = 'topleft',
        tabs = false,
        fullscreen = false,
      },
      mappings = {
        { '<C-t>', builtin.open_in_tab }, -- open file(s) in tab
        { '<C-s>', builtin.open_in_split }, -- open file(s) in split
        { '<C-v>', builtin.open_in_vsplit }, -- open file(s) in vertical split
        { '<C-y>', builtin.copy_to_clipboard }, -- copy file(s) to clipboard
        { '<C-e>', builtin.populate_cmdline }, -- populate cmdline (:) with file(s)
      },
      auto_open = {
        ft_ignore = { 'gitcommit' },
      },
      replace_netrw = 'picker',
      quitcd = 'cd',
    })
  end,
}
}, {})
