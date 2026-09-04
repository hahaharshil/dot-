# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level
directory is a stow package whose contents mirror `$HOME`.

```
nvim/.config/nvim/                        ->  ~/.config/nvim/
i3/.config/i3/config                      ->  ~/.config/i3/config
alacritty/.config/alacritty/alacritty.toml -> ~/.config/alacritty/alacritty.toml
bash/.bashrc, bash/.bash_profile          ->  ~/.bashrc, ~/.bash_profile
```

Stow one package at a time, so a macOS machine can take `nvim` without `i3`.

## Setting up a new machine

```sh
brew install stow          # or: apt install stow
git clone https://github.com/hahaharshil/dot-.git ~/code/dot-
cd ~/code/dot-
stow nvim          # or: stow nvim i3 alacritty bash
```

`stow nvim` symlinks `~/.config/nvim` to this repo, so edits in either place are
the same files.

If `~/.config/nvim` already exists as a real directory, move it aside first —
stow refuses to overwrite:

```sh
mv ~/.config/nvim ~/.config/nvim.bak
stow nvim
```

## Neovim

Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), which
bootstraps itself on first launch. `lazy-lock.json` pins exact commits, so every
machine gets identical plugin versions. Just open `nvim` and wait for the
install to finish.

Requires, for the C/C++ setup:

- `gcc` (Homebrew, provides `g++-15`) — the actual compiler
- `clangd` — LSP; ships with Xcode Command Line Tools on macOS
- [Competitive Companion](https://github.com/jmerle/competitive-companion)
  browser extension (Chrome/Firefox only) for pulling problems into CompetiTest

On macOS `include/bits/stdc++.h` is a shim so clangd can resolve that header;
Apple ships clang, which has no such file. Compilation still uses real GCC.
