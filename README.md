# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level
directory is a stow package whose contents mirror `$HOME`.

```
nvim/.config/nvim/                        ->  ~/.config/nvim/
i3/.config/i3/config                      ->  ~/.config/i3/config
alacritty/.config/alacritty/              ->  ~/.config/alacritty/
bash/.bashrc, bash/.bash_profile          ->  ~/.bashrc, ~/.bash_profile
```

Stow one package at a time, so a macOS machine can take `nvim` without `i3`.
`i3` is Linux-only; `nvim`, `alacritty` and `bash` are portable as-is. It
needs `feh` (wallpaper), `xorg-xset` (disables screen blanking and the idle
lock) and `betterlockscreen` (the `$mod+q` lock screen, AUR) — these are
`exec` lines, so a missing binary fails silently at login rather than
erroring.

betterlockscreen needs its image cache built once per machine, and again
whenever the wallpaper or monitor layout changes:

```sh
betterlockscreen -u ~/Pictures/wallpapers/mountain.png
```

Without it the lock screen comes up blank rather than failing loudly. Its
theme is `i3/.config/betterlockscreen/betterlockscreenrc` in this repo —
note the directory: the older `~/.config/betterlockscreenrc` path still works
but warns on every lock.

The `alacritty` package ships `themes/` alongside `alacritty.toml`, because the
config `import`s a theme from it. Stow both together (`stow -t ~ alacritty`) —
linking only the toml leaves the import dangling and Alacritty falls back to
default colors. Switch themes by editing the one `import` line.

Currently on **`jetbrains-islands-dark`**, which reproduces the CLion console
exactly. The values were extracted from the installed IDE rather than matched
by eye: background and foreground from `themes/islands/IslandSchemeDark.xml`
inside `intellij.platform.ide.impl.jar`, and the ANSI 16 from the `Darcula`
scheme in `DefaultColorSchemesManager.xml`, which that file names as its
`parent_scheme` and does not override.

`alacritty.toml` deliberately carries no `[colors.*]` block, so the theme is
the single source of truth. If CLion's own scheme shifts in a future release,
re-extract those two files rather than hand-editing the theme.

### Fonts

Alacritty is set to **JetBrainsMono Nerd Font**. The Nerd Font build matters:
`nvim-tree` and `nvim-web-devicons` draw patched glyphs that the plain
`ttf-jetbrains-mono` package does not carry, so the unpatched font shows tofu
boxes in the file tree. Install it before stowing `alacritty`:

```sh
sudo pacman -S ttf-jetbrains-mono-nerd              # Arch
brew install --cask font-jetbrains-mono-nerd-font   # macOS
```

The family name is the same on both, so no per-machine edit is needed. If the
font is absent Alacritty quietly falls back to the default monospace — if the
terminal looks unstyled, check `fc-list | grep JetBrains` first.

## Setting up a new machine

```sh
brew install stow          # or: apt install stow
git clone https://github.com/hahaharshil/dot-.git ~/code/dot-
cd ~/code/dot-
stow -t ~ nvim     # or: stow -t ~ nvim i3 alacritty bash
```

**`-t ~` is required.** Stow defaults its target to the *parent* of the repo, so
a bare `stow nvim` from `~/code/dot-` would link into `~/code/`, not `~`.
Undo a mistake with `stow -D nvim` (same flags you stowed with).

`stow -t ~ nvim` symlinks `~/.config/nvim` to this repo, so edits in either place are
the same files.

If `~/.config/nvim` already exists as a real directory, move it aside first —
stow refuses to overwrite:

```sh
mv ~/.config/nvim ~/.config/nvim.bak
stow -t ~ nvim
```

Verify with `ls -ld ~/.config/nvim` — it should show an arrow into this repo.
Then remove the backup.

### Check the *directory* is linked, not just one file

If `~/.config/nvim` already exists as a real directory, stow "folds": it links
the individual files it can and silently leaves the rest absent. That looks
like it worked — `init.lua` is a symlink, nvim starts — while `templates/` and
`include/` never get linked at all, so `:CP` fails with "template missing" and
the macOS clangd shim goes missing. `lazy-lock.json` stays a real file and
drifts, defeating the pinning.

So check the directory itself, not a file inside it:

```sh
ls -ld ~/.config/nvim              # must be a symlink, not drwx
find -L ~/.config/nvim -type f     # must list all 5 files
```

If it's a real directory, `rm` the linked files, `rmdir` it, and re-stow.

## Neovim

Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), which
bootstraps itself on first launch. `lazy-lock.json` pins exact commits, so every
machine gets identical plugin versions. Just open `nvim` and wait for the
install to finish.

Requires, for the C/C++ setup:

- `gcc` (`brew install gcc`) — the actual compiler. The config discovers the
  newest `g++-N` in `/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin`
  (Intel), so a Homebrew major bump needs no edit. Without it, `:Run` falls
  back to Apple clang, which has no `<bits/stdc++.h>` — the template's first
  line — so nvim warns at that point rather than failing cryptically.
- `clangd` — LSP; ships with Xcode Command Line Tools on macOS
- [Competitive Companion](https://github.com/jmerle/competitive-companion)
  browser extension (Chrome/Firefox only) for pulling problems into CompetiTest

On macOS `include/bits/stdc++.h` is a shim so clangd can resolve that header;
Apple ships clang, which has no such file. Compilation still uses real GCC.
