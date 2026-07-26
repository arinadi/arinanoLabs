#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════
#  arinanoX proot-setup — simple install
#  Rolling release: fresh install each time
# ═══════════════════════════════════════════

IMAGE="ghcr.io/arinadi/arinanox:latest"
CONTAINER="arinanox"
CONTAINERS_DIR="/data/data/com.termux/files/usr/var/lib/proot-distro/containers"

echo ">>> Setting up arinanoX proot..."

# Remove existing container if present
if [ -d "${CONTAINERS_DIR}/${CONTAINER}" ]; then
    echo "  [*] Removing previous container..."
    proot-distro remove "$CONTAINER" 2>/dev/null || true
fi

echo "  [*] Pulling arinanoX image..."
proot-distro install "$IMAGE" --name "$CONTAINER"

echo "  [+] arinanoX proot ready."
