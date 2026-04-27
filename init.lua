-- General Settings
vim.opt.number = true             -- Show absolute line numbers
vim.opt.relativenumber = true     -- Show relative line numbers (great for jumping lines)
vim.opt.cursorline = true         -- Highlight the line where the cursor is
vim.opt.mouse = 'a'               -- Enable mouse support (useful for scrolling/selecting)
vim.opt.termguicolors = true      -- Enable 24-bit RGB colors

-- Tabs and Indentation
vim.opt.tabstop = 4               -- Number of spaces a tab counts for
vim.opt.shiftwidth = 4            -- Number of spaces for auto-indent
vim.opt.expandtab = true          -- Convert tabs to spaces
vim.opt.smartindent = true        -- Make indenting "smart" for C/C++

-- Search
vim.opt.ignorecase = true         -- Ignore case in search patterns
vim.opt.smartcase = true          -- ...unless the search contains an uppercase letter
vim.opt.hlsearch = false          -- Don't keep highlighting after the search is done

-- Clipboard & Performance
vim.opt.clipboard = 'unnamedplus' -- Use system clipboard
vim.opt.updatetime = 250          -- Faster completion and UI updates

vim.cmd("colorscheme habamax")




-- 1. BOOTSTRAP THE PLUGIN MANAGER (LAZY.NVIM)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 2. PLUGINS (LSP + SUGGESTIONS)
require("lazy").setup({
  "neovim/nvim-lspconfig", -- Enables "Smart" C/C++ support
  {"williamboman/mason.nvim", config = true},
  {"williamboman/mason-lspconfig.nvim" , config = true},
  "echasnovski/mini.nvim",  -- A "Swiss Army Knife" of tiny, fast modules
  "ellisonleao/gruvbox.nvim",
  {
      "nvim-tree/nvim-tree.lua",
      version = "*",
      lazy = false,
      dependencies = {
          "nvim-tree/nvim-web-devicons",
        },
    config = function()
        require("nvim-tree").setup ({
            renderer = {
                icons = {
                    show = {
                    file = true,
                    folder = true,
                    git = true,
                },
                },
            },
        })
    end,
  },

})
-- 4. BASIC SETTINGS
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.clipboard = "unnamedplus"
vim.cmd("colorscheme gruvbox")
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })

vim.lsp.config('clangd', {
  cmd = { "clangd" },
  root_markers = { ".git", "compile_commands.json" },
})

vim.lsp.enable('clangd')


require('mini.completion').setup({}) -- Simple, lightweight auto-suggestions
