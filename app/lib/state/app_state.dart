import 'package:flutter/material.dart';
import 'package:arinanox_app/services/shell_bridge.dart';

/// Central state for arinanoX companion app.
///
/// ATM from DroidDesk's AppState. Heavily simplified:
/// - No setup wizard (arinanoX is pre-installed via Termux scripts)
/// - No distro/DE picker (opinionated: Debian 13 + XFCE)
/// - No root/chroot logic (proot-only)
/// - Focus on: status, start/stop, terminal, health check, snapshots
/// - Update/rollback removed — use CLI: arinanox update, arinanox rollback
class AppState extends ChangeNotifier {
  // ── State ──
  bool _isInstalled = false;
  bool _isRunning = false;
  String _version = '';
  String _containerSize = '';
  int _layeredPackages = 0;

  // ── Device Info ──
  Map<String, dynamic> _deviceInfo = {};

  // ── Error ──
  String? _errorMessage;

  // Terminal
  final List<String> _terminalOutput = [
    'arinanoX Terminal\nType commands below.\n',
  ];

  // ── Getters ──
  bool get isInstalled => _isInstalled;
  bool get isRunning => _isRunning;
  String get version => _version;
  String get containerSize => _containerSize;
  int get layeredPackages => _layeredPackages;
  Map<String, dynamic> get deviceInfo => _deviceInfo;
  String? get errorMessage => _errorMessage;
  List<String> get terminalOutput => _terminalOutput;

  String get gpuType {
    final vendor = _deviceInfo['gpuVendor']?.toString() ?? '';
    if (vendor.contains('adreno')) return 'Adreno (Snapdragon)';
    if (vendor.contains('mali')) return 'Mali (MediaTek/Exynos)';
    if (vendor.contains('powervr')) return 'PowerVR';
    return 'Unknown GPU';
  }

  // ── Initialization ──

  Future<void> initialize() async {
    ArinanoxShell.onTerminalOutput = (text) {
      if (_terminalOutput.isEmpty) _terminalOutput.add('');
      final lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (i == 0) {
          _terminalOutput[_terminalOutput.length - 1] += lines[i];
        } else {
          _terminalOutput.add(lines[i]);
        }
      }
      notifyListeners();
    };

    await refreshStatus();
    await loadDeviceInfo();
  }

  Future<void> refreshStatus() async {
    try {
      _errorMessage = null;

      // Check if arinanoX is installed
      final installed = await _runQuick('test -d ~/.arinanox && echo YES || echo NO');
      _isInstalled = installed.trim() == 'YES';

      if (_isInstalled) {
        // Check if desktop is running
        final running = await _runQuick(
          'pgrep -f "xfce4-session" > /dev/null 2>&1 && echo YES || echo NO',
        );
        _isRunning = running.trim() == 'YES';

        // Get version
        _version = (await _runQuick(
          'cat ~/.arinanox/VERSION 2>/dev/null || echo "unknown"',
        )).trim();

        // Get container size
        _containerSize = (await _runQuick(
          'du -sh /data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox 2>/dev/null | cut -f1 || echo "N/A"',
        )).trim();

        // Get layered packages count
        final countStr = (await _runQuick(
          'wc -l < ~/.arinanox/layers.txt 2>/dev/null || echo "0"',
        )).trim();
        _layeredPackages = int.tryParse(countStr) ?? 0;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh status: $e';
      notifyListeners();
    }
  }

  Future<String> _runQuick(String command) async {
    try {
      return await ArinanoxShell.executeCommand(command);
    } catch (_) {
      return '';
    }
  }

  Future<void> loadDeviceInfo() async {
    try {
      _deviceInfo = await ArinanoxShell.getDeviceInfo();
      notifyListeners();
    } catch (_) {
      // Non-fatal
    }
  }

  // ── Actions ──

  Future<void> startDesktop() async {
    try {
      _errorMessage = null;
      _terminalOutput.add('\$ arinanox start\n');
      notifyListeners();
      await ArinanoxShell.executeCommand('arinanox start');
      await refreshStatus();
    } catch (e) {
      _errorMessage = 'Failed to start: $e';
      notifyListeners();
    }
  }

  Future<void> stopDesktop() async {
    try {
      _errorMessage = null;
      _terminalOutput.add('\$ arinanox stop\n');
      notifyListeners();
      await ArinanoxShell.executeCommand('arinanox stop');
      await refreshStatus();
    } catch (e) {
      _errorMessage = 'Failed to stop: $e';
      notifyListeners();
    }
  }

  Future<void> runDoctor() async {
    try {
      _errorMessage = null;
      _terminalOutput.add('\$ arinanox doctor\n');
      notifyListeners();
      await ArinanoxShell.executeCommand('arinanox doctor');
    } catch (e) {
      _errorMessage = 'Doctor failed: $e';
      notifyListeners();
    }
  }

  Future<void> createSnapshot() async {
    try {
      _errorMessage = null;
      _terminalOutput.add('\$ arinanox snapshot\n');
      notifyListeners();
      await ArinanoxShell.executeCommand('arinanox snapshot');
    } catch (e) {
      _errorMessage = 'Snapshot failed: $e';
      notifyListeners();
    }
  }

  Future<void> executeCommand(String command) async {
    try {
      _terminalOutput.add('\$ $command\n');
      notifyListeners();
      await ArinanoxShell.executeCommand(command);
    } catch (e) {
      _terminalOutput.add('Error: $e\n');
      notifyListeners();
    }
  }

  Future<void> interruptCommand() async {
    try {
      await ArinanoxShell.interruptCommand();
      _terminalOutput.add('\n^C (Command interrupted)\n');
      notifyListeners();
    } catch (_) {}
  }

  void clearTerminal() {
    _terminalOutput.clear();
    _terminalOutput.add('arinanoX Terminal\nType commands below.\n');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
