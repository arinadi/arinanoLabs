#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Doctor (health-check)
# Usage: bash ~/.arinanox/scripts/doctor.sh
# ═══════════════════════════════════════════════════════════════
set -uo pipefail

GREEN="✓"
RED="✗"
WARN="⚠"
DIM="•"

echo "╔══════════════════════════════════════════╗"
echo "║        arinanoX Doctor v1               ║"
echo "╚══════════════════════════════════════════╝"
echo ""

FAILS=0
WARNS=0

# ── System ──────────────────────────────────────────────────
echo "── System ──"
ANDROID_SDK=$(getprop ro.build.version.sdk 2>/dev/null || echo "?")
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "?")
echo "  ${DIM} Android ${ANDROID_VER} (SDK ${ANDROID_SDK}) · $(uname -m) · $(free -m | awk '/Mem:/{printf "%dMB free", $4}')"

# ── Seccomp ─────────────────────────────────────────────────
echo "── Seccomp ──"
SECCOMP_OK=0
if bash "$HOME/.arinanox/scripts/seccomp-check.sh" 2>/dev/null; then
    SECCOMP_OK=1
    echo "  ${GREEN} seccomp OK"
else
    echo "  ${RED} seccomp BLOCKING proot"
    FAILS=$((FAILS + 1))
fi

# ── Packages ────────────────────────────────────────────────
echo "── Termux Host ──"
for pkg in termux-x11-nightly proot-distro pulseaudio virglrenderer-android; do
    if dpkg -l "$pkg" &>/dev/null; then
        echo "  ${GREEN} $pkg"
    else
        echo "  ${RED} $pkg — MISSING"
        FAILS=$((FAILS + 1))
    fi
done

# ── Proot Container ─────────────────────────────────────────
echo "── Proot Container ──"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"
if [ -d "$ROOTFS/home/admin" ]; then
    SIZE=$(du -sh /data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs 2>/dev/null | awk '{print $1}')
    echo "  ${GREEN} arinanox (${SIZE:-?})"
    
    # Check core packages inside
    for bin in firefox-esr xfce4-session; do
        if proot-distro login arinanox -- which "$bin" &>/dev/null; then
            echo "  ${GREEN}   $bin"
        else
            echo "  ${WARN}   $bin — MISSING"
            WARNS=$((WARNS + 1))
        fi
    done
else
    echo "  ${RED} arinanox container NOT FOUND"
    FAILS=$((FAILS + 1))
fi

# ── GPU ─────────────────────────────────────────────────────
echo "── GPU ──"
if command -v virgl_test_server_android &>/dev/null; then
    echo "  ${GREEN} virgl android path"
elif command -v virgl_test_server &>/dev/null; then
    echo "  ${GREEN} virgl ANGLE path"
else
    echo "  ${WARN} no virgl — CPU rendering only"
    WARNS=$((WARNS + 1))
fi

# ── Storage ─────────────────────────────────────────────────
echo "── Storage ──"
FREE=$(df -h /data 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
ARINANOX_DIR="$HOME/.arinanox"
if [ -d "$ARINANOX_DIR" ]; then
    DIR_SIZE=$(du -sh "$ARINANOX_DIR" 2>/dev/null | awk '{print $1}')
    echo "  ${DIM} ~/.arinanox: ${DIR_SIZE} · /data free: ${FREE}"
else
    echo "  ${WARN} ~/.arinanox not found (not installed?)"
    WARNS=$((WARNS + 1))
fi

# ── Runtime ─────────────────────────────────────────────────
echo "── Runtime ──"
if netstat -tlnp 2>/dev/null | grep -q "4713"; then
    echo "  ${GREEN} PulseAudio (port 4713)"
else
    echo "  ${WARN} PulseAudio not running"
    WARNS=$((WARNS + 1))
fi

if pgrep -x "termux.x11" &>/dev/null || pgrep -x "com.termux.x11" &>/dev/null || pgrep -f "termux.x11" &>/dev/null; then
    echo "  ${GREEN} Termux:X11"
else
    echo "  ${WARN} Termux:X11 not running"
    WARNS=$((WARNS + 1))
fi

if pgrep -f "xfce4-session" &>/dev/null; then
    echo "  ${GREEN} XFCE session active"
else
    echo "  ${DIM} XFCE not running"
fi

# ── Summary ─────────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────"
if [ "$FAILS" -eq 0 ] && [ "$WARNS" -eq 0 ]; then
    echo "  ${GREEN} All checks passed."
elif [ "$FAILS" -eq 0 ]; then
    echo "  ${WARN} ${WARNS} warning(s), ready to launch."
else
    echo "  ${RED} ${FAILS} failure(s) + ${WARNS} warning(s)."
    echo "  Run: bash ~/stop.sh && bash ~/start.sh"
fi
echo "──────────────────────────────────────────"
