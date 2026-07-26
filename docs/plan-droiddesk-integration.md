# Plan: DroidDesk Integration → arinanoX

> **Source:** Analysis of [DroidDesk](https://github.com/orailnoor/DroidDesk) (cloned 2026-07-26)
> **Target:** [arinanoX](https://github.com/arinadi/arinanoX)
> **Status:** Draft — ready for review

---

## Executive Summary

DroidDesk and arinanoX solve the same problem (Linux desktop on Android) with complementary architectures. DroidDesk brings three assets arinanoX lacks: a Flutter Android management app, an embedded X11 server, and a proot-to-native menu bridge. This plan prioritizes adopting those assets into arinanoX without disrupting its established prebuilt-image + Silverblue-rollback core.

---

## 1. DroidDesk Android App — Architecture Analysis

### 1.1 Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3.10+ (Dart) |
| State Management | Provider (`ChangeNotifier`) |
| Platform Bridge | `MethodChannel` (`com.droiddesk/core`) |
| Native Layer | Kotlin (Android) — bootstrap extraction, pkg install, process management |
| Display Server | Embedded `termux-x11` (C + wlroots/wayland) via `PlatformView` + `JNI` |
| GPU | Turnip (freedreno) / Zink Mesa drivers bundled as `.so` in `jniLibs/` |

### 1.2 Key Components

```
app/lib/
├── main.dart                    # Entry + Provider setup
├── state/app_state.dart         # Central ChangeNotifier (~500 lines)
├── services/platform_bridge.dart # MethodChannel abstraction
├── theme/droid_theme.dart       # Dark theme, gradients, typography
├── screens/
│   ├── welcome_screen.dart      # Animated landing with feature chips
│   ├── home_screen.dart         # Dashboard: status, actions, terminal, system info
│   ├── desktop_screen.dart      # PlatformView for embedded X11 compositor
│   ├── setup/
│   │   ├── de_picker.dart       # Desktop environment selection (XFCE/LXQt/MATE/KDE)
│   │   ├── distro_picker.dart   # Linux distro selection (Ubuntu/Debian/Kali)
│   │   ├── de_install_screen.dart # Download/extract progress with live log
│   │   └── setup_progress.dart  # Reusable progress widget
│   └── apps/
│       └── app_catalog_screen.dart # Optional app installer grid
└── assets/
    ├── bootstrap-aarch64.zip    # Bundled Termux bootstrap (~30MB)
    └── socket_hook.c            # C source for X11 socket forwarding
```

### 1.3 App State Machine

```
┌──────────┐   no bootstrap   ┌───────────┐
│ WELCOME  │ ───────────────→ │ DISTRO    │
│ (brand)  │                  │ PICKER    │
└──────────┘                  └─────┬─────┘
       │                            │
       │ has bootstrap              ↓
       │                      ┌───────────┐
       │                      │ DE PICKER │
       │                      └─────┬─────┘
       │                            │
       ↓                            ↓
┌──────────┐                  ┌───────────┐
│  HOME    │ ←─── done ────── │ INSTALL   │
│ DASHBOARD│                  │ PROGRESS  │
└────┬─────┘                  └───────────┘
     │
     ├─ "Launch Desktop" → embedded X11 (desktop_screen.dart)
     ├─ "Terminal"       → bottom sheet with executeCommand()
     ├─ "Add Apps"       → app_catalog (optional packages)
     └─ "Stop Server"    → stopLinux()
```

### 1.4 Platform Bridge Methods

| Method | Direction | Purpose |
|--------|-----------|---------|
| `getRuntimeStatus` | Flutter→Kotlin | Is bootstrap done? Is DE installed? Is session running? |
| `getDeviceInfo` | Flutter→Kotlin | Model, Android version, GPU vendor, RAM, storage |
| `checkRoot` | Flutter→Kotlin | Detect root for chroot path |
| `setupBootstrap` | Flutter→Kotlin | Extract bundled `bootstrap-aarch64.zip` |
| `downloadRootfs` | Flutter→Kotlin | Download Ubuntu rootfs (chroot mode) |
| `extractRootfs` | Flutter→Kotlin | Extract downloaded rootfs |
| `installDesktopEnvironment` | Flutter→Kotlin | `apt install` DE packages inside chroot |
| `installDesktopNative` | Flutter→Kotlin | `pkg install` DE from TUR (non-root mode) |
| `startLinux` | Flutter→Kotlin | Launch X11 server + DE session |
| `stopLinux` | Flutter→Kotlin | Kill all sessions |
| `executeCommand` | Flutter→Kotlin | Run shell command, stream stdout |
| `launchDesktopActivity` | Flutter→Kotlin | Bring embedded X11 to foreground |
| `getOptionalApps` | Flutter→Kotlin | Query installed optional packages |
| `installOptionalApp` | Flutter→Kotlin | Install a specific optional package |
| `requestBatteryOptimization` | Flutter→Kotlin | Open Android battery settings |
| `interruptCommand` | Flutter→Kotlin | Send SIGINT to running command |

### 1.5 Embedded X11 Server (How It Works)

DroidDesk bundles a native X11 server (`termux-x11`) inside the APK instead of requiring a separate install:

1. **Native libraries** (`jniLibs/arm64-v8a/`): `wlroots`, `wayland`, `libxkbcommon`, `pixman`, `libdrm`, `libffi` — fetched via `fetch_deps.sh` from Termux package repos.
2. **C code** (`socket_hook.c`): Hooks `socket()` calls to redirect Unix socket paths from Termux prefix to app-private directory.
3. **Flutter PlatformView** (`desktop_screen.dart`): Renders the X11 compositor directly inside a Flutter widget via `AndroidViewSurface`.
4. **Lifecycle**: The app starts the X11 server process, then launches the DE session inside chroot/proot connected to that display.

---

## 2. Gap Analysis: arinanoX vs DroidDesk

| Feature | arinanoX (current) | DroidDesk | Priority |
|---------|-------------------|-----------|----------|
| **Android App** | None (CLI + scripts only) | Full Flutter app with setup wizard, dashboard, terminal | 🔴 HIGH |
| **Display Server** | External Termux:X11 APK required | Embedded in-app (PlatformView) | 🔴 HIGH |
| **Setup UX** | `curl \| bash` in Termux terminal | Step-by-step animated wizard | 🟡 MEDIUM |
| **Session Management** | Start/stop scripts | One-tap buttons with live status indicator | 🟡 MEDIUM |
| **Terminal in GUI** | Must switch to Termux app | In-app terminal bottom sheet | 🟡 MEDIUM |
| **Menu Bridge** | None (all in proot, no menu sync needed)* | Proot→native .desktop sync | 🟢 LOW |
| **GPU Accel** | virgl (3-tier: android → angle → CPU) | Turnip/Zink (Adreno native) | 🟢 LOW |
| **Multi-DE** | XFCE only (opinionated) | XFCE4/LXQt/MATE/KDE | ❌ OUT |
| **Root/chroot** | Proot only | chroot (root) + non-root fallback | ⚠️ RISK |
| **Pi Bridge** | In archive (legacy) | VNC-based Pi Zero 2W bridge | 🟢 LOW |
| **AI Stack** | Pre-installed (Pi, lean-ctx, playwright) | Not included | N/A |

\* arinanoX runs the full desktop inside proot, so the XFCE menu is already inside proot. The menu bridge is less critical than in DroidDesk where the desktop runs natively in Termux and only some apps are in proot.

---

## 3. Implementation Plan

### Phase 1: arinanoX Companion App (Flutter) 🚀

**Goal:** A management app that wraps arinanoX's existing scripts in a polished UI. No embedded X11 yet — still uses external Termux:X11 APK.

**Estimated effort:** Medium (2-3 weeks for MVP)

#### 3.1.1 Architecture

```
arinanox_app/
├── lib/
│   ├── main.dart                  # Entry + Provider setup
│   ├── state/app_state.dart       # Mirrors DroidDesk's AppState pattern
│   ├── services/shell_bridge.dart # Execute arinanox CLI commands
│   ├── theme/arinanox_theme.dart  # arinanoX brand colors
│   ├── screens/
│   │   ├── welcome_screen.dart    # "Your phone is a Linux workstation"
│   │   ├── home_screen.dart       # Dashboard (reuse DroidDesk layout)
│   │   ├── terminal_screen.dart   # In-app terminal (reuse DroidDesk _TerminalSheet)
│   │   └── settings_screen.dart   # Config, battery, about
│   └── widgets/
│       ├── status_card.dart       # "Desktop Active" / "Desktop Idle"
│       ├── quick_action.dart      # Reusable action card
│       └── system_info.dart       # Device + container info
├── android/
│   └── app/src/main/kotlin/.../
│       └── ShellExecutor.kt       # Execute shell commands, stream output
└── assets/
    └── icons/logo.png
```

#### 3.1.2 State Model (adapted from DroidDesk)

```dart
class ArinanoxState extends ChangeNotifier {
  bool _isInstalled;       // ~/.arinanox exists?
  bool _isRunning;         // XFCE session active?
  bool _hasContainer;      // proot-distro container exists?
  String _containerSize;   // du -sh of container
  String _rollbackSize;    // arinanox-prev size
  Map<String, dynamic> _deviceInfo;  // model, android, gpu, ram
  List<String> _terminalOutput;      // terminal history
  int _layeredPackages;    // count from layers.txt
  
  // Actions (call arinanox CLI / scripts)
  Future<void> install();     // curl bootstrap.sh
  Future<void> start();       // arinanox start
  Future<void> stop();        // arinanox stop
  Future<void> status();      // arinanox status (doctor.sh)
  Future<void> update();      // arinanox update
  Future<void> rollback();    // arinanox rollback
  Future<void> snapshot();    // arinanox snapshot create
  Future<void> execCommand(String cmd);  // run inside proot
}
```

#### 3.1.3 Shell Bridge

Unlike DroidDesk which bundles Termux bootstrap and implements everything in Kotlin, arinanoX's companion app should **delegate to existing arinanoX scripts**:

```dart
class ShellBridge {
  static const _channel = MethodChannel('com.arinadi.arinanox/shell');
  
  // Execute any arinanox command
  static Future<ProcessResult> exec(String command, {
    Function(String)? onStdout,
    Function(String)? onStderr,
  }) async {
    // Kotlin side: Runtime.getRuntime().exec() with PTY
    // Streams output back via MethodChannel callbacks
  }
  
  // Convenience wrappers
  static Future<bool> isInstalled() =>
    exec('test -d ~/.arinanox && echo YES || echo NO');
  
  static Future<bool> isRunning() =>
    exec('pgrep -f "xfce4-session" > /dev/null && echo YES || echo NO');
  
  static Future<void> doStart() =>
    exec('arinanox start');
  
  static Future<void> doStop() =>
    exec('arinanox stop');
}
```

#### 3.1.4 Key Screens (reusing DroidDesk patterns)

**Home Dashboard** — adapt DroidDesk's `home_screen.dart`:
- Status card (running/idle with pulse indicator) — direct reuse
- Quick actions: Launch Desktop, Stop Server, Terminal, Snapshot, Update — adapt `_ActionCard`
- System info grid: Distro (Debian 13), Desktop (XFCE), GPU (from virgl tier), Device, RAM, Storage — direct reuse
- Layered packages count from `~/.arinanox/layers.txt`

**Terminal** — direct reuse of DroidDesk's `_TerminalSheet`:
- Auto-scroll output
- Command input with send button
- Interrupt (Ctrl+C) support
- Runs commands inside proot via `proot-distro login arinanox -- bash -c`

#### 3.1.5 What to SKIP from DroidDesk

- ❌ **Distro picker** — arinanoX is Debian 13 only (opinionated)
- ❌ **DE picker** — arinanoX is XFCE only (opinionated)
- ❌ **chroot/root path** — arinanoX is proot-only by design
- ❌ **Bundled bootstrap** — arinanoX uses `curl bootstrap.sh`, not a bundled zip
- ❌ **Download/extract progress** — arinanoX pulls a prebuilt GHCR image (30s), not apt-based install

---

### Phase 2: Embedded X11 Server 🎯

**Goal:** Bundle `termux-x11` inside the arinanoX app so users don't need a separate Termux:X11 APK install.

**Estimated effort:** High (4-6 weeks, significant native dev)

#### 3.2.1 Approach

Replicate DroidDesk's embedded X11 architecture:

1. **Bundle native libraries:**
   - Use `fetch_deps.sh` pattern to pull `wlroots`, `wayland`, `libxkbcommon`, `pixman`, `libdrm`, `libffi` `.so` files from Termux package repos into `jniLibs/arm64-v8a/`
   - Compile `termux-x11` C sources against these bundled libs

2. **Socket forwarding:**
   - Adapt `socket_hook.c` to redirect Unix sockets to app-private directory
   - arinanoX uses `$TMPDIR/.X11-unix/X0` — hook must map this

3. **Flutter PlatformView:**
   - Reuse DroidDesk's `desktop_screen.dart` with `AndroidViewSurface`
   - Connect to the embedded X11 compositor on `DISPLAY=:0`

4. **Session management:**
   - Adapt `launchers/start.sh` to detect embedded vs external X11
   - When embedded: skip `am start -n com.termux.x11` (app already rendering)

#### 3.2.2 Risk: Legal & Compatibility

⚠️ DroidDesk's embedded X11 uses GPL-licensed `termux-x11` code. arinanoX is also GPLv3 — compatible, but:
- Must maintain proper attribution per `NOTICE.md` / `THIRD_PARTY_NOTICES.md`
- DroidDesk's README notes "unresolved source provenance" and "reproducible-build" items in their compliance checklist
- Recommendation: wait for DroidDesk's compliance to stabilize, or fork `termux-x11` directly

---

### Phase 3: Proot App Bridge (Menu Sync) 🔗

**Goal:** Auto-sync `.desktop` files from proot container into XFCE menu. Currently arinanoX runs the full desktop inside proot, so this is less critical — but useful for edge cases (e.g., user installs Chromium via `patch.sh` and wants it in the menu without restarting XFCE).

**Estimated effort:** Low (1-2 days)

#### 3.3.1 Adapted Script

DroidDesk's `proot-menu-sync.sh` can be adapted with minimal changes:
- Replace `PROOT_DISTRO="ubuntu"` with `"arinanox"` (or autodetect)
- Replace hardcoded TUR paths with arinanoX paths
- The script already handles dbus-run-session, X11 socket binding, and GPU env — all compatible with arinanoX

#### 3.3.2 Integration Points

```bash
# Add to launchers/start.sh (Phase 2/3 — after XFCE starts)
# Sync proot apps into menu (background, non-blocking)
[ -f ~/.arinanox/scripts/proot-menu-sync.sh ] && \
  bash ~/.arinanox/scripts/proot-menu-sync.sh > /dev/null 2>&1 &
```

---

### Phase 4: Pi Monitor Bridge (Revival) 🖥️

**Goal:** Reactivate external monitor support via Raspberry Pi Zero 2W.

**Estimated effort:** Low (1-2 days, mostly adapting existing scripts)

#### 3.4.1 Current State

arinanoX has legacy VNC launcher scripts in `archive/`:
- `archive/launch-pi-vnc.sh` — VNC launcher for Pi bridge
- `archive/run-api-bridge.sh` — API bridge runner

DroidDesk's `pi-launch_phone.sh` is a cleaner, self-contained VNC bridge.

#### 3.4.2 Adaptation

- Copy `pi-launch_phone.sh` to `scripts/pi-bridge.sh`
- Replace hardcoded VNC port (5901) with arinanoX's VNC config
- Update `launchers/start.sh` to optionally start VNC alongside X11
- Document in README

---

## 4. Recommended Implementation Order

```
Week 1-3:  Phase 1 (Companion App MVP)
           └─ Flutter app with dashboard, terminal, start/stop/status
           └─ Shell bridge to arinanox CLI
           └─ Publish to GitHub Releases as APK

Week 4:    Polish Phase 1
           └─ Error handling, battery optimization dialog
           └─ Setup wizard for first-time install (calls bootstrap.sh)
           └─ User testing

Week 5-6:  Phase 3 (Proot Menu Bridge)
           └─ Adapt proot-menu-sync.sh
           └─ Integrate into launchers/start.sh
           └─ Test with patch.sh-installed apps

Week 7+:   Phase 2 (Embedded X11) — OPTIONAL, high effort
           └─ Bundle termux-x11 native libs
           └─ PlatformView integration
           └─ Compliance review

Phase 4:   Pi Bridge — whenever needed
```

---

## 5. Key Risks & Decisions

| Risk | Mitigation |
|------|-----------|
| **Embedded X11 compliance** | Start with external Termux:X11 + Companion App. Embedded X11 is an enhancement, not a blocker. |
| **Flutter app adds maintenance burden** | Keep it thin — all logic stays in bash scripts. The app is a UI shell. |
| **Two codebases to sync** | arinanoX scripts and Flutter app have a clear boundary: scripts do the work, app calls them. |
| **Android 15+ seccomp** | arinanoX already handles this with `PROOT_NO_SECCOMP=1`. The app just needs to respect the existing fix. |
| **DroidDesk GPL compliance gaps** | Do not copy code that lacks clear provenance. Use DroidDesk as design reference, not source. |

---

## 6. What NOT to Adopt from DroidDesk

| Feature | Reason |
|---------|--------|
| Native Termux TUR packages | arinanoX's prebuilt image is faster, more reproducible |
| chroot/root mode | arinanoX is proot-only by design |
| Multi-DE support | arinanoX is opinionated about XFCE |
| Bundled bootstrap zip | arinanoX's `curl \| bash` is simpler and always up-to-date |
| apt-based install | Prebuilt GHCR image is 30s vs 20-30 min |
| VNC as primary display | Termux:X11 is faster; VNC only for Pi bridge |
| DroidDesk's Kotlin native bootstrap | Overlaps with arinanoX's bash scripts; keep concerns separated |

---

## 7. Comparison Table (Post-Integration Target State)

| Feature | arinanoX (current) | arinanoX (post-integration) |
|---------|-------------------|---------------------------|
| Android App | ❌ | ✅ Flutter companion app |
| Display Server | External APK | External APK (Phase 1), Embedded (Phase 2) |
| Setup UX | Terminal `curl \| bash` | Terminal OR guided app wizard |
| Session Control | Scripts / shortcuts | One-tap buttons in app |
| Terminal | Switch to Termux | In-app terminal |
| Menu Bridge | N/A | ✅ Auto-sync from proot |
| Pi Bridge | Archive (broken) | ✅ Revived + documented |
| AI Stack | ✅ Pre-installed | ✅ (unchanged) |
| Atomic Updates | ✅ | ✅ (unchanged) |
| Manifest System | ✅ | ✅ (unchanged) |

---

## References

- DroidDesk repo: `https://github.com/orailnoor/DroidDesk` (cloned at `/data/data/com.termux/files/home/DroidDesk`)
- DroidDesk termux-linux-setup.sh: 1104 lines, 12-step setup with progress bar
- DroidDesk app state machine: `app/lib/state/app_state.dart` (ChangeNotifier pattern)
- DroidDesk platform bridge: `app/lib/services/platform_bridge.dart` (15 MethodChannel methods)
- arinanoX blueprint: `blueprint.md` (full architecture reference)
- arinanoX audit: `arinanox-audit.md` (complete source trace)
- arinanoX contracts: `.pi-tasks/contracts.md` (already references DroidDesk as design anchor)
