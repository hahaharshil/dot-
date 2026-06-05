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
require("gruvbox").setup({ contrast = "hard"})
vim.cmd("colorscheme gruvbox")
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })

vim.lsp.config('clangd', {
  cmd = { "clangd" },
  root_markers = { ".git", "compile_commands.json" },
})

vim.lsp.enable('clangd')

-- Save, compile, and run C++ with input.txt redirection
vim.keymap.set('n', '<F5>', function()
  vim.cmd('write') -- Save current file
  -- Compile and run, piping input.txt directly into the execution
  vim.cmd('split | term g++ -std=c++17 sol.cpp -o sol && ./sol < input.txt')
end, { desc = "Compile and Run CP with input.txt" })


vim.api.nvim_create_user_command('CP', function()
  local template = {
    "#include <bits/stdc++.h>",
    "using namespace std;",
    "",
    "using ll  = long long;",
    "using vi  = vector<int>;",
    "using vll = vector<long long>;",
    "using pii = pair<int, int>;",
    "using pp  = pair<int, int>;",
    "",
    "#define pb push_back",
    "#define all(x) (x).begin(), (x).end()",
    "#define sz(x) (int)(x).size()",
    "",
    "void solve() {",
    "    ",
    "}",
    "",
    "int main() {",
    "    ios_base::sync_with_stdio(false);",
    "    cin.tie(NULL);",
    "    ",
    "    int t = 1;",
    "    cin >> t;",
    "    while (t--) {",
    "        solve();",
    "    }",
    "    return 0;",
    "}"
  }

  vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
  vim.fn.cursor(15, 5)
end, {})

vim.api.nvim_create_user_command('Run', function()
  vim.cmd('write')
  local file_dir = vim.fn.expand('%:p:h')
  local file_name = vim.fn.expand('%:t')
  local file_no_ext = vim.fn.expand('%:t:r')
  local run_cmd = string.format(
    'cd "%s" && /opt/homebrew/bin/g++-15 -std=c++17 -DLOCAL "%s" -o "%s" && ./"%s" < input.txt > output.txt',
    file_dir, file_name, file_no_ext, file_no_ext
  )
  local compile_output = vim.fn.system(run_cmd)
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({{compile_output, "ErrorMsg"}}, true, {})
  else
    print("✓ Executed Successfully")
  end
end, {})



-- Show the diagnostic error message in a floating window
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Show diagnostic error float" })
-- Jump to the previous/next error
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
-- open init.lua (Leader + v)
vim.keymap.set('n', '<leader>v', ':e $MYVIMRC<CR>', { desc = "Open Neovim Config" })

-- reload init.lua after saving (Leader + x)
vim.keymap.set('n', '<leader>x', ':source $MYVIMRC<CR>', { desc = "Reload Neovim Config" })

vim.api.nvim_create_user_command('R', 'Run', {})
require('mini.completion').setup({}) -- Simple, lightweight auto-suggestion

-- Jump to definition
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to Definition' })

-- Jump to declaration
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'Go to Declaration' })
