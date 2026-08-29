import 'models.dart';

class GameContent {
  GameContent._();

  static const fruits = <FruitDef>[
    FruitDef(
      id: FruitId.mango,
      name: 'Mango',
      asset: 'assets/sprites/mango.png',
      goldenAsset: 'assets/sprites/golden_mango.png',
      treeAsset: 'assets/sprites/tree_mango.png',
      rarity: FruitRarity.common,
      value: 14,
      goldenValue: 120,
      blurb: 'Sun-sweet tropical mango, the heart of Juicy Meadow.',
    ),
    FruitDef(
      id: FruitId.pineapple,
      name: 'Pineapple',
      asset: 'assets/sprites/pineapple.png',
      goldenAsset: 'assets/sprites/golden_pineapple.png',
      treeAsset: 'assets/sprites/tree_pineapple.png',
      rarity: FruitRarity.rare,
      value: 18,
      goldenValue: 150,
      blurb: 'Heavy crown fruit. Rain and wind drop it best.',
    ),
    FruitDef(
      id: FruitId.coconut,
      name: 'Coconut',
      asset: 'assets/sprites/coconut.png',
      goldenAsset: 'assets/sprites/golden_coconut.png',
      treeAsset: 'assets/sprites/tree_coconut.png',
      rarity: FruitRarity.common,
      value: 12,
      goldenValue: 110,
      blurb: 'Palm-coast staple with a sturdy shell.',
    ),
    FruitDef(
      id: FruitId.papaya,
      name: 'Papaya',
      asset: 'assets/sprites/papaya.png',
      goldenAsset: 'assets/sprites/golden_papaya.png',
      treeAsset: 'assets/sprites/tree_papaya.png',
      rarity: FruitRarity.rare,
      value: 16,
      goldenValue: 140,
      blurb: 'Soft orange flesh packed with dark seeds.',
    ),
    FruitDef(
      id: FruitId.banana,
      name: 'Banana',
      asset: 'assets/sprites/banana.png',
      goldenAsset: 'assets/sprites/golden_banana.png',
      treeAsset: 'assets/sprites/tree_banana.png',
      rarity: FruitRarity.common,
      value: 11,
      goldenValue: 100,
      blurb: 'Light fruit that falls quickly in a breeze.',
    ),
    FruitDef(
      id: FruitId.lime,
      name: 'Lime',
      asset: 'assets/sprites/lime.png',
      goldenAsset: 'assets/sprites/golden_lime.png',
      treeAsset: 'assets/sprites/tree_lime.png',
      rarity: FruitRarity.rare,
      value: 15,
      goldenValue: 130,
      blurb: 'Zesty green slice that shines after a storm.',
    ),
    FruitDef(
      id: FruitId.orange,
      name: 'Orange',
      asset: 'assets/sprites/orange.png',
      goldenAsset: 'assets/sprites/golden_orange.png',
      treeAsset: 'assets/sprites/tree_orange.png',
      rarity: FruitRarity.common,
      value: 13,
      goldenValue: 115,
      blurb: 'Bright citrus from the grove trees.',
    ),
    FruitDef(
      id: FruitId.passionFruit,
      name: 'Passion Fruit',
      asset: 'assets/sprites/passion_fruit.png',
      goldenAsset: 'assets/sprites/golden_passion_fruit.png',
      treeAsset: 'assets/sprites/tree_passion.png',
      rarity: FruitRarity.epic,
      value: 22,
      goldenValue: 180,
      blurb: 'Rare seedy jewel of the Golden Tropics.',
    ),
  ];

  static FruitDef fruit(FruitId id) => fruits.firstWhere((f) => f.id == id);

