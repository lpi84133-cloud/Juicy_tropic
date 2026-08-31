import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../canopy/dew_sense.dart';
import '../canopy/fruit_bell.dart';
import '../canopy/grove_cache.dart';
import '../canopy/grove_probe.dart';
import '../canopy/trail_scent.dart';
import '../core/assets.dart';
import '../core/design.dart';
import '../grove/grove_mark.dart';
import '../mist/drought_pane.dart';
import '../mist/juice_pane.dart';
import '../mist/rustle_invite.dart';
import '../sap/dawn_pick.dart';
import '../sap/harvest_lane.dart';
import '../services/bootstrap_service.dart';
import '../screens/home_screen.dart';
import 'dawn_steer.dart';
import 'orchard_root.dart';
import 'prime_shell.dart';

class DawnGuide extends StatefulWidget {
  const DawnGuide({
    super.key,
    required this.cache,
    required this.dew,
    required this.scent,
    required this.probe,
    required this.bell,
  });

  final GroveCache cache;
  final DewSense dew;
  final TrailScent scent;
  final GroveProbe probe;
  final FruitBell bell;

  @override
  State<DawnGuide> createState() => _DawnGuideState();
}

class _DawnGuideState extends State<DawnGuide> with TickerProviderStateMixin {
  late final AnimationController _dots;
  late final AnimationController _bar;
  Timer? _drip;
  bool _routed = false;
  double _ceiling = 0.18;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _bar = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    _startDrip();
    _run();
  }

  @override
  void dispose() {
    _drip?.cancel();
    _dots.dispose();
    _bar.dispose();
    super.dispose();
  }

  void _startDrip() {
    _drip?.cancel();
    _drip = Timer.periodic(const Duration(milliseconds: 220), (_) {
      if (!mounted || _routed) return;
      final double next = (_bar.value + 0.014).clamp(0.0, _ceiling);
      if (next > _bar.value) _bar.value = next;
    });
  }

  Future<void> _run() async {
    await primeShell();
    final DawnSteer steer = DawnSteer(
      cache: widget.cache,
      dew: widget.dew,
      scent: widget.scent,
      probe: widget.probe,
      bell: widget.bell,
    );

    DawnPick pick;
    try {
      pick = await steer
          .decide(
            onFill: (double value) {
              if (!mounted) return;
              _ceiling = value.clamp(_ceiling, 1.0);
              if (value >= _bar.value) _bar.value = value.clamp(0.0, 1.0);
            },
          )
          .timeout(
            GroveMark.routeBudget,
            onTimeout: () => widget.cache.readLane() == HarvestLane.grove
                ? const GrovePick()
                : const DryPick(),
          );
    } catch (_) {
      pick = widget.cache.readLane() == HarvestLane.grove
          ? const GrovePick()
          : const DryPick();
    }

    switch (pick) {
      case DryPick():
        await _toDry();
      case JuicePick(:final String link, :final bool fromPush):
        _bar.value = 1;
        await Future<void>.delayed(const Duration(milliseconds: 180));
        _toJuice(link, fromPush: fromPush);
      case GrovePick():
        await _goGrove();
    }
  }

  Future<void> _goGrove() async {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final AppSession session = await BootstrapService.run((double v, _) {
      final double mapped = 0.28 + (v.clamp(0.0, 1.0) * 0.70);
      if (mapped > _ceiling) _ceiling = mapped;
      if (mapped > _bar.value) _bar.value = mapped;
    });
    _bar.value = 1;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (_routed || !mounted) return;
    _routed = true;
    _drip?.cancel();
    OrchardRoot.attachStore(session.store);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  void _toJuice(String link, {bool fromPush = false}) {
    if (_routed || !mounted) return;
    if (!GroveMark.isWebLink(link)) {
      unawaited(_toDry());
      return;
    }
    _routed = true;
    _drip?.cancel();
    if (!fromPush && widget.cache.shouldOfferRustle()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RustleInvite(
            cache: widget.cache,
            bell: widget.bell,
            dew: widget.dew,
            contentLink: link,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => JuicePane(
            link: link,
            cache: widget.cache,
            bell: widget.bell,
            dew: widget.dew,
            fromPush: fromPush,
          ),
        ),
      );
    }
  }

  Future<void> _toDry() async {
    if (_routed || !mounted) return;
    _routed = true;
    _drip?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DroughtPane(
          onRetryBuild: (_) => DawnGuide(
            cache: widget.cache,
            dew: widget.dew,
            scent: widget.scent,
            probe: widget.probe,
            bell: widget.bell,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final String bg =
        landscape ? AppAssets.loadingLandscape : AppAssets.loadingPortrait;

    return PopScope(
      canPop: false,
      child: IgnorePointer(
        child: Scaffold(
          backgroundColor: D.ink,
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(bg, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Color(0x88000000)],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    landscape ? 64 : 32,
                    0,
                    landscape ? 64 : 32,
                    landscape ? 28 : 46,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _dots,
                        builder: (BuildContext context, _) {
                          const List<String> frames = <String>[
                            '',
                            '.',
                            '. .',
                            '. . .',
                          ];
                          final int n = (_dots.value * 4).floor() % 4;
                          return Text(
                            'Loading${frames[n]}',
                            style: D.label(
                              18,
                              color: Colors.white.withValues(alpha: 0.9),
                              tracking: 1.5,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _bar,
                        builder: (BuildContext context, _) {
                          final double v = _bar.value.clamp(0.0, 1.0);
                          return Column(
                            children: <Widget>[
                              Text(
                                '${(v * 100).floor().clamp(0, 100)}%',
                                style: D.numeric(34, wght: 800),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: v,
                                    minHeight: 12,
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.45),
                                    color: D.lime,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
