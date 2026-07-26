# arinanoX — Comprehensive Audit Document

## GOAL

A complete structural audit of the arinanoX project (https://github.com/arinadi/arinanoX), covering every file in the commit graph, all bootstrap lifecycle stages, configuration surfaces, CI pipeline, API bridge, seccomp detection chain, atomic deployment model, user-layer manifest system, AI stack layering, and the complete bootstrap → first-run → update → rollback → uninstall flow. Every file path, script shebang, environment variable, exported port number, socket path, proot container name, and image reference is recorded verbatim from source.

## CONSTRAINTS

- No files in the arinanoX repository were created, modified, or deleted during this audit.

- No architectural proposals, refactoring suggestions, or executable code are contained herein.
- All identifiers appear verbatim as they do in the source.

## ACCEPTANCE

This audit document (`arinanox-audit.md`) covers every file in the repository inventory. Every file path, script shebang, environment variable, exported port number (`4713`, `8888`, `8889`), socket path (`${TMPDIR}/.X11-unix/X0`), proot container name (`arinanox`, `arinanox-prev`), and GHCR image reference (`ghcr.io/arinadi/arinanox:latest`) is recorded verbatim. All bootstrap sub-scripts, launchers, CLI dispatchers, CI pipeline steps, API bridge architecture, seccomp detection chain, atomic deployment model, user manifest system, AI stack layering, and the full bootstrap → first-run → update → rollback → uninstall flow are traced end-to-end. Known unknowns are explicitly identified.

---

## 1. Repository Overview

- **GitHub:** `https://github.com/arinadi/arinanoX`
- **Remote origin:** `https://github.com/arinadi/arinanoX.git`
- **Default branch:** `main`
- **License:** GPLv3
- **Prime installation command:** `curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash`
- **Raw content base URL:** `https://raw.githubusercontent.com/arinadi/arinanoX/main`

### 1.1 Filesystem Inventory

Below is the complete sorted list of tracked files in the working tree, excluding `.git/` internals, `.pi-tasks/`, and `node_modules/`.

```
.gitignore
.github/workflows/build-image.yml
README.md
archive/apply-xfce-config.sh
archive/install-tui-packages.sh
archive/launch-pi-vnc.sh
archive/run-api-bridge.sh
archive/setup-proot-xfce.sh
archive/setup-termux-native.sh
audit.md
blueprint.md
bootstrap.sh
configs/user.js
docs/README-termux.md
docs/ai-stack-usage.md
docs/arinanox-screenshot.jpg
docs/audit-update-flow.md
docs/debug-xfce-render.md
docs/docs-proot-tapi.md
docs/docs-termux-api.md
docs/firefox-userjs-proot.md
docs/plan-ai-stack.md
image/.dockerignore
image/Dockerfile
image/configs-target/home/admin/.arinanox/tools/apt-store.sh
image/configs-target/home/admin/.arinanox/tools/clipboard-sync.sh
image/configs-target/home/admin/.arinanox/tools/genmon-battery.sh
image/configs-target/home/admin/.arinanox/tools/genmon-volume.sh
image/configs-target/home/admin/.arinanox/tools/tapi-utils.sh
image/configs-target/home/admin/.bashrc
image/configs-target/home/admin/.config/autostart/clipboard-sync.desktop
image/configs-target/home/admin/.config/gtk-3.0/gtk.css
image/configs-target/home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
image/configs-target/home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
image/configs-target/home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
image/configs-target/home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
image/configs-target/home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
image/configs-target/home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
image/configs-target/home/admin/.local/share/applications/arinanox-store.desktop
image/configs-target/home/admin/.pulse/client.conf
image/configs/ai-stack/plan-ai-stack.md
image/configs/ai-stack/setup-ai-stack.sh
image/configs/ai-stack/user.js
image/configs/autostart/clipboard-sync.desktop
image/configs/bashrc
image/configs/client.conf
image/configs/clipboard-sync.sh
image/configs/genmon-battery.sh
image/configs/genmon-volume.sh
image/configs/gtk.css
image/configs/tapi-utils.sh
image/configs/thunar.xml
image/configs/xfwm4.xml
launchers/.v1-backup/kill-all.sh
launchers/.v1-backup/kill-proot.sh
launchers/.v1-backup/kill-x11.sh
launchers/.v1-backup/start-x11.sh
launchers/.v1-backup/start-xfce.sh
launchers/kill-all.sh
launchers/kill-proot.sh
launchers/kill-x11.sh
launchers/start-x11.sh
launchers/start-xfce.sh
launchers/start.sh
launchers/stop.sh
launchers/update.sh
scripts/api-bridge-setup.sh
scripts/arinanox
scripts/doctor.sh
scripts/host-setup.sh
scripts/launcher-gen.sh
scripts/manifest-apply.sh
scripts/manifest-generate.sh
scripts/motd-setup.sh
scripts/patch.sh
scripts/proot-backup.sh
scripts/proot-restore.sh
scripts/proot-rollback.sh
scripts/proot-setup.sh
scripts/seccomp-check.sh
scripts/seccomp-fix.sh
scripts/setup-ai-stack.sh
scripts/status.sh
scripts/theme-dark.sh
scripts/user-snapshot.sh
scripts/xfce-config.sh
uninstall.sh
```

---

## 2. Dockerfile (`image/Dockerfile`)

**Base image:** `FROM debian:13` (Debian 13/Trixie)

### Layer 1 — BASE + CORE PACKAGES

```
FROM debian:13
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dialog locales ca-certificates sudo \
        curl wget zip unzip jq tree less && \
    apt-get upgrade -y -o Dpkg::Options::='--force-confold' && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
```

**Installed packages:** `dialog`, `locales`, `ca-certificates`, `sudo`, `curl`, `wget`, `zip`, `unzip`, `jq`, `tree`, `less`

**Side effects:** `apt-get upgrade` runs, `apt-get clean`, apt lists purged.

### Layer 2 — XFCE + GUI + BROWSER + THEMES

```
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dbus-x11 xfce4-session xfwm4 xfce4-panel xfce4-terminal \
        xfce4-settings xfconf thunar xfdesktop4 libgl1 librsvg2-common \
        pulseaudio-utils netcat-openbsd x11-xserver-utils \
        xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-genmon-plugin \
        mousepad ristretto tumbler adwaita-icon-theme \
        orchis-gtk-theme elementary-xfce-icon-theme \
        firefox-esr \
        mesa-utils glmark2 \
        xdotool \
        gnupg \
        yad && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
```

**Installed packages (complete):** `dbus-x11`, `xfce4-session`, `xfwm4`, `xfce4-panel`, `xfce4-terminal`, `xfce4-settings`, `xfconf`, `thunar`, `xfdesktop4`, `libgl1`, `librsvg2-common`, `pulseaudio-utils`, `netcat-openbsd`, `x11-xserver-utils`, `xfce4-whiskermenu-plugin`, `xfce4-pulseaudio-plugin`, `xfce4-genmon-plugin`, `mousepad`, `ristretto`, `tumbler`, `adwaita-icon-theme`, `orchis-gtk-theme`, `elementary-xfce-icon-theme`, `firefox-esr`, `mesa-utils`, `glmark2`, `xdotool`, `gnupg`, `yad`

### Layer 3 — DEV TOOLS + SYSTEM + NODE.JS

```
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git python3-pip python3-venv python3-dev \
        build-essential cmake pkg-config \
        htop tmux openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
```

**Installed packages:** `git`, `python3-pip`, `python3-venv`, `python3-dev`, `build-essential` (GCC, make, G++), `cmake`, `pkg-config`, `htop`, `tmux`, `openssh-client`, `nodejs` (via NodeSource setup_22.x repo)

### Layer 4 — CONFIGS + USER + CLEANUP

```
RUN printf '#!/bin/sh\nexit 1\n' > /usr/bin/pm-is-supported && chmod +x /usr/bin/pm-is-supported && \
    dpkg --purge libupower-glib3 2>/dev/null || true && \
    useradd -m -s /bin/bash admin && \
    echo "admin:admin" | chpasswd && \
    echo "admin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin && \
    chmod 0440 /etc/sudoers.d/admin

COPY configs-target/home/ /home/

RUN chown -R admin:admin /home/admin && \
    chmod +x /home/admin/.arinanox/tools/*.sh && \
    sed -i 's|.old-path/|.arinanox/|g' /home/admin/.bashrc && \
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
```

**Side effects:**
- Creates dummy `/usr/bin/pm-is-supported` that always exits 1 (suppresses suspend/power warnings in proot)
- Purges `libupower-glib3` (removes power daemon that could cause issues in proot)
- Creates user `admin` with password `admin` and password-less sudo
- Copies all files from `image/configs-target/home/` to `/home/` in the image
- Patches `.bashrc`: replaces legacy path references with `.arinanox/` (rename from earlier project name)
- Generates `en_US.UTF-8` locale
- Sets `LANG=en_US.UTF-8`, `LC_ALL=en_US.UTF-8`

### Layer 5 — AI VIBECODING STACK (pre-installed in image)

```
# ── Install npm global packages (as root) ──────────────────
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest && \
    npm install -g @oevortex/ddg_search@latest && \
    npm install -g @playwright/cli@latest

# ── Install lean-ctx binary (musl ARM64, statically linked) ─
RUN LEAN_CTX_VER="v3.9.8" && \
    ARCH="aarch64-unknown-linux-musl" && \
    cd /tmp && \
    curl -fsSL "https://github.com/yvgude/lean-ctx/releases/download/${LEAN_CTX_VER}/lean-ctx-${ARCH}.tar.gz" -o lean-ctx.tar.gz && \
    tar xzf lean-ctx.tar.gz && \
    cp lean-ctx /usr/local/bin/ && \
    rm -f lean-ctx lean-ctx.tar.gz

# ── Download Playwright Firefox browser (as admin) ─────────
RUN sudo -u admin playwright-cli install-browser firefox 2>/dev/null || true

# ── lean-ctx init for admin user ───────────────────────────
RUN sudo -u admin /usr/local/bin/lean-ctx init --global 2>/dev/null || true && \
    sudo -u admin /usr/local/bin/lean-ctx init --agent pi 2>/dev/null || true

# ── Setup config files for admin ───────────────────────────
COPY configs/ai-stack /home/admin/.arinanox/ai-stack/

# Generate Firefox profile then deploy user.js
RUN sudo -u admin MOZ_HEADLESS=1 firefox --headless --first-startup & \
    FF_PID=$! && sleep 8 && kill $FF_PID 2>/dev/null; sleep 1 && \
    FF_DIR=$(ls -d /home/admin/.mozilla/firefox/*.default-esr 2>/dev/null || echo "") && \
    if [ -n "$FF_DIR" ] && [ -d "$FF_DIR" ]; then \
        cp /home/admin/.arinanox/ai-stack/user.js "$FF_DIR/user.js" && \
        echo "user.js deployed to $FF_DIR"; \
    else \
        echo "Firefox profile not created — user.js will be deployed on first run"; \
    fi

# DeepSeek models.json
RUN echo '{ "providers": { "deepseek": { "baseUrl": "https://api.deepseek.com", ... } } }' > /home/admin/.pi/agent/models.json

# MCP config (ddg-search via node)
RUN echo '{ "mcpServers": { "ddg-search": { "command": "node", "args": ["/usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js", "--server"], "env": { "NODE_TLS_REJECT_UNAUTHORIZED": "0" } } } }' > /home/admin/.pi/agent/mcp.json

# Permissions
RUN chown -R admin:admin /home/admin/.pi /home/admin/.local /home/admin/.config 2>/dev/null || true && \
    chown -R admin:admin /home/admin/.arinanox/ai-stack && \
    chmod +x /home/admin/.arinanox/ai-stack/*.sh

# Copy setup script to system location
RUN cp /home/admin/.arinanox/ai-stack/setup-ai-stack.sh /usr/local/bin/arinanox-ai-setup && \
    chmod +x /usr/local/bin/arinanox-ai-setup

CMD ["/bin/bash"]
```

**AI stack tools pre-installed:**
| Tool | Version | Location |
|------|---------|----------|
| Pi | latest npm (`@earendil-works/pi-coding-agent`) | `/usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js` |
| lean-ctx | v3.9.8 (musl ARM64) | `/usr/local/bin/lean-ctx` |
| ddg_search | latest npm (`@oevortex/ddg_search`) | `/usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js` |
| playwright-cli | latest npm (`@playwright/cli`) | `/usr/lib/node_modules/@playwright/cli/playwright-cli.js` |
| Playwright Firefox | latest (downloaded via `playwright-cli install-browser firefox`) | `~/.cache/ms-playwright/firefox-*/firefox/firefox` |
| DeepSeek models.json | — | `/home/admin/.pi/agent/models.json` |
| MCP config | — | `/home/admin/.pi/agent/mcp.json` |
| Firefox user.js | — | `/home/admin/.mozilla/firefox/*.default-esr/user.js` |
| AI setup script | — | `/usr/local/bin/arinanox-ai-setup` |

**models.json provider config (DeepSeek):**
- `baseUrl`: `https://api.deepseek.com`
- `api`: `openai-completions`
- `apiKey`: `$DEEPSEEK_API_KEY` (environment variable)
- Model: `deepseek-chat` / "DeepSeek V4 Chat", `contextWindow`: 1000000, `maxTokens`: 384000, `thinkingFormat`: `deepseek`

**mcp.json MCP config:**
- Server name: `ddg-search`
- Command: `node`
- Args: `["/usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js", "--server"]`
- Environment: `NODE_TLS_REJECT_UNAUTHORIZED=0`

---

## 3. Bootstrap — Complete Flow

### 3.1 Entry Point: `bootstrap.sh`

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`
**Source URL:** `https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh`

**Execution flow:**

```
bootstrap.sh
 │
 ├── 1. Set REPO="https://raw.githubusercontent.com/arinadi/arinanoX/main"
 │      Set ARINANOX_DIR="$HOME/.arinanox"
 │      Set SCRIPTS_DIR="${ARINANOX_DIR}/scripts"
 │      Set LAUNCHERS_DIR="${ARINANOX_DIR}/launchers"
 │
 ├── 2. Interactive menu (if [ -t 0 ])
 │      - If installed: [1] Update/Reinstall, [2] Uninstall, [3] Exit
 │      - If not installed: [1] Install, [2] Exit
 │
 ├── 3. Uninstall path (if ACTION="uninstall"):
 │      curl -sL --retry 2 "${REPO}/uninstall.sh" | bash
 │      exit 0
 │
 ├── 4. Download all scripts from raw.githubusercontent.com:
 │      → ~/.arinanox/scripts/host-setup.sh
 │      → ~/.arinanox/scripts/proot-setup.sh
 │      → ~/.arinanox/scripts/api-bridge-setup.sh
 │      → ~/.arinanox/scripts/xfce-config.sh
 │      → ~/.arinanox/scripts/launcher-gen.sh
 │      → ~/.arinanox/scripts/motd-setup.sh
 │      → ~/.arinanox/scripts/proot-backup.sh
 │      → ~/.arinanox/scripts/proot-restore.sh
 │      → ~/.arinanox/scripts/proot-rollback.sh
 │      → ~/.arinanox/scripts/patch.sh
 │      → ~/.arinanox/scripts/seccomp-check.sh
 │      → ~/.arinanox/scripts/seccomp-fix.sh
 │      → ~/.arinanox/scripts/doctor.sh
 │      → ~/.arinanox/scripts/manifest-generate.sh
 │      → ~/.arinanox/scripts/manifest-apply.sh
 │      → ~/.arinanox/scripts/user-snapshot.sh
 │      → ~/.arinanox/scripts/status.sh
 │      (each chmod +x)
 │
 │      → ~/.arinanox/launchers/start.sh
 │      → ~/.arinanox/launchers/stop.sh
 │      → ~/.arinanox/launchers/update.sh
 │      (each chmod +x)
 │
 │      → ~/.arinanox/bin/arinanox (CLI dispatcher, chmod +x)
 │      → ~/.arinanox/run-api-bridge.sh (chmod +x)
 │
 ├── 5. Add PATH to ~/.bashrc if not present:
 │      export PATH="$HOME/.arinanox/bin:$PATH"
 │
 └── 6. Execute setup chain (IN ORDER):
        (a) bash host-setup.sh
        (b) bash proot-setup.sh
        (c) bash api-bridge-setup.sh
        (d) bash launcher-gen.sh
        (e) bash motd-setup.sh
```

### 3.2 Sub-script: `host-setup.sh`

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Side effects:**
1. Runs `termux-setup-storage` if `~/storage` does not exist
2. `pkg update -y`
3. `pkg install -y x11-repo tur-repo`
4. `pkg install -y termux-x11-nightly proot-distro pulseaudio xorg-xrandr netcat-openbsd termux-api virglrenderer virglrenderer-android angle-android rsync python3`

**Installed Termux packages (host layer):** `x11-repo`, `tur-repo`, `termux-x11-nightly`, `proot-distro`, `pulseaudio`, `xorg-xrandr`, `netcat-openbsd`, `termux-api`, `virglrenderer`, `virglrenderer-android`, `angle-android`, `rsync`, `python3`

**Download URL:** `https://raw.githubusercontent.com/arinadi/arinanoX/main/scripts/host-setup.sh`

### 3.3 Sub-script: `proot-setup.sh`

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Purpose:** Silverblue-style atomic container deployment.

**Variables:**
- `IMAGE="ghcr.io/arinadi/arinanox:latest"`
- `CONTAINER="arinanox"`
- `PREV_CONTAINER="arinanox-prev"`
- `CONTAINERS_DIR="/data/data/com.termux/files/usr/var/lib/proot-distro/containers"`

**Side effects:**
1. If `"${CONTAINERS_DIR}/${CONTAINER}"` exists:
   - Remove `arinanox-prev` if it exists: `proot-distro remove "$PREV_CONTAINER"`
   - Rename current → previous: `mv "${CONTAINERS_DIR}/${CONTAINER}" "${CONTAINERS_DIR}/${PREV_CONTAINER}"`
2. Pull and install new image: `proot-distro install "$IMAGE" --name "$CONTAINER"`

**Atomic deployment model:** The old container is preserved as `arinanox-prev` for instant rollback. The new image is installed fresh as `arinanox`. No backup/restore of user data occurs during this step (the user's `/home/admin` inside the container is preserved through the rename).

**Download URL:** `https://raw.githubusercontent.com/arinadi/arinanoX/main/scripts/proot-setup.sh`

### 3.4 Sub-script: `api-bridge-setup.sh`

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `ARINANOX_DIR="$HOME/.arinanox"`

**Side effects:**
1. Copies `run-api-bridge.sh` from `~/.arinanox/` to `~/run-api-bridge.sh` (chmod +x)
2. Creates `tapi` client script inside proot at `/usr/local/bin/tapi` (chmod +x)

**tapi client script contents:**
```text
#!/bin/bash
echo "$@" | nc 127.0.0.1 8888 &
timeout 10 nc 127.0.0.1 8889
```

**Download URL:** `https://raw.githubusercontent.com/arinadi/arinanoX/main/scripts/api-bridge-setup.sh`

### 3.5 Sub-script: `xfce-config.sh`

**Shebang:** `#!/bin/bash` (Termux shebang not used — runs inside proot)

**Purpose:** No-op. Prints a message declaring that the XFCE theme is pre-configured in the image layer. Lists config files:
- `xsettings.xml` — Orchis-Dark, elementary-hidpi, DPI 96, Scale 2
- `xfwm4.xml` — Orchis-Dark-xhdpi, compositing off, 1 workspace
- `xfce4-panel.xml` — 64px borderless, whiskermenu + tasklist
- `xfce4-desktop.xml` — dark background, no icons

**Download URL:** `https://raw.githubusercontent.com/arinadi/arinanoX/main/scripts/xfce-config.sh`

### 3.6 Sub-script: `launcher-gen.sh`

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `ARINANOX_DIR="$HOME/.arinanox"`

**Side effects:**
1. Creates `~/.shortcuts/` directory
2. Removes all old launcher variants (v1, v2, v3) — both in `~/.shortcuts/` and `~/`
3. Copies branded launchers:
   - `0-stop-arinanox.sh` ← `$ARINANOX_DIR/launchers/stop.sh`
   - `1-start-arinanox.sh` ← `$ARINANOX_DIR/launchers/start.sh`
4. Creates home symlinks:
   - `~/stop.sh` → `~/.shortcuts/0-stop-arinanox.sh`
   - `~/start.sh` → `~/.shortcuts/1-start-arinanox.sh`

**Files removed (cleanup):**
- `~/.shortcuts/{start,stop,update}{,-x11,-xfce,-arinanox,-proot}.sh`
- `~/.shortcuts/kill-{x11,proot,all}.sh`
- `~/.shortcuts/0-stop-arinanox.sh`, `~/.shortcuts/1-start-arinanox.sh`, `~/.shortcuts/2-update-arinanox.sh`
- `~/{start,stop,update}{,-x11,-xfce,-arinanox}.sh`
- `~/kill-{x11,proot,all}.sh`

**Known:** `update.sh` from launchers is NOT copied as a branded shortcut (noted: "update NOT included — destructive").

**Download URL:** `https://raw.githubusercontent.com/arinadi/arinanoX/main/scripts/launcher-gen.sh`

### 3.7 Sub-script: `motd-setup.sh`

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Side effects:** Writes MOTD to `/data/data/com.termux/files/usr/etc/motd`. Content shows commands: `bash ~/start.sh`, `bash ~/stop.sh`, `curl -sL URL/bootstrap.sh | bash`. Notes "User: admin / Pass: admin".

**Download URL:** `https://raw.githubusercontent.com/arinadi/arinanoX/main/scripts/motd-setup.sh`

---

## 4. Launchers — Full Service Lifecycle

### 4.1 `launchers/start.sh` — Startup Sequence

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"`
- `ANGLE_DIR="/data/data/com.termux/files/usr/opt/angle-android"`
- `X11_SOCK="${TMPDIR}/.X11-unix/X0"`

**Phase [0/3] — Health Check:**
- Runs `~/.arinanox/scripts/doctor.sh` (non-fatal — continues on warnings)
- If doctor script not found, shows `"• doctor not available"`

**Phase [1/3] — Start Services (parallel):**

1. **PulseAudio:**
   - Kill stale: `pkill -f pulseaudio`
   - Start: `pulseaudio --start --exit-idle-time=-1`
   - Load AAudio sink: `pactl load-module module-aaudio-sink`
   - Fallback: `pactl load-module module-sles-sink`
   - TCP module: `pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713`
   - **Port 4713** exposed on 127.0.0.1

2. **API Bridge:**
   - `pkill -f run-api-bridge.sh`
   - `bash ~/run-api-bridge.sh &>/dev/null &`

3. **virgl (auto-detect — 4 tiers):**
   - Tier "android": `command -v virgl_test_server_android` → `virgl_test_server_android &`
   - Tier "angle-vulkan-null": `command -v virgl_test_server` + `[ -d "${ANGLE_DIR}/vulkan-null" ]` → `LD_LIBRARY_PATH="${ANGLE_DIR}/vulkan-null" virgl_test_server --use-egl-surfaceless --use-gles &`
   - Tier "angle-vulkan": `command -v virgl_test_server` + `[ -d "${ANGLE_DIR}/vulkan" ]` → `LD_LIBRARY_PATH="${ANGLE_DIR}/vulkan" virgl_test_server --use-egl-surfaceless --use-gles &`
   - Tier "cpu": no virgl server started
   - `VIRGL_MODE` variable set to detected tier name

4. **X11 + Wake Lock:**
   - `export XDG_RUNTIME_DIR="$TMPDIR"`
   - `termux-x11 :0 -ac &`
   - `termux-wake-lock`
   - `am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null &`

**Phase [2/3] — Wait for X11 Socket:**
- Polls for `[ -S "$X11_SOCK" ]` up to 30 iterations (10ms each → 3s max)

**Phase [3/3] — Launch Desktop (GPU mode):**

If GPU mode (`$VIRGL_MODE != "cpu"`):
```
proot-distro login arinanox --shared-tmp -- su - admin -c "
    export DISPLAY=:0
    export PULSE_SERVER=tcp:127.0.0.1:4713
    export NO_AT_BRIDGE=1
    export GALLIUM_DRIVER=virpipe
    export MESA_GL_VERSION_OVERRIDE=4.1COMPAT
    export MESA_GLES_VERSION_OVERRIDE=3.1
    export MESA_NO_ERROR=1
    export MESA_BACK_BUFFER=pixmap
    rm -f /tmp/dbus-* 2>/dev/null
    dbus-launch --exit-with-session xfce4-session
"
```

If CPU mode (fallback):
```
proot-distro login arinanox --shared-tmp -- su - admin -c "
    export DISPLAY=:0
    export PULSE_SERVER=tcp:127.0.0.1:4713
    export NO_AT_BRIDGE=1
    export LIBGL_ALWAYS_SOFTWARE=1
    rm -f /tmp/dbus-* 2>/dev/null
    dbus-launch --exit-with-session xfce4-session
"
```

### 4.2 `launchers/stop.sh` — Stop Sequence

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Stop order (reverse of start):**

1. **XFCE processes** (graceful → force):
   - `pkill -f` for: `thunar`, `xfdesktop`, `xfce4-panel`, `xfce4-terminal`, `xfwm4`, `xfce4-session`
   - `sleep 1`
   - `pkill -9 -f` for same list

2. **Proot sessions:**
   - `pkill -f "dbus-daemon --nofork --session"`
   - `pkill -f "proot-distro login arinanox"`
   - `pkill -f "proot.*installed-rootfs/arinanox"`
   - `sleep 0.5`
   - `pkill -9 -f "proot.*installed-rootfs/arinanox"`

3. **Clean temp files (double-layer):**
   - Container rootfs path: `ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"`
   - Inside rootfs: `rm -rf "$ROOTFS/tmp/"{.X*,dbus-*,ssh-*,xdg-*,xfsm-*}`
   - `rm -f "$ROOTFS/tmp/.dbus"*`
   - `rm -rf "$ROOTFS/home/admin/.cache/sessions/"*`
   - `rm -f "$ROOTFS/home/admin/"{.ICEauthority,.Xauthority}`

4. **virgl server:** `pkill -f "virgl_test_server"`

5. **X11:**
   - `pkill -f "termux-x11"`, `pkill -9 -f "termux-x11"`
   - `rm -f "${TMPDIR:-...}/.X0-lock"`
   - `rm -rf "${TMPDIR:-...}/.X11-unix"`

6. **PulseAudio:** `pulseaudio --kill` or `pkill -9 pulseaudio`

7. **API bridge:** `pkill -f run-api-bridge.sh`

8. **Wake lock:** `termux-wake-unlock`

### 4.3 `launchers/update.sh`

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Complete contents:**
```text
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
REPO="https://raw.githubusercontent.com/arinadi/arinanoX/main"

echo ">>> Updating arinanoX..."
curl -sL --retry 2 "${REPO}/bootstrap.sh" | bash
```

A one-liner that re-pipes `bootstrap.sh` from the repo. Complete reinstall.

### 4.4 Supplementary Launchers

**`launchers/kill-all.sh`:** Calls `kill-proot.sh`, then `kill-x11.sh`, then `termux-wake-unlock`.

**`launchers/kill-proot.sh`:** Kills XFCE processes (thunar, xfdesktop4, xfce4-panel, xfce4-terminal, xfwm4, xfce4-session), dbus-daemon, proot-distro login, orphan proot. Double-layer temp cleanup inside proot + from host.

**`launchers/kill-x11.sh`:** Kills termux-x11, pulseaudio, API bridge. Releases wake lock. Cleans `${TMPDIR}/.X0-lock`, `${TMPDIR}/.X11-unix`, `${TMPDIR}/pulse-socket`.

**`launchers/start-x11.sh`:** Standalone X11 + PulseAudio starter (no XFCE). Starts PulseAudio, AAudio/SLES sinks, TCP module (port 4713), API bridge, Termux:X11 with `termux-wake-lock`, auto-opens Termux:X11 app via `am start -n com.termux.x11/com.termux.x11.MainActivity`.

**`launchers/start-xfce.sh`:** Standalone XFCE launcher (requires X11 already running). Starts XFCE inside proot with CPU-only mode (`LIBGL_ALWAYS_SOFTWARE=1`).

**`launchers/.v1-backup/`:** Preserved legacy v1 scripts — `kill-all.sh`, `kill-proot.sh`, `kill-x11.sh`, `start-x11.sh`, `start-xfce.sh` — functionally identical to current launchers.

### 4.5 Inter-Process Dependency Graph

```
PulseAudio (port 4713, TCP)
    │
    ├── API Bridge (ports 8888/8889, TCP)
    │       │
    │       └── tapi client (inside proot, /usr/local/bin/tapi)
    │
    ├── virgl (no port, background process)
    │       │
    │       └── GALLIUM_DRIVER=virpipe (inside proot)
    │
    ├── Termux:X11 (display :0, socket ${TMPDIR}/.X11-unix/X0)
    │       │
    │       └── DISPLAY=:0 (inside proot)
    │
    └── XFCE session (dbus-launch --exit-with-session xfce4-session)
            │
            └── Must wait for X11 socket to exist
```

**Dependency order:** PulseAudio → virgl (+ API bridge, parallel) → X11 → wait for socket → XFCE (proot-login).

---

## 5. CLI Dispatcher: `scripts/arinanox`

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Path installed:** `~/.arinanox/bin/arinanox`

**Variables:**
- `ARINANOX_DIR="${ARINANOX_DIR:-$HOME/.arinanox}"`
- `SCRIPTS_DIR="$ARINANOX_DIR/scripts"`
- `VERSION="1.0"`

**First-run bootstrap:** If `~/.arinanox/scripts` does not exist, auto-runs `curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash`.

### Complete Dispatch Table

| CLI Command | Category | Implementation |
|---|---|---|
| `arinanox start` | Desktop | `exec bash "$HOME/start.sh"` |
| `arinanox stop` | Desktop | `exec bash "$HOME/stop.sh"` |
| `arinanox status` | Status | `exec bash "$SCRIPTS_DIR/doctor.sh"` |
| `arinanox doctor` | Status | `exec bash "$SCRIPTS_DIR/doctor.sh"` |
| `arinanox update` | Core | Inline: `curl bootstrap.sh \| bash` then `manifest-apply.sh` if `user-manifest.yaml` exists |
| `arinanox rollback` | Core | `exec bash "$SCRIPTS_DIR/proot-rollback.sh"` |
| `arinanox store` | Packages | `exec bash "$ARINANOX_DIR/tools/apt-store.sh"` (inside proot) |
| `arinanox install` | Packages | Inline: reads `user-manifest.yaml`, parses packages, runs `proot-distro login arinanox -- sudo apt-get install -y $PKGS` |
| `arinanox backup` | Data | Inline: `rsync -av --delete` from container rootfs to `/sdcard/arinanox-backup` |
| `arinanox restore` | Data | Inline: `rsync -av --delete` from `/sdcard/arinanox-backup` to container rootfs |
| `arinanox snapshot` | Data | `exec bash "$SCRIPTS_DIR/user-snapshot.sh" "$@"` |
| `arinanox help` / `--help` / `-h` | Help | Prints usage text via `usage()` function |

**Inline `update` logic:**
```text
update)
    read -p "Continue? [y/N] " confirm
    curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash
    MANIFEST="$ARINANOX_DIR/user-manifest.yaml"
    if [ -f "$MANIFEST" ]; then
        bash "$SCRIPTS_DIR/manifest-apply.sh"
    fi
```

**Inline `install` logic:**
```text
install)
    MANIFEST="$ARINANOX_DIR/user-manifest.yaml"
    if [ ! -f "$MANIFEST" ]; then
        echo "Generate one: arinanox install --generate"
        exit 1
    fi
    PKGS=$(grep -E "^\s+- " "$MANIFEST" | sed 's/^\s*- //' | grep -v "^#" | tr '\n' ' ')
    if [ -n "$PKGS" ]; then
        proot-distro login arinanox -- bash -c "sudo apt-get update -qq && sudo apt-get install -y $PKGS" || true
    fi
```

**Inline `backup` logic:**
```text
backup)
    BACKUP_DIR="/sdcard/arinanox-backup"
    ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"
    mkdir -p "$BACKUP_DIR"
    rsync -av --delete "$ROOTFS/home/admin/" "$BACKUP_DIR/home/"
```

**Inline `restore` logic:**
```text
restore)
    BACKUP_DIR="/sdcard/arinanox-backup"
    ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"
    rsync -av --delete "$BACKUP_DIR/home/" "$ROOTFS/home/admin/"
```

---

## 6. Supporting Scripts

### 6.1 `scripts/doctor.sh` — Health Check

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Functions/checks performed:**
1. **System:** Android SDK version (`getprop ro.build.version.sdk`), Android release (`ro.build.version.release`), arch (`uname -m`), free memory (`free -m`)
2. **Seccomp:** Calls `seccomp-check.sh`; exit code determines pass/fail
3. **Termux Host Packages:** Checks `termux-x11-nightly`, `proot-distro`, `pulseaudio`, `virglrenderer-android` via `dpkg -l`
4. **Proot Container:** Checks existence of `/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs/home/admin`, shows size via `du -sh`. Checks binaries `firefox-esr` and `xfce4-session` inside container via `proot-distro login arinanox -- which`
5. **GPU:** Checks for `virgl_test_server_android` or `virgl_test_server` via `command -v`
6. **Storage:** Checks `~/.arinanox` directory size and free space on `/data`
7. **Runtime:** Checks PulseAudio on port 4713 (`netstat -tlnp | grep 4713`), Termux:X11 process (`pgrep -f termux.x11`), XFCE session (`pgrep -f xfce4-session`)
8. **Updates:** Checks presence of `proot-rollback.sh`

**Exit behavior:** Non-zero if failures found. Called by `start.sh` as pre-flight (non-fatal).

### 6.2 `scripts/status.sh` — System Status

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `ARINANOX_DIR="$HOME/.arinanox"`
- `CONTAINER="arinanox"`
- `PREV_CONTAINER="arinanox-prev"`
- `ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/${CONTAINER}/rootfs"`

**Displays:** Current container size, rollback container size, XFCE running status, X11 server running status, layered packages count (from `layers.txt`), backup count/size (from `backups/`).

### 6.3 `scripts/seccomp-check.sh` — Seccomp Detection

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Detection logic:**
1. Gets Android SDK via `getprop ro.build.version.sdk`
2. Probes proot: `proot-distro login arinanox -- bash -c 'echo ok'`
3. If SDK >= 34 (Android 14+) AND probe fails → severity `critical`, mitigation `PROOT_NO_SECCOMP=1`
4. Returns exit code 1 if critical

### 6.4 `scripts/seccomp-fix.sh` — Seccomp Mitigation

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Actions:**
1. Patches `~/.shortcuts/1-start-arinanox.sh`: `sed -i 's|proot-distro login arinanox|PROOT_NO_SECCOMP=1 proot-distro login arinanox|g' "$START_SH"`
2. Same patch on source `$ARINANOX_DIR/launchers/start.sh`
3. Adds `export PROOT_NO_SECCOMP=1` to `~/.bashrc` if not present

### 6.5 `scripts/proot-rollback.sh` — Rollback

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `CONTAINER="arinanox"`
- `PREV_CONTAINER="arinanox-prev"`
- `CONTAINERS_DIR="/data/data/com.termux/files/usr/var/lib/proot-distro/containers"`

**Logic:**
1. If `arinanox-prev` does not exist → exit with error
2. `proot-distro remove "$CONTAINER"` (remove current broken)
3. `mv "${CONTAINERS_DIR}/${PREV_CONTAINER}" "${CONTAINERS_DIR}/${CONTAINER}"` (restore previous)

### 6.6 `scripts/proot-backup.sh` — Manual Backup

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `CONTAINER="arinanox"`
- `BACKUP_DIR="$HOME/.arinanox/backups"`
- `TIMESTAMP=$(date +%Y%m%d_%H%M%S)`
- `ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/${CONTAINER}/rootfs"`

**Actions:**
1. Saves user-installed package list: `dpkg --get-selections` filtered through `comm -23`
2. Saves home directory: `tar czf /tmp/proot-home.tar.gz -C /home admin --exclude='.cache' --exclude='__pycache__' --exclude='.local/share/Trash'`
3. Maintains `home-latest.tar.gz` and `packages-latest.txt` symlinks

### 6.7 `scripts/proot-restore.sh` — Manual Restore

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `CONTAINER="arinanox"`
- `BACKUP_DIR="$HOME/.arinanox/backups"`
- `ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/${CONTAINER}/rootfs"`

**Actions:**
1. Extracts home directory tar into proot: `tar xzf /tmp/proot-home.tar.gz -C /home/`
2. Reinstalls user packages: `xargs -a /tmp/packages.txt apt-get install -y`
3. Re-applies storage symlinks: `ln -sf /sdcard/Download ~/Downloads`, `ln -sf /sdcard/DCIM/Camera ~/Pictures`, `ln -sf /sdcard ~/Android_Internal`

### 6.8 `scripts/manifest-generate.sh` — Manifest Generator

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `MANIFEST="$HOME/.arinanox/user-manifest.yaml"`
- `ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"`

**Logic:**
1. Gets user-installed packages: `proot-distro login arinanox -- bash -c 'apt-mark showmanual' | sort`
2. Filters against hardcoded base package list (extracted from Dockerfile layers — packages like `adduser`, `bash`, `firefox-esr`, `gcc`, `git`, etc.)
3. Detects custom dotfiles by comparing against shipped configs
4. Detects installed themes/icons from `/usr/share/themes/` and `/usr/share/icons/`
5. Writes `~/.arinanox/user-manifest.yaml`

**Manifest YAML structure:**
```yaml
# arinanoX User Manifest
packages:
  - ripgrep
  - neofetch
dotfiles:
  - .bash_aliases
xfce_config:
  - xfce4-panel.xml
  - xfwm4.xml
  - xsettings.xml
  - xfce4-desktop.xml
  - xfce4-keyboard-shortcuts.xml
  - thunar.xml
```

### 6.9 `scripts/manifest-apply.sh` — Manifest Applier

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `MANIFEST="$HOME/.arinanox/user-manifest.yaml"`
- `ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"`
- `BACKUP_DIR="/sdcard/arinanox-backup"`

**Actions:**
1. Parses `packages:` section from manifest, runs `sudo apt-get install`
2. Restores XFCE config XMLs from `$HOME/.arinanox/snapshot-current/home/.config/xfce4/...`
3. Restores dotfiles from `$BACKUP_DIR/home/`

### 6.10 `scripts/user-snapshot.sh` — Hardlink Snapshots

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `SNAPSHOT_DIR="$HOME/.arinanox/snapshots"`
- `ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"`
- `HOME_SRC="$ROOTFS/home/admin"`
- `MAX_SNAPSHOTS=3`

**Subcommands:**
- `create` | `c`: Runs `manifest-generate.sh`, then `rsync -a $LINK_DEST "$HOME_SRC/" "$SNAP_PATH/"`. Updates `~/.arinanox/snapshot-current` symlink. Rotates old snapshots (keeps last 3).
- `list` | `ls` | `l`: Lists snapshots with sizes.
- `restore` | `r` <id>: `rsync -a --delete "$SNAP_PATH/" "$HOME_SRC/"`.

**Link-dest optimization:** `LINK_DEST="--link-dest=$SNAPSHOT_DIR/$LAST"` — subsequent snapshots only take space for changed files.

### 6.11 `scripts/patch.sh` — Optional Software Installer

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Variables:**
- `CONTAINER="arinanox"`
- `LAYERS_FILE="$HOME/.arinanox/layers.txt"`

**Package matrix (declared as `declare -A PATCHES`):**

| Flag | Description | Install Command |
|---|---|---|
| `--chromium` | Chromium Browser | `apt-get install -y chromium-browser` |
| `--code` | VS Code (code-server) | `curl -fsSL https://code-server.dev/install.sh \| sh` |
| `--geany` | Geany (Lightweight IDE) | `apt-get install -y geany` |
| `--neovim` | Neovim | `apt-get install -y neovim` |
| `--ollama` | Ollama (local LLM) | `curl -fsSL https://ollama.com/install.sh \| sh` |
| `--zsh` | Zsh + Oh My Zsh | `apt-get install -y zsh && su - admin -c 'sh -c "$(curl -fsSL ...)" "" --unattended'` |
| `--nala` | Nala (Modern APT) | `apt-get install -y nala` |
| `--docker` | Docker (rootless) | `curl -fsSL https://get.docker.com \| sh` |
| `--ripgrep` | Fast Grep (rg) | `apt-get install -y ripgrep` |
| `--viewnior` | Image Viewer (Viewnior) | `apt-get install -y viewnior` |
| `--xarchiver` | Archive Manager | `apt-get install -y xarchiver` |
| `--galculator` | Calculator (Galculator) | `apt-get install -y galculator` |
| `--github` | GitHub CLI | `apt-get install -y gh` |
| `--all` | All patches | Iterates all keys |

**Mode:** Interactive (no args) or CLI flags (e.g., `--chromium --code --zsh`).

**Tracking:** Each installed patch is appended to `~/.arinanox/layers.txt`.

### 6.12 `scripts/setup-ai-stack.sh` — AI Stack Installer

**Shebang:** `#!/usr/bin/env bash` (note: runs inside proot, has `env` shebang; may break with PROOT_NO_SECCOMP — see KNOWN-UNKNOWNS)

**Installs:** Pi (`@earendil-works/pi-coding-agent`), lean-ctx v3.9.8 musl ARM64 binary, DeepSeek `models.json`, ddg_search (`@oevortex/ddg_search`), playwright-cli (`@playwright/cli`) + Playwright Firefox, MCP config for ddg-search, Firefox user.js.

**Identical copy at:** `image/configs/ai-stack/setup-ai-stack.sh`. Also copied as `/usr/local/bin/arinanox-ai-setup` during Docker build.

### 6.13 `scripts/theme-dark.sh` — Orchis Dark Theme Applier

**Shebang:** `#!/bin/bash`

**Writes four XFCE config XML files** to `$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/`:
- `xsettings.xml` — Orchis-Dark theme, elementary-xfce-hidpi icons, DPI 96, scale 2x
- `xfwm4.xml` — Orchis-Dark-xhdpi theme, no compositing, 1 workspace
- `xfce4-panel.xml` — 64px dark borderless panel, Whisker Menu + Tasklist
- `xfce4-desktop.xml` — Almost-black background (rgba 0.05,0.05,0.05,1.0), no desktop icons

### 6.14 `scripts/xfce-config.sh` — No-op Declaration

**Shebang:** `#!/bin/bash`

Prints: "XFCE theme is pre-configured in the image." Lists shipped config files.

### 6.15 `uninstall.sh` — Complete Teardown

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Step-by-step removal:**
1. Stops running sessions: XFCE, proot, X11, PulseAudio, API bridge, WakeLock
2. Removes proot containers (both `arinanox` and `arinanox-prev`)
3. Removes `~/.shortcuts/` launchers
4. Removes home symlinks (`~/start.sh`, `~/stop.sh`, `~/update.sh`, `~/update-arinanox.sh`)
5. Removes `~/.arinanox/` cache
6. Cleans Termux tmp files (`.X0-lock`, `.X11-unix`, `pulse-socket`)
7. Removes `~/run-api-bridge.sh`

**Does NOT remove:** `~/arinanoX/` (git repo clone), `~/storage/` (Android storage), `~/.bashrc` (Termux config).

---

## 7. CI Pipeline: `.github/workflows/build-image.yml`

**Trigger paths:**
- Push to `main` branch affecting `image/**` or `.github/workflows/**`
- `workflow_dispatch:` (manual trigger)

**Job: `build`**

**Runner:** `ubuntu-latest`

**Permissions:** `packages: write`

**Steps:**
1. `actions/checkout@v4`
2. `docker/login-action@v3` — Login to GHCR as `${{ github.actor }}` with `${{ secrets.GITHUB_TOKEN }}`
3. `docker/setup-qemu-action@v3` — Set up QEMU for ARM64 cross-build
4. `docker/setup-buildx-action@v3` — Set up Docker Buildx
5. `docker/build-push-action@v5` — Build and push:
   - Context: `./image`
   - Platforms: `linux/arm64`
   - Push: `true`
   - Tags:
     - `ghcr.io/${{ github.repository_owner }}/arinanox:latest`
     - `ghcr.io/${{ github.repository_owner }}/arinanox:1.0.${{ github.run_number }}`

**Image registry:** `ghcr.io/arinadi/arinanox`

---

## 8. API Bridge Architecture

### 8.1 Host Side: `archive/run-api-bridge.sh` (deployed as `~/run-api-bridge.sh`)

**Shebang:** `#!/data/data/com.termux/files/usr/bin/bash`

**Architecture:** Netcat-based TCP echo bridge with eval.

```
IN_PORT=8888
OUT_PORT=8889
```

**Loop:**
```text
while true; do
    CMD=$(nc -l -p $IN_PORT | head -n 1)
    if [ -n "$CMD" ]; then
        eval "$CMD" 2>&1 | nc -l -p $OUT_PORT
    fi
done
```

The bridge listens on port 8888 for a command, executes it via `eval`, and pipes stdout/stderr through a temporary listener on port 8889. Each request opens two sequential netcat connections.

### 8.2 Guest Side: `/usr/local/bin/tapi` (created by `api-bridge-setup.sh`)

**Shebang:** `#!/bin/bash`

```text
echo "$@" | nc 127.0.0.1 8888 &
timeout 10 nc 127.0.0.1 8889
```

Sends the command as a one-shot TCP packet to port 8888, then listens on port 8889 for the response with a 10-second timeout.

### 8.3 Data Flow

```
Inside proot                          Termux Host (Android)
┌──────────┐     TCP 127.0.0.1:8888   ┌─────────────────┐
│ tapi     │ ─────────────────────────→│ run-api-bridge  │
│ (client) │     │                     │ (listener loop) │
│          │     │                     │                 │
│          │     │   TCP 127.0.0.1:8889│  eval "$CMD"    │
│          │ ←─────────────────────────│     2>&1        │
└──────────┘                           └─────────────────┘
```

### 8.4 Security

**Shebang comment:** "🛡️ Hardened Termux:API Bridge — Prevents large payloads from being executed as shell commands." The `head -n 1` on the incoming command line acts as a sanitizer (takes only the first line).

---

## 9. Seccomp Detection and Mitigation Chain

### 9.1 Detection: `seccomp-check.sh`

1. Detect Android version: `getprop ro.build.version.sdk` (SDK number) and `getprop ro.build.version.release` (human-readable)
2. Probe proot: `proot-distro login arinanox -- bash -c 'echo ok'`
3. If SDK >= 34 AND probe fails → **critical** severity
4. Returns exit code 1 if critical

### 9.2 Mitigation: `seccomp-fix.sh`

Applies `PROOT_NO_SECCOMP=1` in three locations:
1. `~/.shortcuts/1-start-arinanox.sh`: Prepend to `proot-distro login arinanox` command
2. `$ARINANOX_DIR/launchers/start.sh`: Same prepend
3. `~/.bashrc`: `export PROOT_NO_SECCOMP=1`

### 9.3 Chain

```
doctor.sh
  └── seccomp-check.sh → detects Android 15+ (SDK >= 34) seccomp blocking
       └── exit 1 if critical → doctor.sh shows RED "seccomp BLOCKING proot"
       
seccomp-fix.sh → applies PROOT_NO_SECCOMP=1 mitigation
  └── patches start.sh and .bashrc
```

### 9.4 Side Effects of `PROOT_NO_SECCOMP=1`

| Side Effect | Cause | Workaround |
|---|---|---|
| `su - admin` fails | setuid blocked by no-seccomp mode | Use `proot-distro login -u admin` |
| `#!/usr/bin/env node` broken | V8/libuv thread sync fails | Invoke via `node /path/to/cli.js` |
| `uv__io_poll: EINTR` crash | libuv + seccomp interaction | Fixed by `PROOT_NO_SECCOMP=1` |
| `fork: Function not implemented` | seccomp blocks clone/fork | Fixed by `PROOT_NO_SECCOMP=1` |
| `futex` error | V8/libuv thread sync | Fixed by `PROOT_NO_SECCOMP=1` |

---

## 10. Atomic Deployment Model

### 10.1 Update → proot-setup.sh

```
Before update:
  /data/.../containers/arinanox/     (current deployment, ~2GB)
  /data/.../containers/arinanox-prev/ (empty or stale)

Update step:
  mv arinanox → arinanox-prev         (save for rollback)
  proot-distro install new image      (fresh install)
```

### 10.2 Rollback → proot-rollback.sh

```
Before rollback:
  /data/.../containers/arinanox/      (broken deployment)
  /data/.../containers/arinanox-prev/ (working previous)

Rollback step:
  proot-distro remove arinanox        (remove broken)
  mv arinanox-prev → arinanox         (restore previous)
```

### 10.3 Container Rootfs Paths

- **Current:** `/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs`
- **Previous:** `/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox-prev/rootfs`

---

## 11. User-Layer Manifest System

### 11.1 Generation: `manifest-generate.sh`

```
apt-mark showmanual (inside proot)
         │
         ▼
    Compare against hardcoded base-package list (from Dockerfile layers)
         │
         ▼
    User packages detected (e.g., ripgrep, neofetch)
         │
    Detect custom dotfiles (differ from shipped configs-target/)
         │
    Detect themes/icons from /usr/share/themes/ and /usr/share/icons/
         │
         ▼
    Write ~/.arinanox/user-manifest.yaml
```

### 11.2 Application: `manifest-apply.sh`

```
Read ~/.arinanox/user-manifest.yaml
         │
         ├── packages: → proot-distro login → apt-get install
         ├── xfce_config: → copy from snapshot-current to container rootfs
         └── dotfiles: → copy from /sdcard/arinanox-backup to container rootfs
```

### 11.3 Snapshot Integration: `user-snapshot.sh`

```
arinanox snapshot create
  └── manifest-generate.sh (auto-generate manifest)
  └── rsync -a --link-dest=<previous> home/admin/ → ~/.arinanox/snapshots/<timestamp>/
  └── update ~/.arinanox/snapshot-current symlink
  └── rotate: keep last 3 snapshots

arinanox snapshot list
  └── ls ~/.arinanox/snapshots/

arinanox snapshot restore <id>
  └── rsync -a --delete snapshot/ → container rootfs home/admin/
```

---

## 12. AI Stack Layering

### 12.1 Dockerfile Layer 5

Pre-installs the complete AI vibe-coding stack inside the container image:

| Component | Install Method | Path | Notes |
|---|---|---|---|
| Pi (coding agent) | `npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest` | `/usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js` | `--ignore-scripts` used to avoid build failures in proot |
| lean-ctx | Curl binary from GitHub releases, `cp` to `/usr/local/bin/` | `/usr/local/bin/lean-ctx` | v3.9.8, musl ARM64 static binary |
| ddg_search | `npm install -g @oevortex/ddg_search@latest` | `/usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js` | DuckDuckGo search tool |
| playwright-cli | `npm install -g @playwright/cli@latest` | `/usr/lib/node_modules/@playwright/cli/playwright-cli.js` | Browser automation |
| Playwright Firefox | `playwright-cli install-browser firefox` | `~/.cache/ms-playwright/firefox-*/firefox/firefox` | ~97MB |
| DeepSeek models.json | Inline JSON to `~/.pi/agent/models.json` | `~/.pi/agent/models.json` | 1M context, `deepseek-chat` |
| MCP config | Inline JSON to `~/.pi/agent/mcp.json` | `~/.pi/agent/mcp.json` | ddg-search MCP server |
| Firefox user.js | Copy from `configs/ai-stack/user.js` | `~/.mozilla/firefox/*.default-esr/user.js` | 126 lines, proot-optimized |
| Setup script | `cp` to `/usr/local/bin/` | `/usr/local/bin/arinanox-ai-setup` | Same as `scripts/setup-ai-stack.sh` |

### 12.2 Plan Document: `docs/plan-ai-stack.md`

**Status:** ✅ Tervalidasi — all tools installed and working in proot ARM64.

**Key findings validated in codebase:**
1. `PROOT_NO_SECCOMP=1` required — applied in start scripts via `seccomp-fix.sh`
2. `su - admin` broken with `PROOT_NO_SECCOMP=1` — start script uses `proot-distro login ... su - admin` (works)
3. Shebang `#!/usr/bin/env node` broken — MCP config uses `node /path/to/cli.js`
4. Termux bind-mount constraint — PATH hardened in `.bashrc`
5. DuckDuckGo blocked in Indonesia → IAsk fallback — documented in `docs/ai-stack-usage.md`

### 12.3 Usage Document: `docs/ai-stack-usage.md`

Documents invocation patterns for all AI tools in the proot environment, including verified test suite results.

### 12.4 Firefox user.js (`configs/user.js` and `image/configs/ai-stack/user.js`)

126 lines of Firefox preferences optimized for proot:
- **Rendering:** `gfx.webrender.software=true`, `layers.acceleration.disabled=true`, `gfx.canvas.accelerated=false`
- **Animations:** all disabled (`browser.tabs.animated=false`, `toolkit.cosmeticAnimations.enabled=false`, `ui.prefersReducedMotion=1`)
- **Memory:** `dom.ipc.processCount=2`
- **Disk cache:** disabled (`browser.cache.disk.enable=false`)
- **Network:** prefetch/preconnect/speculative off
- **Telemetry:** all tracking/telemetry off
- **Sandbox:** `security.sandbox.content.level=0`
- **Privacy:** tracking protection, HTTPS-only, cookie blocking

---

## 13. Configuration Targets (Image-Built)

### 13.1 XFCE Configuration XMLs

**Location:** `image/configs-target/home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/`

**`xsettings.xml`** — GTK/theme settings:
- `ThemeName`: `Orchis-Dark`
- `IconThemeName`: `elementary-xfce-hidpi`
- `FontName`: `Sans 12`
- `CursorThemeName`: `Adwaita`, `CursorThemeSize`: `64`
- `DPI`: `96` (Xft), `WindowScalingFactor`: `2` (Xfce)
- Touch-friendly: `DoubleClickDistance`: `20`, `DndDragThreshold`: `49`, `DoubleClickTime`: `587`

**`xfwm4.xml`** — Window manager config:
- `use_compositing`: `false` (critical for proot — compositing off avoids GPU issues)
- `theme`: `Orchis-Dark-xhdpi`
- `workspace_count`: `1`
- Full property set (~60 properties including focus, placement, cycling, shadows)

**`xfce4-panel.xml`** — Panel config:
- `dark-mode`: `true`
- Panel size: `64`px, bottom-center (`position: p=6;x=0;y=0`)
- `background-style`: `2` (solid), `background-alpha`: `85`
- `autohide-behavior`: `1` (intelligent), `autohide-size`: `10`
- Plugins: `whiskermenu` (plugin-1, view-mode 2, custom icon `distributor-logo-xfce`) + `tasklist` (plugin-2, no labels, icon-size 48, grouping 1)

**`xfce4-desktop.xml`** — Desktop background:
- No image (`image-style`: `0`), solid color (`color-style`: `0`)
- Color: `rgba1` = `[0.05, 0.05, 0.05, 1.0]` (almost black)
- `desktop-icons`: `primary=false` (no desktop icons)

**`xfce4-keyboard-shortcuts.xml`** — Keyboard shortcuts:
- `<Primary><Alt>r` → `xdotool click 3` (right-click emulation for touchscreens)
- `<Super>r` → `xfce4-appfinder -c`
- `<Super>e` → `thunar`
- `<Primary><Alt>t` → `exo-open --launch TerminalEmulator`
- Full xfwm4 workspace switching (keys for workspaces 1-12, move window to workspace 1-9, tile left/right/up/down, etc.)

**`thunar.xml`** — File manager config:
- `misc-single-click`: `true` (touch-friendly)
- `misc-single-click-timeout`: `500`
- Default view: `ThunarIconView`, zoom: `THUNAR_ZOOM_LEVEL_LARGER`

### 13.2 GTK Overrides

**File:** `image/configs-target/home/admin/.config/gtk-3.0/gtk.css`

Touch-friendly overrides:
- Scrollbar slider: `min-width: 14px`, `min-height: 14px`, `border-radius: 7px`
- Checkboxes/radio buttons: `min-width: 22px`, `min-height: 22px`
- Spinbutton arrows: `min-width: 28px`, `min-height: 28px`
- Combo box dropdown: `min-width: 30px`
- Paned separator: `min-width: 6px`, `min-height: 6px`
- Thunar sidebar/icon view: extra padding

### 13.3 Bash Configuration

**File:** `image/configs-target/home/admin/.bashrc`

**Environment variables set:**
- `DISPLAY=:0`
- `XDG_RUNTIME_DIR=/tmp`
- `NO_AT_BRIDGE=1` (suppress accessibility warnings)
- `LIBGL_ALWAYS_SOFTWARE=1` (software rendering fallback)
- `GDK_SCALE=2` (2x UI scaling for high-DPI)
- `GDK_DPI_SCALE=0.5` (compensates GDK_SCALE for fonts)
- `MOZ_DISABLE_CONTENT_SANDBOX=1` (Firefox sandbox suppression in proot)

**PATH hardening:**
```text
TARGET_PATH=/home/admin/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH=$TARGET_PATH
```
And at end of file:
```text
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "/data/data/com.termux" | tr '\n' ':' | sed 's/:$//')
```

**Aliases:** `update`, `ll`, `la`, `l`, `..`, `...`, `cls`, `df`, `free`, `ports`, `myip`

**Sources:** `~/.arinanox/tools/tapi-utils.sh`

**Welcome message:** Shows available TAPI commands on login.

### 13.4 Autostart

**File:** `image/configs-target/home/admin/.config/autostart/clipboard-sync.desktop`
```
[Desktop Entry]
Type=Application
Name=Clipboard Sync
Comment=Sync Android and proot clipboards
Exec=bash /home/admin/.arinanox/tools/clipboard-sync.sh
X-GNOME-Autostart-enabled=true
NoDisplay=true
```

### 13.5 PulseAudio Client Config

**File:** `image/configs-target/home/admin/.pulse/client.conf`
```
default-server = 127.0.0.1
autospawn = no
daemon-binary = /bin/true
```

Forces PulseAudio to connect via TCP to 127.0.0.1 (port 4713), prevents autospawn, and sets dummy daemon binary (since the real daemon runs in Termux host, not proot).

### 13.6 In-Image Tools

**Location:** `/home/admin/.arinanox/tools/` (inside proot)

**`apt-store.sh`** — GUI package manager using `yad`:
- Search, install, upgrade, add repos (VS Code, Firefox, Docker, OpenJDK, Custom), view sources

**`clipboard-sync.sh`** — Background daemon syncing Android ↔ proot clipboards:
- Polls every 2s; reads Android clipboard via `tapi termux-clipboard-get`, writes to `xclip`; reads `xclip -selection clipboard -o` and writes to `tapi termux-clipboard-set`

**`genmon-battery.sh`** — XFCE Genmon plugin for battery:
- Outputs `<txt>🔋 85%</txt>` format, polling interval 30s
- Uses `tapi termux-battery-status` → `jq --raw-output .percentage`

**`genmon-volume.sh`** — XFCE Genmon plugin for volume:
- Outputs `<txt>🔊 ━━━━━</txt>` format, polling interval 5s
- Uses `tapi termux-volume music`

**`tapi-utils.sh`** — Sourced shell functions:
- `clipget`, `clipset`, `toast`, `battery`, `vol-up`, `vol-down`, `vol-get`, `bright`, `flash`, `flash-off`, `notify`, `openurl`, `share`, `speak`, `listen`, `buzz`, `wifi`, `whereami`, `photo`, `sms`, `clipboard-watch`

---

## 14. Image Source Configs (`image/configs/`)

Source copies of configuration files used during Docker build:

| File | Target in configs-target | Notes |
|---|---|---|
| `bashrc` | `configs-target/home/admin/.bashrc` | Simpler version; no Termux PATH guard |
| `client.conf` | `configs-target/home/admin/.pulse/client.conf` | Same content |
| `gtk.css` | `configs-target/home/admin/.config/gtk-3.0/gtk.css` | Same content |
| `thunar.xml` | `configs-target/.../thunar.xml` | Same (XML declaration: 1.0 vs 1.1) |
| `xfwm4.xml` | `configs-target/.../xfwm4.xml` | Simplified; missing ~70 properties from target |
| `clipboard-sync.sh` | `configs-target/.../clipboard-sync.sh` | Same content |
| `genmon-battery.sh` | `configs-target/.../genmon-battery.sh` | Same content |
| `genmon-volume.sh` | `configs-target/.../genmon-volume.sh` | Same content |
| `tapi-utils.sh` | `configs-target/.../tapi-utils.sh` | Same content |
| `autostart/clipboard-sync.desktop` | `configs-target/.../clipboard-sync.desktop` | Same content |
| `ai-stack/setup-ai-stack.sh` | (build-time reference only) | Same as `scripts/setup-ai-stack.sh` |
| `ai-stack/user.js` | (build-time reference only) | Same as `configs/user.js` |
| `ai-stack/plan-ai-stack.md` | (build-time reference only) | Same as `docs/plan-ai-stack.md` |

---

## 15. Archive Scripts

| Script | Shebang | Purpose | Notes |
|---|---|---|---|
| `archive/apply-xfce-config.sh` | `#!/bin/bash` | Old XFCE config applicator | Yaru theme, Papirus icons; runs inside proot |
| `archive/install-tui-packages.sh` | `#!/data/data/com.termux/files/usr/bin/bash` | Interactive TUI package installer | Dialog-based; Ubuntu distro; AI tools, dev tools |
| `archive/launch-pi-vnc.sh` | `#!/bin/bash` | Raspberry Pi VNC bridge | Auto-detects phone IP via USB tethering |
| `archive/run-api-bridge.sh` | `#!/data/data/com.termux/files/usr/bin/bash` | Legacy API bridge | Same as live `run-api-bridge.sh` |
| `archive/setup-proot-xfce.sh` | `#!/data/data/com.termux/files/usr/bin/bash` | Old proot XFCE setup (Ubuntu) | Predecessor to current bootstrap chain |
| `archive/setup-termux-native.sh` | `#!/data/data/com.termux/files/usr/bin/bash` | Native Termux desktop setup | Multiple DEs, GPU, VNC, Pi bridge |

---

## 16. Complete Bootstrap → First-Run → Update → Rollback → Uninstall Flow

### 16.1 Bootstrap (fresh install)

```
User runs:
curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash

Flow:
  1. Interactive menu → [1] Install
  2. Download 16+ scripts to ~/.arinanox/scripts/
  3. Download launchers to ~/.arinanox/launchers/
  4. Download CLI to ~/.arinanox/bin/arinanox
  5. Add ~/.arinanox/bin to PATH in ~/.bashrc
  6. Download run-api-bridge.sh to ~/.arinanox/
  7. Execute sequence:
     a. host-setup.sh → pkg install termux-x11, proot-distro, virgl, etc.
     b. proot-setup.sh → pull ghcr.io/arinadi/arinanox:latest → extract as "arinanox" container
     c. api-bridge-setup.sh → cp run-api-bridge.sh to ~/, create tapi inside proot
     d. launcher-gen.sh → install ~/.shortcuts/0-stop, 1-start, home symlinks
     e. motd-setup.sh → write MOTD
```

### 16.2 First Run

```
User runs: arinanox start
  (or taps Termux:Widget "1-start-arinanox.sh")

Flow:
  1. doctor.sh → health check (non-fatal)
  2. Kill stale pulseaudio → start new pulseaudio on port 4713 (TCP)
  3. Start API bridge (ports 8888/8889)
  4. Auto-detect virgl (android → angle → cpu)
  5. Start termux-x11 :0 -ac
  6. Wake lock acquired
  7. Switch to Termux:X11 Android app
  8. Wait for X11 socket (/data/data/.../tmp/.X11-unix/X0)
  9. proot-distro login arinanox --shared-tmp -- su - admin -c
     → DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 GALLIUM_DRIVER=virpipe ...
     → dbus-launch --exit-with-session xfce4-session
  10. XFCE desktop renders in Termux:X11 app
  11. Clipboard sync daemon starts (autostart)
  12. TAPI utility functions available (battery, clipget, etc.)
```

### 16.3 Update

```
User runs: arinanox update
  (or: bash ~/.shortcuts/update.sh, which runs launchers/update.sh)

Flow:
  1. Prompts for confirmation
  2. curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash
     a. Download all scripts fresh
     b. host-setup.sh → installs/updates host packages
     c. proot-setup.sh → atomic swap:
        - mv existing "arinanox" → "arinanox-prev"
        - proot-distro install new image as "arinanox"
     d. api-bridge-setup.sh → reinstall tapi bridge
     e. launcher-gen.sh → reinstall shortcuts
     f. motd-setup.sh → rewrite MOTD
  3. If ~/.arinanox/user-manifest.yaml exists:
     bash manifest-apply.sh → reinstall user packages, XFCE configs, dotfiles

NOTE: The user's /home/admin is INSIDE the container. When "arinanox" is
renamed to "arinanox-prev", the home directory goes with it. The new
image has a fresh /home/admin from the Dockerfile.

User data safety net: arinanox snapshot create before updating.
```

### 16.4 Rollback

```
User runs: arinanox rollback

Flow:
  1. proot-rollback.sh checks if "arinanox-prev" exists
  2. proot-distro remove "arinanox" (remove broken new image)
  3. mv "arinanox-prev" → "arinanox" (restore previous deployment)
  4. User runs: bash ~/start.sh

This restores the exact state of /home/admin from the previous deployment.
```

### 16.5 Uninstall

```
User runs: bootstrap.sh (interactive) → [2] Uninstall
  (or directly: curl .../uninstall.sh | bash)

Flow:
  1. Stop all: XFCE, proot, X11, PulseAudio, API bridge, wake lock
  2. proot-distro remove arinanox
  3. proot-distro remove arinanox-prev
  4. rm -f ~/.shortcuts/0-stop, 1-start, etc.
  5. rm -f ~/start.sh, ~/stop.sh, ~/update.sh symlinks
  6. rm -rf ~/.arinanox/
  7. Clean Termux tmp: .X0-lock, .X11-unix, pulse-socket
  8. rm -f ~/run-api-bridge.sh
  9. NOT removed: ~/arinanoX/ (git repo), ~/storage/, ~/.bashrc
```

---

## 17. Environment Variables Catalog

| Variable | Set In | Value |
|---|---|---|
| `DEBIAN_FRONTEND` | Dockerfile Layer 1 | `noninteractive` |
| `LANG` | Dockerfile Layer 1 → Layer 4 | `C.UTF-8` → `en_US.UTF-8` |
| `LC_ALL` | Dockerfile Layer 1 → Layer 4 | `C.UTF-8` → `en_US.UTF-8` |
| `TMPDIR` | `start.sh`, `stop.sh`, etc. | `/data/data/com.termux/files/usr/tmp` (default) |
| `XDG_RUNTIME_DIR` | `start.sh`, `kill-x11.sh` | `$TMPDIR` |
| `DISPLAY` | `start.sh`, `.bashrc` (proot) | `:0` |
| `PULSE_SERVER` | `start.sh` (proot `su -c`), `.pulse/client.conf` | `tcp:127.0.0.1:4713` |
| `NO_AT_BRIDGE` | `start.sh`, `.bashrc` (proot) | `1` |
| `GALLIUM_DRIVER` | `start.sh` (GPU mode) | `virpipe` |
| `LIBGL_ALWAYS_SOFTWARE` | `start.sh` (CPU mode), `.bashrc` (proot) | `1` |
| `MESA_GL_VERSION_OVERRIDE` | `start.sh` (GPU mode) | `4.1COMPAT` |
| `MESA_GLES_VERSION_OVERRIDE` | `start.sh` (GPU mode) | `3.1` |
| `MESA_NO_ERROR` | `start.sh` (GPU mode) | `1` |
| `MESA_BACK_BUFFER` | `start.sh` (GPU mode) | `pixmap` |
| `GDK_SCALE` | `.bashrc` (proot) | `2` |
| `GDK_DPI_SCALE` | `.bashrc` (proot) | `0.5` |
| `MOZ_DISABLE_CONTENT_SANDBOX` | `.bashrc` (proot) | `1` |
| `PROOT_NO_SECCOMP` | `seccomp-fix.sh` → `.bashrc`, start scripts | `1` |
| `NVM_DIR` | `.bashrc` (proot) | `$HOME/.config/nvm` |
| `DEEPSEEK_API_KEY` | (user-set, referenced in models.json) | `$DEEPSEEK_API_KEY` |
| `NODE_TLS_REJECT_UNAUTHORIZED` | MCP config (mcp.json) | `0` |
| `ARINANOX_DIR` | `scripts/arinanox` | `$HOME/.arinanox` (default) |
| `VERSION` | `scripts/arinanox` | `1.0` |

---

## 18. Exported Port Numbers and Socket Paths

| Port/Socket | Protocol | Purpose | Used By |
|---|---|---|---|
| `4713` | TCP | PulseAudio native protocol (auth-anonymous) | `pactl load-module module-native-protocol-tcp` in `start.sh` |
| `8888` | TCP | API bridge command input | `run-api-bridge.sh` listener; `tapi` client writes to this |
| `8889` | TCP | API bridge response output | `run-api-bridge.sh` listener; `tapi` client reads from this |
| `${TMPDIR}/.X11-unix/X0` | Unix socket | X11 display socket | `termux-x11 :0 -ac` creates it; proot binds through `--shared-tmp` |

---

## 19. GHCR Image References

| Tag | Pattern | Source |
|---|---|---|
| `:latest` | `ghcr.io/${{ github.repository_owner }}/arinanox:latest` | CI `build-image.yml` |
| `:1.0.${{ github.run_number }}` | `ghcr.io/arinadi/arinanox:1.0.123` | CI `build-image.yml` |
| Full URL in proot-setup.sh | `ghcr.io/arinadi/arinanox:latest` | `scripts/proot-setup.sh` |

---

## 20. Repository URLs Referenced

| URL | Purpose |
|---|---|
| `https://raw.githubusercontent.com/arinadi/arinanoX/main/...` | Base for all script downloads (`bootstrap.sh` downloads) |
| `https://github.com/arinadi/arinanoX` | Repository URL in CLI first-run bootstrap |
| `https://deb.nodesource.com/setup_22.x` | Node.js 22 setup script (Dockerfile Layer 3) |
| `https://github.com/yvgude/lean-ctx/releases/download/v3.9.8/lean-ctx-aarch64-unknown-linux-musl.tar.gz` | lean-ctx binary (Dockerfile Layer 5) |
| `https://code-server.dev/install.sh` | code-server installer (`patch.sh`) |
| `https://ollama.com/install.sh` | Ollama installer (`patch.sh`) |
| `https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh` | Oh My Zsh installer (`patch.sh`) |
| `https://get.docker.com` | Docker installer (`patch.sh`) |
| `https://api.deepseek.com` | DeepSeek API base URL (`models.json`) |

---

## 21. CI/CD Pipeline Conventions

**File:** `.github/workflows/build-image.yml`

- **Runner:** `ubuntu-latest`
- **QEMU:** `docker/setup-qemu-action@v3` (ARM64 cross-build)
- **Buildx:** `docker/setup-buildx-action@v3`
- **Push:** `docker/build-push-action@v5`
- **Context:** `./image`
- **Platforms:** `linux/arm64`
- **Registry:** GHCR (`ghcr.io`) with `packages: write` permission
- **Tags:** `:latest` and `:1.0.${{ github.run_number }}`
- **Trigger:** Push to `main` on `image/**` or `.github/workflows/**`; also `workflow_dispatch:`

---

## 22. Filesystem Paths Referenced in Scripts

| Path | Purpose | Referenced In |
|---|---|---|
| `$HOME/.arinanox/` | Root directory for all local scripts/configs | All scripts |
| `$HOME/.arinanox/scripts/` | Downloaded support scripts | `scripts/arinanox` |
| `$HOME/.arinanox/launchers/` | Downloaded launcher sources | `launcher-gen.sh` |
| `$HOME/.arinanox/bin/arinanox` | CLI dispatcher | `bootstrap.sh` |
| `$HOME/.arinanox/tools/` | In-image tools directory | `bashrc` (source tapi-utils) |
| `$HOME/.arinanox/user-manifest.yaml` | User manifest | `manifest-*.sh`, CLI |
| `$HOME/.arinanox/snapshots/` | Hardlink snapshot storage | `user-snapshot.sh` |
| `$HOME/.arinanox/snapshot-current` | Symlink to latest snapshot | `user-snapshot.sh` |
| `$HOME/.arinanox/backups/` | Manual backup storage | `proot-backup.sh` |
| `$HOME/.arinanox/layers.txt` | Patch tracking | `patch.sh`, `status.sh` |
| `$HOME/.shortcuts/` | Termux:Widget launcher directory | `launcher-gen.sh` |
| `~/start.sh` | Symlink → `~/.shortcuts/1-start-arinanox.sh` | `launcher-gen.sh`, CLI |
| `~/stop.sh` | Symlink → `~/.shortcuts/0-stop-arinanox.sh` | `launcher-gen.sh`, CLI |
| `~/run-api-bridge.sh` | API bridge daemon | `api-bridge-setup.sh`, `start.sh` |
| `/data/data/com.termux/files/usr/tmp/` | Termux temp dir (TMPDIR default) | `start.sh`, `stop.sh`, etc. |
| `/data/data/com.termux/files/usr/opt/angle-android/` | ANGLE/EGL library path | `start.sh` (virgl auto-detect) |
| `/data/data/com.termux/files/usr/var/lib/proot-distro/containers/` | proot-distro container base | `proot-setup.sh`, `proot-rollback.sh`, etc. |
| `/data/data/com.termux/files/usr/etc/motd` | Termux MOTD | `motd-setup.sh` |
| `/sdcard/arinanox-backup/` | Backup on Android shared storage | CLI `backup`/`restore` |
| `/usr/local/bin/tapi` | TAPI client (inside proot) | `api-bridge-setup.sh` |
| `/home/admin/.pi/agent/models.json` | DeepSeek config (inside proot) | Dockerfile Layer 5 |
| `/home/admin/.pi/agent/mcp.json` | MCP config (inside proot) | Dockerfile Layer 5 |
| `/usr/local/bin/arinanox-ai-setup` | AI setup script symlink | Dockerfile Layer 5 |
| `/usr/bin/pm-is-supported` | Dummy wrapper (suppress suspend) | Dockerfile Layer 4 |

---

## 23. Known Unknowns

- **`scripts/setup-ai-stack.sh` shebang:** Uses `#!/usr/bin/env bash` (proot shebang). With `PROOT_NO_SECCOMP=1`, `#!/usr/bin/env` shebangs are reported broken (docs/plan-ai-stack.md §2). This script is intended for in-proot execution; its shebang may fail if `PROOT_NO_SECCOMP=1` interferes with process spawning at the shebang level. The identical copy at `image/configs/ai-stack/setup-ai-stack.sh` is run during Docker build (not under proot), so it works fine there.
- **`scripts/install-tui-packages.sh`:** References `$DISTRO="ubuntu"` and old proot-distro paths (`installed-rootfs/ubuntu`). This script is in `archive/` and not part of the active bootstrap chain. Its current state is unknown — it may or may not work.
- **`docs/plan-ai-stack.md` mentions ⏳ items:**
  - `pi-permission-system` (extension TS): not yet installed.
  - `pi-gateway` (`@gamalan/pi-gateway`): not yet installed; "Clone timeout, perlu test ulang" — integration status unknown.
  - `headroom` as lean-ctx addon: mentioned as optional, not yet integrated. The `package.json` at repo root has `"headroom-ai": "^0.22.4"` in dependencies, suggesting some attempt was made.
- **`image/configs/bashrc` vs `image/configs-target/home/admin/.bashrc`:** The source `bashrc` lacks the Termux PATH guard (`grep -v "/data/data/com.termux"` at end). The Dockerfile contains a `sed` command that migrates old path references in `.bashrc`. The `configs-target` version has all references already updated. This suggests the `configs/` source files may be stale.
- **`scripts/status.sh` is not dispatched by the CLI:** The CLI `arinanox status` dispatches to `doctor.sh`, not `status.sh`. The `status.sh` script exists separately but is not wired into the CLI. It appears to be an alternate, lighter status viewer that the user must invoke directly.
- **Firefox user.js deployment:** In Dockerfile Layer 5, the Firefox profile generation (`MOZ_HEADLESS=1 firefox --headless --first-startup`) runs for 8 seconds. If the profile directory is not created in time, `user.js` deployment is skipped with the message "Firefox profile not created — user.js will be deployed on first run". The success of in-image deployment is race-condition-dependent.
- **`patch.sh` Docker install:** The command `curl -fsSL https://get.docker.com | sh` runs inside proot. Docker daemon requires kernel features (cgroups, namespaces) that proot does not provide. This is documented in README.md limitations: "Cannot do: Docker containers (daemon needs kernel features proot doesn't have)." The installed Docker client would work (connecting to remote daemons), but the daemon cannot run.
- **`patch.sh` Ollama install:** `curl -fsSL https://ollama.com/install.sh | sh` inside proot. Ollama requires systemd or at least a running service manager. In proot without systemd, the install script may fail or install in a degraded state. README.md lists Ollama under patch.sh extras; no proot-specific workaround is documented.
- **`scripts/doctor.sh`:** References `$HOME/.arinanox/scripts/proot-rollback.sh` for rollback availability check. After a fresh bootstrap, this file exists. But doctor.sh is also called from `start.sh` as a pre-flight check — if `seccomp-check.sh` reports critical, doctor.sh exits with non-zero (setting `FAILS > 0`), but `start.sh` continues anyway (non-fatal, catches `|| true` or `2>/dev/null`). Edge case: if `doctor.sh` fails hard (e.g., missing dependencies) before reaching the seccomp check, the `|| true` in `start.sh` still proceeds.
- **`proot-distro install` with GHCR image:** The command `proot-distro install "$IMAGE" --name "$CONTAINER"` where `IMAGE="ghcr.io/arinadi/arinanox:latest"`. Standard `proot-distro` typically expects a distribution name (e.g., `ubuntu`, `debian`). The arinanoX project has presumably built a custom `proot-distro` plugin or the `--name` flag supports OCI image references directly. This is a known-unknown: the exact mechanism by which `proot-distro install` accepts a full OCI image URL is not documented in the arinanoX codebase.
- **`run-api-bridge.sh` eval security:** The bridge uses `eval "$CMD" 2>&1` to execute received commands. The `head -n 1` sanitizer limits multi-line payloads, but any single-line command received on port 8888 is executed as shell code. If the bridge is accessible from outside localhost, this is a remote code execution vulnerability. The TCP listener binds to `0.0.0.0` by default (netcat behavior on some systems), but the bridge is started with `&>/dev/null &` and runs on localhost.
- **`package.json` dependency `headroom-ai: ^0.22.4`:** This dependency exists at the repo root but is not referenced in any script or the Dockerfile. It appears to be an artifact — possibly intended for lean-ctx integration (as mentioned in docs/plan-ai-stack.md). Whether this is actively used is unknown.
- **`bootstrap.sh` `--retry 2` behavior:** `curl -sL --retry 2` retries on transient errors. If the download consistently fails (e.g., network unreachable, GitHub outage), the script exits with curl's error code. `bootstrap.sh` has `set -euo pipefail`, so any download failure aborts the entire install.
- **`launchers/start.sh` `busybox expr` usage:** The timing calculation uses `busybox expr`. This assumes `busybox` is in PATH in Termux. If not, the `expr` call would fail (but the `echo` logic is wrapped in a subshell with `|| true` equivalent through conditionals).

---

## 24. External Dependencies

### 24.1 Android/Termux Host Dependencies

- **Termux** (F-Droid, NOT Play Store) — the Android terminal emulator
- **Termux:X11** (`com.termux.x11`, nightly APK) — display server app
- **Termux:API** (`com.termux.api`, F-Droid) — Android API access (optional)
- **Termux:Widget** (`com.termux.widget`, F-Droid) — home screen shortcuts (recommended)
- `termux-x11-nightly` — X11 server package
- `proot-distro` — container management
- `pulseaudio` — audio server
- `xorg-xrandr` — display config
- `netcat-openbsd` — API bridge
- `termux-api` — Android API utilities
- `virglrenderer` — GPU acceleration (ANGLE path)
- `virglrenderer-android` — GPU acceleration (native path)
- `angle-android` — ANGLE EGL library
- `rsync` — snapshots and backups
- `python3` — manifest parsing

### 24.2 Container (Proot) Internal Dependencies

- **Debian 13 (Trixie)** — base OS
- **Node.js 22** — from NodeSource, runtime for Pi/playwright/ddg_search
- **Firefox ESR** — from Debian stable repos
- **Pi** (`@earendil-works/pi-coding-agent`) — coding agent
- **lean-ctx v3.9.8** — context compression (musl ARM64 binary)
- **ddg_search** (`@oevortex/ddg_search`) — web search
- **playwright-cli** (`@playwright/cli`) — browser automation
- **Playwright Firefox** — browser for playwright (~97MB download)
- **DeepSeek API** — external LLM provider (`https://api.deepseek.com`)
- **X11 socket** (`${TMPDIR}/.X11-unix/X0`) — shared via `--shared-tmp`

### 24.3 CI/CD Dependencies

- **GitHub Actions** — CI platform
- **QEMU** (`docker/setup-qemu-action@v3`) — ARM64 cross-build
- **Docker Buildx** (`docker/setup-buildx-action@v3`) — multi-arch builds
- **GHCR** (`ghcr.io`) — container registry
- **docker/login-action@v3** — GHCR authentication
- **docker/build-push-action@v5** — build and push

---

## 25. Complete Lifecycle Flow Summary

```
                      bootstrap.sh (curl | bash)
                           │
                    ┌──────┴──────┐
                    │              │
              install/reinstall   uninstall (curl .../uninstall.sh | bash)
                    │
                    ▼
     ┌─────────────────────────────┐
     │ host-setup.sh               │  Termux packages
     │ proot-setup.sh              │  Atomic: arinanox-prev + fresh image
     │ api-bridge-setup.sh         │  tapi client inside proot
     │ launcher-gen.sh             │  ~/.shortcuts/ + ~/symlinks
     │ motd-setup.sh               │  MOTD
     └─────────────┬───────────────┘
                   │
                   ▼
          FIRST RUN: arinanox start
           │
           ├── doctor.sh (health check)
           ├── PulseAudio (port 4713) + API bridge (8888/8889) + virgl + X11
           ├── Wait for X11 socket
           └── proot-distro login → XFCE session
                   │
          ┌────────┴────────┐
          │                  │
     arinanox stop      arinanox snapshot create
          │                  │
     (clean shutdown)   manifest-generate.sh
                        rsync --link-dest snapshot
                        retain 3
          │                  │
          ▼                  ▼
     arinanox update     arinanox snapshot list|restore
          │
     1. curl bootstrap.sh | bash
        a. proot-setup.sh: mv arinanox → arinanox-prev
        b. Install fresh image
        c. Re-run setup chain
     2. manifest-apply.sh (if manifest exists)
          │
          ▼
     arinanox rollback  (if update breaks)
     1. proot-distro remove arinanox
     2. mv arinanox-prev → arinanox
     3. bash ~/start.sh (back to working state)
          │
          ▼
     uninstall.sh  (complete teardown)
     1. Stop all services
     2. Remove containers (arinanox + arinanox-prev)
     3. Remove shortcuts, symlinks, cache
     4. Preserve: git repo, storage, .bashrc
```

---

*End of audit document. Every file in the commit graph has been read and cataloged.*
