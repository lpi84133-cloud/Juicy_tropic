import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/progress_store.dart';
import '../services/audio_service.dart';

class GardenTree {
  GardenTree({
    required this.nx,
    required this.ny,
    required this.fruit,
    required this.stock,
  });

  final double nx;
  final double ny;
  final FruitId fruit;
  int stock;
  double ripeness = 0.15;
  double wetness = 0;
  double dropCd = 0;
}

class DecorItem {
  DecorItem(this.nx, this.ny, this.asset, this.size);
  final double nx;
  final double ny;
  final String asset;
  final double size;
}

class FallingFruit {
  FallingFruit({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.fruit,
    required this.golden,
    required this.groundY,
  });

  double x;
  double y;
  double vx;
  double vy;
  final FruitId fruit;
  final bool golden;
  final double groundY;
  bool landed = false;
  double life = 2.6;
  bool taken = false;
}

class CloudDrift {
  CloudDrift(this.nx, this.ny, this.speed, this.asset, this.size);
  double nx;
  double ny;
  final double speed;
  final String asset;
  final double size;
}

class CargoItem {
  CargoItem(this.fruit, this.golden, this.value);
  final FruitId fruit;
  final bool golden;
  final int value;
}

/// Short-lived floating label that confirms a catch or an unload.
class Pop {
  Pop(this.x, this.y, this.text, this.golden);
  double x;
  double y;
  final String text;
  final bool golden;
  double life = 0.9;
}

class GameEngine extends ChangeNotifier {
  GameEngine({
    required this.garden,
    required this.levelIndex,
    required this.store,
  }) : level = garden.levels[levelIndex] {
    _buildField();
    timeLeft = level.seconds.toDouble();
  }

  final GardenDef garden;
  final int levelIndex;
  final LevelDef level;
  final ProgressStore store;
  final _rng = Random();

  final trees = <GardenTree>[];
  final decor = <DecorItem>[];
  final falling = <FallingFruit>[];
  final clouds = <CloudDrift>[];
  final cargo = <CargoItem>[];
  final pops = <Pop>[];
  final collectedBy = <FruitId, int>{};
  final goldenBy = <FruitId, int>{};

  WeatherKind weather = WeatherKind.calm;
  double weatherLeft = 0;
  double switchLock = 0;
  double timeLeft = 0;
  double comboTimer = 0;
  int combo = 0;
  int maxCombo = 0;
  int collected = 0;
  int golden = 0;
  int missed = 0;
  int runCoins = 0;
  int unloadedCoins = 0;
  int rainUses = 0;
  bool usedStorm = false;
  bool finished = false;
  bool won = false;
  double droneX = 0.5;
  double droneY = 0.82;
  double? targetX;
  double? targetY;
  double lightning = 0;
  double windBurst = 0;
  Size field = const Size(360, 640);

  static const station = Offset(0.50, 0.90);
  static const beacon = Offset(0.86, 0.10);

  void _buildField() {
    final pool = garden.fruitPool;
    final placed = <Offset>[];
    for (var i = 0; i < level.treeCount; i++) {
      Offset p;
      var tries = 0;
      do {
        p = Offset(0.12 + _rng.nextDouble() * 0.76, 0.14 + _rng.nextDouble() * 0.62);
        tries++;
      } while (tries < 36 && placed.any((o) => (o - p).distance < 0.22));
      placed.add(p);
      trees.add(GardenTree(
        nx: p.dx,
        ny: p.dy,
        fruit: pool[i % pool.length],
        stock: 3 + _rng.nextInt(4),
      ));
    }

    void add(List<String> assets, int n, double size) {
      for (var i = 0; i < n; i++) {
        decor.add(DecorItem(
          _rng.nextDouble(),
          0.08 + _rng.nextDouble() * 0.78,
          assets[_rng.nextInt(assets.length)],
          size,
        ));
      }
    }

    add(['assets/sprites/palm_01.png', 'assets/sprites/palm_02.png', 'assets/sprites/palm_03.png'], 3, 88);
    add(['assets/sprites/bush_01.png', 'assets/sprites/bush_02.png', 'assets/sprites/bush_03.png'], 4, 52);
    add(['assets/sprites/stone_01.png', 'assets/sprites/stone_02.png'], 2, 42);
    add(['assets/sprites/plant_01.png', 'assets/sprites/plant_04.png'], 3, 40);
    if (garden.unlockIndex >= 1) {
      add(['assets/sprites/pond_01.png', 'assets/sprites/pond_02.png'], 1, 52);
    }
    if (store.gardenDev.contains('hut')) {
      decor.add(DecorItem(0.12, 0.86, 'assets/sprites/structure_01.png', 46));
    }

    clouds.addAll([
      CloudDrift(-0.1, 0.08, 0.018, 'assets/sprites/cloud_01.png', 90),
      CloudDrift(0.45, 0.18, 0.012, 'assets/sprites/cloud_02.png', 80),
      CloudDrift(0.8, 0.05, 0.015, 'assets/sprites/cloud_03.png', 86),
    ]);
  }

