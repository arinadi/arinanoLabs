import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arinanox_app/theme/arinanox_theme.dart';
import 'package:arinanox_app/state/app_state.dart';
import 'package:arinanox_app/services/shell_bridge.dart';
import 'package:arinanox_app/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ArinanoxShell.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ArinanoxApp(),
    ),
  );
}

class ArinanoxApp extends StatefulWidget {
  const ArinanoxApp({super.key});

  @override
  State<ArinanoxApp> createState() => _ArinanoxAppState();
}

class _ArinanoxAppState extends State<ArinanoxApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'arinanoX',
      debugShowCheckedModeBanner: false,
      theme: ArinanoxTheme.themeData,
      home: const HomeScreen(),
    );
  }
}
