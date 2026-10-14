#!/usr/bin/env bash
# Set up an Arch + i3 machine from this repo, from a bare archinstall:
#
#   curl -fsSL https://raw.githubusercontent.com/hahaharshil/dot-/master/install.sh | bash
#
# or, from a clone: ./install.sh
#
# Needs only a sudo user and a network connection; works from any archinstall
# profile, Minimal included. Safe to re-run: every step skips what is done.
# Laptops: run ./laptop-setup.sh afterwards for the system-level settings.
set -euo pipefail

REPO=https://github.com/hahaharshil/dot-.git
PACKAGES=(
    git base-devel stow
    # X and a login screen, so a Minimal profile boots into i3 too. --needed
    # makes these no-ops when archinstall's i3 profile already put them there.
    xorg-server xorg-xinit ly mesa
    i3-wm i3blocks dmenu xss-lock dex xorg-xset feh brightnessctl
    networkmanager network-manager-applet flameshot xclip sysstat
    pipewire pipewire-pulse wireplumber
    bluez bluez-utils blueman
    alacritty ttf-jetbrains-mono-nerd fastfetch
    neovim clang gcc
)
STOW_PACKAGES=(nvim i3 alacritty bash)

say()  { printf '\n\033[1;32m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# Everything runs from main, called on the last line, so bash has read the
# whole script before any step runs. Under `curl | bash` the script arrives on
# stdin, and a step that read stdin would otherwise swallow the rest of it.
main() {
    [ "$(id -u)" -ne 0 ] || { echo "Run as your user, not root; it sudos itself." >&2; exit 1; }
    command -v pacman >/dev/null || { echo "Arch only (needs pacman)." >&2; exit 1; }

    install_packages
    install_aur
    clone_repos
    stow_packages
    ensure_host_file
    enable_services
    install_nvim_plugins

    say "Done. Reboot, or \$mod+Shift+r if already in i3."
    if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
        echo "This is a laptop: run $DOTS/laptop-setup.sh next."
    fi
}

install_packages() {
    say "Installing packages"
    # pipewire-pulse conflicts with pulseaudio, and --noconfirm answers "no"
    # to removing it, which fails the whole transaction. Swap it out first.
    # Take its plugins (pulseaudio-bluetooth, -alsa, ...) with it, or they're
    # left depending on a package that's gone.
    local pulse
    pulse=$(pacman -Qq | grep '^pulseaudio' || true)
    if [ -n "$pulse" ]; then
        warn "Replacing pulseaudio with pipewire-pulse"
        # shellcheck disable=SC2086 # one package name per word
        sudo pacman -Rdd --noconfirm $pulse
    fi
    sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"
}

install_aur() {
    local helper
    helper=$(command -v yay || command -v paru || true)
    if [ -z "$helper" ]; then
        say "Bootstrapping yay"
        local tmp
        tmp=$(mktemp -d)
        git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
        helper=yay
    fi
    say "Installing betterlockscreen (AUR)"
    "$helper" -S --needed --noconfirm betterlockscreen
}

clone_repos() {
    # Must exist before stow, or stow links ~/.config itself into the first
    # package and every app then writes its settings into the repo.
    mkdir -p "$HOME/.config"

    say "Cloning repos"
    # Run from a clone: use it, wherever it lives. Piped from curl: clone.
    local self="${BASH_SOURCE[0]:-}"
    if [ -n "$self" ] && [ -f "$self" ] && [ -d "$(dirname "$self")/i3" ]; then
        DOTS=$(cd "$(dirname "$self")" && pwd)
    else
        DOTS=$HOME/dot-
        [ -d "$DOTS/.git" ] || git clone "$REPO" "$DOTS"
    fi
    echo "dotfiles: $DOTS"

    [ -d "$HOME/.config/i3blocks-contrib" ] ||
        git clone --depth 1 https://github.com/vivien/i3blocks-contrib "$HOME/.config/i3blocks-contrib"
}

stow_packages() {
    say "Stowing"
    # Any real file where a link should go (/etc/skel's .bashrc, the config
    # i3-config-wizard writes on a first login, ...) makes stow abort every
    # package. Ask stow what's in the way and move each aside, not delete it.
    # Two patterns: stow >= 2.3 and older phrase the conflict differently.
    # The dry run exits non-zero exactly when there are conflicts, so capture
    # it rather than let pipefail end the script.
    local f dry
    dry=$(stow -n -d "$DOTS" -t "$HOME" -R "${STOW_PACKAGES[@]}" 2>&1 || true)
    printf '%s\n' "$dry" |
        sed -n -e 's/.*over existing target \(.*\) since .*/\1/p' \
               -e 's/.*existing target is neither a link nor a directory: \(.*\)/\1/p' |
        while IFS= read -r f; do
            mv "$HOME/$f" "$HOME/$f.pre-dotfiles"
            warn "moved ~/$f to ~/$f.pre-dotfiles"
        done
    stow -d "$DOTS" -t "$HOME" -R "${STOW_PACKAGES[@]}"
}

ensure_host_file() {
    # i3 includes hosts/`uname -n`.conf and silently skips a missing one,
    # which leaves X's 10-minute blank-and-lock. Give a new machine a file,
    # from the laptop or desktop flavour depending on whether it has a battery.
    local host dir
    host=$(uname -n)
    dir=$DOTS/i3/.config/i3/hosts
    [ -f "$dir/$host.conf" ] && return
    if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
        cat > "$dir/$host.conf" <<'EOF'
# Laptop: lock after 5 minutes idle -- xss-lock catches the screensaver
# signal -- and power the screen off after 10. Requires xorg-xset.
exec --no-startup-id xset s 300 300
exec --no-startup-id xset dpms 0 0 600
EOF
    else
        cat > "$dir/$host.conf" <<'EOF'
# Desktop: never blank, power down, or lock on idle; the only lock is $mod+q.
# Requires xorg-xset.
exec --no-startup-id xset s off -dpms
EOF
    fi
    warn "Created i3/.config/i3/hosts/$host.conf -- commit it to keep it."
}

enable_services() {
    say "Enabling services"
    # nm-applet needs NetworkManager, but two network managers fight over the
    # same interfaces; leave a machine set up with systemd-networkd alone.
    if systemctl is-enabled --quiet systemd-networkd.service 2>/dev/null; then
        warn "systemd-networkd is enabled; not enabling NetworkManager."
    else
        sudo systemctl enable NetworkManager.service
    fi
    # bluetooth.service is conditioned on /sys/class/bluetooth, so on a
    # machine without an adapter it's enabled but simply never starts.
    sudo systemctl enable bluetooth.service
    # Only when no login screen is set up yet: archinstall's profiles enable
    # their own, and two fight over the same tty. Check the .wants links too:
    # ly is enabled as a template instance (ly@tty2) and never creates the
    # display-manager.service alias.
    if [ -e /etc/systemd/system/display-manager.service ] ||
        ls /etc/systemd/system/*.wants/ 2>/dev/null |
            grep -qE '^(ly|lightdm|sddm|gdm|greetd|lxdm|lemurs)(@.*)?\.service$'; then
        echo "login screen already enabled; leaving it"
    elif [ -e /usr/lib/systemd/system/ly@.service ]; then
        sudo systemctl enable ly@tty2.service
    else
        sudo systemctl enable ly.service   # ly before the 1.1 template unit
    fi
}

install_nvim_plugins() {
    say "Installing nvim plugins (pinned by lazy-lock.json)"
    # Not fatal: nvim installs them on first launch anyway.
    nvim --headless "+Lazy! restore" +qa ||
        warn "nvim plugin install failed; open nvim to retry."
}

main "$@"
