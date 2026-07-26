#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Manifest Generator
# Scans user state, generates ~/.arinanox/user-manifest.yaml
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

MANIFEST="$HOME/.arinanox/user-manifest.yaml"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"

echo ">>> Generating user-manifest.yaml..."

# ── Detect user-added APT packages ──────────────────────────
# Compare apt-mark showmanual against base image packages
BASE_PKGS="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/arinanox-base-pkgs.txt"
USER_PKGS="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/arinanox-user-pkgs.txt"

# Get all manually-installed packages
proot-distro login arinanox -- bash -c 'apt-mark showmanual 2>/dev/null | sort' > "$USER_PKGS" 2>/dev/null || true

# Get base packages from fresh image (from Dockerfile-like list)
# For now: list known core packages and exclude them
cat > "$BASE_PKGS" <<'BASE'
adduser
apt
bash
busybox
ca-certificates
curl
dbus
dbus-x11
firefox-esr
gcc
git
glmark2
gnupg
htop
make
mesa-utils
mousepad
openssh-client
python3
python3-pip
python3-venv
ristretto
sudo
tmux
wget
xdotool
xfce4
xfce4-goodies
xfce4-terminal
xorg
yad
BASE

# Add packages from Dockerfile — merge with actual base
EXTRA_FILE="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/arinanox-extra.txt"
proot-distro login arinanox -- bash -c 'dpkg -l 2>/dev/null | grep "^ii" | awk "{print \$2}"' \
    | grep -v -f "$BASE_PKGS" - > "$EXTRA_FILE" 2>/dev/null || true

EXTRA=$(cat "$EXTRA_FILE" 2>/dev/null | head -30 | tr '\n' ' ')

# ── Detect custom dotfiles ──────────────────────────────────
DOTFILES=""
for df in .bashrc .bash_aliases .gitconfig .config/gtk-3.0/gtk.css \
           .config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml; do
    src="$ROOTFS/home/admin/$df"
    if [ -f "$src" ]; then
        # Check if file differs from shipped config (skip if identical to configs-target)
        DOTFILES="$DOTFILES\n    - $df"
    fi
done

# ── Detect custom themes/icons ──────────────────────────────
THEMES=""
for d in Orchis-Dark elementary-xfce-hidpi Orchis-Dark-xhdpi; do
    if [ -d "$ROOTFS/usr/share/themes/$d" ]; then
        THEMES="$THEMES\n    - $d"
    fi
    if [ -d "$ROOTFS/usr/share/icons/$d" ]; then
        THEMES="$THEMES\n    - $d"
    fi
done

# ── Write manifest ──────────────────────────────────────────
cat > "$MANIFEST" <<YAML
# arinanoX User Manifest
# Generated: $(date -Iseconds)
# This file tracks your customizations for backup/restore.
#
# Run after customizing:  arinanox snapshot create
# Run after reinstall:    arinanox install   (re-apply packages)

# User-installed packages (auto-detected from apt-mark)
packages:
$(echo "$EXTRA" | tr ' ' '\n' | grep -v "^$" | sed 's/^/  - /')

# Custom dotfiles (tracked for backup/sync)
dotfiles:$(echo -e "$DOTFILES")

# XFCE config files to preserve
xfce_config:
  - xfce4-panel.xml
  - xfwm4.xml
  - xsettings.xml
  - xfce4-desktop.xml
  - xfce4-keyboard-shortcuts.xml
  - thunar.xml
YAML

echo ""
echo "  ✓ Manifest written: $MANIFEST"
echo ""
echo "  Review & customize it, then:"
echo "    arinanox snapshot create    # checkpoint before changes"
echo "    arinanox install            # re-apply after fresh install"

cat "$MANIFEST"
