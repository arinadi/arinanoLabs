#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Manifest Apply
# Reads user-manifest.yaml, installs packages, restores dotfiles
# Called manually after fresh install
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

MANIFEST="$HOME/.arinanox/user-manifest.yaml"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"
BACKUP_DIR="/sdcard/arinanox-backup"

if [ ! -f "$MANIFEST" ]; then
    echo "  • No user-manifest.yaml — skipping user layer"
    exit 0
fi

echo ">>> Applying user manifest..."

# ── Install packages ────────────────────────────────────────
if grep -q "^packages:" "$MANIFEST" 2>/dev/null; then
    PKGS=$(sed -n '/^packages:/,/^[a-z]/p' "$MANIFEST" | grep -E "^\s+- " | sed 's/^\s*- //' | grep -v "^#" | tr '\n' ' ')
    PKGS=$(echo "$PKGS" | xargs)  # trim
    
    if [ -n "$PKGS" ]; then
        echo "  Installing: $PKGS"
        proot-distro login arinanox -- bash -c "
            sudo apt-get update -qq 2>/dev/null
            for pkg in $PKGS; do
                echo \"    → \$pkg\"
                sudo apt-get install -y -qq \"\$pkg\" 2>/dev/null || echo \"    ⚠ skipped: \$pkg\"
            done
        " || true
        echo "  ✓ Packages installed"
    else
        echo "  • No packages in manifest"
    fi
fi

# ── Restore XFCE configs ────────────────────────────────────
CONFIG_DIR="$HOME/.arinanox/snapshot-current/home/.config/xfce4/xfconf/xfce-perchannel-xml"
TARGET_DIR="$ROOTFS/home/admin/.config/xfce4/xfconf/xfce-perchannel-xml"

if [ -d "$CONFIG_DIR" ]; then
    echo "  Restoring XFCE configs..."
    mkdir -p "$TARGET_DIR"
    for xml in xfce4-panel.xml xfwm4.xml xsettings.xml xfce4-desktop.xml \
               xfce4-keyboard-shortcuts.xml thunar.xml; do
        if [ -f "$CONFIG_DIR/$xml" ]; then
            cp "$CONFIG_DIR/$xml" "$TARGET_DIR/$xml"
            echo "    → $xml"
        fi
    done
    echo "  ✓ Configs restored"
fi

# ── Restore dotfiles from backup ────────────────────────────
if [ -d "$BACKUP_DIR/home" ]; then
    echo "  Restoring dotfiles from backup..."
    for df in .bashrc .bash_aliases .gitconfig .config/gtk-3.0/gtk.css; do
        src="$BACKUP_DIR/home/$df"
        dest="$ROOTFS/home/admin/$df"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
            echo "    → $df"
        fi
    done
    echo "  ✓ Dotfiles restored"
else
    echo "  • No backup found — skipping dotfiles"
fi

echo ""
echo "  ✓ User manifest applied."
echo "  Start: arinanox start"