  int get capacity => GameContent.capacityFor(store.upgradeLevel(UpgradeId.droneCapacity));
  bool get full => cargo.length >= capacity;
  double get collectRadius {
    final lv = store.upgradeLevel(UpgradeId.droneRadius);
    return 52 + lv * 6;
  }

  double get _speed {
    final lv = store.upgradeLevel(UpgradeId.droneSpeed);
    final ret = store.upgradeLevel(UpgradeId.droneReturn);
    final base = 2.15 + lv * 0.22;
    return full ? base * (1.05 + ret * 0.08) : base;
  }

  void resize(Size size) {
    if (size == field) return;
    field = size;
  }

  void pointer(Offset local) {
    aim(local.dx / field.width, local.dy / field.height);
  }

  void aim(double nx, double ny) {
    targetX = nx.clamp(0.04, 0.96);
    targetY = ny.clamp(0.06, 0.94);
  }

  void setWeather(WeatherKind next) {
    if (!garden.weathers.contains(next) || switchLock > 0 || finished) return;
    weather = next;
    final stormLv = store.upgradeLevel(UpgradeId.weatherStorm);
    weatherLeft = next == WeatherKind.storm ? 7 + stormLv * 1.1 : 9.5;
    switchLock = next == WeatherKind.storm ? 1.1 : 0.35;
    if (next == WeatherKind.rain) rainUses += 1;
    if (next == WeatherKind.storm) usedStorm = true;
    AudioService.instance.weather();
    notifyListeners();
  }

  void tick(double dt) {
    if (finished) return;
    timeLeft = max(0, timeLeft - dt);
    switchLock = max(0, switchLock - dt);
    comboTimer = max(0, comboTimer - dt);
    if (comboTimer <= 0) combo = 0;
    weatherLeft = max(0, weatherLeft - dt);
    if (weatherLeft <= 0 && weather != WeatherKind.calm) {
      weather = WeatherKind.calm;
    }
    lightning = max(0, lightning - dt);
    windBurst = max(0, windBurst - dt);

    _applyEvent(dt);
    _moveDrone(dt);
    _growTrees(dt);
    _moveFruit(dt);
    _collect();
    _tryUnload();
    _driftClouds(dt);
    _agePops(dt);
    _checkEnd();
  }

  void _agePops(double dt) {
    for (final p in pops) {
      p.life -= dt;
      p.y -= 42 * dt;
    }
    pops.removeWhere((p) => p.life <= 0);
  }

  /// How close the drone is to the unloading station, 0..1 (1 = docked).
  double get stationProximity {
    final d = Offset(droneX - station.dx, droneY - station.dy).distance;
    return (1 - (d / 0.28)).clamp(0.0, 1.0);
  }

  void _driftClouds(double dt) {
    for (final cloud in clouds) {
      cloud.nx += cloud.speed * dt;
      if (cloud.nx > 1.2) cloud.nx = -0.3;
    }
  }

  void _applyEvent(double dt) {
    switch (level.event) {
      case GardenEventKind.windBurst:
        windBurst -= dt;
        if (windBurst <= -6) {
          windBurst = 1.6;
          for (final t in trees) {
            if (t.ripeness > 0.72 && t.stock > 0) _dropFrom(t, force: true);
          }
        }
      case GardenEventKind.tropicalStorm:
        if (weather == WeatherKind.calm) {
          weather = WeatherKind.rain;
          weatherLeft = max(weatherLeft, 2);
        }
      case GardenEventKind.heatWave:
      case GardenEventKind.heavyRain:
      case GardenEventKind.goldenRain:
      case GardenEventKind.none:
        break;
    }
    if (weather == WeatherKind.storm && _rng.nextDouble() < dt * 0.55) {
      lightning = 0.18;
      AudioService.instance.lightning();
    }
  }

