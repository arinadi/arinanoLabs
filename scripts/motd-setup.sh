#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Setting up MOTD..."

cat > /data/data/com.termux/files/usr/etc/motd << 'MOTDEOF'

==========================================
 📱 arinanoX Proot XFCE
==========================================

 Start:
    bash ~/start.sh
 Stop:
    bash ~/stop.sh

 Reinstall (fresh):
    curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash

 User: admin / Pass: admin
==========================================
MOTDEOF

echo ">>> MOTD updated."
