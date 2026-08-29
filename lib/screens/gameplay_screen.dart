import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../game/game_engine.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';
import 'garden_select_screen.dart' show weatherColor, weatherIcon;
import 'results_screen.dart';
import 'settings_screen.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.gardenId, required this.levelIndex});
  final String gardenId;
  final int levelIndex;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  GameEngine? _engine;
  bool _paused = false;
  bool _leaving = false;

  GameEngine get engine => _engine!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_engine != null) return;
    _engine = GameEngine(
      garden: GameContent.gardenById(widget.gardenId),
      levelIndex: widget.levelIndex,
      store: ProgressScope.of(context),
    )..addListener(_onEngine);
  }

  void _onEngine() {
    if (!mounted || _leaving || _engine == null || !engine.finished) return;
    _leaving = true;
    final result = engine.toResult();
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      pushPage(
        context,
        ResultsScreen(
          gardenId: widget.gardenId,
          levelIndex: widget.levelIndex,
          result: result,
          collected: engine.collectedBy,
          golden: engine.goldenBy,
          rainUses: engine.rainUses,
          usedStorm: engine.usedStorm,
        ),
        replace: true,
      );
    });
  }

  @override
  void dispose() {
    _engine?.removeListener(_onEngine);
    _engine?.dispose();
    super.dispose();
  }

  void _pause(bool value) => setState(() => _paused = value);

  @override
  Widget build(BuildContext context) {
    if (_engine == null) {
      return const Scaffold(backgroundColor: D.ink, body: SizedBox.expand());
    }
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: D.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: _PlayField(engine: engine, paused: _paused),
          ),
          Positioned.fill(
            child: _HudLayer(
              engine: engine,
              pad: pad,
              onPause: () => _pause(true),
            ),
          ),
          if (_paused)
            _PauseSheet(
              onContinue: () {
                AudioService.instance.close();
                _pause(false);
              },
              onRestart: () => pushPage(
                context,
                GameplayScreen(gardenId: widget.gardenId, levelIndex: widget.levelIndex),
                replace: true,
              ),
              onExit: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

/// Solid plate — no BackdropFilter. Blur on every frame was hitching the run.
class _Plate extends StatelessWidget {
  const _Plate({required this.child, this.padding = const EdgeInsets.all(12), this.radius = 20});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE60A1116),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: D.hairline(0.14)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _HudLayer extends StatefulWidget {
  const _HudLayer({required this.engine, required this.pad, required this.onPause});
  final GameEngine engine;
  final EdgeInsets pad;
  final VoidCallback onPause;

  @override
  State<_HudLayer> createState() => _HudLayerState();
}

class _HudLayerState extends State<_HudLayer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final pad = widget.pad;
    return Stack(
      children: [
        Positioned.fill(child: IgnorePointer(child: _WeatherVeil(engine: e))),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopHud(engine: e, onPause: widget.onPause),
        ),
        Positioned(
          left: pad.left + 14,
          top: 0,
          bottom: 0,
          child: _BasketRail(engine: e),
        ),
        Positioned(
          right: pad.right + 14,
          bottom: pad.bottom + 18,
          child: _WeatherRail(engine: e, onChanged: () => setState(() {})),
        ),
        if (e.full)
          Positioned(
            left: 24,
            right: 24,
            bottom: pad.bottom + 118,
            child: const IgnorePointer(child: _FullBanner()),
          ),
      ],
    );
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({required this.engine, required this.onPause});
  final GameEngine engine;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final secs = e.timeLeft.ceil();
    final mins = (secs ~/ 60).toString().padLeft(2, '0');
    final rest = (secs % 60).toString().padLeft(2, '0');
    final goalValue = e.level.goalAmount == 0 ? 0.0 : e.goalCurrent / e.level.goalAmount;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Plate(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'x${e.combo}',
                        style: D.numeric(28, color: e.combo > 1 ? D.gold : D.text, wght: 800),
                      ),
                      const SizedBox(width: 8),
                      Text('COMBO', style: D.label(11, color: D.textFaint, wght: 800, tracking: 1.4)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 148,
                    child: MeterBar(value: goalValue, height: 8, color: D.lime, glow: goalValue > 0.75),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${e.goalCurrent}/${e.level.goalAmount} · ${_goalWord(e.level.goal)}',
                    style: D.label(11, color: D.textDim, wght: 700, tracking: 0.8),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    _Plate(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          SpriteImg(AppAssets.coin, size: 22),
                          const SizedBox(width: 8),
                          Text('${e.unloadedCoins}', style: D.numeric(18, color: D.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TapScale(
                      onTap: onPause,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xE60A1116),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: D.hairline(0.14)),
                        ),
                        child: const Icon(LucideIcons.pause, size: 22, color: D.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Plate(
                  radius: 40,
                  padding: const EdgeInsets.all(8),
                  child: RingMeter(
                    value: e.timeLeft / e.level.seconds,
                    size: 86,
                    stroke: 5,
                    color: e.timeLeft < 12 ? D.coral : D.teal,
                    child: Text('$mins:$rest', style: D.numeric(16, wght: 800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _goalWord(GoalType goal) {
    switch (goal) {
      case GoalType.collectFruits:
        return 'FRUIT';
      case GoalType.collectGolden:
        return 'GOLDEN';
      case GoalType.reachCombo:
        return 'COMBO';
      case GoalType.earnCoins:
        return 'COINS';
      case GoalType.useStorm:
        return 'STORM RUN';
    }
  }
}

class _BasketRail extends StatelessWidget {
  const _BasketRail({required this.engine});
  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final fill = e.capacity == 0 ? 0.0 : (e.cargo.length / e.capacity).clamp(0.0, 1.0);
    final color = e.full ? D.coral : D.teal;

    return SafeArea(
      child: Center(
        child: _Plate(
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${e.cargo.length}',
                style: D.numeric(18, color: e.full ? D.coral : D.text, wght: 800),
              ),
              const SizedBox(height: 8),
              Container(
                width: 12,
                height: 148,
                decoration: BoxDecoration(
                  color: D.ink.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: D.hairline(0.12)),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: fill == 0 ? 0.0001 : fill,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('${e.capacity}', style: D.numeric(13, color: D.textFaint)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherRail extends StatelessWidget {
  const _WeatherRail({required this.engine, required this.onChanged});
  final GameEngine engine;
  final VoidCallback onChanged;

  static const _order = [WeatherKind.sun, WeatherKind.rain, WeatherKind.wind, WeatherKind.storm];

  @override
  Widget build(BuildContext context) {
    final kinds = _order.where(engine.garden.weathers.contains).toList();
    if (kinds.isEmpty) return const SizedBox.shrink();

    return _Plate(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < kinds.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _WeatherKey(kind: kinds[i], engine: engine, onChanged: onChanged),
          ],
        ],
      ),
    );
  }
}

class _WeatherKey extends StatelessWidget {
  const _WeatherKey({required this.kind, required this.engine, required this.onChanged});
  final WeatherKind kind;
  final GameEngine engine;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final active = engine.weather == kind;
    final locked = engine.switchLock > 0 && !active;
    final color = weatherColor(kind);
    final left = active ? (engine.weatherLeft / 9.5).clamp(0.0, 1.0) : 0.0;

    return TapScale(
      strongHaptic: true,
      onTap: () {
        HapticFeedback.lightImpact();
        engine.setWeather(kind);
        onChanged();
      },
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active) RingMeter(value: left, size: 72, color: color, stroke: 3.5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: active ? color.withValues(alpha: 0.28) : D.glass(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? color : D.hairline(0.16),
                    width: active ? 2 : 1.2,
                  ),
                ),
                child: Icon(weatherIcon(kind), size: 28, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullBanner extends StatelessWidget {
  const _FullBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: D.coral.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            'BASKET FULL — DOCK AT THE STATION',
            textAlign: TextAlign.center,
            style: D.label(11, color: D.ink, wght: 800, tracking: 1.1),
          ),
        ),
      ),
    );
  }
}

class _WeatherVeil extends StatelessWidget {
  const _WeatherVeil({required this.engine});
  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final e = engine;
    if (e.weather == WeatherKind.calm && e.lightning <= 0) return const SizedBox.shrink();
    final color = weatherColor(e.weather);
    return ColoredBox(
      color: color.withValues(alpha: e.lightning > 0 ? 0.18 : (e.weather == WeatherKind.storm ? 0.16 : 0.09)),
      child: const SizedBox.expand(),
    );
  }
}

/// Isolated ticker + camera. HUD does not rebuild with the field.
class _PlayField extends StatefulWidget {
  const _PlayField({required this.engine, required this.paused});
  final GameEngine engine;
  final bool paused;

  @override
  State<_PlayField> createState() => _PlayFieldState();
}

class _PlayFieldState extends State<_PlayField> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _last = Duration.zero;
  Offset _cam = Offset.zero;
  bool _follow = true;
  bool _panning = false;
  static const _zoom = 1.42;

  GameEngine get e => widget.engine;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (widget.paused || e.finished) {
      _last = elapsed;
      return;
    }
    final dt = _last == Duration.zero ? 0.016 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    e.tick(dt.clamp(0.0, 0.033));
    _followDrone(dt.clamp(0.0, 0.033));
    if (mounted) setState(() {});
  }

  Size _world(Size view) => Size(view.width * _zoom, view.height * _zoom);

  void _followDrone(double dt) {
    if (!_follow || _panning) return;
    final view = context.size;
    if (view == null || view.width <= 0) return;
    final world = _world(view);
    final target = Offset(
      e.droneX * world.width - view.width / 2,
      e.droneY * world.height - view.height / 2,
    );
    final k = 1 - math.exp(-3.1 * dt);
    _cam = Offset(
      _cam.dx + (target.dx - _cam.dx) * k,
      _cam.dy + (target.dy - _cam.dy) * k,
    );
    _clampCam(view, world);
  }

  void _clampCam(Size view, Size world) {
    _cam = Offset(
      _cam.dx.clamp(0.0, math.max(0.0, world.width - view.width)),
      _cam.dy.clamp(0.0, math.max(0.0, world.height - view.height)),
    );
  }

  Offset _toWorldNorm(Offset local, Size view, Size world) {
    return Offset(
      ((_cam.dx + local.dx) / world.width).clamp(0.0, 1.0),
      ((_cam.dy + local.dy) / world.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final view = Size(c.maxWidth, c.maxHeight);
        final world = _world(view);
        if (e.field != world) e.resize(world);
        _clampCam(view, world);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (d) {
            _panning = d.pointerCount >= 2;
            if (!_panning) {
              final n = _toWorldNorm(d.localFocalPoint, view, world);
              e.aim(n.dx, n.dy);
              _follow = true;
            }
          },
          onScaleUpdate: (d) {
            if (d.pointerCount >= 2) {
              _panning = true;
              _follow = false;
              _cam -= d.focalPointDelta;
              _clampCam(view, world);
            } else {
              final n = _toWorldNorm(d.localFocalPoint, view, world);
              e.aim(n.dx, n.dy);
              _follow = true;
            }
          },
          onScaleEnd: (_) => _panning = false,
          onTapDown: (d) {
            final n = _toWorldNorm(d.localPosition, view, world);
            e.aim(n.dx, n.dy);
            _follow = true;
          },
          child: RepaintBoundary(
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -_cam.dx,
                    top: -_cam.dy,
                    width: world.width,
                    height: world.height,
                    child: Image.asset(
                      AppAssets.grass,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                      gaplessPlayback: true,
                    ),
                  ),
                  for (final d in e.decor)
                    _worldItem(
                      nx: d.nx,
                      ny: d.ny,
                      size: d.size,
                      world: world,
                      child: Opacity(opacity: 0.92, child: SpriteImg(d.asset)),
                    ),
                  for (final cl in e.clouds)
                    _worldItem(
                      nx: cl.nx + cl.size / (2 * world.width),
                      ny: cl.ny + cl.size * 0.28 / world.height,
                      size: cl.size,
                      world: world,
                      child: Opacity(opacity: 0.48, child: SpriteImg(cl.asset)),
                    ),
                  for (final t in e.trees)
                    _worldItem(
                      nx: t.nx,
                      ny: t.ny,
                      size: 132,
                      world: world,
                      child: _Tree(tree: t),
                    ),
                  _worldItem(
                    nx: GameEngine.beacon.dx,
                    ny: GameEngine.beacon.dy,
                    size: 78,
                    world: world,
                    child: Opacity(opacity: 0.88, child: SpriteImg(AppAssets.beacon)),
                  ),
                  _worldItem(
                    nx: GameEngine.station.dx,
                    ny: GameEngine.station.dy,
                    size: 128,
                    world: world,
                    child: _Station(engine: e),
                  ),
                  for (final f in e.falling)
                    _worldItem(
                      nx: f.x / world.width,
                      ny: f.y / world.height,
                      size: 48,
                      world: world,
                      child: _Fruit(fruit: f),
                    ),
                  _worldItem(
                    nx: e.droneX,
                    ny: e.droneY,
                    size: 96,
                    world: world,
                    child: _Drone(engine: e),
                  ),
                  for (final p in e.pops)
                    Positioned(
                      left: p.x - _cam.dx - 50,
                      top: p.y - _cam.dy - 36,
                      width: 100,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: p.life.clamp(0.0, 1.0),
                          child: Text(
                            p.text,
                            textAlign: TextAlign.center,
                            style: D.numeric(p.golden ? 17 : 15, color: p.golden ? D.gold : D.lime, wght: 800),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _worldItem({
    required double nx,
    required double ny,
    required double size,
    required Size world,
    required Widget child,
  }) {
    return Positioned(
      left: nx * world.width - size / 2 - _cam.dx,
      top: ny * world.height - size / 2 - _cam.dy,
      width: size,
      height: size,
      child: child,
    );
  }
}

class _Tree extends StatelessWidget {
  const _Tree({required this.tree});
  final GardenTree tree;

  @override
  Widget build(BuildContext context) {
    final ripe = tree.ripeness.clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.center,
      children: [
        if (ripe > 0.7)
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [D.gold.withValues(alpha: 0.28 * ripe), Colors.transparent],
              ),
            ),
          ),
        SpriteImg(GameContent.fruit(tree.fruit).treeAsset, size: 118),
        if (tree.stock > 0)
          Positioned(
            bottom: 4,
            child: SizedBox(
              width: 52,
              child: MeterBar(
                value: ripe,
                height: 5,
                color: tree.wetness > 0.45 ? D.sky : D.lime,
              ),
            ),
          ),
      ],
    );
  }
}

class _Fruit extends StatelessWidget {
  const _Fruit({required this.fruit});
  final FallingFruit fruit;

  @override
  Widget build(BuildContext context) {
    final def = GameContent.fruit(fruit.fruit);
    final asset = fruit.golden ? def.goldenAsset : def.asset;
    return DecoratedBox(
      decoration: fruit.golden
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: D.gold.withValues(alpha: 0.5), blurRadius: 14)],
            )
          : const BoxDecoration(),
      child: Opacity(
        opacity: fruit.landed ? (fruit.life / 2.6).clamp(0.35, 1.0) : 1,
        child: SpriteImg(asset),
      ),
    );
  }
}