  void _moveDrone(double dt) {
    final tx = targetX ?? droneX;
    final ty = targetY ?? droneY;
    final k = 1 - exp(-_speed * dt * 3.2);
    droneX += (tx - droneX) * k;
    droneY += (ty - droneY) * k;
    var drift = 0.0;
    if (weather == WeatherKind.wind || weather == WeatherKind.storm || level.event == GardenEventKind.tropicalStorm) {
      final resist = store.upgradeLevel(UpgradeId.droneWind) * 0.12;
      drift = (0.22 - resist).clamp(0.04, 0.22);
    }
    if (windBurst > 0) drift += 0.18;
    droneX = (droneX + sin(timeLeft * 6) * drift * dt).clamp(0.04, 0.96);
  }

  void _growTrees(double dt) {
    final sun = 0.11 + store.upgradeLevel(UpgradeId.weatherSun) * 0.025;
    final rain = 0.16 + store.upgradeLevel(UpgradeId.weatherRain) * 0.03;
    final wind = 0.28 + store.upgradeLevel(UpgradeId.weatherWind) * 0.05;
    var sunMul = weather == WeatherKind.sun ? 1.0 : (weather == WeatherKind.calm ? 0.22 : 0.08);
    var rainMul = weather == WeatherKind.rain ? 1.0 : 0.0;
    var windMul = weather == WeatherKind.wind || weather == WeatherKind.storm ? 1.0 : 0.0;
    if (level.event == GardenEventKind.heatWave) {
      sunMul *= weather == WeatherKind.sun ? 1.45 : 1;
      if (weather == WeatherKind.sun && weatherLeft < 3) sunMul *= 0.55;
    }
    if (level.event == GardenEventKind.heavyRain && weather == WeatherKind.rain) {
      rainMul *= 1.55;
    }
    if (level.event == GardenEventKind.tropicalStorm) {
      rainMul = max(rainMul, 0.55);
      windMul = max(windMul, 0.7);
    }

    for (final t in trees) {
      if (t.stock <= 0) {
        t.ripeness = min(1, t.ripeness + dt * 0.03);
        if (t.ripeness >= 1) {
          t.stock = 2 + _rng.nextInt(3);
          t.ripeness = 0.2;
        }
        continue;
      }
      t.ripeness = (t.ripeness + dt * sun * sunMul).clamp(0, 1);
      t.wetness = (t.wetness + dt * rain * rainMul - dt * 0.04).clamp(0, 1);
      t.dropCd = max(0, t.dropCd - dt);
      final ready = t.ripeness >= 0.78;
      if (ready && t.wetness >= 0.5 && t.dropCd <= 0) {
        _dropFrom(t);
        t.dropCd = 0.55;
      }
      if (ready && windMul > 0 && t.dropCd <= 0 && _rng.nextDouble() < wind * windMul * dt) {
        _dropFrom(t);
        t.dropCd = 0.4;
      }
    }
  }

  void _dropFrom(GardenTree t, {bool force = false}) {
    if (t.stock <= 0 && !force) return;
    if (t.stock <= 0) return;
    t.stock -= 1;
    t.ripeness *= 0.62;
    t.wetness *= 0.4;
    final goldChance = 0.10 + store.upgradeLevel(UpgradeId.weatherGold) * 0.03;
    var isGold = weather == WeatherKind.storm && _rng.nextDouble() < goldChance;
    if (level.event == GardenEventKind.goldenRain && _rng.nextDouble() < 0.28) {
      isGold = true;
    }
    final x = t.nx * field.width;
    final y = t.ny * field.height;
    falling.add(
      FallingFruit(
        x: x,
        y: y,
        vx: (_rng.nextDouble() - 0.5) * 40,
        vy: 18 + _rng.nextDouble() * 30,
        fruit: t.fruit,
        golden: isGold,
        groundY: y + 70 + _rng.nextDouble() * 36,
      ),
    );
  }

