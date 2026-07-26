# Effort Comparison: Flutter vs Kotlin Native untuk arinanoX Companion App

> **Konteks:** ATM (Amati Tiru Modifikasi) dari DroidDesk Flutter app
> **Target:** arinanoX Android companion app
> **Tanggal:** 2026-07-26

---

## TL;DR

| | Flutter (ATM DroidDesk) | Kotlin Native (Compose) |
|---|---|---|
| **Effort total** | 🟢 2-3 minggu | 🟡 4-6 minggu |
| **Code reuse dari DroidDesk** | ~60-70% (copy-paste + modifikasi) | ~10-15% (hanya logika, rewrite UI) |
| **Learning curve** | Dart + Flutter (jika belum familiar) | Kotlin + Compose (jika belum familiar) |
| **Embedded X11** | Siap pakai (PlatformView sudah jadi) | Harus bikin dari nol (SurfaceView + JNI) |
| **Terminal widget** | Copy-paste dari DroidDesk | Harus bikin custom |
| **Maintenance** | Dua codebase (bash + Dart) | Dua codebase (bash + Kotlin) |
| **Performance** | 60fps (ada overhead bridge) | 60fps (native, no bridge overhead) |
| **APK size** | +15-20MB (Flutter engine) | +3-5MB (pure Compose) |

**Rekomendasi:** Flutter untuk Phase 1 (cepat, banyak reuse). Kotlin worth dipertimbangkan jika tim sudah expert Kotlin/Compose dan ada rencana jangka panjang untuk deep native integration.

---

## 1. Breakdown per Komponen — ATM vs Rewrite

### 1.1 State Management

**DroidDesk Flutter (langsung ATM):**
```dart
// app/lib/state/app_state.dart — ~500 lines
// Bisa copy-paste struktur, ganti isi method:
class ArinanoxState extends ChangeNotifier {
  // GANTI: _isBootstrapReady → _isInstalled
  // GANTI: _deInstalled → _isRunning  
  // GANTI: downloadRootfs() → execBootstrap()
  // TETAP: pola ChangeNotifier + notifyListeners()
}
```
**Effort: 1-2 jam** — rename field, ganti implementasi method.

**Kotlin Compose (rewrite):**
```kotlin
// Harus bikin dari nol dengan StateFlow/MutableState
class ArinanoxViewModel : ViewModel() {
    private val _isRunning = MutableStateFlow(false)
    val isRunning: StateFlow<Boolean> = _isRunning
    
    // Pola mirip ChangeNotifier, tapi syntax beda total
    fun start() {
        viewModelScope.launch {
            shellBridge.execute("arinanox start")
            _isRunning.value = true
        }
    }
}
```
**Effort: 3-4 jam** — rewrite dari nol, test ulang.

### 1.2 Platform Bridge (Shell Execution)

**DroidDesk Flutter (ATM):**
```dart
// app/lib/services/platform_bridge.dart — ~200 lines
// 15 method, tinggal ganti nama + url:
static Future<ProcessResult> exec(String command) async {
  return await _channel.invokeMethod('executeCommand', {
    'command': command,
    'workDir': '/data/data/com.termux/files/home',
  });
}
```

**Kotlin side juga sudah jadi (copy-paste):**
```kotlin
// DroidDesk sudah punya ShellExecutor.kt
// Tinggal copas ke project arinanoX, ganti package name
```

**Effort: 1 jam** — copy dua sisi, rename.

**Kotlin Compose (pure native — no MethodChannel):**
```kotlin
// Gak perlu MethodChannel! Langsung akses Runtime:
class ShellExecutor {
    fun exec(command: String): ProcessResult {
        val process = Runtime.getRuntime().exec(
            arrayOf("sh", "-c", command),
            null,
            File("/data/data/com.termux/files/home")
        )
        return process.waitFor()
    }
}
```
**Effort: 2 jam** — lebih simpel, tapi harus bikin dari nol + bungkus coroutine.

### 1.3 UI Screens

Ini area paling besar bedanya.

#### Welcome Screen

**DroidDesk Flutter (ATM):**
- ~300 lines, animasi fade-in, feature chips
- Copy-paste `welcome_screen.dart`, ganti text + logo
- Effort: **30 menit**

