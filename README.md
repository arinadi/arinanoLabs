<div align="center">
  <h1>📱 arinanoX</h1>
  <p><strong>Your phone is a Linux workstation — ~30s to a working desktop, not 30 minutes of apt.</strong></p>
  <p>
    <a href="https://arinano.work"><img src="https://img.shields.io/badge/site-arinano.work-blue"></a>
    <a href="https://github.com/arinadi/arinanoX/actions"><img src="https://img.shields.io/github/actions/workflow/status/arinadi/arinanoX/build-image.yml?label=image"></a>
    <a href="https://github.com/arinadi/arinanoX/actions"><img src="https://img.shields.io/github/actions/workflow/status/arinadi/arinanoX/build-apk.yml?label=apk"></a>
    <a href="https://github.com/arinadi/arinanoX/blob/main/LICENSE"><img src="https://img.shields.io/github/license/arinadi/arinanoX"></a>
  </p>
</div>

---

## ⚡ Quick Start

### 1. Install Termux + Extras

Install from **F-Droid** (NOT Play Store):

- [Termux](https://f-droid.org/en/packages/com.termux/)
- [Termux:X11](https://github.com/termux/termux-x11/releases/tag/nightly) — display server
- [Termux:API](https://f-droid.org/en/packages/com.termux.api/) — battery, clipboard, voice

### 2. Install arinanoX APK

Download the latest APK from [GitHub Releases](https://github.com/arinadi/arinanoX/releases) and install it.

### 3. Open the app → tap **Install arinanoX**

~30 seconds. The app downloads and sets up the prebuilt Debian 13 + XFCE image from GitHub Container Registry.

### 4. Tap **Launch Desktop**

Done. Full Linux desktop on your phone.

> **CLI fallback:** You can also install via Termux terminal:
> ```bash
> curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash
> arinanox start
> ```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│  arinanoX APK (Flutter)             │  ← Companion app: start/stop/terminal/snapshots
├─────────────────────────────────────┤
│  Bash scripts (~/.arinanox/)        │  ← Downloaded by bootstrap, updatable from app
├─────────────────────────────────────┤
│  Proot container (ghcr.io)          │  ← Prebuilt Debian 13 + XFCE image
│  Built from image/Dockerfile        │     CI-built, tagged, pushed to GHCR
└─────────────────────────────────────┘
```

### What's in the image

| What | Detail |
|------|--------|
| OS | Debian 13 (Trixie) ARM64 |
| Desktop | XFCE4 + Whisker Menu + PulseAudio tray |
| Browser | Firefox ESR |
| Dev tools | Git, Node.js 22 LTS, Python 3 (pip/venv/dev), GCC, Make, CMake |
| Theme | Orchis-Dark Material Design + elementary-hidpi icons |
| Touch | Single-click Thunar, large scrollbars, clipboard auto-sync |
| Terminal | mousepad, ristretto, htop, tmux, OpenSSH |
| GPU | virglrenderer auto-detect (3-tier: android → angle-vulkan → CPU) |

### GPU Acceleration (virglrenderer)

Auto-detected at launch:

```
1. android           → virgl_test_server_android      (native GLES)
2. angle-vulkan-null → virgl + ANGLE passthrough       (Vulkan GPUs)
3. CPU fallback      → LIBGL_ALWAYS_SOFTWARE=1         (desktop only)
```

---

## 📱 Companion App (Flutter)

Download APK from [GitHub Releases](https://github.com/arinadi/arinanoX/releases).

| Feature | Description |
|---------|-------------|
| 📥 Install | Download and set up Debian 13 + XFCE (~30s, one tap) |
| 🟢 Start/Stop | One-tap launch or shutdown XFCE desktop |
| 💻 Terminal | In-app proot shell with streaming output |
| 🩺 Health Check | Run doctor.sh to diagnose issues |
| 📸 Snapshot | Instant user-home checkpoint (hardlinked) |
| 🔄 Update Scripts | Download latest launchers + scripts from GitHub |
| 📊 System Info | GPU, RAM, storage, container size |

The app uses Termux bash internally — all commands run in the correct environment with proper PATH, HOME, and library paths.

APK builds are CI-triggered manually (`workflow_dispatch`) — no spam on every commit.

---

## 🚀 CLI Usage

```bash
arinanox start        # Start desktop (PulseAudio → X11 → virgl → XFCE)
arinanox stop         # Stop everything
arinanox status       # System overview + layered packages
arinanox doctor       # Full health-check
arinanox store        # APT Store GUI (install/search/upgrade)
arinanox snapshot     # Instant checkpoint (hardlinked, 3 retained)
arinanox install      # Apply packages from user-manifest.yaml
arinanox help         # All commands
```

---

## 📋 Termux:API (inside proot)

| Command | Action |
|---------|--------|
| `battery` | Battery % and health |
| `clipget` / `clipset` | Android clipboard |
| `vol-up` / `vol-down` | Media volume |
| `bright 50` | Brightness 0-100 |
| `toast "msg"` | Toast popup |
| `notify "T" "B"` | Notification |
| `speak "hello"` | Text-to-speech |
| `speechlisten` | Speech-to-text |
| `openurl` / `share` | Open / share in Android |
| `whereami` / `wifi` | GPS / WiFi |
| `photo` / `flash` | Camera / flashlight |

---

## 🛑 Android 12+ Phantom Process Killer

Background processes get silently killed. Disable it:

- **Android 14+:** Developer Options → Disable child process restrictions
- **Android 12–13:** `adb shell settings put global settings_enable_monitor_phantom_procs false`

---

## ⚠️ Limitations

| Limitation | Workaround |
|-----------|------------|
| No root | proot provides root-like environment, not real root |
| No systemd | Start services manually |
| No GPU passthrough | virglrenderer auto-detected (3-tier fallback) |
| ARM64 only | QEMU user-mode for cross-arch (slow) |
| No native X11 | Termux:X11 APK required |
| Docker containers | Not possible (daemon needs kernel features proot lacks) |

---

## 📂 Repo Structure

```
arinanoX/
├── app/                  ← 📱 Flutter app (APK) — primary entry point
│   ├── lib/              ←    Dart: screens, state, services, theme
│   └── android/          ←    Kotlin: shell executor, script updater
├── bootstrap.sh          ← CLI fallback: curl | bash
├── image/                ← 🎯 System definition (Dockerfile)
│   ├── Dockerfile        ←    declarative: packages, configs, themes
│   └── configs-target/   ←    XFCE, bash, GTK, autostart
├── scripts/              ← setup, patch, status, doctor, snapshots
├── launchers/             ← start/stop shortcuts
├── docs/                  ← documentation
└── .github/workflows/     ← CI: build-image (manual), build-apk (manual)
```

---

## 📜 License

GPLv3 — see [LICENSE](LICENSE).
