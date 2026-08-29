import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';
import 'models.dart';

class ProgressStore extends ChangeNotifier {
  ProgressStore(this._prefs) {
    _load();
    refreshTimedContent();
  }

  final SharedPreferences _prefs;

  String playerName = 'Gardener';
  int coins = 180;
  int crystals = 4;
  int bestCombo = 0;
  int totalFruits = 0;
  int levelsWon = 0;
  bool soundOn = true;
  bool musicOn = true;
  bool hapticsOn = true;
  String lastGiftDay = '';
  String lastQuestDay = '';
  int contractsAt = 0;

  final Map<String, int> upgrades = {
    for (final id in UpgradeId.values) id.name: 0,
  };
  final Set<String> unlockedGardens = {'juicy_meadow'};
  final Map<String, int> cleared = {};
  final Map<String, int> stars = {};
  final Set<String> gardenDev = {};
  final Set<String> discovered = {};
  final Map<String, int> fruitCounts = {};
  final Map<String, int> goldenCounts = {};
  final Map<String, int> questProgress = {};
  final Set<String> questClaimed = {};
  List<String> dailyQuestIds = [];
  List<String> contractIds = [];
  final Map<String, int> contractProgress = {};
  final Set<String> contractClaimed = {};

  void _load() {
    final raw = _prefs.getString('progress_v1');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      playerName = m['playerName'] as String? ?? playerName;
      coins = m['coins'] as int? ?? coins;
      crystals = m['crystals'] as int? ?? crystals;
      bestCombo = m['bestCombo'] as int? ?? 0;
      totalFruits = m['totalFruits'] as int? ?? 0;
      levelsWon = m['levelsWon'] as int? ?? 0;
      soundOn = m['soundOn'] as bool? ?? true;
      musicOn = m['musicOn'] as bool? ?? true;
      hapticsOn = m['hapticsOn'] as bool? ?? true;
      lastGiftDay = m['lastGiftDay'] as String? ?? '';
      lastQuestDay = m['lastQuestDay'] as String? ?? '';
      contractsAt = m['contractsAt'] as int? ?? 0;
      final up = m['upgrades'] as Map<String, dynamic>? ?? {};
      for (final e in up.entries) {
        upgrades[e.key] = e.value as int;
      }
      unlockedGardens
        ..clear()
        ..addAll(((m['unlockedGardens'] as List?) ?? ['juicy_meadow']).cast<String>());
      _readIntMap(m['cleared'], cleared);
      _readIntMap(m['stars'], stars);
      gardenDev
        ..clear()
        ..addAll(((m['gardenDev'] as List?) ?? const []).cast<String>());
      discovered
        ..clear()
        ..addAll(((m['discovered'] as List?) ?? const []).cast<String>());
      _readIntMap(m['fruitCounts'], fruitCounts);
      _readIntMap(m['goldenCounts'], goldenCounts);
      _readIntMap(m['questProgress'], questProgress);
      questClaimed
        ..clear()
        ..addAll(((m['questClaimed'] as List?) ?? const []).cast<String>());
      dailyQuestIds = ((m['dailyQuestIds'] as List?) ?? const []).cast<String>();
      contractIds = ((m['contractIds'] as List?) ?? const []).cast<String>();
      _readIntMap(m['contractProgress'], contractProgress);
      contractClaimed
        ..clear()
        ..addAll(((m['contractClaimed'] as List?) ?? const []).cast<String>());
    } catch (_) {
      // Keep defaults if the save is unreadable.
    }
  }

  void _readIntMap(dynamic raw, Map<String, int> dest) {
    dest.clear();
    if (raw is Map) {
      raw.forEach((k, v) {
        dest['$k'] = v is int ? v : int.tryParse('$v') ?? 0;
      });
    }
  }

  Future<void> persist() async {
    final data = <String, dynamic>{
      'playerName': playerName,
      'coins': coins,
      'crystals': crystals,
      'bestCombo': bestCombo,
      'totalFruits': totalFruits,
      'levelsWon': levelsWon,
      'soundOn': soundOn,
      'musicOn': musicOn,
      'hapticsOn': hapticsOn,
      'lastGiftDay': lastGiftDay,
      'lastQuestDay': lastQuestDay,
      'contractsAt': contractsAt,
      'upgrades': upgrades,
      'unlockedGardens': unlockedGardens.toList(),
      'cleared': cleared,
      'stars': stars,
      'gardenDev': gardenDev.toList(),
      'discovered': discovered.toList(),
      'fruitCounts': fruitCounts,
      'goldenCounts': goldenCounts,
      'questProgress': questProgress,
      'questClaimed': questClaimed.toList(),
      'dailyQuestIds': dailyQuestIds,
      'contractIds': contractIds,
      'contractProgress': contractProgress,
      'contractClaimed': contractClaimed.toList(),
    };
    await _prefs.setString('progress_v1', jsonEncode(data));
    notifyListeners();
  }

  String get todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  bool get giftAvailable => lastGiftDay != todayKey;

  void refreshTimedContent() {
    var changed = false;
    if (lastQuestDay != todayKey || dailyQuestIds.length < 3) {
      final pool = List<QuestDef>.from(GameContent.dailyQuestPool)..shuffle();
      for (final id in dailyQuestIds) {
        questProgress.remove(id);
        questClaimed.remove(id);
      }
      dailyQuestIds = pool.take(3).map((q) => q.id).toList();
      lastQuestDay = todayKey;
      changed = true;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (contractIds.isEmpty || now - contractsAt > const Duration(hours: 8).inMilliseconds) {
      final pool = List<ContractDef>.from(GameContent.contractPool())..shuffle();
      contractIds = pool.take(3).map((c) => c.id).toList();
      contractProgress.clear();
      contractClaimed.clear();
      contractsAt = now;
      changed = true;
    }
    if (changed) {
      persist();
    }
  }

  int upgradeLevel(UpgradeId id) => upgrades[id.name] ?? 0;

  bool gardenUnlocked(String id) => unlockedGardens.contains(id);

  int clearedIn(String gardenId) => cleared[gardenId] ?? -1;

  int starsOf(String gardenId, int level) => stars['${gardenId}_$level'] ?? 0;

  int gardenStars(String gardenId) {
    final g = GameContent.gardenById(gardenId);
    var sum = 0;
    for (var i = 0; i < g.levels.length; i++) {
      sum += starsOf(gardenId, i);
    }
    return sum;
  }

  bool levelOpen(String gardenId, int level) {
    if (!gardenUnlocked(gardenId)) return false;
    return level <= clearedIn(gardenId) + 1;
  }

  Future<void> applyRun({
    required String gardenId,
    required int levelIndex,
    required RunResult result,
    required Map<FruitId, int> collected,
    required Map<FruitId, int> golden,
    required int rainUses,
    required bool usedStorm,
  }) async {
    if (result.won) {
      coins += result.coins;
      crystals += result.crystals;
      levelsWon += 1;
      final key = '${gardenId}_$levelIndex';
      stars[key] = max(stars[key] ?? 0, result.stars);
      cleared[gardenId] = max(clearedIn(gardenId), levelIndex);
      final garden = GameContent.gardenById(gardenId);
      if (levelIndex >= garden.levels.length - 1) {
        final next = GameContent.gardens.where((g) => g.unlockIndex == garden.unlockIndex + 1);
        if (next.isNotEmpty) {
          unlockedGardens.add(next.first.id);
        }
      }
      addQuest(QuestKind.completeLevel, 1);
      if (result.missed < 3) addQuest(QuestKind.noMiss, 1);
    }
    bestCombo = max(bestCombo, result.maxCombo);
    totalFruits += result.fruits;
    collected.forEach((id, n) {
      fruitCounts[id.name] = (fruitCounts[id.name] ?? 0) + n;
      if (n > 0) discovered.add(id.name);
    });
    golden.forEach((id, n) {
      goldenCounts[id.name] = (goldenCounts[id.name] ?? 0) + n;
      if (n > 0) discovered.add('gold_${id.name}');
    });
    addQuest(QuestKind.collectFruits, result.fruits);
    addQuest(QuestKind.collectGolden, result.golden);
    addQuest(QuestKind.reachCombo, result.maxCombo, asMax: true);
    addQuest(QuestKind.useRain, rainUses);
    _applyContracts(collected, golden);
    await persist();
  }

  void _applyContracts(Map<FruitId, int> collected, Map<FruitId, int> golden) {
    for (final id in contractIds) {
      final def = GameContent.contractPool().firstWhere((c) => c.id == id);
      final add = def.needGolden ? (golden[def.fruit] ?? 0) : (collected[def.fruit] ?? 0);
      contractProgress[id] = (contractProgress[id] ?? 0) + add;
    }
  }

  void addQuest(QuestKind kind, int amount, {bool asMax = false}) {
    final defs = [
      ...GameContent.dailyQuestPool.where((q) => dailyQuestIds.contains(q.id)),
      ...GameContent.permanentQuests,
    ];
    for (final def in defs) {
      if (def.kind != kind) continue;
      if (asMax) {
        questProgress[def.id] = max(questProgress[def.id] ?? 0, amount);
      } else {
        questProgress[def.id] = (questProgress[def.id] ?? 0) + amount;
      }
    }
  }

  Future<bool> buyUpgrade(UpgradeDef def) async {
    final level = upgradeLevel(def.id);
    if (level >= def.maxLevel) return false;
    final cost = GameContent.upgradeCost(def, level);
    if (coins < cost) return false;
    coins -= cost;
    upgrades[def.id.name] = level + 1;
    await persist();
    return true;
  }

  Future<bool> buyPlot(GardenPlotDef plot) async {
    if (gardenDev.contains(plot.id) || coins < plot.cost) return false;
    coins -= plot.cost;
    gardenDev.add(plot.id);
    await persist();
    return true;
  }

  Future<int> claimDailyGift() async {
    if (!giftAvailable) return 0;
    lastGiftDay = todayKey;
    final gain = 80 + Random().nextInt(121);
    coins += gain;
    if (Random().nextBool()) crystals += 1;
    await persist();
    return gain;
  }

  Future<bool> claimQuest(QuestDef def) async {
    if (questClaimed.contains(def.id)) return false;
    if ((questProgress[def.id] ?? 0) < def.target) return false;
    questClaimed.add(def.id);
    coins += def.rewardCoins;
    crystals += def.rewardCrystals;
    await persist();
    return true;
  }

  Future<bool> claimContract(ContractDef def) async {
    if (contractClaimed.contains(def.id)) return false;
    if ((contractProgress[def.id] ?? 0) < def.amount) return false;
    contractClaimed.add(def.id);
    coins += def.rewardCoins;
    await persist();
    return true;
  }

  Future<void> setName(String name) async {
    playerName = name.trim().isEmpty ? 'Gardener' : name.trim();
    await persist();
  }

  Future<void> setSound(bool value) async {
    soundOn = value;
    await persist();
  }

  Future<void> setMusic(bool value) async {
    musicOn = value;
    await persist();
  }

  Future<void> setHaptics(bool value) async {
    hapticsOn = value;
    await persist();
  }
}