**Kotlin Compose (rewrite):**
- Harus bikin animasi dari nol (AnimatedVisibility, Crossfade)
- Effort: **3-4 jam**

#### Home Dashboard

**DroidDesk Flutter (ATM):**
- ~500 lines, layout card grid
- Copy `home_screen.dart`, ganti widget konten
- `_StatusCard`, `_ActionCard`, `_SystemInfoCard` langsung pakai
- Effort: **2-3 jam**

**Kotlin Compose (rewrite):**
- Harus bikin layout dari nol (LazyVerticalGrid, Card)
- Effort: **6-8 jam**

#### Terminal Screen

**DroidDesk Flutter (ATM):**
- ~200 lines, scrollable output + input field
- Copy-paste `_TerminalSheet`, ganti command prefix
- Effort: **1 jam**

**Kotlin Compose (rewrite):**
- Harus bikin custom terminal widget
- LazyColumn + TextField + auto-scroll logic
- Effort: **4-5 jam**

### 1.4 Embedded X11 Server (Phase 2)

Ini adalah pembunuh — area dengan delta effort paling besar.

**DroidDesk Flutter — sudah jadi:**
```
app/android/app/src/main/
├── cpp/
│   ├── CMakeLists.txt         # Build config untuk .so
│   ├── socket_hook.c          # Hook socket() untuk redirect path
│   └── x11_bridge.c           # JNI bridge untuk SurfaceView
├── jniLibs/arm64-v8a/
│   ├── libwlroots.so          # Prebuilt dari fetch_deps.sh
│   ├── libwayland-server.so
│   ├── libxkbcommon.so
│   └── ... (6 file)
└── kotlin/
    └── X11CompositorView.kt   # PlatformView wrapper
```

**ATM:** Copy semua native code + jniLibs. Effort: **2-3 hari** (perlu test compatibility).

**Kotlin Compose — harus bikin:**
- Sama seperti di atas untuk native layer (C + JNI tetap sama)
- Tapi UI wrapper-nya: ganti `AndroidViewSurface` (Flutter) jadi `AndroidView` (Compose)
- Effort: **5-7 hari** — C/JNI layer tetap bisa copy, tapi Compose wrapper harus bikin sendiri.

---

## 2. Hitungan Total Effort (Phase 1 MVP)

### Flutter (ATM DroidDesk)

| Komponen | Effort | Reuse |
|----------|--------|-------|
| Project scaffold | 1 jam | — |
| State management | 2 jam | 80% |
| Shell bridge (Flutter side) | 1 jam | 90% |
| Shell bridge (Kotlin side) | 1 jam | 95% |
| Welcome screen | 0.5 jam | 90% |
| Home dashboard | 3 jam | 70% |
| Terminal screen | 1 jam | 85% |
| Theme/styling | 2 jam | 60% |
| Settings screen | 2 jam | — (baru) |
| Setup wizard (bootstrap.sh) | 4 jam | 50% |
| Testing + bugfix | 3 jam | — |
| APK build config | 1 jam | — |
| **TOTAL** | **~22 jam** | |

### Kotlin Compose (Rewrite)

| Komponen | Effort | Reuse |
|----------|--------|-------|
| Project scaffold | 2 jam | — |
| State management (ViewModel) | 4 jam | 20% (pola) |
| Shell executor (pure Kotlin) | 2 jam | 0% |
| Welcome screen | 4 jam | 10% (desain) |
| Home dashboard | 8 jam | 10% (desain) |
| Terminal screen | 5 jam | 10% (desain) |
| Theme/styling | 4 jam | 0% |
| Settings screen | 3 jam | — (baru) |
| Setup wizard | 6 jam | 10% (flow) |
| Testing + bugfix | 5 jam | — |
| APK build config | 1 jam | — |
| **TOTAL** | **~44 jam** | |

**Rasio: Kotlin ~2x effort Flutter untuk Phase 1.**

---

## 3. Faktor Kualitatif yang Mempengaruhi Keputusan

### 3.1 Kapan Flutter lebih baik (ATM jalan)