  void _moveFruit(double dt) {
    for (final f in falling) {
      if (f.taken) continue;
      if (!f.landed) {
        f.vy += 210 * dt;
        f.x += f.vx * dt;
        f.y += f.vy * dt;
        if (weather == WeatherKind.wind || weather == WeatherKind.storm) {
          f.x += 36 * dt;
        }
        if (f.y >= f.groundY) {
          f.y = f.groundY;
          f.landed = true;
          f.vx = 0;
        }
      } else {
        f.life -= dt;
        if (f.life <= 0) {
          f.taken = true;
          missed += 1;
          combo = 0;
        }
      }
    }
    falling.removeWhere((f) => f.taken && f.life <= 0);
  }

  void _collect() {
    if (full) return;
    final dx = droneX * field.width;
    final dy = droneY * field.height;
    for (final f in falling) {
      if (f.taken || cargo.length >= capacity) continue;
      final d = Offset(f.x - dx, f.y - dy).distance;
      if (d <= collectRadius) {
        f.taken = true;
        final def = GameContent.fruit(f.fruit);
        final base = f.golden ? def.goldenValue : def.value;
        final bonus = GameContent.comboBonusPercent(combo + 1);
        final value = (base * (1 + bonus / 100)).round();
        cargo.add(CargoItem(f.fruit, f.golden, value));
        collected += 1;
        collectedBy[f.fruit] = (collectedBy[f.fruit] ?? 0) + 1;
        if (f.golden) {
          golden += 1;
          goldenBy[f.fruit] = (goldenBy[f.fruit] ?? 0) + 1;
        }
        combo += 1;
        maxCombo = max(maxCombo, combo);
        comboTimer = 2.4;
        runCoins += value;
        pops.add(Pop(f.x, f.y, '+$value', f.golden));
        if (f.golden) {
          AudioService.instance.gold();
        } else {
          AudioService.instance.fruit();
        }
        if (combo == 5 || combo == 10 || combo == 20) {
          AudioService.instance.combo();
        }
      }
    }
    falling.removeWhere((f) => f.taken);
  }

  void _tryUnload() {
    if (cargo.isEmpty) return;
    final d = Offset(droneX - station.dx, droneY - station.dy).distance;
    if (d < 0.085) {
      var gain = 0;
      for (final c in cargo) {
        gain += c.value;
      }
      unloadedCoins += gain;
      cargo.clear();
      pops.add(Pop(station.dx * field.width, station.dy * field.height, 'BANKED +$gain', true));
      AudioService.instance.coin();
    }
  }

  int get goalCurrent {
    switch (level.goal) {
      case GoalType.collectFruits:
        return collected;
      case GoalType.collectGolden:
        return golden;
      case GoalType.reachCombo:
        return maxCombo;
      case GoalType.earnCoins:
        return unloadedCoins;
      case GoalType.useStorm:
        return usedStorm && collected >= 8 ? 1 : 0;
    }
  }

  bool get goalMet => goalCurrent >= level.goalAmount;

  void _checkEnd() {
    if (goalMet) {
      _finish(true);
      return;
    }
    if (timeLeft <= 0 || missed >= level.missLimit) {
      _finish(false);
    }
  }

  void _finish(bool success) {
    if (finished) return;
    finished = true;
    won = success;
    if (cargo.isNotEmpty) {
      final keep = success ? 1.0 : 0.7;
      for (final c in cargo) {
        unloadedCoins += (c.value * keep).round();
      }
      cargo.clear();
    }
    if (success) {
      AudioService.instance.win();
    } else {
      AudioService.instance.fail();
    }
    notifyListeners();
  }

  RunResult toResult() {
    final payout = won ? unloadedCoins + 120 + levelIndex * 25 : (unloadedCoins * 0.35).round();
    final crystals = won && levelIndex >= 4 && _rng.nextDouble() < 0.45 ? 1 : 0;
    final chest = won && (levelIndex == garden.levels.length - 1 || _rng.nextDouble() < 0.22);
    var star = 0;
    if (won) {
      star = 1;
      if (missed <= max(2, level.missLimit ~/ 3) || timeLeft > level.seconds * 0.2) star = 2;
      if (missed <= 2 && timeLeft > level.seconds * 0.28) star = 3;
    }
    return RunResult(
      won: won,
      stars: star,
      fruits: collected,
      golden: golden,
      maxCombo: maxCombo,
      coins: payout + (chest ? 80 + _rng.nextInt(220) : 0),
      crystals: crystals,
      chest: chest,
      missed: missed,
      secondsLeft: timeLeft.ceil(),
      goalLabel: GameContent.goalText(level),
    );
  }
}
