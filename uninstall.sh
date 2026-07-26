#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# uninstall.sh — Clean uninstall of arinanoX
# Removes: proot container, generated scripts, symlinks, configs

echo "╔═══════════════════════════════════╗"
echo "║  🗑️  arinanoX Uninstaller        ║"
echo "╠═══════════════════════════════════╣"
echo ""
echo "This will remove:"
echo "  • proot container (arinanox)"
echo "  • launcher scripts (~/.shortcuts/)"
echo "  • home symlinks (start-*, kill-*, update*)"
echo "  • ~/.arinanox/ cache"
echo ""
echo "This will NOT remove:"
echo "  • ~/arinanoX/ (git repo)"
echo "  • ~/storage/ (Android storage)"
echo "  • ~/.bashrc (Termux config)"
echo ""

if [ -t 0 ]; then read -rp "Proceed? [y/N] " confirm; else confirm="y"; fi
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# 1. Stop any running sessions
echo ">>> Stopping running sessions..."
pkill -f "startxfce4" 2>/dev/null && echo "  [x] XFCE stopped" || true
pkill -f "proot-distro login" 2>/dev/null && echo "  [x] proot login stopped" || true
pkill -f "termux-x11" 2>/dev/null && echo "  [x] X11 stopped" || true
pulseaudio --kill 2>/dev/null && echo "  [x] PulseAudio stopped" || true
pkill -f run-api-bridge 2>/dev/null && echo "  [x] API bridge stopped" || true
termux-wake-unlock 2>/dev/null && echo "  [x] Wake lock released" || true
sleep 1

# 2. Remove proot container
echo ""
echo ">>> Removing proot container..."
if proot-distro list 2>/dev/null | grep -q "arinanox"; then
    proot-distro remove arinanox 2>&1 && echo "  [x] arinanox removed" || echo "  [-] Failed to remove"
fi

# 3. Remove launcher scripts
echo ""
echo ">>> Removing launcher scripts..."
rm -f ~/.shortcuts/0-stop-arinanox.sh ~/.shortcuts/1-start-arinanox.sh ~/.shortcuts/2-update-arinanox.sh \
      ~/.shortcuts/stop.sh \
      ~/.shortcuts/update.sh \
      ~/.shortcuts/update-arinanox.sh
echo "  [x] ~/.shortcuts/ cleaned"

# 4. Remove home symlinks
echo ""
echo ">>> Removing home symlinks..."
rm -f ~/start.sh \
      ~/stop.sh \
      ~/update.sh \
      ~/update-arinanox.sh
echo "  [x] Home symlinks removed"

# 5. Remove ~/.arinanox cache
echo ""
echo ">>> Removing ~/.arinanox cache..."
rm -rf ~/.arinanox
echo "  [x] ~/.arinanox removed"

# 6. Clean Termux tmp
echo ""
echo ">>> Cleaning Termux tmp..."
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
rm -f "${TERMUX_TMP}/.X0-lock" 2>/dev/null
rm -rf "${TERMUX_TMP}/.X11-unix" 2>/dev/null
rm -f "${TERMUX_TMP}/pulse-socket" 2>/dev/null
echo "  [x] Temp files cleaned"

# 7. Remove run-api-bridge.sh from home
echo ""
echo ">>> Removing API bridge..."
rm -f ~/run-api-bridge.sh
echo "  [x] run-api-bridge.sh removed"

echo ""
echo "╔═══════════════════════════════════╗"
echo "║  ✅ arinanoX uninstalled         ║"
echo "╠═══════════════════════════════════╣"
echo "║                                   ║"
echo "║  To reinstall:                    ║"
echo "║  curl -sL URL/bootstrap.sh | bash ║"
echo "║                                   ║"
echo "║  To remove ~/arinanoX repo:      ║"
echo "║  rm -rf ~/arinanoX               ║"
echo "╚═══════════════════════════════════╝"
