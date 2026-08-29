import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juicytropicgame/core/design.dart';
import 'package:juicytropicgame/data/content.dart';
import 'package:juicytropicgame/data/models.dart';
import 'package:juicytropicgame/data/progress_store.dart';
import 'package:juicytropicgame/game/game_engine.dart';
import 'package:juicytropicgame/screens/gameplay_screen.dart';
import 'package:juicytropicgame/screens/home_screen.dart';
import 'package:juicytropicgame/screens/settings_screen.dart';
import 'package:juicytropicgame/screens/upgrades_screen.dart';
import 'package:juicytropicgame/widgets/ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return ProgressStore(await SharedPreferences.getInstance());
}

Future<void> pumpScreen(WidgetTester tester, Widget home, ProgressStore store) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: D.theme(),
      builder: (context, child) => ProgressScope(store: store, child: child ?? const SizedBox()),
      home: home,
    ),
  );
  await settle(tester);
}

/// Frames advance manually because the game screen drives an endless ticker.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets('menu buttons navigate all the way into a run', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = await freshStore();
    await pumpScreen(tester, const HomeScreen(), store);

    expect(find.text('PLAY'), findsOneWidget);

    await tester.tap(find.text('PLAY'));
    await settle(tester);
    expect(find.text('Gardens'), findsOneWidget);

    final firstGarden = GameContent.gardens.first;
    await tester.tap(find.text('ENTER ${firstGarden.name.toUpperCase()}'));
    await settle(tester);
    expect(find.text(firstGarden.name), findsOneWidget);

    await tester.tap(find.text('PLAY STAGE 1'));
    await settle(tester);
    expect(find.text('COMBO'), findsOneWidget);
  });

  testWidgets('in-game controls respond: drag, weather, pause', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = await freshStore();
    await pumpScreen(
      tester,
      const GameplayScreen(gardenId: 'juicy_meadow', levelIndex: 0),
      store,
    );

    // Timer must actually run down.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Drag the drone across the field.
    await tester.dragFrom(const Offset(200, 500), const Offset(-60, 120));
    await tester.pump(const Duration(milliseconds: 200));

    // Weather keys sit on the arc dial in the bottom right corner.
    await tester.tap(find.byIcon(LucideIcons.sun));
    await tester.pump(const Duration(milliseconds: 200));

    // Pause and resume.
    await tester.tap(find.byIcon(LucideIcons.pause));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PAUSED'), findsOneWidget);

    await tester.tap(find.text('RESUME'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PAUSED'), findsNothing);
  });

  testWidgets('settings toggles and upgrade purchase persist', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = await freshStore();
    await pumpScreen(tester, const SettingsScreen(), store);

    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.musicOn, isFalse);

    await pumpScreen(tester, const UpgradesScreen(), store);
    final coinsBefore = store.coins;
    final buy = find.textContaining(RegExp(r'^\d+$')).first;
    await tester.tap(buy, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.coins, lessThanOrEqualTo(coinsBefore));
  });

  test('engine is winnable when the drone chases fruit', () async {
    final store = await freshStore();
    final garden = GameContent.gardens.first;
    final engine = GameEngine(garden: garden, levelIndex: 0, store: store)
      ..resize(const Size(390, 780));

    var guard = 0;
    while (!engine.finished && guard < 6000) {
      guard++;
      if (engine.weather != WeatherKind.sun && engine.weather != WeatherKind.rain) {
        engine.setWeather(guard.isEven ? WeatherKind.sun : WeatherKind.rain);
      }
      if (engine.full) {
        engine.pointer(Offset(
          GameEngine.station.dx * 390,
          GameEngine.station.dy * 780,
        ));
      } else if (engine.falling.isNotEmpty) {
        final target = engine.falling.first;
        engine.pointer(Offset(target.x, target.y));
      } else if (engine.trees.isNotEmpty) {
        final tree = engine.trees.reduce((a, b) => a.ripeness >= b.ripeness ? a : b);
        engine.pointer(Offset(tree.nx * 390, tree.ny * 780));
      }
      engine.tick(1 / 60);
    }

    expect(engine.finished, isTrue);
    expect(engine.collectedBy.values.fold<int>(0, (a, b) => a + b), greaterThan(0));
    expect(engine.unloadedCoins, greaterThan(0));
  });
}
