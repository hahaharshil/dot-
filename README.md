# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level
directory is a stow package whose contents mirror `$HOME`.

```
nvim/.config/nvim/                        ->  ~/.config/nvim/
i3/.config/i3/config, hosts/               ->  ~/.config/i3/config, hosts/
i3/.config/i3blocks/                      ->  ~/.config/i3blocks/
i3/.config/betterlockscreen/              ->  ~/.config/betterlockscreen/
alacritty/.config/alacritty/              ->  ~/.config/alacritty/
bash/.bashrc, bash/.bash_profile          ->  ~/.bashrc, ~/.bash_profile
```

## Quick start (Arch)

On a fresh archinstall (a sudo user, network up, PipeWire for audio; any
profile, Minimal included), log in at the console and run:

```sh
curl -fsSL https://raw.githubusercontent.com/hahaharshil/dot-/master/install.sh | bash
```

It installs every package below (plus X and the `ly` login screen if none is
set up, and Bluetooth: `bluez` with the `blueman` tray applet), clones this repo to `~/dot-` and i3blocks-contrib, moves aside any
file that would block stow (as `*.pre-dotfiles`), stows everything, creates a
`hosts/` file for a new machine, and pre-installs the nvim plugins. Re-running
it is safe. On a laptop, follow with:

```sh
~/dot-/laptop-setup.sh
```

which does the safe system-level settings: TLP with charge thresholds for every
battery, touchpad tap-to-click, suspend-then-hibernate (only if hibernation
already works), and a firmware and sleep-mode check. It writes drop-in files
under `/etc`, so package upgrades don't fight it. It does nothing on a machine
without a battery.

The repo is cloned over HTTPS, so pushing from a new machine needs
`git remote set-url origin git@github.com:hahaharshil/dot-.git` and an SSH key.

The rest of this file explains what the scripts do, for setting up by hand.

## Packages

Stow one package at a time, so a macOS machine can take `nvim` without `i3`.
`i3` is Linux-only; `nvim`, `alacritty` and `bash` are portable as-is. It
needs `feh` (wallpaper), `xorg-xset` (disables screen blanking and the idle
lock) and `betterlockscreen` (the `$mod+q` lock screen, AUR) — these are
`exec` lines, so a missing binary fails silently at login rather than
erroring.

The full Arch package list is `PACKAGES` at the top of `install.sh`. A few
that are easy to drop by mistake:

`xclip` is not optional: nvim sets `clipboard = 'unnamedplus'`, which silently
does nothing on X11 without a clipboard tool. `clangd` comes from the `clang`
package. `git` is needed for lazy.nvim to bootstrap. `sysstat` provides the
`mpstat` the cpu block runs. The volume keys use `pactl` and the volume block
uses `wpctl`, so PipeWire needs both its Pulse shim and WirePlumber.

### Per-machine i3 config (`hosts/`)

The idle timer differs per machine: the desktop (`archlinux`) never blanks or
locks, the laptop (`karma`) locks after 5 minutes and turns the screen off
after 10. i3's `include` can add settings but not override earlier ones, so the
`xset` line lives only in `i3/.config/i3/hosts/<hostname>.conf`, pulled in by
`` include ~/.config/i3/hosts/`uname -n`.conf ``.

**A new machine needs its own file named after `uname -n`.** A missing one is
skipped silently, which leaves X's default: blank and lock after 10 minutes.
`install.sh` creates one (laptop or desktop flavour, by whether there's a
battery); commit it. The desktop's file also sets the two-monitor
wallpaper; the laptop has none.

### Status bar (i3blocks)

The cpu, memory and bandwidth blocks run scripts from
[i3blocks-contrib](https://github.com/vivien/i3blocks-contrib), which is not
vendored. `install.sh` clones it; by hand:

```sh
git clone https://github.com/vivien/i3blocks-contrib ~/.config/i3blocks-contrib
```

The battery block sums every `BAT*` (the T480 has two) and prints nothing on a
machine without one, so i3blocks hides it on the desktop.

betterlockscreen needs its image cache built once per machine (it is sized to
the screen layout, so it does not carry over), and again whenever the
wallpaper or monitor layout changes:

```sh
betterlockscreen -u ~/Pictures/wallpapers/mountain.png
```

Without it the lock screen still locks, on a solid colour. Its
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

`install.sh` handles all of this. By hand, two things to do first on a fresh
install, or stow goes wrong:

- **`mkdir -p ~/.config`.** If it doesn't exist, stow links `~/.config`
  *itself* into the first package, and every app after that writes its
  settings into this repo.
- **Delete the skeleton `~/.bashrc` and `~/.bash_profile`** (`/etc/skel` copies
  them in when the user is created). They conflict with `bash`, and a
  conflict aborts the *whole* stow, not just that package.

Also stow `i3` before the first i3 login, or i3-config-wizard writes its own
`~/.config/i3/config` in the way.

```sh
sudo pacman -S stow        # or: brew install stow / apt install stow
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

## ThinkPad T480 (`karma`)

`laptop-setup.sh` covers TLP, charge thresholds, the touchpad, and the lid
and critical-battery actions once hibernation works. The rest is by hand,
roughly in order of how badly it bites:

1. **Update firmware before anything else**: `fwupdmgr refresh && fwupdmgr
   update`, on AC power. Early T480 Thunderbolt controller firmware wears out
   its own flash chip and kills USB-C. USB-C is the only charging port, so a
   dead controller means a laptop that can't charge. The Thunderbolt
   controller must be enabled in BIOS for the update to apply. fwupd also
   updates the BIOS.
2. **Secure Boot** must be off (BIOS → Security) unless you set up `sbctl`, or
   the installed system won't boot.
3. **Sleep state**: BIOS → Config → Power → Sleep State → **Linux**, so that
   `cat /sys/power/mem_sleep` shows `[deep]`. On `s2idle` the battery drains
   several percent an hour while suspended. Fallback: kernel parameter
   `mem_sleep_default=deep`.
4. **Hibernation** needs real swap ≥ RAM. archinstall's default swap is
   **zram, which can't hibernate**. Add a swap partition or swapfile (on
   btrfs, get the offset with `btrfs inspect-internal map-swapfile -r`), set
   `resume=` (and `resume_offset=` for a swapfile), and on a busybox
   initramfs add the `resume` hook (the `systemd` hook handles it itself).
   Test `systemctl hibernate` once, then re-run `laptop-setup.sh` to switch
   the lid to suspend-then-hibernate.

Worth knowing:

- **With thresholds set, "Not charging" at 79% is normal.** `sudo tlp
  fullcharge` charges to 100% once, before a long day away.
- **The external battery (BAT1) drains first**, then the internal one. That's
  firmware behaviour, not a fault. The bar shows the combined percentage.
- **Check battery health** on a used machine:
  `upower -i /org/freedesktop/UPower/devices/battery_BAT0` and compare
  `energy-full` with `energy-full-design`. Same for `BAT1`.
- **Before opening the case**, set BIOS → Config → Power → *Disable built-in
  battery*, or the internal battery stays live while you work on the board.
- **If the clock or BIOS settings keep resetting**, the internal CMOS coin
  cell is dead. That's common on machines this old.
- **The fingerprint reader** isn't supported by stock `fprintd`; it needs
  `python-validity` from the AUR.
- **Docks and other Thunderbolt devices** need `bolt` (`boltctl authorize`)
  before they work.
- **Kernel parameters** go in `/boot/loader/entries/*.conf` with
  systemd-boot, or in `GRUB_CMDLINE_LINUX` in `/etc/default/grub` followed
  by `grub-mkconfig -o /boot/grub/grub.cfg` with GRUB.
