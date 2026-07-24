# arinanoX — Codebase Blueprint & Audit

> Generated from the working tree at `/data/data/com.termux/files/home/arinanoX`.
> GitHub: [`arinadi/arinanoX`](https://github.com/arinadi/arinanoX).
> Cross-references: `docs/audit-update-flow.md`, `docs/plan-ai-stack.md`.

---

## Table of Contents

1. [Directory Tree](#1-directory-tree)
2. [Architecture Overview](#2-architecture-overview)
3. [Module Boundaries & Inter-Script Relationships](#3-module-boundaries--inter-script-relationships)
   - [Root-Level Entry Points](#31-root-level-entry-points)
   - [scripts/ Directory](#32-scripts-directory)
   - [launchers/ Directory](#33-launchers-directory)
   - [image/ Directory](#34-image-directory)
   - [docs/ Directory](#35-docs-directory)
   - [archive/ Directory](#36-archive-directory)
4. [Exported Interfaces](#4-exported-interfaces)
   - [CLI Dispatch (scripts/arinanox)](#41-cli-dispatch-scriptsarinanox)
   - [Sourced Utility Functions (tapi-utils.sh)](#42-sourced-utility-functions-tapi-utilssh)
   - [Image-Built Tools (inside proot)](#43-image-built-tools-inside-proot)
5. [Internal Dependencies Between Modules](#5-internal-dependencies-between-modules)
6. [Runtime Behavior](#6-runtime-behavior)
   - [Startup Sequence (start.sh)](#61-startup-sequence-startsh)
   - [Stop Sequence (stop.sh)](#62-stop-sequence-stopsh)
   - [Update Flow (bootstrap.sh → proot-setup.sh)](#63-update-flow-bootstrapsh--proot-setupsh)
   - [Rollback Flow (proot-rollback.sh)](#64-rollback-flow-proot-rollbacksh)
   - [CLI Dispatch Chain (scripts/arinanox)](#65-cli-dispatch-chain-scriptsarinanox)
7. [Notable Architectural Patterns](#7-notable-architectural-patterns)
   - [Silverblue-Style Atomic Update/Rollback](#71-silverblue-style-atomic-updaterollback)
   - [Two-Layer Core/User Architecture](#72-two-layer-coreuser-architecture)
   - [Proot Bind-Mount Constraints](#73-proot-bind-mount-constraints)
   - [GPU Auto-Detection Tiers](#74-gpu-auto-detection-tiers)
   - [PROOT_NO_SECCOMP Side Effects](#75-proot_noseccomp-side-effects)
   - [Declarative User Manifest](#76-declarative-user-manifest)
   - [Hardlinked Snapshots](#77-hardlinked-snapshots)
   - [Termux:API Bridge Mechanics](#78-termuxapi-bridge-mechanics)
8. [Design Document Cross-References](#8-design-document-cross-references)
   - [docs/audit-update-flow.md Findings](#81-docsaudit-update-flowmd-findings)
   - [docs/plan-ai-stack.md Findings](#82-docsplan-ai-stackmd-findings)

---

## 1. Directory Tree

```
arinanoX/
├── .github/
│   └── workflows/
│       └── build-image.yml          # CI: builds + pushes Docker image to GHCR
├── archive/
│   ├── apply-xfce-config.sh         # Legacy XFCE config applicator
│   ├── install-tui-packages.sh      # Legacy TUI package installer
│   ├── launch-pi-vnc.sh             # Legacy VNC launcher for Pi bridge
│   ├── run-api-bridge.sh            # Legacy API bridge runner (in archive)
│   ├── setup-proot-xfce.sh          # Legacy proot XFCE setup
│   └── setup-termux-native.sh       # Legacy native Termux desktop setup
├── configs/
│   └── user.js                      # Firefox user.js (proot-optimized, 126 lines)
├── docs/
│   ├── README-termux.md             # Docs for native Termux setup (separate project)
│   ├── ai-stack-usage.md            # Usage reference for Pi, lean-ctx, ddg_search, playwright
│   ├── arinanox-screenshot.jpg      # Desktop screenshot
│   ├── audit-update-flow.md         # Audit of update/backup/restore flow with recommendations
│   ├── debug-xfce-render.md         # Debugging guide for blank XFCE desktop
│   ├── docs-proot-tapi.md           # Proot Termux:API bridge documentation
│   ├── docs-termux-api.md           # Termux:API command reference
│   └── firefox-userjs-proot.md     # Firefox user.js cheatsheet for proot
├── image/
│   ├── .dockerignore
│   ├── Dockerfile                   # 🎯 System definition — the image
│   ├── configs/                     # Source configs (ai-stack, bashrc, autostart, etc.)
│   │   ├── ai-stack/
│   │   │   ├── plan-ai-stack.md     # AI stack architecture plan
│   │   │   ├── setup-ai-stack.sh    # AI stack installer (duplicate of scripts/setup-ai-stack.sh)
│   │   │   └── user.js              # Firefox user.js source for image build
│   │   ├── autostart/
│   │   │   └── clipboard-sync.desktop
│   │   ├── bashrc                   # Source .bashrc for admin user
│   │   ├── client.conf              # PulseAudio client config
│   │   ├── clipboard-sync.sh        # Source clipboard sync script
│   │   ├── genmon-battery.sh        # XFCE genmon battery monitor
│   │   ├── genmon-volume.sh         # XFCE genmon volume controller
│   │   ├── gtk.css                  # GTK overrides
│   │   ├── tapi-utils.sh            # Source TAPI utility functions
│   │   ├── thunar.xml               # Thunar file manager config
│   │   └── xfwm4.xml                # XFWM4 window manager config
│   └── configs-target/              # Deployed to /home/admin/ in image
│       └── home/admin/
│           ├── .bashrc              # Entry-point shell config (with PATH hardening)
│           ├── .config/
│           │   ├── autostart/
│           │   │   └── clipboard-sync.desktop
│           │   └── gtk-3.0/
│           │       └── gtk.css
│           │   └── xfce4/xfconf/xfce-perchannel-xml/
│           │       ├── thunar.xml
│           │       ├── xfce4-desktop.xml
│           │       ├── xfce4-keyboard-shortcuts.xml
│           │       ├── xfce4-panel.xml
│           │       ├── xfwm4.xml
│           │       └── xsettings.xml
│           ├── .local/share/applications/
│           │   └── arinanox-store.desktop
│           └── .pulse/
│               └── client.conf
│           └── .arinanox/tools/
│               ├── apt-store.sh          # GUI package manager (yad-based)
│               ├── clipboard-sync.sh     # Background clipboard sync daemon
│               ├── genmon-battery.sh     # Battery genmon panel plugin
│               ├── genmon-volume.sh      # Volume genmon panel plugin
│               └── tapi-utils.sh         # Sourced shell functions: battery, clipget, etc.
├── launchers/
│   ├── .v1-backup/                 # Legacy v1 launcher scripts
│   │   ├── kill-all.sh
│   │   ├── kill-proot.sh
│   │   ├── kill-x11.sh
│   │   ├── start-x11.sh
│   │   └── start-xfce.sh
│   ├── kill-all.sh                 # Stop everything (X11 + proot + wake lock)
│   ├── kill-proot.sh               # Stop XFCE + proot sessions only
│   ├── kill-x11.sh                 # Stop X11 + PulseAudio + API bridge only
│   ├── start-x11.sh                # Start PulseAudio + X11 + API bridge only
│   ├── start-xfce.sh               # Start XFCE session inside proot only
│   ├── start.sh                    # 🚀 Full unified start (health → services → desktop)
│   ├── stop.sh                     # 🛑 Unified stop (XFCE → proot → virgl → X11 → PulseAudio)
│   └── update.sh                   # Update: curl bootstrap.sh | bash
├── scripts/
│   ├── api-bridge-setup.sh         # Install Termux:API bridge (tapi client inside proot)
│   ├── arinanox                    # 🎯 Unified CLI dispatch (the arinanox command)
│   ├── doctor.sh                   # Full health-check (packages, container, GPU, runtime)
│   ├── host-setup.sh               # Install Termux host packages (termux-x11, proot-distro, etc.)
│   ├── launcher-gen.sh             # Install branded ~/.shortcuts/ launchers + home symlinks
│   ├── manifest-apply.sh           # Apply user-manifest.yaml (packages, configs, dotfiles)
│   ├── manifest-generate.sh        # Generate user-manifest.yaml from current user state
│   ├── motd-setup.sh               # Set Termux MOTD
│   ├── patch.sh                    # Optional software installer (chromium, code, ollama, etc.)
│   ├── proot-backup.sh             # Manual backup: home dir + package list (tar)
│   ├── proot-restore.sh            # Manual restore: home dir + package list (tar)
│   ├── proot-rollback.sh           # 🔄 Silverblue rollback: rename arinanox-prev → arinanox
│   ├── proot-setup.sh              # 🔄 Silverblue update: keep arinanox-prev, pull new image
│   ├── seccomp-check.sh            # Detect Android 15+ seccomp-bpf blocking proot
│   ├── seccomp-fix.sh              # Apply PROOT_NO_SECCOMP=1 mitigation
│   ├── setup-ai-stack.sh           # Install AI coding stack (Pi, lean-ctx, ddg_search, playwright)
│   ├── status.sh                   # Silverblue-style system status overview
│   ├── theme-dark.sh               # Apply Orchis Dark XFCE theme
│   ├── user-snapshot.sh            # Hardlink-based snapshot create/list/restore (3 retained)
│   └── xfce-config.sh              # Declares theme is pre-configured in image (no-op)
├── bootstrap.sh                    # ⚡ One-command entry point: download scripts + run setup chain
├── uninstall.sh                    # Complete teardown: container, launchers, cache
├── configs/user.js                 # Firefox user.js (at repo root, also at configs/)
├── package.json                    # NPM dependency: "headroom-ai": "^0.22.4"
├── package-lock.json               # Lockfile for headroom-ai
├── README.md                       # Project README (main documentation)
└── .gitignore                      # Ignores node_modules/
```

---

## 2. Architecture Overview

arinanoX is a **Termux-hosted proot-distro** environment that boots a Debian 13 (Trixie) XFCE4 desktop on Android ARM64 phones. The architecture follows a **NixOS / Silverblue-inspired two-layer model**:

```
┌───────────────────────────────────────────┐
│  USER LAYER (mutable)                     │
│  → ~/.arinanox/user-manifest.yaml         │
│  → ~/.arinanox/snapshots/                 │
│  → ~/.arinanox/backups/                   │
│  → /home/admin/ (inside proot)            │
│  Preserved across updates via manifest    │
├───────────────────────────────────────────┤
│  CORE LAYER (declarative & reproducible)  │
│  → ghcr.io/arinadi/arinanox:latest        │
│  → Built from image/Dockerfile in CI      │
│  → /data/data/.../containers/arinanox/    │
│  Atomic swap on update                    │
├───────────────────────────────────────────┤
│  HOST LAYER (Termux)                      │
│  → bootstrap.sh, launchers/*.sh           │
│  → ~/.arinanox/scripts/                   │
│  → ~/.shortcuts/                          │
│  Orchestrates proot from outside          │
└───────────────────────────────────────────┘
```

All orchestration scripts execute as **Termux host scripts** (shebang `#!/data/data/com.termux/files/usr/bin/bash`). The proot container is managed through `proot-distro`. The **~350MB+ prebuilt image** is pulled from GHCR, extracted, and run — no apt-get in the install path, no compiling.

---

## 3. Module Boundaries & Inter-Script Relationships

### 3.1 Root-Level Entry Points

#### `bootstrap.sh`
- **Purpose:** One-command entry point (`curl ... | bash`). Downloads all scripts from GitHub RAW, places them into `~/.arinanox/`, then runs the setup chain.
- **Exports:** Nothing (sourced by nobody). Invoked directly or piped from curl.
- **Call relationships:**
  - Calls `host-setup.sh` — install Termux host packages
  - Calls `proot-setup.sh` — deploy/update the proot container (Silverblue atomic swap)
  - Calls `api-bridge-setup.sh` — install Termux:API TCP bridge
  - Calls `launcher-gen.sh` — install `~/.shortcuts/` launchers
  - Calls `motd-setup.sh` — set Termux MOTD
  - Downloads `uninstall.sh` to `~/.arinanox/` on request (menu selection)
- **Invoked by:** User via curl pipe, or by `update.sh` (launchers/update.sh), or by the `update` subcommand in `scripts/arinanox`.

#### `uninstall.sh`
- **Purpose:** Complete teardown. Stops running sessions, removes proot container (`arinanox` + `arinanox-prev`), deletes `~/.shortcuts/`, `~/start.sh`/`~/stop.sh` symlinks, `~/.arinanox/` cache, and cleans Termux tmp.
- **Exports:** Nothing.
- **Invoked by:** `bootstrap.sh` (when user selects "uninstall" from interactive menu), or directly by user.

#### `package.json`
- **Purpose:** Declares a single npm dependency: `"headroom-ai": "^0.22.4"`. The AI stack (Pi, ddg_search, playwright-cli) is installed natively inside the proot container via the Dockerfile, **not** tracked in this `package.json`.

#### `configs/user.js`
- **Purpose:** Firefox user.js (126 lines) optimized for proot. Disables HW acceleration, disk cache, animations, telemetry. Sets sandbox level 0, content process count 2, software WebRender. Source copy of what gets deployed to `~/.mozilla/firefox/*.default-esr/user.js` during image build or by `setup-ai-stack.sh`.

---

### 3.2 scripts/ Directory

#### `scripts/arinanox`
- **Purpose:** Unified CLI dispatcher. The `arinanox` command installed at `~/.arinanox/bin/arinanox`.
- **Exports:** Nothing (standalone CLI entry point).
- **Dispatch table:**
  | Command | Dispatches To |
  |---|---|
  | `start` | `exec bash "$HOME/start.sh"` |
  | `stop` | `exec bash "$HOME/stop.sh"` |
  | `status` | `exec bash "$SCRIPTS_DIR/doctor.sh"` |
  | `doctor` | `exec bash "$SCRIPTS_DIR/doctor.sh"` |
  | `update` | Inline: `curl bootstrap.sh \| bash`, then calls `manifest-apply.sh` if manifest exists |
  | `rollback` | `exec bash "$SCRIPTS_DIR/proot-rollback.sh"` |
  | `store` | `exec bash "$ARINANOX_DIR/tools/apt-store.sh"` (inside proot) |
  | `install` | Inline: reads `user-manifest.yaml`, installs packages via `proot-distro login` |
  | `backup` | Inline: `rsync` from container rootfs to `/sdcard/arinanox-backup` |
  | `restore` | Inline: `rsync` from `/sdcard` to container rootfs |
  | `snapshot` | `exec bash "$SCRIPTS_DIR/user-snapshot.sh" "$@"` |
  | `help` | Prints usage |
- **First-run bootstrap:** If `~/.arinanox/scripts` doesn't exist, it auto-runs `curl bootstrap.sh | bash` before dispatching.
- **Invoked by:** User from PATH (`~/.arinanox/bin/`).

#### `scripts/host-setup.sh`
- **Purpose:** Installs required Termux host packages: `termux-x11-nightly`, `proot-distro`, `pulseaudio`, `xorg-xrandr`, `netcat-openbsd`, `termux-api`, `virglrenderer`, `virglrenderer-android`, `angle-android`, `rsync`, `python3`. Also runs `termux-setup-storage` if `~/storage` doesn't exist.
- **Exports:** Nothing.
- **Invoked by:** `bootstrap.sh` (part of setup chain).

#### `scripts/proot-setup.sh`
- **Purpose:** Silverblue-style atomic update. Pulls `ghcr.io/arinadi/arinanox:latest`, renames any existing `arinanox` container to `arinanox-prev` (atomic backup), then installs the new image.
- **Exports:** Nothing.
- **Invoked by:** `bootstrap.sh` (setup chain), or implicitly via `curl bootstrap.sh | bash` from the `update` CLI command.
- **Related:** `scripts/proot-rollback.sh` reverses the rename.

#### `scripts/proot-rollback.sh`
- **Purpose:** Reverses `proot-setup.sh`. Removes current `arinanox` container, renames `arinanox-prev` back to `arinanox`.
- **Exports:** Nothing.
- **Invoked by:** CLI `arinanox rollback`, or directly by user.

#### `scripts/doctor.sh`
- **Purpose:** Full health-check: Android SDK version, seccomp status, Termux host packages installed, proot container existence and size, core binaries inside container (`firefox-esr`, `xfce4-session`), GPU virgl availability, storage, PulseAudio port 4713, Termux:X11 process, XFCE session, rollback script presence.
- **Exports:** Nothing (standalone diagnostic).
- **Invoked by:** CLI `arinanox doctor` or `arinanox status`, and by `launchers/start.sh` (as a pre-flight check).
- **Calls:** `scripts/seccomp-check.sh` internally.

#### `scripts/seccomp-check.sh`
- **Purpose:** Detects Android 15+ (SDK >= 34) seccomp-bpf filtering that blocks proot. Probes by running `proot-distro login arinanox -- bash -c 'echo ok'`. Returns exit code 1 if critical.
- **Exports:** Nothing (called by `doctor.sh` and directly by user).
- **Invoked by:** `scripts/doctor.sh`, or directly by user.

#### `scripts/seccomp-fix.sh`
- **Purpose:** Applies `PROOT_NO_SECCOMP=1` mitigation: patches `~/.shortcuts/1-start-arinanox.sh`, the source `~/.arinanox/launchers/start.sh`, and `~/.bashrc`.
- **Exports:** Nothing.

#### `scripts/api-bridge-setup.sh`
- **Purpose:** Copies the host-side `run-api-bridge.sh` to `~/`, then creates the `tapi` client script inside the proot container at `/usr/local/bin/tapi` (a netcat wrapper).
- **Exports:** Nothing.
- **Invoked by:** `bootstrap.sh` (setup chain).

#### `scripts/launcher-gen.sh`
- **Purpose:** Installs branded `~/.shortcuts/` launchers: `0-stop-arinanox.sh` and `1-start-arinanox.sh`. Creates home convenience symlinks: `~/start.sh` → `~/.shortcuts/1-start-arinanox.sh`, `~/stop.sh` → `~/.shortcuts/0-stop-arinanox.sh`.
- **Exports:** Nothing.
- **Invoked by:** `bootstrap.sh` (setup chain).

#### `scripts/motd-setup.sh`
- **Purpose:** Writes MOTD to `/data/data/com.termux/files/usr/etc/motd`.
- **Exports:** Nothing.
- **Invoked by:** `bootstrap.sh` (setup chain).

#### `scripts/patch.sh`
- **Purpose:** Interactive or CLI-driven installer for optional software (patches). Supports `--chromium`, `--code`, `--geany`, `--neovim`, `--ollama`, `--zsh`, `--nala`, `--docker`, `--ripgrep`, `--viewnior`, `--xarchiver`, `--galculator`, `--github`, `--all`, `--list`. Each patch runs a shell command inside the proot container. Tracks layered packages in `~/.arinanox/layers.txt`.
- **Exports:** Nothing.
- **Invoked by:** User directly or from scripts.

#### `scripts/user-snapshot.sh`
- **Purpose:** Hardlinked snapshot tool for `/home/admin` inside the proot container. Subcommands: `create` (generates manifest first, then `rsync --link-dest`), `list`, `restore <id>`. Retains maximum 3 snapshots. Maintains `~/.arinanox/snapshot-current` symlink.
- **Exports:** Nothing.
- **Invoked by:** CLI `arinanox snapshot` dispatch.
- **Calls:** `scripts/manifest-generate.sh` on `create`.

#### `scripts/manifest-generate.sh`
- **Purpose:** Scans user state inside proot: compares `apt-mark showmanual` against a hardcoded base-package list to detect user-installed packages; detects custom dotfiles; writes `~/.arinanox/user-manifest.yaml`.
- **Exports:** Nothing.
- **Invoked by:** `scripts/user-snapshot.sh` (on `create`), or directly by user.

#### `scripts/manifest-apply.sh`
- **Purpose:** Reads `~/.arinanox/user-manifest.yaml` and applies it: installs user packages, restores XFCE configs from snapshot, restores dotfiles from `/sdcard/arinanox-backup`.
- **Exports:** Nothing.
- **Invoked by:** CLI `arinanox update` (auto-applied after bootstrap), or directly by user.

#### `scripts/proot-backup.sh`
- **Purpose:** Manual backup of user layer (home directory as tar + dpkg package list). Saves to `~/.arinanox/backups/`. Maintains `home-latest.tar.gz` and `packages-latest.txt` symlinks.
- **Exports:** Nothing.
- **Status:** Designated as "manual tool" per `docs/audit-update-flow.md` recommendations.

#### `scripts/proot-restore.sh`
- **Purpose:** Manual restore of user layer onto a fresh image. Extracts home directory tar, reinstalls packages via `apt-get install`, re-creates storage symlinks.
- **Exports:** Nothing.
- **Status:** Designated as "manual tool" per `docs/audit-update-flow.md` recommendations.

#### `scripts/setup-ai-stack.sh`
- **Purpose:** Installs the AI vibe-coding stack inside the proot container (or as a standalone script). Installs: Pi coding agent (`@earendil-works/pi-coding-agent`), lean-ctx (musl ARM64 binary from GitHub releases), ddg_search (`@oevortex/ddg_search`), playwright-cli (`@playwright/cli`) + Firefox browser, DeepSeek `models.json`, MCP config for ddg_search, Firefox user.js.
- **Exports:** Nothing (standalone installer).
- **Invoked by:** User inside proot, or pre-baked in Dockerfile Layer 5.
- **Note:** An identical copy lives at `image/configs/ai-stack/setup-ai-stack.sh` for the Dockerfile build. Both are functionally identical.

#### `scripts/status.sh`
- **Purpose:** Silverblue-style system status overview. Shows current container size, rollback container size, XFCE/X11 running status, layered packages count, backup count/size.
- **Exports:** Nothing.
- **Invoked by:** CLI `arinanox status` (which actually dispatches to `doctor.sh`; `status.sh` is a separate lighter alternative).

#### `scripts/theme-dark.sh`
- **Purpose:** Applies Orchis Dark XFCE theme with mobile-optimized settings. Writes `xsettings.xml`, `xfwm4.xml`, `xfce4-panel.xml`, `xfce4-desktop.xml` to `~/.config/xfce4/xfconf/xfce-perchannel-xml/`.
- **Exports:** Nothing.

#### `scripts/xfce-config.sh`
- **Purpose:** No-op. Declares that the XFCE theme is pre-configured in the image layer. Prints a message listing shipped config files.
- **Exports:** Nothing.

---

### 3.3 launchers/ Directory

#### `launchers/start.sh`
- **Purpose:** 🚀 **Unified desktop startup.** Executes a 3-step sequence: (1) runs `doctor.sh` health-check, (2) starts PulseAudio, API bridge, virgl (auto-detected), Termux:X11, and WakeLock in parallel, (3) waits for X11 socket, then launches XFCE inside proot.
- **Exports:** Nothing (standalone launcher).
- **Invoked by:** CLI `arinanox start`, `~/.shortcuts/1-start-arinanox.sh`, `~/start.sh` symlink.
- **Calls:** `scripts/doctor.sh` (pre-flight), `run-api-bridge.sh`, `proot-distro login arinanox` with XFCE session.
- **GPU modes:** Three-tier auto-detection for virgl (see §7.4).

#### `launchers/stop.sh`
- **Purpose:** 🛑 **Unified desktop stop.** Graceful shutdown chain: XFCE → proot → virgl → X11 → PulseAudio → API bridge → WakeLock. Performs aggressive cleanup of temp files, XFCE sessions, ICEauthority, `.Xauthority`, and stale sockets both inside proot and from host side.
- **Exports:** Nothing.
- **Invoked by:** CLI `arinanox stop`, `~/.shortcuts/0-stop-arinanox.sh`, `~/stop.sh` symlink.

#### `launchers/kill-all.sh`
- **Purpose:** Calls `kill-proot.sh` + `kill-x11.sh` + `termux-wake-unlock`.
- **Invoked by:** User directly.

#### `launchers/kill-proot.sh`
- **Purpose:** Kills XFCE processes (leaf apps first, session manager last), dbus-daemon, proot-distro login, orphan proot processes. Does double-layer cleanup: `rm -rf` inside proot + host-side `rm -rf` on rootfs temp files and session cache.
- **Invoked by:** `launchers/kill-all.sh` or directly.

#### `launchers/kill-x11.sh`
- **Purpose:** Kills termux-x11, PulseAudio, API bridge, releases WakeLock, cleans `$TMPDIR` stale files (`.X0-lock`, `.X11-unix`, `pulse-socket`).
- **Invoked by:** `launchers/kill-all.sh` or directly.

#### `launchers/start-x11.sh`
- **Purpose:** Starts PulseAudio + AAudio/SLES sink + TCP module, API bridge, Termux:X11, then auto-opens the Termux:X11 Android app. Does **not** start XFCE (separate step via `start-xfce.sh`).
- **Exports:** Nothing.

#### `launchers/start-xfce.sh`
- **Purpose:** Starts XFCE session inside proot with CPU-only GPU mode (`LIBGL_ALWAYS_SOFTWARE=1`). A simpler version of the desktop launch without the auto-detect GPU logic.
- **Exports:** Nothing.

#### `launchers/update.sh`
- **Purpose:** One-liner: `curl -sL --retry 2 "${REPO}/bootstrap.sh" | bash`.
- **Exports:** Nothing.
- **Invoked by:** User directly.

---

### 3.4 image/ Directory

#### `image/Dockerfile`
- **Purpose:** Declarative system definition for the prebuilt container image. Five layers:
  - **Layer 1:** Base + core packages (dialog, ca-certificates, sudo, curl, wget, zip, unzip, jq, tree)
  - **Layer 2:** XFCE + GUI + Firefox ESR + themes (Orchis GTK, elementary-xfce icons, whiskermenu, genmon panel plugins, pulseaudio-utils, yad, mesa-utils)
  - **Layer 3:** Dev tools (Node.js 22 from NodeSource, Python 3 with pip/venv, GCC, make, CMake, git, htop, tmux, openssh-client)
  - **Layer 4:** Configs + admin user (copies `configs-target/` to `/home/admin/`, adds `admin` user with password-less sudo, purges `libupower-glib3`, creates dummy `pm-is-supported` to suppress suspend errors)
  - **Layer 5 (AI VibeCoding Stack):** Pre-installs Pi, lean-ctx (musl binary), ddg_search, playwright-cli, Playwright Firefox browser, DeepSeek `models.json`, MCP config for ddg_search, Firefox `user.js` for admin user
- **Built via:** CI (`build-image.yml`) on push to `main` when `image/**` or `.github/workflows/**` paths change. Pushes to `ghcr.io/arinadi/arinanox:latest` and versioned tags.

#### `image/configs-target/`
- **Purpose:** Files deployed to `/home/admin/` inside the image. The `.bashrc` at `configs-target/home/admin/.bashrc` is the **key entry point** for the proot user session — it hardens PATH (strips Termux bind-mount from PATH), sources `tapi-utils.sh`, sets XFCE environment variables (`DISPLAY=:0`, `XDG_RUNTIME_DIR=/tmp`, `GDK_SCALE=2`, etc.), and provides aliases.

#### `image/configs/`
- **Purpose:** Source configuration files that are referenced by the Dockerfile during build:
  - `ai-stack/setup-ai-stack.sh` — AI stack installer (duplicate of `scripts/setup-ai-stack.sh`)
  - `ai-stack/user.js` — Firefox user.js source
  - `ai-stack/plan-ai-stack.md` — AI stack architecture plan (copy of `docs/plan-ai-stack.md`)
  - `bashrc` — source `.bashrc` content
  - `client.conf` — PulseAudio client config
  - `clipboard-sync.sh` — source clipboard sync daemon
  - `genmon-battery.sh` / `genmon-volume.sh` — XFCE genmon panel plugins
  - `gtk.css` — GTK overrides
  - `tapi-utils.sh` — source TAPI utility functions
  - `thunar.xml` / `xfwm4.xml` — XFCE configs

#### `image/.dockerignore`
- **Purpose:** Prevents unnecessary files from entering the Docker build context.

---

### 3.5 docs/ Directory

#### `docs/audit-update-flow.md`
- **Purpose:** Audit of the update/backup/restore flow. Identifies risks in the original automatic backup/restore during updates (429 rate limits, dpkg base vs user package conflicts, stale XFCE sessions, silent failures). **Recommends** removing auto-backup/restore, replacing `update.sh` with a simple fresh install, keeping `proot-backup.sh` and `proot-restore.sh` as optional manual tools. This recommendation has been partially adopted — the current `update.sh` is a simple `curl bootstrap.sh | bash`, and `proot-setup.sh` has no auto-backup/restore (the Silverblue-style atomic rename obsoletes it).

#### `docs/plan-ai-stack.md`
- **Purpose:** Architecture plan and validation report for the AI coding stack (Pi, lean-ctx, ddg_search, playwright-cli) inside proot on ARM64. Documents the `PROOT_NO_SECCOMP=1` requirement (fixes `uv__io_poll`, `fork`, `futex` bugs), the invocation pattern for Node.js tools (must use `node /path/to/cli.js` because `#!/usr/bin/env node` shebang is broken), the bind-mount constraint (Termux binaries visible but unexecutable due to bionic vs glibc ABI mismatch), and MCP/DeepSeek configuration. Referenced extensively in §7.3 and §7.5.

#### `docs/ai-stack-usage.md`
- **Purpose:** Usage reference for Pi, lean-ctx, ddg_search, and playwright-cli. Documents invocation patterns (Node.js direct), lean-ctx health checks, ddg_search AI mode (IAsk backend, because DuckDuckGo is blocked in Indonesia), playwright-cli session-based automation, Pi agent startup, and a full test suite.

#### `docs/debug-xfce-render.md`
- **Purpose:** Debugging guide for blank XFCE desktop. Lists 8 research areas: Termux:X11 config, XFCE compositing (xfwm4 compositor in proot without GPU), dbus session, XFCE first-run config dependencies, proot bind-mounts and `--shared-tmp`, alternative WMs, Termux:X11 version issues, Android-side permissions.

#### `docs/docs-proot-tapi.md`
- **Purpose:** Technical documentation of the `tapi` bridge (Termux:API inside proot). Explains the TCP bridge architecture (host listener on port 8888, guest client on port 8889), usage examples, Python integration, and troubleshooting.

#### `docs/docs-termux-api.md`
- **Purpose:** Reference guide for Termux:API commands available through arinanoX (battery, notifications, clipboard, torch, brightness, volume, location, sensors, etc.). Includes practical examples.

#### `docs/firefox-userjs-proot.md`
- **Purpose:** Cheatsheet for Firefox `user.js` tuning in proot. Covers rendering (software WebRender), animation, memory (2 content processes), disk cache disabled, network (prefetch off), telemetry off, sandbox level 0, and troubleshooting.

#### `docs/README-termux.md`
- **Purpose:** A separate documentation track for the native Termux desktop setup (the "Termux-native" approach, not the proot approach). Documents an older installation method targeting multiple desktop environments (XFCE4/LXQt/MATE/KDE) with VNC and Pi bridge support. **Not** the primary arinanoX proot path.

---

### 3.6 archive/ Directory

Contains legacy scripts from earlier v1 versions of the project:
- `apply-xfce-config.sh` — Old XFCE config applier
- `install-tui-packages.sh` — Old TUI package installer
- `launch-pi-vnc.sh` — Old VNC launcher for Raspberry Pi monitor bridge
- `run-api-bridge.sh` — Legacy API bridge (identical to the live version)
- `setup-proot-xfce.sh` — Old proot XFCE setup
- `setup-termux-native.sh` — Old native Termux desktop setup (matches `docs/README-termux.md`)

These are preserved for reference but are **not part of the active code path**. The v1 launcher backups in `launchers/.v1-backup/` serve a similar archival purpose.

---

## 4. Exported Interfaces

### 4.1 CLI Dispatch (`scripts/arinanox`)

The `arinanox` command is the unified user-facing CLI. It is installed at `~/.arinanox/bin/arinanox` and added to `PATH` in `~/.bashrc` by `bootstrap.sh`. It dispatches to scripts in `~/.arinanox/scripts/` and `~/` launchers.

| Subcommand | Dispatch Target | Category |
|---|---|---|
| `start` | `~/start.sh` (→ `~/.shortcuts/1-start-arinanox.sh`) | Desktop |
| `stop` | `~/stop.sh` (→ `~/.shortcuts/0-stop-arinanox.sh`) | Desktop |
| `status` | `~/.arinanox/scripts/doctor.sh` | Status |
| `doctor` | `~/.arinanox/scripts/doctor.sh` | Status |
| `update` | Inline: `curl bootstrap.sh \| bash` + `manifest-apply.sh` | Core |
| `rollback` | `~/.arinanox/scripts/proot-rollback.sh` | Core |
| `store` | `~/.arinanox/tools/apt-store.sh` (inside proot) | Packages |
| `install` | Inline: reads `user-manifest.yaml` → proot-distro apt | Packages |
| `backup` | Inline: rsync to `/sdcard/arinanox-backup` | Data |
| `restore` | Inline: rsync from `/sdcard` | Data |
| `snapshot` | `~/.arinanox/scripts/user-snapshot.sh "$@"` | Data |

### 4.2 Sourced Utility Functions (`tapi-utils.sh`)

The file `~/.arinanox/tools/tapi-utils.sh` (deployed inside the proot image at `/home/admin/.arinanox/tools/tapi-utils.sh`) is **sourced** by `/home/admin/.bashrc` (the proot-side bashrc). It exports the following shell functions for use inside the proot desktop session:

| Function | What It Does |
|---|---|
| `clipget` | Read Android clipboard → proot: `tapi termux-clipboard-get` |
| `clipset` | Write proot clipboard → Android: `echo "$text" \| tapi termux-clipboard-set` |
| `toast` | Show Android toast notification via `tapi termux-toast` |
| `battery` | Show battery percentage, status, health, temperature via `tapi termux-battery-status` |
| `vol-up` / `vol-down` / `vol-get` | Adjust/get music volume via `tapi termux-volume` |
| `bright` | Set screen brightness (0-100): `tapi termux-brightness` |
| `flash` / `flash-off` | Toggle camera torch |
| `notify` | Send Android notification: `tapi termux-notification` |
| `openurl` | Open URL in Android browser |
| `share` | Share text via Android share sheet |
| `speak` | Text-to-speech via `tapi termux-tts-speak` |
| `listen` | Speech-to-text via `tapi termux-speech-to-text` |
| `buzz` | Short vibration (200ms) via `tapi termux-vibrate` |
| `wifi` | WiFi connection info via `tapi termux-wifi-connectioninfo` |
| `whereami` | GPS location via `tapi termux-location` |
| `photo` | Take photo via `tapi termux-camera-photo` |
| `sms` | Send SMS via `tapi termux-sms-send` |
| `clipboard-watch` | Start background clipboard sync daemon (`clipboard-sync.sh`) |

### 4.3 Image-Built Tools (inside proot)

These tools are pre-installed in the container image (Dockerfile Layer 5) and available natively (glibc, not Termux bind-mount):

| Tool | Path | Invocation |
|---|---|---|
| Pi (coding agent) | `/usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js` | `node /path/to/cli.js` (shebang broken) |
| lean-ctx | `/usr/local/bin/lean-ctx` | `lean-ctx` (musl static binary, works normally) |
| ddg_search | `/usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js` | `node /path/to/cli.js --server` for MCP; `node /path/to/cli.js --mode ai --backend iask "query"` for search |
| playwright-cli | `/usr/lib/node_modules/@playwright/cli/playwright-cli.js` | `node /path/to/playwright-cli.js open <url> --browser firefox -s=<session>` |
| DeepSeek models.json | `~/.pi/agent/models.json` | Pre-configured for Pi: model `deepseek-chat` with 1M context |
| MCP config | `~/.pi/agent/mcp.json` | Pre-configured with ddg-search MCP server |

---

## 5. Internal Dependencies Between Modules

```
User
  │
  ├─ arinanox (CLI)
  │    ├──> ~/start.sh  [launchers/start.sh]
  │    │      ├──> ~/.arinanox/scripts/doctor.sh
  │    │      │      └──> ~/.arinanox/scripts/seccomp-check.sh
  │    │      ├──> ~/run-api-bridge.sh [from api-bridge-setup.sh]
  │    │      └──> proot-distro login arinanox (XFCE session)
  │    │
  │    ├──> ~/stop.sh  [launchers/stop.sh]
  │    │
  │    ├──> ~/.arinanox/scripts/proot-rollback.sh
  │    │
  │    ├──> ~/.arinanox/scripts/user-snapshot.sh
  │    │      └──> ~/.arinanox/scripts/manifest-generate.sh
  │    │
  │    └──> (inline) curl bootstrap.sh | bash
  │           ├──> scripts/host-setup.sh
  │           ├──> scripts/proot-setup.sh      (Silverblue atomic swap)
  │           ├──> scripts/api-bridge-setup.sh
  │           ├──> scripts/launcher-gen.sh      (creates ~/.shortcuts/ + ~/symlinks)
  │           └──> scripts/motd-setup.sh
  │
  ├─ ~/update.sh  [launchers/update.sh]
  │    └──> curl bootstrap.sh | bash
  │
  ├─ bootstrap.sh (direct pipe)
  │    └──> [same chain as above]
  │
  ├─ uninstall.sh
  │    └──> proot-distro remove arinanox / arinanox-prev
  │         rm -rf ~/.arinanox ~/.shortcuts/ ~/symlinks
  │
  ├─ ~/.arinanox/scripts/setup-ai-stack.sh  (inside proot)
  │    └──> npm install -g Pi, ddg_search, playwright-cli
  │         curl lean-ctx binary
  │         write ~/.pi/agent/models.json, mcp.json
  │         copy user.js to Firefox profile
  │
  ├─ ~/.arinanox/tools/apt-store.sh  (inside proot, yad GUI)
  │    └──> apt-cache search, apt-get install/upgrade
  │         gpg, curl for adding repositories
  │
  └─ ~/.arinanox/tools/tapi-utils.sh  (sourced by ~/.bashrc)
       └──> tapi (netcat wrapper) → run-api-bridge.sh (host)
```

---

## 6. Runtime Behavior

### 6.1 Startup Sequence (`start.sh`)

```
[0/3] Health Check
  └─ ~/.arinanox/scripts/doctor.sh (non-fatal — continues on warnings)
       └─ ~/.arinanox/scripts/seccomp-check.sh (checks Android SDK + proot probe)

[1/3] Start Services (in parallel)
  ├─ PulseAudio
  │     kill stale pulseaudio
  │     pulseaudio --start --exit-idle-time=-1
  │     pactl load-module module-aaudio-sink  (fallback: module-sles-sink)
  │     pactl load-module module-native-protocol-tcp (port 4713, 127.0.0.1)
  │
  ├─ API Bridge
  │     pkill -f run-api-bridge.sh
  │     bash ~/run-api-bridge.sh &>/dev/null &
  │
  ├─ virgl (auto-detect — 3 tiers, see §7.4)
  │     Tier 1: virgl_test_server_android (native GLES)
  │     Tier 2: virgl_test_server with ANGLE vulkan-null or vulkan
  │     Tier 3: none (CPU fallback)
  │
  ├─ Termux:X11
  │     export XDG_RUNTIME_DIR="$TMPDIR"
  │     termux-x11 :0 -ac &
  │     termux-wake-lock
  │     am start -n com.termux.x11/.MainActivity  (switch to X11 app)
  │
  [2/3] Wait for X11 socket (/tmp/.X11-unix/X0, up to 3s)

[3/3] Launch Desktop (proot-distro login)
  │
  ├─ GPU mode detected:
  │     proot-distro login arinanox --shared-tmp -- su - admin -c "
  │       DISPLAY=:0  PULSE_SERVER=tcp:127.0.0.1:4713
  │       GALLIUM_DRIVER=virpipe
  │       MESA_GL_VERSION_OVERRIDE=4.1COMPAT
  │       MESA_GLES_VERSION_OVERRIDE=3.1
  │       MESA_NO_ERROR=1  MESA_BACK_BUFFER=pixmap
  │       rm -f /tmp/dbus-*
  │       dbus-launch --exit-with-session xfce4-session
  │     "
  │
  └─ CPU mode (no virgl):
        proot-distro login arinanox --shared-tmp -- su - admin -c "
          DISPLAY=:0  PULSE_SERVER=tcp:127.0.0.1:4713
          LIBGL_ALWAYS_SOFTWARE=1
          rm -f /tmp/dbus-*
          dbus-launch --exit-with-session xfce4-session
        "
```

Key environment variables set inside the proot session:
- `DISPLAY=:0` — points to Termux:X11
- `PULSE_SERVER=tcp:127.0.0.1:4713` — TCP PulseAudio bridge
- `NO_AT_BRIDGE=1` — suppress AT bridge warnings
- `GALLIUM_DRIVER=virpipe` or `LIBGL_ALWAYS_SOFTWARE=1` — GPU selection
- `MESA_*` overrides — GPU rendering tweaks

### 6.2 Stop Sequence (`stop.sh`)

```
1. XFCE processes (graceful → force)
     pkill -f thunar, xfdesktop, xfce4-panel, xfce4-terminal, xfwm4, xfce4-session
     sleep 1
     pkill -9 -f same list

2. Proot sessions
     pkill -f dbus-daemon --nofork --session
     pkill -f proot-distro login arinanox
     pkill -f proot.*installed-rootfs/arinanox
     sleep 0.5 then pkill -9

3. Clean temp files (double-layer: inside proot + host)
     rm -rf /tmp/{.X*,dbus-*,ssh-*,xdg-*,xfsm-*}   (inside rootfs)
     rm -f /tmp/.dbus* /home/admin/.cache/sessions/*
     rm -f /home/admin/{.ICEauthority,.Xauthority}

4. virgl server
     pkill -f virgl_test_server

5. X11
     pkill -f termux-x11 ; pkill -9 -f termux-x11
     rm -f $TMPDIR/.X0-lock
     rm -rf $TMPDIR/.X11-unix

6. PulseAudio
     pulseaudio --kill ; pkill -9 pulseaudio

7. API bridge
     pkill -f run-api-bridge.sh

8. Wake lock release
     termux-wake-unlock
```

### 6.3 Update Flow (`bootstrap.sh` → `proot-setup.sh`)

```
bootstrap.sh (curl | bash)
  │
  ├── 1. Download scripts from raw.githubusercontent.com
  │       → ~/.arinanox/scripts/*.sh (all scripts/ files)
  │       → ~/.arinanox/launchers/*.sh (start.sh, stop.sh, update.sh)
  │       → ~/.arinanox/bin/arinanox (CLI)
  │       → ~/run-api-bridge.sh
  │
  ├── 2. Run setup chain
  │       host-setup.sh         (pkg install termux-x11, proot-distro, pulseaudio, virgl, etc.)
  │       proot-setup.sh        (Silverblue atomic swap — see below)
  │       api-bridge-setup.sh   (install tapi client + ~/run-api-bridge.sh)
  │       launcher-gen.sh       (install ~/.shortcuts/ + ~/symlinks)
  │       motd-setup.sh         (write MOTD)
  │
  └── 3. PATH setup in ~/.bashrc

proot-setup.sh (atomic update)
  │
  ├── IF container "arinanox" exists:
  │     ├── proot-distro remove arinanox-prev  (remove old rollback)
  │     └── mv arinanox → arinanox-prev        (save as rollback target)
  │
  └── proot-distro install ghcr.io/arinadi/arinanox:latest --name arinanox
```

After bootstrap completes, if a `user-manifest.yaml` exists, the CLI `update` subcommand also runs `manifest-apply.sh` to re-apply user packages and configs on top of the fresh image.

**Note:** As recommended by `docs/audit-update-flow.md`, there is **no automatic backup/restore** during updates. The Silverblue-style rename (`arinanox-prev`) provides the safety net. Manual backup tools (`proot-backup.sh`, `proot-restore.sh`) exist separately.

### 6.4 Rollback Flow (`proot-rollback.sh`)

```
proot-rollback.sh
  │
  ├── IF arinanox-prev does NOT exist → exit with error
  │
  ├── proot-distro remove arinanox   (remove current broken image)
  └── mv arinanox-prev → arinanox   (restore previous deployment)
```

No data loss: the rename is instant (filesystem-level, no copy). The user layer (`/home/admin` inside the container) is whatever was in the previous deployment at the time it was saved.

### 6.5 CLI Dispatch Chain (`scripts/arinanox`)

The CLI itself performs a first-run bootstrap check:

```
arinanox <command>
  │
  ├── IF ~/.arinanox/scripts/ does NOT exist:
  │     └── curl -sL bootstrap.sh | bash   (auto-install)
  │
  └── CASE <command>
        start   → exec bash ~/start.sh
        stop    → exec bash ~/stop.sh
        status  → exec bash ~/.arinanox/scripts/doctor.sh
        doctor  → exec bash ~/.arinanox/scripts/doctor.sh
        update  → curl bootstrap.sh | bash
                   then if user-manifest.yaml exists:
                     bash ~/.arinanox/scripts/manifest-apply.sh
        rollback→ exec bash ~/.arinanox/scripts/proot-rollback.sh
        store   → exec bash ~/.arinanox/tools/apt-store.sh
        install → read user-manifest.yaml
                   proot-distro login → apt-get install
        backup  → rsync container/home → /sdcard/arinanox-backup
        restore → rsync /sdcard/arinanox-backup → container/home
        snapshot→ exec bash ~/.arinanox/scripts/user-snapshot.sh "$@"
```

---

## 7. Notable Architectural Patterns

### 7.1 Silverblue-Style Atomic Update/Rollback

Inspired by Fedora Silverblue and NixOS, the update mechanism uses **atomic directory renaming** rather than package-level diffs:

| Concept | Implementation |
|---|---|
| Current deployment | `/data/data/.../containers/arinanox/` |
| Previous deployment | `/data/data/.../containers/arinanox-prev/` |
| Update action | `mv arinanox → arinanox-prev` (save), then `proot-distro install` new image as `arinanox` |
| Rollback action | `proot-distro remove arinanox` (remove broken), `mv arinanox-prev → arinanox` (restore) |
| User layer persistence | `/home/admin` is inside the container; the rename preserves its state |

This is documented as analogous to NixOS in `README.md`:
| Concept | NixOS | arinanoX |
|---|---|---|
| System definition | `configuration.nix` | `image/Dockerfile` |
| Atomic upgrades | generations | rename + rollback script |
| Rollback | `nixos-rebuild switch --rollback` | `proot-rollback.sh` |
| User overlays | home-manager | `arinanox install`, `user-manifest.yaml` |

**Caution:** The rename preserves the exact state of `/home/admin` at the time of update. If a user's home directory is in a broken state, the rollback restores that broken state. This is mitigated by the snapshot system (`user-snapshot.sh`).

### 7.2 Two-Layer Core/User Architecture

The architecture separates mutable user state from immutable system state:

- **Core Layer (immutable, declarative):** Defined by `image/Dockerfile`, built in CI, distributed as a GHCR OCI image. Contains the OS, XFCE desktop, Firefox ESR, themes, dev tools, and AI stack. Replaced entirely on update.
- **User Layer (mutable, declarative):** Tracked by `user-manifest.yaml` (generated by `manifest-generate.sh`, applied by `manifest-apply.sh`). Includes user-installed APT packages (detected via `apt-mark showmanual` minus base packages), dotfiles, and XFCE config overrides. Re-applied automatically after `arinanox update` if a manifest exists.
- **Layered Packages:** Optional software installed via `patch.sh` is tracked in `~/.arinanox/layers.txt` and not part of the image — these need to be re-applied manually after an update.

This mirrors the NixOS/home-manager split and the Silverblue/coreOS layer model.

### 7.3 Proot Bind-Mount Constraints

This is the most critical constraint of the entire architecture, documented comprehensively in `docs/plan-ai-stack.md` §8 and summarized in `README.md`.

Termux's `/data/data/com.termux/files/usr` is **bind-mounted** into the proot container at the same path. This means:

1. **Binaries are visible but unexecutable:** Termux binaries use bionic libc (Android NDK) with linker `/system/bin/linker64`, while proot binaries use glibc (Debian) with linker `/lib/ld-linux-aarch64.so.1`. Running a Termux binary from inside proot gives `No such file or directory` (linker mismatch).

2. **PATH hardening prevents accidental use:** The proot-side `.bashrc` (`image/configs-target/home/admin/.bashrc`) sets a clean PATH pointing only to proot-native directories (`/usr/local/bin:/usr/bin:/bin:...`) and ends with a guard that strips any Termux paths from PATH:

   ```bash
   export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "/data/data/com.termux" | tr '\n' ':' | sed 's/:$//')
   ```

3. **The bind-mount is intentional:** It enables sharing data (TAPI utilities, Android storage) without the binaries conflicting — because PATH keeps them separate.

4. **Four protection layers** (documented in `README.md`):
   - **Layer 1:** PATH hardening in `.bashrc` (Termux paths stripped at end of init)
   - **Layer 2:** Runtime audit via `arinanox doctor` (warns if Termux binaries in PATH)
   - **Layer 3:** `PROOT_NO_SECCOMP=1` in launcher scripts
   - **Layer 4:** Documentation (`plan-ai-stack.md` §8, `README.md`)

### 7.4 GPU Auto-Detection Tiers

The startup sequence (`launchers/start.sh`) automatically selects the best available GPU rendering path:

| Tier | Detection | Command | Env | Performance |
|---|---|---|---|---|
| **1. android** | `command -v virgl_test_server_android` | `virgl_test_server_android &` | `GALLIUM_DRIVER=virpipe` | 4K video, 3D games |
| **2. angle-vulkan-null** | `command -v virgl_test_server` + `ANGLE_DIR/vulkan-null` exists | `LD_LIBRARY_PATH=... virgl_test_server --use-egl-surfaceless --use-gles &` | `GALLIUM_DRIVER=virpipe` | Decent GPU passthrough |
| **3. angle-vulkan** | `command -v virgl_test_server` + `ANGLE_DIR/vulkan` exists | `LD_LIBRARY_PATH=... virgl_test_server --use-egl-surfaceless --use-gles &` | `GALLIUM_DRIVER=virpipe` | Good GPU passthrough |
| **4. cpu (fallback)** | none found | (no virgl server started) | `LIBGL_ALWAYS_SOFTWARE=1` | Desktop only |

The variable `VIRGL_MODE` (set to `"android"`, `"angle-vulkan-null"`, `"angle-vulkan"`, or `"cpu"`) is displayed in the startup log. The proot login command switches between GPU and CPU environment variable sets accordingly.

### 7.5 PROOT_NO_SECCOMP Side Effects

`PROOT_NO_SECCOMP=1` is required for all Node.js tools (Pi, ddg_search, playwright-cli) inside proot. It fixes three bugs documented in `docs/plan-ai-stack.md`:

| Bug | Without Fix | With Fix |
|---|---|---|
| `uv__io_poll: Assertion 'errno == EINTR'` | Crash in Node.js event loop | ✅ Normal |
| `fork: Function not implemented` | Failed to spawn processes | ✅ Normal |
| `futex` error | Failed V8/libuv thread sync | ✅ Normal |

**Side effects:**
- ❌ `su - admin` is broken (setuid blocked by no-seccomp mode) → must use `proot-distro login -u admin` instead
- ❌ Shebang `#!/usr/bin/env node` is broken → all Node.js tools must be invoked as `node /path/to/cli.js`
- ✅ lean-ctx (Rust musl static binary) is unaffected

These side effects are documented in `docs/plan-ai-stack.md` §2 and `docs/ai-stack-usage.md` §6. The start script uses `proot-distro login -u admin` (via `su - admin` which works because it falls through to proot-distro), and the MCP config invokes Node.js tools via `node /path/to/cli.js`.

### 7.6 Declarative User Manifest

The `user-manifest.yaml` system enables declarative user customization:

```yaml
# Generated by: manifest-generate.sh
# Applied by: manifest-apply.sh
# Location: ~/.arinanox/user-manifest.yaml

packages:
  - ripgrep
  - neofetch

dotfiles:
  - .bash_aliases
  - .gitconfig

xfce_config:
  - xfce4-panel.xml
  - xfwm4.xml
  - xsettings.xml
  - xfce4-desktop.xml
  - xfce4-keyboard-shortcuts.xml
  - thunar.xml
```

**Generation** (`manifest-generate.sh`): Compares `apt-mark showmanual` output against a hardcoded list of image base packages (extracted from the Dockerfile). Detects custom dotfiles by comparing against shipped configs. Detects installed themes/icons from `/usr/share/themes/` and `/usr/share/icons/`.

**Application** (`manifest-apply.sh`): Runs `apt-get install` for each user package inside proot, copies XFCE config XML files from `snapshot-current` or backup, and restores dotfiles from `/sdcard/arinanox-backup`.

### 7.7 Hardlinked Snapshots

The `user-snapshot.sh` system uses `rsync --link-dest` for space-efficient snapshots:

```
~/.arinanox/snapshots/
├── 20250331-143022/   (full data, ~2GB)
├── 20250331-151045/   (only changed files, ~50MB with --link-dest)
└── 20250331-161532/   (only changed files)
~/.arinanox/snapshot-current → snapshots/20250331-161532/
```

- First snapshot is a full copy.
- Subsequent snapshots use `--link-dest=<previous>` for hardlink deduplication.
- Maximum 3 snapshots retained (rotation on `create`).
- `snapshot-current` symlink always points to the most recent snapshot.
- Snapshot is created from the container rootfs `/home/admin/`.

### 7.8 Termux:API Bridge Mechanics

The `tapi` bridge enables proot-internal commands to invoke Termux:API on the Android host:

**Host side** (`run-api-bridge.sh`):
```
TCP listener on port 8888   (receives commands)
TCP listener on port 8889   (sends responses)
Loop: nc -l -p 8888 → eval "$CMD" 2>&1 | nc -l -p 8889
```

**Guest side** (`/usr/local/bin/tapi`, created by `api-bridge-setup.sh`):
```bash
#!/bin/bash
echo "$@" | nc 127.0.0.1 8888 &    # send command to host
timeout 10 nc 127.0.0.1 8889        # receive response from host
```

This is a one-shot TCP pattern: each `tapi` invocation opens two separate netcat connections (one to send, one to receive), and the host listener runs them sequentially per request.

---

## 8. Design Document Cross-References

### 8.1 `docs/audit-update-flow.md` Findings

This document audited the original update/backup/restore flow and identified seven risks:

| Risk | Status in Current Code |
|---|---|
| 1. `CACHE_BUST` in update.sh causing 429 rate limits | **Resolved.** Current `update.sh` (launchers/update.sh) is a simple `curl bootstrap.sh \| bash` with `--retry 2`. No cache-busting tokens. |
| 2. `dpkg` backup does not filter image base vs user packages → restore conflicts | **Resolved.** Automatic backup/restore removed from update flow. The new `manifest-generate.sh` explicitly filters base packages from user packages (hardcoded base list from Dockerfile). |
| 3. Home dir restore → stale XFCE sessions, ICEauthority, cache conflicts | **Mitigated.** `stop.sh` aggressively cleans XFCE sessions, ICEauthority, `.Xauthority` on shutdown. `manifest-apply.sh` does not restore these stale artifacts. |
| 4. `apt install` with `2>/dev/null` → silent failure | **Partially.** Current `manifest-apply.sh` uses `2>/dev/null` for apt but logs skipped packages. The inline `install` CLI command in `scripts/arinanox` uses `|| true`. |
| 5. Tar/untar in proot → permission issues, broken symlinks | **Resolved.** Tar backup/restore moved to optional manual tools (`proot-backup.sh`, `proot-restore.sh`). Default update path uses Silverblue atomic rename (no tar). |
| 6. Script corrupt (429) → stranded user | **Mitigated.** `--retry 2` on curl. Atomic rename means the previous deployment is preserved even if the new download fails (the rename happens _after_ successful download). |
| 7. Complexity vs value | **Addressed.** Update is now a simple `curl bootstrap.sh \| bash` (~30s), matching the document's recommendation. |

The document's **primary recommendation** — "HAPUS auto-backup/restore. Ganti update.sh jadi simple install fresh, pakai patch.sh for packages" — has been adopted. `proot-backup.sh` and `proot-restore.sh` remain as optional manual tools with clear warnings in their headers.

### 8.2 `docs/plan-ai-stack.md` Findings

This document validated the AI vibe-coding stack for proot ARM64 and produced several architecture notes that are reflected in the codebase:

| Finding | Codebase Implementation |
|---|---|
| `PROOT_NO_SECCOMP=1` required for all Node.js tools | Applied in `~/.shortcuts/1-start-arinanox.sh` (via `seccomp-fix.sh`), documented in `docs/ai-stack-usage.md`, MCP config uses `node /path/to/cli.js` pattern |
| `su - admin` broken with `PROOT_NO_SECCOMP=1` | The start script uses `proot-distro login ... su - admin` which works; documented as known side effect |
| Shebang `#!/usr/bin/env node` broken | All Node.js tools invoked via `node /path/to/cli.js` in MCP config, start scripts, and user docs |
| Termux bind-mount: binaries visible but unexecutable | Protected by PATH hardening in `.bashrc` (grep -v `/data/data/com.termux`), `doctor.sh` audits for this, documented in §8 of the plan document |
| DuckDuckGo blocked from Indonesia → use IAsk backend | `ddg_search --mode ai --backend iask` is the documented invocation in `docs/ai-stack-usage.md` and MCP config |
| lean-ctx musl binary unaffected | Written in Rust, musl-static, no glibc dependency — tested and confirmed in plan document |
| AI stack pre-installed in image | Dockerfile Layer 5 installs Pi, lean-ctx, ddg_search, playwright-cli, DeepSeek config, MCP config, Firefox user.js — exactly as specified in the plan |
| Pi permission system (extension TS) | Not yet installed (marked as ⏳ in plan — "Belum dipasang") |
| pi-gateway (Telegram gateway) | Not yet installed (marked as ⏳ — "Clone timeout, perlu test ulang") |
| headroom as lean-ctx addon | Mentioned as optional (+ "kalau butuh cross-agent memory"), not yet integrated |

The AI stack Dockerfile layers (Layer 5) replicate the installation steps from `docs/plan-ai-stack.md` §1 almost verbatim, confirming the plan drove the implementation.

---

> **End of Blueprint.** This document maps the complete working tree at commit time and should be updated when significant structural changes (new directories, new exported interfaces, architecture changes) are introduced.
