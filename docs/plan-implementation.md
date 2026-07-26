# Implementasi Plan: arinanoX Flutter App + GitHub Actions

> **Status:** Ready to execute
> **Tanggal:** 2026-07-26
> **Referensi ATM:** [DroidDesk](https://github.com/orailnoor/DroidDesk) (cloned at `/data/data/com.termux/files/home/DroidDesk`)

---

## 1. Ringkasan Perubahan

### File yang Dimodifikasi

| File | Perubahan |
|------|-----------|
| `.github/workflows/build-image.yml` | Hapus `push` trigger, jadi `workflow_dispatch` only + input tag |

### File yang Dibuat

| File | Deskripsi |
|------|-----------|
| `.github/workflows/build-apk.yml` | Flutter APK build (manual trigger, 30 hari retention) |
| `app/` | **Full Flutter project (12 file)** — ATM dari DroidDesk |
| `docs/plan-droiddesk-integration.md` | Analisis DroidDesk + rencana 4 fase |
| `docs/plan-flutter-vs-kotlin.md` | Perbandingan effort Flutter vs Kotlin |

### Struktur App Lengkap

```
app/
├── .gitignore
├── README.md
├── pubspec.yaml                          # Flutter deps: provider, google_fonts, flutter_animate
├── analysis_options.yaml
├── lib/
│   ├── main.dart                         # Entry + Provider + routing
│   ├── state/
│   │   └── app_state.dart               # ChangeNotifier: status, actions, terminal
│   ├── services/
│   │   └── shell_bridge.dart            # MethodChannel → Kotlin
│   ├── theme/
│   │   └── arinanox_theme.dart          # Design system (teal + amber brand)
│   └── screens/
│       ├── home_screen.dart             # Dashboard: status card, actions, system info
│       └── terminal_screen.dart         # Terminal bottom sheet
├── android/
│   └── app/
│       ├── build.gradle.kts             # Android config (API 28+, arm64-v8a)
│       └── src/main/
│           ├── AndroidManifest.xml      # Single activity, internet permission
│           └── kotlin/com/arinadi/arinanox/
│               ├── MainActivity.kt      # MethodChannel handler (9 methods)
│               ├── ShellExecutor.kt     # Runtime.exec + streaming output
│               └── DeviceInfoHelper.kt  # GPU, RAM, storage detection
└── assets/
    └── icons/                           # (placeholder — tambahkan logo.png)
```

---

## 2. Cara Kerja (Architecture Flow)

```
┌──────────────────────────────────────────────────┐
│  User taps "Launch Desktop"                       │
│                                                    │
│  Flutter (Dart)                                    │
│  └─ ArinanoxShell.executeCommand("arinanox start") │
│       │                                            │
│       ▼ MethodChannel("com.arinadi.arinanox/shell")│
│  Kotlin (native)                                   │
│  └─ ShellExecutor.executeCommand(...)              │
│       │                                            │
│       ▼ Runtime.exec("sh", "-c", command)           │
│  Termux (bash)                                     │
│  └─ ~/.arinanox/bin/arinanox start                 │
│       │                                            │
│       ▼ Launch scripts                             │
│  ┌──────────────────────────────┐                  │
│  │ 1. pulseaudio --start        │                  │
│  │ 2. termux-x11 :0             │  (external APK) │
│  │ 3. proot-distro login ...    │                  │
│  │ 4. startxfce4                │                  │
│  └──────────────────────────────┘                  │
└──────────────────────────────────────────────────┘
```

**Prinsip kunci:** App adalah UI wrapper. Semua logika tetap di bash script arinanoX. App hanya menjalankan command dan menampilkan output.

---

## 3. Perbandingan dengan DroidDesk (ATM)

| Komponen | DroidDesk (sumber ATM) | arinanoX (hasil) |
|----------|------------------------|-------------------|
| **main.dart** | 50 baris, welcome/home routing | 40 baris, langsung ke home |
| **app_state.dart** | ~500 baris, 7 state flags, chroot+native | ~200 baris, 3 state flags, proot-only |
| **platform_bridge.dart** | ~200 baris, 15 methods | ~70 baris, 5 methods |
| **theme** | DroidTheme — indigo/cyan | ArinanoxTheme — teal/amber |
| **home_screen.dart** | ~700 baris, setup wizard + actions | ~400 baris, actions + system info |
| **terminal** | Copy langsung | Copy langsung |
| **Kotlin MainActivity** | ~400 baris, chroot+root+bootstrap | ~100 baris, shell only |
| **Kotlin helpers** | 14 files (runtime, x11, compositor) | 2 files (shell + device info) |

---

## 4. GitHub Actions

### build-image.yml (dimodifikasi)
- **Trigger:** Manual (`workflow_dispatch`) + input tag
- **Build:** Docker image ARM64 → push ke GHCR
- **Tags:** `ghcr.io/arinadi/arinanox:${{ inputs.tag }}` + `1.0.${{ run_number }}`

### build-apk.yml (baru)
- **Trigger:** Manual (`workflow_dispatch`)
- **Flutter:** v3.29.0 stable
- **Java:** Temurin 17
- **Output:** APK artifact (30 hari) + optional GitHub Release draft
- **Tidak ada push trigger** — tidak spam CPU

---

## 5. Checklist Sebelum Commit

- [ ] Tambahkan `assets/icons/logo.png` (96x96 atau 512x512 PNG)
- [ ] Copy font files ke `app/assets/fonts/` (JetBrainsMono-Regular.ttf, JetBrainsMono-Bold.ttf)
- [ ] Sumber font: download dari [JetBrains Mono releases](https://github.com/JetBrains/JetBrainsMono/releases) atau reuse dari DroidDesk `app/assets/fonts/`
- [ ] Test `flutter pub get` di environment Flutter 3.29+
- [ ] Test `flutter analyze` — pastikan tidak ada error
- [ ] Set `JAVA_HOME` ke JDK 17 di environment build lokal
- [ ] Jalankan `flutter build apk --debug` untuk test build lokal
- [ ] Commit semua file ke branch `main`
- [ ] Trigger `Build arinanoX Image` workflow manual untuk test
- [ ] Trigger `Build arinanoX APK` workflow manual untuk test

---

## 6. Next Steps (Diluar Scope Phase Ini)

| Fase | Apa | Prioritas |
|------|-----|-----------|
| Polish | Battery optimization dialog di welcome screen | Low |
| Phase 2 | Embedded X11 server (copy jniLibs + C dari DroidDesk) | Medium |
| Phase 3 | Proot menu bridge (adapt `proot-menu-sync.sh`) | Low |
| Phase 4 | Pi bridge revival (adapt `pi-launch_phone.sh`) | Low |
| Enhancement | Setup wizard untuk first-time install (panggil `bootstrap.sh`) | Medium |

---

## 7. Known Issues & Gotchas

1. **Font files not bundled yet** — `pubspec.yaml` references `assets/fonts/` tapi filenya belum ada. Copy dari DroidDesk `app/assets/fonts/` atau download dari JetBrains.
2. **Logo placeholder** — `pubspec.yaml` references `assets/icons/logo.png` untuk launcher icon.
3. **APK signing** — `build.gradle.kts` menggunakan debug key untuk release build (sama seperti DroidDesk). Untuk distribusi publik, perlu proper signing key.
4. **minSdk 28** — DroidDesk pakai ini untuk bypass W^X restriction. arinanoX app tidak perlu ini (tidak ada native code execution), tapi disamakan untuk konsistensi.
5. **Termux dependency** — App berasumsi `$HOME/.arinanox/` ada di Termux home. Jika user install app tanpa Termux, semua status akan "not installed" (graceful degradation).