  static const gardens = <GardenDef>[
    GardenDef(
      id: 'juicy_meadow',
      name: 'Juicy Meadow',
      subtitle: 'Learn the weather and catch the first harvest.',
      unlockIndex: 0,
      accent: 0xFF7CFF3A,
      fruitPool: [FruitId.mango, FruitId.banana, FruitId.orange],
      weathers: [WeatherKind.sun, WeatherKind.rain],
      levels: [
        LevelDef(goal: GoalType.collectFruits, goalAmount: 12, seconds: 95, treeCount: 8, missLimit: 10),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 18, seconds: 90, treeCount: 9, missLimit: 10),
        LevelDef(goal: GoalType.earnCoins, goalAmount: 180, seconds: 90, treeCount: 10, missLimit: 9),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 24, seconds: 85, treeCount: 11, missLimit: 9),
        LevelDef(goal: GoalType.reachCombo, goalAmount: 8, seconds: 85, treeCount: 11, missLimit: 8),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 30, seconds: 80, treeCount: 12, missLimit: 8, event: GardenEventKind.heavyRain),
      ],
    ),
    GardenDef(
      id: 'palm_coast',
      name: 'Palm Coast',
      subtitle: 'Coconuts, palms, and stronger wind.',
      unlockIndex: 1,
      accent: 0xFF2EE6C8,
      fruitPool: [FruitId.coconut, FruitId.banana, FruitId.lime, FruitId.mango],
      weathers: [WeatherKind.sun, WeatherKind.rain, WeatherKind.wind],
      levels: [
        LevelDef(goal: GoalType.collectFruits, goalAmount: 22, seconds: 85, treeCount: 12, missLimit: 9),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 28, seconds: 80, treeCount: 13, missLimit: 9),
        LevelDef(goal: GoalType.earnCoins, goalAmount: 280, seconds: 80, treeCount: 14, missLimit: 8),
        LevelDef(goal: GoalType.reachCombo, goalAmount: 10, seconds: 80, treeCount: 14, missLimit: 8, event: GardenEventKind.windBurst),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 34, seconds: 75, treeCount: 15, missLimit: 8),
        LevelDef(goal: GoalType.earnCoins, goalAmount: 360, seconds: 75, treeCount: 16, missLimit: 7, event: GardenEventKind.tropicalStorm),
      ],
    ),
    GardenDef(
      id: 'mango_grove',
      name: 'Mango Grove',
      subtitle: 'Dense trees. Keep the Harvest Combo alive.',
      unlockIndex: 2,
      accent: 0xFFFF8A2B,
      fruitPool: [FruitId.mango, FruitId.papaya, FruitId.orange, FruitId.lime],
      weathers: [WeatherKind.sun, WeatherKind.rain, WeatherKind.wind],
      levels: [
        LevelDef(goal: GoalType.reachCombo, goalAmount: 12, seconds: 80, treeCount: 14, missLimit: 8),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 36, seconds: 80, treeCount: 16, missLimit: 8),
        LevelDef(goal: GoalType.earnCoins, goalAmount: 420, seconds: 75, treeCount: 16, missLimit: 7),
        LevelDef(goal: GoalType.reachCombo, goalAmount: 16, seconds: 75, treeCount: 18, missLimit: 7),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 42, seconds: 70, treeCount: 18, missLimit: 7, event: GardenEventKind.heatWave),
        LevelDef(goal: GoalType.reachCombo, goalAmount: 20, seconds: 70, treeCount: 20, missLimit: 6),
      ],
    ),
    GardenDef(
      id: 'pineapple_fields',
      name: 'Pineapple Fields',
      subtitle: 'Heavy fruit. Time rain and wind carefully.',
      unlockIndex: 3,
      accent: 0xFFFFC84A,
      fruitPool: [FruitId.pineapple, FruitId.papaya, FruitId.mango, FruitId.coconut],
      weathers: [WeatherKind.sun, WeatherKind.rain, WeatherKind.wind],
      levels: [
        LevelDef(goal: GoalType.collectFruits, goalAmount: 32, seconds: 80, treeCount: 15, missLimit: 8),
        LevelDef(goal: GoalType.earnCoins, goalAmount: 480, seconds: 75, treeCount: 16, missLimit: 7),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 40, seconds: 75, treeCount: 18, missLimit: 7, event: GardenEventKind.heavyRain),
        LevelDef(goal: GoalType.reachCombo, goalAmount: 14, seconds: 70, treeCount: 18, missLimit: 7),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 46, seconds: 70, treeCount: 20, missLimit: 6),
        LevelDef(goal: GoalType.earnCoins, goalAmount: 620, seconds: 68, treeCount: 20, missLimit: 6, event: GardenEventKind.windBurst),
      ],
    ),
    GardenDef(
      id: 'storm_garden',
      name: 'Storm Garden',
      subtitle: 'Thunder, gold fruit, and risky weather.',
      unlockIndex: 4,
      accent: 0xFF9B6BFF,
      fruitPool: [FruitId.lime, FruitId.passionFruit, FruitId.papaya, FruitId.orange],
      weathers: [WeatherKind.sun, WeatherKind.rain, WeatherKind.wind, WeatherKind.storm],
      levels: [
        LevelDef(goal: GoalType.collectGolden, goalAmount: 3, seconds: 80, treeCount: 16, missLimit: 8),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 40, seconds: 75, treeCount: 18, missLimit: 7),
        LevelDef(goal: GoalType.useStorm, goalAmount: 1, seconds: 75, treeCount: 18, missLimit: 7),
        LevelDef(goal: GoalType.collectGolden, goalAmount: 5, seconds: 70, treeCount: 20, missLimit: 7, event: GardenEventKind.goldenRain),
        LevelDef(goal: GoalType.earnCoins, goalAmount: 700, seconds: 70, treeCount: 22, missLimit: 6),
        LevelDef(goal: GoalType.collectGolden, goalAmount: 7, seconds: 68, treeCount: 22, missLimit: 6, event: GardenEventKind.tropicalStorm),
      ],
    ),
    GardenDef(
      id: 'golden_tropics',
      name: 'Golden Tropics',
      subtitle: 'Rare harvest and wild weather events.',
      unlockIndex: 5,
      accent: 0xFFFFE38A,
      fruitPool: [FruitId.passionFruit, FruitId.pineapple, FruitId.mango, FruitId.lime, FruitId.papaya],
      weathers: [WeatherKind.sun, WeatherKind.rain, WeatherKind.wind, WeatherKind.storm],
      levels: [
        LevelDef(goal: GoalType.collectFruits, goalAmount: 48, seconds: 75, treeCount: 20, missLimit: 7),
        LevelDef(goal: GoalType.collectGolden, goalAmount: 6, seconds: 72, treeCount: 22, missLimit: 6, event: GardenEventKind.goldenRain),
        LevelDef(goal: GoalType.reachCombo, goalAmount: 18, seconds: 70, treeCount: 24, missLimit: 6),
        LevelDef(goal: GoalType.earnCoins, goalAmount: 900, seconds: 68, treeCount: 24, missLimit: 6, event: GardenEventKind.heatWave),
        LevelDef(goal: GoalType.collectGolden, goalAmount: 8, seconds: 66, treeCount: 26, missLimit: 5, event: GardenEventKind.tropicalStorm),
        LevelDef(goal: GoalType.collectFruits, goalAmount: 60, seconds: 64, treeCount: 28, missLimit: 5, event: GardenEventKind.goldenRain),
      ],
    ),
  ];

  static GardenDef gardenById(String id) =>
      gardens.firstWhere((g) => g.id == id);

  static const droneUpgrades = <UpgradeDef>[
    UpgradeDef(id: UpgradeId.droneSpeed, title: 'Move Speed', hint: 'The drone follows your finger faster.', maxLevel: 8, baseCost: 120),
    UpgradeDef(id: UpgradeId.droneCapacity, title: 'Capacity', hint: 'Carry more fruit before unloading.', maxLevel: 5, baseCost: 180),
    UpgradeDef(id: UpgradeId.droneRadius, title: 'Collect Radius', hint: 'Catch fruit from farther away.', maxLevel: 8, baseCost: 150),
    UpgradeDef(id: UpgradeId.droneWind, title: 'Wind Resist', hint: 'Less drift during wind and storms.', maxLevel: 6, baseCost: 160),
    UpgradeDef(id: UpgradeId.droneReturn, title: 'Return Speed', hint: 'Faster travel when the basket is full.', maxLevel: 6, baseCost: 140),
  ];

  static const weatherUpgrades = <UpgradeDef>[
    UpgradeDef(id: UpgradeId.weatherSun, title: 'Sun Power', hint: 'Fruit ripens faster under the sun.', maxLevel: 8, baseCost: 130),
    UpgradeDef(id: UpgradeId.weatherRain, title: 'Rain Soak', hint: 'Ripe fruit falls sooner in the rain.', maxLevel: 8, baseCost: 140),
    UpgradeDef(id: UpgradeId.weatherWind, title: 'Wind Force', hint: 'Stronger gusts shake more fruit loose.', maxLevel: 8, baseCost: 150),
    UpgradeDef(id: UpgradeId.weatherStorm, title: 'Storm Time', hint: 'Thunderstorms last longer.', maxLevel: 6, baseCost: 220),
    UpgradeDef(id: UpgradeId.weatherGold, title: 'Gold Chance', hint: 'More fruit turns golden in a storm.', maxLevel: 5, baseCost: 280),
  ];

  static const gardenPlots = <GardenPlotDef>[
    GardenPlotDef(id: 'plot', title: 'New Plot', cost: 1500, asset: 'assets/sprites/soil.png'),
    GardenPlotDef(id: 'hut', title: 'Storage Hut', cost: 800, asset: 'assets/sprites/structure_01.png'),
    GardenPlotDef(id: 'pond', title: 'Garden Pond', cost: 600, asset: 'assets/sprites/pond_01.png'),
    GardenPlotDef(id: 'warehouse', title: 'Fruit Warehouse', cost: 900, asset: 'assets/sprites/structure_02.png'),
    GardenPlotDef(id: 'house', title: 'Summer House', cost: 700, asset: 'assets/sprites/structure_03.png'),
    GardenPlotDef(id: 'deco', title: 'Flower Decor', cost: 400, asset: 'assets/sprites/plant_01.png'),
  ];

  static const permanentQuests = <QuestDef>[
    QuestDef(id: 'p_fruits', title: 'Collect 500 fruits', target: 500, rewardCoins: 800, rewardCrystals: 2, kind: QuestKind.collectFruits),
    QuestDef(id: 'p_combo', title: 'Reach x20 Harvest Combo', target: 20, rewardCoins: 600, rewardCrystals: 2, kind: QuestKind.reachCombo),
    QuestDef(id: 'p_gold', title: 'Collect 25 golden fruits', target: 25, rewardCoins: 900, rewardCrystals: 3, kind: QuestKind.collectGolden),
    QuestDef(id: 'p_clear', title: 'Complete 10 garden runs', target: 10, rewardCoins: 700, rewardCrystals: 2, kind: QuestKind.completeLevel),
  ];

  static const dailyQuestPool = <QuestDef>[
    QuestDef(id: 'q_fruits', title: 'Collect 100 fruits', target: 100, rewardCoins: 180, rewardCrystals: 0, kind: QuestKind.collectFruits),
    QuestDef(id: 'q_combo', title: 'Reach x12 Harvest Combo', target: 12, rewardCoins: 160, rewardCrystals: 1, kind: QuestKind.reachCombo),
    QuestDef(id: 'q_gold', title: 'Collect 5 golden fruits', target: 5, rewardCoins: 220, rewardCrystals: 1, kind: QuestKind.collectGolden),
    QuestDef(id: 'q_rain', title: 'Use Rain 8 times', target: 8, rewardCoins: 140, rewardCrystals: 0, kind: QuestKind.useRain),
    QuestDef(id: 'q_clear', title: 'Complete 2 garden runs', target: 2, rewardCoins: 200, rewardCrystals: 1, kind: QuestKind.completeLevel),
    QuestDef(id: 'q_clean', title: 'Finish a run with under 3 misses', target: 1, rewardCoins: 240, rewardCrystals: 1, kind: QuestKind.noMiss),
  ];

  static List<ContractDef> contractPool() => const [
        ContractDef(id: 'c_mango', title: 'Collect 20 Mangoes', fruit: FruitId.mango, amount: 20, rewardCoins: 250),
        ContractDef(id: 'c_pine', title: 'Collect 16 Pineapples', fruit: FruitId.pineapple, amount: 16, rewardCoins: 280),
        ContractDef(id: 'c_coco', title: 'Collect 18 Coconuts', fruit: FruitId.coconut, amount: 18, rewardCoins: 230),
        ContractDef(id: 'c_papa', title: 'Collect 14 Papayas', fruit: FruitId.papaya, amount: 14, rewardCoins: 260),
        ContractDef(id: 'c_ban', title: 'Collect 22 Bananas', fruit: FruitId.banana, amount: 22, rewardCoins: 220),
        ContractDef(id: 'c_lime', title: 'Collect 12 Limes', fruit: FruitId.lime, amount: 12, rewardCoins: 240),
        ContractDef(id: 'c_ora', title: 'Collect 18 Oranges', fruit: FruitId.orange, amount: 18, rewardCoins: 230),
        ContractDef(id: 'c_pass', title: 'Collect 8 Passion Fruits', fruit: FruitId.passionFruit, amount: 8, rewardCoins: 320),
        ContractDef(id: 'c_gmango', title: 'Collect 3 Golden Mangoes', fruit: FruitId.mango, amount: 3, rewardCoins: 400, needGolden: true),
      ];

  static String goalText(LevelDef level) {
    switch (level.goal) {
      case GoalType.collectFruits:
        return 'Collect ${level.goalAmount} fruits';
      case GoalType.collectGolden:
        return 'Collect ${level.goalAmount} golden fruits';
      case GoalType.reachCombo:
        return 'Reach x${level.goalAmount} Harvest Combo';
      case GoalType.earnCoins:
        return 'Earn ${level.goalAmount} coins';
      case GoalType.useStorm:
        return 'Complete a storm harvest';
    }
  }

  static String eventTitle(GardenEventKind event) {
    switch (event) {
      case GardenEventKind.none:
        return '';
      case GardenEventKind.tropicalStorm:
        return 'Tropical Storm';
      case GardenEventKind.goldenRain:
        return 'Golden Rain';
      case GardenEventKind.heatWave:
        return 'Heat Wave';
      case GardenEventKind.windBurst:
        return 'Wind Burst';
      case GardenEventKind.heavyRain:
        return 'Heavy Rain';
    }
  }

  static String eventBlurb(GardenEventKind event) {
    switch (event) {
      case GardenEventKind.none:
        return '';
      case GardenEventKind.tropicalStorm:
        return 'Hard rain and wind. Fruit drops fast, the drone drifts more.';
      case GardenEventKind.goldenRain:
        return 'Part of the falling harvest turns golden on its own.';
      case GardenEventKind.heatWave:
        return 'The sun is stronger, but plants tire if it stays too long.';
      case GardenEventKind.windBurst:
        return 'Short, powerful gusts shake many ripe fruits at once.';
      case GardenEventKind.heavyRain:
        return 'Fruit soaks quickly and drops in heavy waves.';
    }
  }

  static int comboBonusPercent(int combo) {
    if (combo >= 20) return 100;
    if (combo >= 10) return 60;
    if (combo >= 5) return 35;
    if (combo >= 3) return 20;
    if (combo >= 2) return 10;
    return 0;
  }

  static int upgradeCost(UpgradeDef def, int level) {
    var cost = def.baseCost.toDouble();
    for (var i = 0; i < level; i++) {
      cost *= 1.42;
    }
    return cost.round();
  }

  static int capacityFor(int level) {
    const steps = [20, 30, 40, 55, 75, 90];
    return steps[level.clamp(0, steps.length - 1)];
  }
}