class _Drone extends StatelessWidget {
  const _Drone({required this.engine});
  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final aura = (engine.collectRadius * 1.35).clamp(64.0, 120.0);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: aura,
          height: aura,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: D.teal.withValues(alpha: 0.30)),
            gradient: RadialGradient(
              colors: [D.teal.withValues(alpha: 0.12), Colors.transparent],
            ),
          ),
        ),
        SpriteImg(AppAssets.drone, size: 86),
      ],
    );
  }
}

class _Station extends StatelessWidget {
  const _Station({required this.engine});
  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final glow = engine.cargo.isEmpty ? 0.0 : (0.25 + engine.stationProximity * 0.6);
    return Stack(
      alignment: Alignment.center,
      children: [
        if (glow > 0)
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [D.lime.withValues(alpha: 0.30 * glow), Colors.transparent],
              ),
            ),
          ),
        SpriteImg(AppAssets.station, size: 118),
      ],
    );
  }
}

class _PauseSheet extends StatelessWidget {
  const _PauseSheet({required this.onContinue, required this.onRestart, required this.onExit});
  final VoidCallback onContinue;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: D.ink.withValues(alpha: 0.78),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text('PAUSED', style: D.label(10, color: D.lime, wght: 800, tracking: 3)),
                const SizedBox(height: 8),
                Text('Take a breath.\nThe garden waits.', style: D.display(26, wght: 600)),
                const SizedBox(height: 24),
                PillButton(label: 'RESUME', onTap: onContinue),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'RESTART',
                        kind: PillKind.ghost,
                        height: 50,
                        trailing: const SizedBox.shrink(),
                        onTap: onRestart,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PillButton(
                        label: 'SETTINGS',
                        kind: PillKind.accent,
                        height: 50,
                        trailing: const SizedBox.shrink(),
                        onTap: () => pushPage(context, const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: 'EXIT TO MENU',
                  kind: PillKind.danger,
                  height: 50,
                  trailing: const SizedBox.shrink(),
                  onTap: onExit,
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}
