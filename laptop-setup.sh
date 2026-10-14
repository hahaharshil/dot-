#!/usr/bin/env bash
# System-level laptop settings the dotfiles can't hold, because they live in
# /etc rather than $HOME. Run after install.sh, on any laptop:
#
#   ~/dot-/laptop-setup.sh
#
# Only does what is safe unattended. Settings go in drop-in files (*.conf.d/)
# rather than edits to the packaged configs, so package upgrades never
# conflict with them and a re-run just rewrites the same files. Firmware, BIOS
# and hibernation setup stay manual -- see the README.
set -euo pipefail

# Charge thresholds: holding a battery below full slows its wear on a laptop
# that lives on AC. `tlp fullcharge` charges to 100% once, for a day out.
CHARGE_START=75
CHARGE_STOP=80

# How long the lid-closed laptop stays asleep before hibernating. systemd still
# hibernates sooner if the battery runs low while asleep.
HIBERNATE_AFTER=4h

say()  { printf '\n\033[1;32m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# Write stdin to a root-owned file, creating its directory.
put() {
    sudo mkdir -p "$(dirname "$1")"
    sudo tee "$1" >/dev/null
    echo "wrote $1"
}

main() {
    [ "$(id -u)" -ne 0 ] || { echo "Run as your user, not root; it sudos itself." >&2; exit 1; }
    local bats=(/sys/class/power_supply/BAT*)
    [ -e "${bats[0]}" ] || { echo "No battery found; nothing to do on a desktop."; exit 0; }

    power_management "${bats[@]}"
    touchpad
    sleep_and_lid
    firmware_check
    report

    say "Done. Reboot to apply everything."
}

power_management() {
    say "TLP"
    # TLP and power-profiles-daemon both tune the same knobs and conflict at
    # the package level; archinstall's power profile may have pulled ppd in.
    if pacman -Qq power-profiles-daemon >/dev/null 2>&1; then
        warn "Removing power-profiles-daemon (conflicts with TLP)"
        sudo systemctl disable --now power-profiles-daemon.service 2>/dev/null || true
        sudo pacman -Rns --noconfirm power-profiles-daemon
    fi
    sudo pacman -S --needed --noconfirm tlp
    sudo systemctl enable --now tlp.service
    # TLP manages radios itself; systemd-rfkill would restore stale state over it.
    sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

    # One threshold pair per battery actually present (the T480 has two). On
    # hardware without threshold support TLP just ignores them.
    local b name
    {
        echo "# Written by laptop-setup.sh"
        for b in "$@"; do
            name=$(basename "$b")
            echo "START_CHARGE_THRESH_$name=$CHARGE_START"
            echo "STOP_CHARGE_THRESH_$name=$CHARGE_STOP"
        done
    } | put /etc/tlp.d/10-charge-thresholds.conf
    sudo tlp start >/dev/null
}

touchpad() {
    say "Touchpad"
    # libinput leaves tap-to-click off under X.
    put /etc/X11/xorg.conf.d/30-touchpad.conf <<'EOF'
# Written by laptop-setup.sh
Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
EndSection
EOF
}

sleep_and_lid() {
    say "Sleep and lid"
    # Lid suspend works out of the box. Only escalate to hibernate when the
    # system says it can resume from it (real swap >= RAM, resume= set);
    # otherwise suspend-then-hibernate fails and the laptop never sleeps.
    local can
    can=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager CanSuspendThenHibernate 2>/dev/null || true)
    if [ "$can" = 's "yes"' ]; then
        put /etc/systemd/logind.conf.d/10-lid.conf <<'EOF'
# Written by laptop-setup.sh: hibernate after HibernateDelaySec asleep
# (sleep.conf.d), so a laptop forgotten in a bag doesn't run flat.
[Login]
HandleLidSwitch=suspend-then-hibernate
EOF
        put /etc/systemd/sleep.conf.d/10-hibernate-delay.conf <<EOF
# Written by laptop-setup.sh
[Sleep]
HibernateDelaySec=$HIBERNATE_AFTER
EOF
        # UPower has no drop-in directory, so this one is an in-place edit.
        if [ -f /etc/UPower/UPower.conf ]; then
            sudo sed -i 's/^CriticalPowerAction=.*/CriticalPowerAction=Hibernate/' /etc/UPower/UPower.conf
            echo "set CriticalPowerAction=Hibernate in /etc/UPower/UPower.conf"
        fi
    else
        warn "Hibernation isn't set up, so the lid just suspends (the default)."
        warn "Set up swap + resume= (README), then re-run this to enable"
        warn "suspend-then-hibernate."
    fi
}

firmware_check() {
    say "Firmware"
    sudo pacman -S --needed --noconfirm fwupd
    # Report only: updates can reboot into the flasher, so run them by hand.
    fwupdmgr refresh --force </dev/null >/dev/null 2>&1 || true
    if fwupdmgr get-updates </dev/null >/dev/null 2>&1; then
        warn "Firmware updates are available: fwupdmgr update (on AC power)."
    else
        echo "Firmware is up to date (or fwupd has nothing for this machine)."
    fi
}

report() {
    say "Checks"
    # s2idle drains a few percent an hour asleep; deep is proper S3. Fixed in
    # BIOS (ThinkPads: Config > Power > Sleep State > Linux), not from here.
    if grep -q '\[deep\]' /sys/power/mem_sleep 2>/dev/null; then
        echo "sleep: deep (good)"
    else
        warn "sleep: $(cat /sys/power/mem_sleep 2>/dev/null) -- set the BIOS sleep state to Linux,"
        warn "or add the kernel parameter mem_sleep_default=deep."
    fi
    if grep -qi thinkpad /sys/class/dmi/id/product_version 2>/dev/null; then
        warn "ThinkPad: make sure Thunderbolt firmware is current (fwupdmgr) --"
        warn "old T480-era firmware can brick USB-C, the only charging port."
    fi
}

main "$@"
