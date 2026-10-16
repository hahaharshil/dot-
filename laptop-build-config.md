# Laptop build config

The full specification of the laptop build, the setup every other machine
should match. It was taken from the running laptop on 2026-10-16. Everything
in this file lives in this repo or is listed here, so another machine
(or Claude Code on it) can rebuild the same thing from this file alone.

To copy it onto another machine, open Claude Code in `~/dot-` and say:

> Read `laptop-build-config.md` and make this machine match it.

## Hardware (the laptop)

| Part     | Spec                                                        |
|----------|-------------------------------------------------------------|
| Model    | Lenovo ThinkPad T480 (20L6SJQE00)                            |
| CPU      | Intel Core i5-8350U, 4 cores / 8 threads, 1.70 GHz           |
| GPU      | Intel UHD Graphics 620 (integrated, Kaby Lake-R)            |
| RAM      | 16 GB                                                       |
| Storage  | 256 GB NVMe SSD (SK hynix BC711)                             |
| Screen   | 14" 1920x1080 (LG panel), at scale 1                         |
| Wi-Fi    | Intel Wireless 8265                                         |
| Audio    | Intel Sunrise Point-LP HD Audio                             |
| Battery  | Two: BAT0 internal, BAT1 external                            |
| External | Dell P2419H 1920x1080 monitor (when docked)                 |

## System

- **OS:** Arch Linux, kernel 7.2.9-arch1-1, hostname `archlinux`
- **Swap:** 4 GB zram (`zram-generator`)
- **Audio:** PipeWire 1.6.9 with `pipewire-pulse`, `pipewire-alsa`,
  `pipewire-jack` and WirePlumber 0.5.18
- **Network:** NetworkManager, with `nm-applet` in the bar; `systemd-resolved`
- **Firewall:** `ufw` (enabled)
- **Power:** TLP 1.10.2 (laptop only, set up by `laptop-setup.sh`)
- **Printing:** CUPS + `system-config-printer`
- **Login:** plain tty login (`getty`). `ly` is not installed on the laptop,
  but `install.sh` installs it on a machine with no login screen.
- **AUR helper:** `yay-bin`

Enabled services: `NetworkManager`, `bluetooth`, `tlp`, `ufw`, `cups`,
`systemd-resolved`, `systemd-timesyncd`, `fstrim.timer`.

## Desktop: Hyprland

| Component       | Package / version            | Config in repo                                |
|-----------------|------------------------------|-----------------------------------------------|
| Compositor      | hyprland 0.56.2 (Lua config) | `hyprland/.config/hypr/hyprland.lua`           |
| Bar             | waybar 0.15.0                | `hyprland/.config/waybar/config.jsonc`, `style.css` |
| Notifications   | mako 1.11.0                  | `hyprland/.config/mako/config`                 |
| Lock screen     | hyprlock 0.9.6               | `hyprland/.config/hypr/hyprlock.conf`          |
| Idle            | hypridle 0.1.8               | `hyprland/.config/hypr/hypridle.conf`          |
| Wallpaper       | swaybg 1.2.2                 | `hyprland/.config/hypr/wallpaper.jpg`          |
| Launcher        | wmenu (`wmenu-run`)          | colours set in `hyprland.lua`                  |
| Terminal        | kitty 0.49.2                 | `kitty/.config/kitty/kitty.conf`               |
| File manager    | pcmanfm                      | none                                          |
| Music           | spotify-player 0.25.1        | `hyprland/.config/spotify-player/app.toml`     |
| GTK theme       | Adwaita dark                 | `hyprland/.config/gtk-3.0/settings.ini`        |
| Fonts           | JetBrainsMono Nerd Font      | `hyprland/.config/fontconfig/fonts.conf`       |

### Look

- Tiling layout `dwindle` with `preserve_split`. Gaps are 4 between windows
  and 8 at the screen edge.
- 2px borders: cyan `#33ccff` on the focused window, grey otherwise.
  Corners are rounded to 6, with no shadows and no blur.
- Animations take 0.3 s on a "snappy" bezier curve.
- Wallpaper: `swaybg -m fill`.
- kitty: JetBrainsMono Nerd Font at 10.5 pt, `background_opacity 0.7`, and a
  cursor trail.
- nvim: gruvbox (hard contrast) with `transparent_mode`, so kitty's
  see-through background shows behind the text.
- Dark mode for GTK 3, GTK 4 and portal apps such as Firefox.

### Waybar

- Left: the workspaces and the focused window's title.
- Centre: the clock (`HH:MM:SS`, ticking every second). Click it to show the
  full date.
