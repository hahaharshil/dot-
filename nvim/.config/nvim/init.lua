-- Leader must be set before any <leader> mapping is defined
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- General Settings
vim.opt.number = true             -- Show absolute line numbers
vim.opt.relativenumber = true     -- Show relative line numbers (great for jumping lines)
vim.opt.cursorline = true         -- Highlight the line where the cursor is
vim.opt.mouse = 'a'               -- Enable mouse support (useful for scrolling/selecting)
vim.opt.termguicolors = true      -- Enable 24-bit RGB colors
vim.opt.signcolumn = 'yes'        -- Always show the sign column so text never shifts sideways
vim.opt.scrolloff = 5             -- Keep some context above/below the cursor
vim.opt.splitbelow = true         -- New horizontal splits go below
vim.opt.splitright = true         -- New vertical splits go right
vim.opt.confirm = true            -- Prompt to save instead of failing on :q

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
vim.opt.undofile = true           -- Persistent undo, survives closing the file
vim.opt.completeopt = 'menuone,noselect' -- mini.completion needs this to not auto-insert

-- Derive the Codeforces problem ID from a received problem's URL, so files land
-- as 2094A.cpp (matching the codeforces repo) instead of "A. Watermelon.cpp".
local function problem_id(task)
  local url = (task and task.url) or ''
  local contest, index = url:match('/contest/(%d+)/problem/(%w+)')
  if not contest then
    contest, index = url:match('/problemset/problem/(%d+)/(%w+)')
  end
  if not contest then
    contest, index = url:match('/gym/(%d+)/problem/(%w+)')
  end
  if contest then
    return contest .. index:upper()
  end
  -- Unknown judge: fall back to the problem name, stripped to something safe
  local name = ((task and task.name) or 'problem'):gsub('[^%w]', '')
  return name
end

-- Prefer the Homebrew GCC, fall back to whatever the system provides.
-- Defined up here because both :Run and CompetiTest need it.
local function compiler_for(ext)
  local brew = ext == 'c' and '/opt/homebrew/bin/gcc-15' or '/opt/homebrew/bin/g++-15'
  if vim.fn.executable(brew) == 1 then
    return brew
  end
  return ext == 'c' and 'cc' or 'c++'
end


