import 'package:flutter/material.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../core/orientation.dart';
import '../services/bootstrap_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, required this.onReady});
  final void Function(AppSession session) onReady;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    unlockForLoading();
    _boot();
  }

  Future<void> _boot() async {
    final session = await BootstrapService.run((value, _) {
      if (!mounted) return;
      setState(() => _progress = value);
    });
    if (!mounted || _launching) return;
    _launching = true;
    await lockPortrait();
    if (!mounted) return;
    widget.onReady(session);
  }

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final art = landscape ? AppAssets.loadingLandscape : AppAssets.loadingPortrait;
    final pct = (_progress * 100).floor().clamp(0, 100);

    return Scaffold(
      backgroundColor: D.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(art, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  D.ink.withValues(alpha: 0.12),
                  D.ink.withValues(alpha: 0.28),
                  D.ink.withValues(alpha: 0.62),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                landscape ? 64 : 32,
                16,
                landscape ? 64 : 32,
                landscape ? 22 : 36,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$pct%', style: D.numeric(40, wght: 800)),
                  const SizedBox(height: 14),
                  _LoadRail(progress: _progress),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadRail extends StatelessWidget {
  const _LoadRail({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final v = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: D.ink.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: D.hairline(0.16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 6,
                width: ((c.maxWidth - 4) * v).clamp(0.0, c.maxWidth - 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(colors: [D.teal, D.lime]),
                  boxShadow: [BoxShadow(color: D.lime.withValues(alpha: 0.55), blurRadius: 14)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