- Right: CPU %, CPU temperature (turns red at 80°C), RAM in MB, brightness,
  volume, network, battery and the tray.

### Keybinds (Super = Windows key)

| Key                          | Action                                   |
|------------------------------|------------------------------------------|
| Super+Enter                  | kitty                                    |
| Super+D                      | wmenu launcher                           |
| Super+E                      | pcmanfm                                  |
| Super+Shift+Q                | close window                             |
| Super+F                      | fullscreen                               |
| Super+Shift+Space            | toggle floating                          |
| Super+B                      | next window opens to the right           |
| Super+V                      | next window opens below                  |
| Super+H/J/K/L or arrows      | move focus                               |
| Super+Shift+H/J/K/L or arrows| move window                              |
| Super+1..0                   | go to workspace 1..10                    |
| Super+Shift+1..0             | send window to workspace 1..10           |
| Super+left/right mouse drag  | move / resize window                     |
| Super+Escape                 | lock (hyprlock)                          |
| Super+Shift+E                | exit Hyprland                            |
| Print / Shift+Print          | screenshot of the whole screen / a dragged area, saved to `~/Pictures` and copied |
| Volume, brightness, media keys | wpctl / brightnessctl / playerctl (these work while locked) |
| 3-finger horizontal swipe    | switch workspace                         |

Input: US keyboard layout, key repeat after 300 ms at 40 per second, focus
follows the mouse, touchpad natural scroll.

Idle: lock at 5 min, screen off at 6 min, suspend at 15 min. The screen also
locks before every suspend.

### Autostart

`swaybg`, `waybar`, `mako`, `hypridle`, `nm-applet`, `hyprpolkitagent`, and
`gsettings ... color-scheme prefer-dark`.

## Neovim

neovim 0.12.6 with lazy.nvim. Plugins are pinned by
`nvim/.config/nvim/lazy-lock.json`: gruvbox.nvim, mini.nvim, nvim-lspconfig,
nvim-tree, nvim-web-devicons, nui.nvim and competitest.nvim. `clangd` (from
`clang`) and `gcc` handle C/C++. See the README's Neovim section.

## Shell

bash, with `bash/.bashrc` and `bash/.bash_profile`. The prompt is a green
user and a cyan working directory. `~/.local/bin` is on `PATH`, and
`fastfetch` runs when a shell opens.

## Rebuilding on another machine

```sh
git clone https://github.com/hahaharshil/dot-.git ~/dot-   # or: cd ~/dot- && git pull
cd ~/dot- && DESKTOP=hyprland ./install.sh
```

`install.sh` installs the base and Hyprland packages, then stows `nvim`,
`alacritty`, `kitty`, `bash` and `hyprland` into `~` and pins the nvim
plugins. Any existing file in the way is moved aside as `*.pre-dotfiles`.

The laptop also has these apps that `install.sh` does **not** install. Add
them to match it exactly:

```sh
sudo pacman -S --needed firefox github-cli htop ranger zathura zathura-pdf-mupdf \
    nwg-displays openssh ufw cups cups-pk-helper system-config-printer \
    vim nano wget cmake ninja smartmontools fwupd xdg-utils \
    pipewire-alsa pipewire-jack gst-plugin-pipewire libpulse hyprlauncher zram-generator
yay -S --needed zen-browser-bin
sudo systemctl enable --now ufw cups
```

These are laptop-only and **not** for the PC: `tlp` and `laptop-setup.sh`
(battery), plus the Intel GPU drivers (`intel-media-driver`,
`libva-intel-driver`, `vulkan-intel`) and `intel-ucode` unless the PC is
also Intel.

### Hardware differences to check on the PC

- **CPU temperature in waybar** reads Intel's `coretemp`
  (`/sys/devices/platform/coretemp.0/hwmon`). An AMD CPU needs the `k10temp`
  hwmon path in `config.jsonc`, or the module stays blank.
- **GPU:** an AMD GPU needs `vulkan-radeon` and `libva-mesa-driver`. NVIDIA
  needs the `nvidia-open` driver and the NVIDIA setup on the Hyprland wiki.
- **Monitors:** every screen is set to its preferred mode at `scale = 1`. A
  1440p or 4K screen may want 1.25 to 1.5 in `hyprland.lua`. The laptop's
  `monitors.lua` from nwg-displays is machine-specific and not in the repo.
- **No battery:** waybar's battery module hides itself, and `install.sh`
  skips the laptop steps.
- **Idle suspend at 15 min** comes from `hypridle.conf`. Remove that
  listener if the PC shouldn't sleep.