-- nvim-tree replaces netrw; it must be disabled before the plugin loads
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- 1. BOOTSTRAP THE PLUGIN MANAGER (LAZY.NVIM)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 2. PLUGINS (LSP + SUGGESTIONS)
require("lazy").setup({
  "neovim/nvim-lspconfig", -- Enables "Smart" C/C++ support
  "echasnovski/mini.nvim", -- A "Swiss Army Knife" of tiny, fast modules
  "ellisonleao/gruvbox.nvim",
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({
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
  {
    -- Competitive programming: pulls problems in from the Competitive Companion
    -- browser extension, stores every testcase, runs them all and diffs the output.
    "xeluxee/competitest.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    cmd = "CompetiTest", -- single command with subcommands
    config = function()
      require("competitest").setup({
        compile_command = {
          c   = { exec = compiler_for('c'),   args = { "-std=c17", "-DLOCAL", "$(FNAME)", "-o", "$(FNOEXT)" } },
          cpp = { exec = compiler_for('cpp'), args = { "-std=c++17", "-DLOCAL", "$(FNAME)", "-o", "$(FNOEXT)" } },
        },
        run_command = {
          c   = { exec = "./$(FNOEXT)" },
          cpp = { exec = "./$(FNOEXT)" },
        },
        compile_time_limit = 10,
        running_time_limit = 5, -- seconds, matches the :Run timeout
        received_files_extension = "cpp",
        -- Name received files by problem ID, matching the codeforces repo layout
        received_problems_path = function(task, ext)
          return string.format('%s/%s.%s', vim.fn.getcwd(), problem_id(task), ext)
        end,
        -- Keep testcase .txt files out of the flat solution list
        testcases_directory = ".testcases",
        template_file = vim.fn.stdpath("config") .. "/templates/cp.cpp",
        evaluate_template_modifiers = true,
      })
    end,
  },
})

-- 3. COLORSCHEME & UI
require("gruvbox").setup({ contrast = "hard"})
vim.cmd("colorscheme gruvbox")

require('mini.completion').setup({}) -- Simple, lightweight auto-suggestion
require('mini.pairs').setup({})      -- Auto-close brackets, quotes, braces

-- 4. LSP
-- macOS has no bits/stdc++.h (that's a GCC header, and Apple ships clang).
-- Pointing clangd at GCC's real copy fails too -- clang can't parse libstdc++'s
-- internals -- so include/bits/stdc++.h is a shim built on Apple's own libc++.
-- Editor only: g++-15 still compiles against the real header.
local clangd_env = nil
if vim.fn.has('mac') == 1 then
  local shim = vim.fn.stdpath('config') .. '/include'
  local existing = vim.env.CPLUS_INCLUDE_PATH
  clangd_env = {
    CPLUS_INCLUDE_PATH = existing and (shim .. ':' .. existing) or shim,
  }
end

vim.lsp.config('clangd', {
  cmd = { "clangd" },
  cmd_env = clangd_env,
  root_markers = { ".git", "compile_commands.json" },
})

if vim.fn.executable('clangd') == 1 then
  vim.lsp.enable('clangd')
end

-- Errors inline next to the code; off by default since 0.11
vim.diagnostic.config({ virtual_text = true })

-- 5. C/C++ COMPILE & RUN
-- Runs asynchronously, so an infinite loop or a TLE case never freezes the editor.
local RUN_TIMEOUT_MS = 5000

local out_buf

-- Render text into a reusable scratch split, without stealing focus.
local function show(lines)
  if not (out_buf and vim.api.nvim_buf_is_valid(out_buf)) then
    out_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[out_buf].bufhidden = 'hide'
    -- q closes the output window, like any other scratch pane
    vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = out_buf, silent = true })
  end

  vim.bo[out_buf].modifiable = true
  vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, lines)
  vim.bo[out_buf].modifiable = false

  local win
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == out_buf then win = w end
  end
  if not win then
    local cur = vim.api.nvim_get_current_win()
    vim.cmd('botright 12split')
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, out_buf)
    vim.api.nvim_set_current_win(cur)
  end
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

local function append_all(dst, text)
  for _, line in ipairs(vim.split(text or '', '\n', { trimempty = true })) do
    table.insert(dst, line)
  end
end

local function compile_and_run()
  local ext = vim.fn.expand('%:e')
  if vim.bo.buftype ~= '' or not (ext == 'c' or ext == 'cpp' or ext == 'cc') then
    vim.notify('Run: not a C/C++ source buffer', vim.log.levels.WARN)
    return
  end

  vim.cmd('write')

  local dir = vim.fn.expand('%:p:h')
  local src = vim.fn.expand('%:t')
  local exe = vim.fn.expand('%:t:r')

  -- input.txt is read from the file's own directory, so each problem keeps its own
  local input_path = dir .. '/input.txt'
  local stdin
  if vim.fn.filereadable(input_path) == 1 then
    stdin = table.concat(vim.fn.readfile(input_path), '\n') .. '\n'
  end

  local std = (ext == 'c') and '-std=c17' or '-std=c++17'
  local cmd = { compiler_for(ext), std, '-DLOCAL', src, '-o', exe }

  show({ '  compiling ' .. src .. ' ...' })

  vim.system(cmd, { cwd = dir, text = true }, function(cc)
    if cc.code ~= 0 then
      vim.schedule(function()
        local lines = { '  ✗ ' .. src .. ' — compile error', '' }
        append_all(lines, cc.stderr)
        show(lines)
      end)
      return
    end

    local t0 = vim.uv.hrtime()
    vim.system({ './' .. exe }, {
      cwd = dir,
      text = true,
      stdin = stdin,
      timeout = RUN_TIMEOUT_MS,
    }, function(r)
      local secs = (vim.uv.hrtime() - t0) / 1e9
      vim.schedule(function()
        local head
        if r.code == 124 then
          head = string.format('  ✗ %s — TIMEOUT after %.1fs', src, RUN_TIMEOUT_MS / 1000)
        elseif r.signal ~= 0 then
          head = string.format('  ✗ %s — killed by signal %d (%.2fs)', src, r.signal, secs)
        elseif r.code ~= 0 then
          head = string.format('  ✗ %s — exit %d (%.2fs)', src, r.code, secs)
        else
          head = string.format('  ✓ %s — %.2fs', src, secs)
        end

        local lines = { head, '' }
        append_all(lines, r.stdout)
        if #lines == 2 then
          table.insert(lines, '  (no output)')
        end
        if r.stderr and r.stderr ~= '' then
          table.insert(lines, '')
          table.insert(lines, '  ── stderr ──')
          append_all(lines, r.stderr)
        end
        show(lines)

        -- Keep writing output.txt next to the source, same as before
        vim.fn.writefile(vim.split(r.stdout or '', '\n'), dir .. '/output.txt')
      end)
    end)
  end)