- ✅ **Kecepatan delivery** — 2-3 minggu vs 4-6 minggu
- ✅ **DroidDesk sebagai referensi hidup** — bisa diff langsung, lihat cara mereka solve problem
- ✅ **Embedded X11 Phase 2** — DroidDesk sudah solved, tinggal copas
- ✅ **Android minima support** — Flutter handle backward compat
- ✅ **Dart null safety + hot reload** — development loop cepat

### 3.2 Kapan Kotlin lebih baik

- ✅ **Tim sudah expert Kotlin/Compose, gak familiar Dart** — learning curve Flutter bisa 1-2 minggu sendiri
- ✅ **Deep Android API access** — akses ke Notification, Foreground Service, Battery Manager tanpa bridge
- ✅ **APK lebih kecil** — gak ada Flutter engine (15-20MB)
- ✅ **No bridge overhead** — shell execution langsung, gak perlu serialize/deserialize MethodChannel
- ✅ **Long-term maintainability** — satu bahasa untuk seluruh Android layer

### 3.3 Risiko Flutter

- 🔴 Jika tim belum pernah Flutter: learning curve 1-2 minggu (Dart, widget tree, state management)
- 🟡 Flutter engine update bisa breaking
- 🟡 APK lebih besar 15-20MB
- 🟢 MethodChannel overhead negligible untuk use case arinanoX (bukan game, bukan real-time)

### 3.4 Risiko Kotlin

- 🔴 Tidak ada reference implementation — semuanya dari nol
- 🔴 Embedded X11 (Phase 2) — harus riset sendiri, gak bisa copas dari DroidDesk
- 🟡 Compose masih relatif baru, beberapa library belum mature
- 🟢 Performance lebih baik (no bridge, no Dart VM)

---

## 4. Rekomendasi Berdasarkan Skenario

### Skenario A: "Cepat jalan, ATM maksimal" → Flutter ✅

Cocok jika:
- Mau deliver companion app dalam 2-3 minggu
- Tim OK belajar Dart/Flutter (atau hire Flutter dev)
- Phase 2 (embedded X11) penting — DroidDesk sudah solved ini
- APK size 15-20MB bukan masalah

### Skenario B: "Investasi jangka panjang, full native" → Kotlin ✅

Cocok jika:
- Tim sudah kuat di Kotlin/Compose
- Gak buru-buru (4-6 minggu)
- Mau deep Android integration (notification, foreground service, etc.)
- APK size penting (target di bawah 10MB)
- Phase 2 (embedded X11) gak prioritas, atau mau riset sendiri

### Skenario C: Hybrid (rekomendasi saya) → Flutter dulu, Kotlin nanti

1. **Phase 1: Flutter ATM** — deliver companion app cepat, sambil belajar struktur DroidDesk
2. **Phase 2: Flutter** — embedded X11 langsung copas dari DroidDesk
3. **Phase 3+: Evaluasi rewrite ke Kotlin** — setelah app stabil, jika butuh deep native access

Alasan: DroidDesk sudah jadi reference implementation yang solid. Lebih baik ATM dulu untuk deliver value, baru optimize later. Ini juga sesuai pola arinanoX yang selalu "jalan dulu, sempurnakan nanti" (lihat audit update-flow yang replace auto-backup dengan simple reinstall).

---

## 5. Catatan: Yang Tetap Sama Regardless of Choice

Baik Flutter maupun Kotlin, layer **bash script arinanoX tetap tidak berubah**. App hanya UI wrapper:

```
┌─────────────────────────────────┐
│  Android App (Flutter/Kotlin)   │  ← Layer baru
│  "Remote control" untuk script  │
├─────────────────────────────────┤
│  Shell Executor                 │  ← MethodChannel (Flutter) atau Runtime.exec (Kotlin)
├─────────────────────────────────┤
│  arinanoX bash scripts          │  ← TIDAK BERUBAH
│  (start.sh, doctor.sh, etc.)    │
├─────────────────────────────────┤
│  proot-distro + Debian 13       │  ← TIDAK BERUBAH
└─────────────────────────────────┘
```

Ini adalah prinsip arsitektur yang sama dengan yang dipakai DroidDesk: native Kotlin mereka juga cuma executor, logika utamanya tetap di bash (`termux-linux-setup.sh`).
