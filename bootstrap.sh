#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ══════════════════════════════════════════
#  arinanoX Bootstrap — curl | bash
#  https://github.com/arinadi/arinanoX
# ══════════════════════════════════════════

REPO="https://raw.githubusercontent.com/arinadi/arinanoX/main"
ARINANOX_DIR="$HOME/.arinanox"
SCRIPTS_DIR="${ARINANOX_DIR}/scripts"
LAUNCHERS_DIR="${ARINANOX_DIR}/launchers"

INSTALLED=false
[ -d "$ARINANOX_DIR" ] && INSTALLED=true

# --- Menu (only when interactive) ---
if [ -t 0 ]; then
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║  📱 arinanoX — Linux on Android      ║"
    echo "╠═══════════════════════════════════════╣"

    if $INSTALLED; then
        echo "║  Status: installed                   ║"
        echo "╠═══════════════════════════════════════╣"
        echo "║                                       ║"
        echo "║  [1] Reinstall (fresh)               ║"
        echo "║  [2] Uninstall                       ║"
        echo "║  [3] Exit                             ║"
        echo "║                                       ║"
    else
        echo "║  Status: not installed                ║"
        echo "╠═══════════════════════════════════════╣"
        echo "║                                       ║"
        echo "║  [1] Install                         ║"
        echo "║  [2] Exit                             ║"
        echo "║                                       ║"
    fi
    echo "╚═══════════════════════════════════════╝"
    echo ""

    read -rp "  Choose: " CHOICE

    if $INSTALLED; then
        case "$CHOICE" in
            1) ACTION="reinstall" ;;
            2) ACTION="uninstall" ;;
            *) echo ">>> Bye!"; exit 0 ;;
        esac
    else
        case "$CHOICE" in
            1) ACTION="install" ;;
            *) echo ">>> Bye!"; exit 0 ;;
        esac
    fi
else
    echo ">>> Installing arinanoX..."
    ACTION="reinstall"
fi

# --- Uninstall ---
if [ "$ACTION" = "uninstall" ]; then
    curl -sL --retry 2 "${REPO}/uninstall.sh" | bash
    exit 0
fi

# --- Install / Reinstall ---
echo ">>> Downloading scripts..."
rm -rf "$SCRIPTS_DIR" "$LAUNCHERS_DIR"
mkdir -p "$SCRIPTS_DIR" "$LAUNCHERS_DIR"

for f in host-setup.sh proot-setup.sh api-bridge-setup.sh xfce-config.sh \
         launcher-gen.sh motd-setup.sh \
         patch.sh \
         seccomp-check.sh seccomp-fix.sh doctor.sh \
         manifest-generate.sh manifest-apply.sh user-snapshot.sh \
         status.sh; do
    curl -sL --retry 2 "${REPO}/scripts/${f}" -o "${SCRIPTS_DIR}/${f}"
    chmod +x "${SCRIPTS_DIR}/${f}"
done

echo ">>> Downloading launchers..."
for f in start.sh stop.sh update.sh; do
    curl -sL --retry 2 "${REPO}/launchers/${f}" -o "${LAUNCHERS_DIR}/${f}"
    chmod +x "${LAUNCHERS_DIR}/${f}"
done

echo ">>> Downloading CLI..."
mkdir -p "${ARINANOX_DIR}/bin"
curl -sL --retry 2 "${REPO}/scripts/arinanox" -o "${ARINANOX_DIR}/bin/arinanox"
chmod +x "${ARINANOX_DIR}/bin/arinanox"

# Add to PATH
if ! grep -q '.arinanox/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo '' >> "$HOME/.bashrc"
    echo '# arinanoX CLI' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.arinanox/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo ">>> Downloading API bridge..."
curl -sL --retry 2 "${REPO}/run-api-bridge.sh" -o "${ARINANOX_DIR}/run-api-bridge.sh"
chmod +x "${ARINANOX_DIR}/run-api-bridge.sh"

# --- Execute Setup ---
echo ">>> Running host setup..."
bash "${SCRIPTS_DIR}/host-setup.sh"

echo ">>> Setting up Debian proot..."
bash "${SCRIPTS_DIR}/proot-setup.sh"

echo ">>> Setting up Termux:API bridge..."
bash "${SCRIPTS_DIR}/api-bridge-setup.sh"

echo ">>> Installing launchers..."
bash "${SCRIPTS_DIR}/launcher-gen.sh"

echo ">>> Setting up MOTD..."
bash "${SCRIPTS_DIR}/motd-setup.sh"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  ✅ arinanoX ready!                  ║"
echo "╠═══════════════════════════════════════╣"
echo "║  Widget:  0-stop · 1-start            ║"
echo "║  CLI:    arinanox start               ║"
echo "║          arinanox stop                ║"
echo "║          arinanox help                ║"
echo "║                                       ║"
echo "║  ⚠️ arinanox update = fresh install    ║"
echo "║  Run 'arinanox snapshot' first.       ║"
echo "╚═══════════════════════════════════════╝"
