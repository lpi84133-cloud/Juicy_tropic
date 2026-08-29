import 'package:flutter/material.dart';

import 'core/design.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'services/bootstrap_service.dart';
import 'widgets/ui.dart';

class JuicyApp extends StatefulWidget {
  const JuicyApp({super.key});

  @override
  State<JuicyApp> createState() => _JuicyAppState();
}

class _JuicyAppState extends State<JuicyApp> {
  AppSession? _session;

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return MaterialApp(
      title: 'Juicy Tropic',
      debugShowCheckedModeBanner: false,
      theme: D.theme(),
      builder: (context, child) {
        final page = child ?? const SizedBox.shrink();
        if (session == null) return page;
        return ProgressScope(store: session.store, child: page);
      },
      home: session == null
          ? LoadingScreen(onReady: (s) => setState(() => _session = s))
          : const HomeScreen(),
    );
  }
}
