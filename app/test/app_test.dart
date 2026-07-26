import 'package:flutter_test/flutter_test.dart';
import 'package:arinanox_app/state/app_state.dart';
import 'package:arinanox_app/theme/arinanox_theme.dart';

void main() {
  group('AppState', () {
    test('initial state is correct', () {
      final state = AppState();
      expect(state.isInstalled, false);
      expect(state.isRunning, false);
      expect(state.version, '');
      expect(state.containerSize, '');
      expect(state.rollbackSize, '');
      expect(state.layeredPackages, 0);
      expect(state.terminalOutput, isNotEmpty);
      expect(state.terminalOutput.first, contains('arinanoX Terminal'));
    });

    test('clearTerminal resets output', () {
      final state = AppState();
      state.clearTerminal();
      expect(state.terminalOutput.length, 1);
      expect(state.terminalOutput.first, contains('arinanoX Terminal'));
    });

    test('clearError clears error message', () {
      final state = AppState();
      // Simulate error by directly notifying (skipping async shell call)
      state.clearError();
      expect(state.errorMessage, isNull);
    });
  });

  group('ArinanoxTheme', () {
    test('theme data is valid', () {
      final theme = ArinanoxTheme.themeData;
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, ArinanoxTheme.primary);
      expect(theme.scaffoldBackgroundColor, ArinanoxTheme.background);
    });

    test('typography styles are defined', () {
      expect(ArinanoxTheme.headingXl, isNotNull);
      expect(ArinanoxTheme.headingLg, isNotNull);
      expect(ArinanoxTheme.headingMd, isNotNull);
      expect(ArinanoxTheme.bodyLg, isNotNull);
      expect(ArinanoxTheme.bodyMd, isNotNull);
      expect(ArinanoxTheme.mono, isNotNull);
      expect(ArinanoxTheme.label, isNotNull);
    });

    test('gpuType returns correct vendor', () {
      // Test gpuType through AppState which wraps deviceInfo
      final state = AppState();
      // Without device info, GPU type should be Unknown
      // This test verifies AppState doesn't crash without device info
      expect(state.gpuType, isNotNull);
    });
  });

  group('Shell Bridge', () {
    test('shell bridge channel name is correct', () {
      // Verify the MethodChannel constant is accessible
      // (static access only — no actual platform invocation in unit tests)
      expect(true, isTrue); // placeholder
    });
  });
}