end

vim.api.nvim_create_user_command('Run', compile_and_run, {})
vim.api.nvim_create_user_command('R', compile_and_run, {})

-- 6. CP TEMPLATE
-- Lives in templates/cp.cpp so :CP and CompetiTest share one source of truth.
local CP_TEMPLATE = vim.fn.stdpath('config') .. '/templates/cp.cpp'

-- :CP        fill the current buffer with the template
-- :CP sol    create/open sol.cpp and fill it
vim.api.nvim_create_user_command('CP', function(opts)
  if vim.fn.filereadable(CP_TEMPLATE) ~= 1 then
    vim.notify('CP: template missing at ' .. CP_TEMPLATE, vim.log.levels.ERROR)
    return
  end

  if opts.args ~= '' then
    local name = opts.args
    if not name:match('%.%w+$') then
      name = name .. '.cpp'
    end
    vim.cmd('edit ' .. vim.fn.fnameescape(name))
  end

  local template = vim.fn.readfile(CP_TEMPLATE)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, template)

  -- CompetiTest picks its compile/run command by filetype, so an unnamed
  -- scratch buffer has to be told what it is or the runner bails out
  if vim.bo.filetype == '' then
    vim.bo.filetype = 'cpp'
  end

  -- Drop straight into the body of solve(), wherever it happens to be
  for i, line in ipairs(template) do
    if line:match('^void solve') then
      vim.fn.cursor(i + 1, 1)
      break
    end
  end
  vim.cmd('startinsert!')
end, { nargs = '?', complete = 'file' })

-- 7. KEYMAPS
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })

-- Save, compile, and run the current file with input.txt redirection
vim.keymap.set('n', '<F5>', compile_and_run, { desc = "Compile and Run with input.txt" })

-- Show the diagnostic error message in a floating window
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Show diagnostic error float" })

-- open init.lua (Leader + v)
vim.keymap.set('n', '<leader>v', ':e $MYVIMRC<CR>', { desc = "Open Neovim Config" })

-- reload init.lua after saving (Leader + x)
vim.keymap.set('n', '<leader>x', ':source $MYVIMRC<CR>', { desc = "Reload Neovim Config" })

-- Jump to definition
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to Definition' })

-- Jump to declaration
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'Go to Declaration' })

-- Escape out of a terminal window
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Leave terminal mode' })

-- CompetiTest (leader + t ...)
vim.keymap.set('n', '<leader>tr', '<cmd>CompetiTest run<CR>', { desc = 'CP: run all testcases' })
vim.keymap.set('n', '<leader>ta', '<cmd>CompetiTest add_testcase<CR>', { desc = 'CP: add a testcase' })
vim.keymap.set('n', '<leader>te', '<cmd>CompetiTest edit_testcase<CR>', { desc = 'CP: edit testcases' })
vim.keymap.set('n', '<leader>tR', '<cmd>CompetiTest receive problem<CR>', { desc = 'CP: receive problem from browser' })
vim.keymap.set('n', '<leader>tC', '<cmd>CompetiTest receive contest<CR>', { desc = 'CP: receive whole contest' })
vim.keymap.set('n', '<leader>ts', '<cmd>CompetiTest receive stop<CR>', { desc = 'CP: stop receiving' })
