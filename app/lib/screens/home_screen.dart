import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arinanox_app/theme/arinanox_theme.dart';
import 'package:arinanox_app/state/app_state.dart';
import 'package:arinanox_app/services/shell_bridge.dart';
import 'package:arinanox_app/screens/terminal_screen.dart';

/// Home dashboard — main screen after app launch.
/// ATM from DroidDesk's HomeScreen, simplified for arinanoX.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ArinanoxTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: ArinanoxTheme.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.terminal_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('arinanoX', style: ArinanoxTheme.headingSm),
                          Text(
                            state.isRunning ? 'Desktop Running' : 'Ready',
                            style: ArinanoxTheme.bodySm.copyWith(
                              color: state.isRunning
                                  ? ArinanoxTheme.accent
                                  : ArinanoxTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showSettings(context),
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: ArinanoxTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Error Banner ──
              if (state.errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ArinanoxTheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ArinanoxTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: ArinanoxTheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: ArinanoxTheme.bodySm.copyWith(
                                color: ArinanoxTheme.error,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16,
                                color: ArinanoxTheme.textMuted),
                            onPressed: state.clearError,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 24, minHeight: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Status Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildStatusCard(state)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, duration: 500.ms),
                ),
              ),

              // ── Not Installed Banner ──
              if (!state.isInstalled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Card(
                      color: ArinanoxTheme.warning.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('arinanoX not installed',
                                style: ArinanoxTheme.headingSm.copyWith(
                                    color: ArinanoxTheme.warning)),
                            const SizedBox(height: 8),
                            Text(
                              'Run this command in Termux to install:',
                              style: ArinanoxTheme.bodySm,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                'curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash',
                                style: ArinanoxTheme.monoSm.copyWith(
                                  color: ArinanoxTheme.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  ),
                ),

              // ── Quick Actions ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text('QUICK ACTIONS', style: ArinanoxTheme.label)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    children: [
                      // ── Launch / Stop ──
                      _ActionCard(
                        icon: state.isRunning
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_rounded,
                        title: state.isRunning
                            ? 'Stop Desktop'
                            : 'Launch Desktop',
                        subtitle: state.isRunning
                            ? 'Shutdown XFCE session'
                            : 'Start Debian 13 + XFCE desktop',
                        color: state.isRunning
                            ? ArinanoxTheme.error
                            : ArinanoxTheme.primary,
                        gradient: state.isRunning
                            ? null
                            : ArinanoxTheme.primaryGradient,
                        enabled: state.isInstalled,
                        onTap: () async {
                          if (state.isRunning) {
                            await state.stopDesktop();
                          } else {
                            await state.startDesktop();
                          }
                        },
                      ),

                      const SizedBox(height: 10),

                      // ── Terminal ──
                      _ActionCard(
                        icon: Icons.terminal_rounded,
                        title: 'Terminal',
                        subtitle: 'Open a proot shell to run commands',
                        color: ArinanoxTheme.secondary,
                        enabled: state.isInstalled,
                        onTap: () => _showTerminal(context, state),
                      ),

                      const SizedBox(height: 10),

                      // ── Doctor (health check) ──
                      _ActionCard(
                        icon: Icons.health_and_safety_rounded,
                        title: 'Health Check',
                        subtitle: 'Run doctor.sh to diagnose issues',
                        color: ArinanoxTheme.primaryLight,
                        enabled: state.isInstalled,
                        onTap: () async {
                          await state.runDoctor();
                          _showTerminal(context, state);
                        },
                      ),

                      const SizedBox(height: 10),

                      // ── Snapshot ──
                      _ActionCard(
                        icon: Icons.camera_alt_rounded,
                        title: 'Snapshot',
                        subtitle:
                            'Create a restore point before making changes',
                        color: ArinanoxTheme.primary,
                        enabled: state.isInstalled,
                        onTap: state.createSnapshot,
                      ),

                      // ── Update Scripts ──
                      _ActionCard(
                        icon: Icons.sync_rounded,
                        title: 'Update Scripts',
                        subtitle:
                            'Download latest launchers + scripts from GitHub',
                        color: ArinanoxTheme.primary,
                        gradient: ArinanoxTheme.primaryGradient,
                        enabled: state.isInstalled && !state.isUpdating,
                        onTap: () async {
                          await state.updateScripts();
                          _showTerminal(context, state);
                        },
                      ),

                    ]
                        .animate(interval: 80.ms)
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.05, duration: 400.ms),
                  ),
                ),
              ),

              // ── System Info ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Text('SYSTEM', style: ArinanoxTheme.label)
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: _buildSystemInfo(state)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status Card ──

  Widget _buildStatusCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: state.isRunning
            ? const LinearGradient(
                colors: [Color(0xFF0D2818), Color(0xFF0A1F14)],
              )
            : ArinanoxTheme.cardGradient,
        borderRadius: BorderRadius.circular(ArinanoxTheme.radiusLg),
        border: Border.all(
          color: state.isRunning
              ? ArinanoxTheme.accent.withValues(alpha: 0.3)
              : ArinanoxTheme.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.isRunning
                  ? ArinanoxTheme.accent
                  : ArinanoxTheme.textDim,
              boxShadow: state.isRunning
                  ? [
                      BoxShadow(
                        color: ArinanoxTheme.accent.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isRunning ? 'Desktop Active' : 'Desktop Idle',
                  style: ArinanoxTheme.headingSm.copyWith(
                    color: state.isRunning
                        ? ArinanoxTheme.accent
                        : ArinanoxTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.isInstalled
                      ? 'Debian 13 · XFCE · v${state.version}'
                      : 'Not installed — see instructions below',
                  style: ArinanoxTheme.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── System Info Card ──

  Widget _buildSystemInfo(AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArinanoxTheme.cardBg,
        borderRadius: BorderRadius.circular(ArinanoxTheme.radiusMd),
        border: Border.all(color: ArinanoxTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          _infoRow('Distribution', 'Debian 13 (Trixie)'),
          _divider(),
          _infoRow('Desktop', 'XFCE 4'),
          _divider(),
          _infoRow('GPU', state.gpuType),
          _divider(),
          _infoRow(
            'Renderer',
            state.deviceInfo['graphicsMode']?.toString() ?? 'virgl (auto)',
          ),
          _divider(),
          _infoRow(
            'Container Size',
            state.isInstalled ? state.containerSize : 'N/A',
          ),
          _divider(),
          _infoRow(
            'Layered Packages',
            state.isInstalled ? '${state.layeredPackages}' : 'N/A',
          ),
          _divider(),
          _infoRow(
            'Device',
            '${state.deviceInfo['brand'] ?? ''} ${state.deviceInfo['model'] ?? ''}',
          ),
          _divider(),
          _infoRow(
            'Android',
            '${state.deviceInfo['androidVersion'] ?? ''} (SDK ${state.deviceInfo['sdkVersion'] ?? ''})',
          ),
          _divider(),
          _infoRow(
            'RAM',
            '${state.deviceInfo['totalRamMB'] ?? 'N/A'} MB',
          ),
          _divider(),
          _infoRow(
            'Storage Free',
            '${state.deviceInfo['availableStorageMB'] ?? 'N/A'} MB',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: ArinanoxTheme.bodySm),
          const Spacer(),
          Text(value,
              style:
                  ArinanoxTheme.monoSm.copyWith(color: ArinanoxTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: ArinanoxTheme.surfaceBorder.withValues(alpha: 0.5),
    );
  }

  // ── Settings ──

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArinanoxTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: ArinanoxTheme.headingLg),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.battery_charging_full,
                  color: ArinanoxTheme.warning),
              title: const Text('Battery Optimization'),
              subtitle:
                  const Text('Disable to prevent background session killing'),
              onTap: () {
                ArinanoxShell.requestBatteryOptimization();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: ArinanoxTheme.secondary),
              title: const Text('Refresh Status'),
              subtitle: const Text('Re-check installation and runtime state'),
              onTap: () {
                context.read<AppState>().refreshStatus();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTerminal(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TerminalSheet(state: state),
    );
  }
}

// ── Action Card (ATM from DroidDesk's _ActionCard) ──

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Gradient? gradient;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.gradient,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.04),
                  ],
                ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ArinanoxTheme.headingSm),
                    const SizedBox(height: 2),
                    Text(subtitle, style: ArinanoxTheme.bodySm),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: ArinanoxTheme.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
