import 'package:flutter/material.dart';
import 'package:arinanox_app/theme/arinanox_theme.dart';
import 'package:arinanox_app/state/app_state.dart';

/// Terminal bottom sheet — ATM from DroidDesk's _TerminalSheet.
/// Handles command input, streaming output, and interrupt.
class TerminalSheet extends StatefulWidget {
  final AppState state;
  const TerminalSheet({super.key, required this.state});

  @override
  State<TerminalSheet> createState() => _TerminalSheetState();
}

class _TerminalSheetState extends State<TerminalSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _runCommand() async {
    final cmd = _controller.text.trim();
    if (cmd.isEmpty) return;
    _controller.clear();
    await widget.state.executeCommand(cmd);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ArinanoxTheme.textDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.terminal,
                        size: 18, color: ArinanoxTheme.secondary),
                    const SizedBox(width: 8),
                    Text('Terminal', style: ArinanoxTheme.headingSm),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.stop_circle_rounded,
                          color: ArinanoxTheme.error, size: 20),
                      onPressed: () => widget.state.interruptCommand(),
                      tooltip: 'Interrupt (Ctrl+C)',
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('proot · Debian 13',
                        style: ArinanoxTheme.monoSm),
                  ],
                ),
              ),

              const Divider(color: ArinanoxTheme.surfaceBorder, height: 1),

              // Output
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.state.terminalOutput.length,
                  itemBuilder: (context, index) {
                    final line = widget.state.terminalOutput[index];
                    return SelectableText(
                      line,
                      style: ArinanoxTheme.mono.copyWith(
                        color: line.startsWith('\$')
                            ? ArinanoxTheme.accent
                            : ArinanoxTheme.textSecondary,
                        height: 1.4,
                      ),
                    );
                  },
                ),
              ),

              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0D0D),
                  border: Border(
                    top: BorderSide(color: ArinanoxTheme.surfaceBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Text('\$ ',
                        style: ArinanoxTheme.mono.copyWith(
                            color: ArinanoxTheme.accent)),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: ArinanoxTheme.mono.copyWith(fontSize: 13),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter command...',
                          hintStyle:
                              TextStyle(color: ArinanoxTheme.textDim),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _runCommand(),
                        autofocus: true,
                      ),
                    ),
                    IconButton(
                      onPressed: _runCommand,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      color: ArinanoxTheme.primary,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
