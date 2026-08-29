enum FruitId {
  mango,
  pineapple,
  coconut,
  papaya,
  banana,
  lime,
  orange,
  passionFruit,
}

enum FruitRarity { common, rare, epic, golden }

enum WeatherKind { calm, sun, rain, wind, storm }

enum GoalType { collectFruits, collectGolden, reachCombo, earnCoins, useStorm }

enum GardenEventKind { none, tropicalStorm, goldenRain, heatWave, windBurst, heavyRain }

enum UpgradeId {
  droneSpeed,
  droneCapacity,
  droneRadius,
  droneWind,
  droneReturn,
  weatherSun,
  weatherRain,
  weatherWind,
  weatherStorm,
  weatherGold,
}

class FruitDef {
  const FruitDef({
    required this.id,
    required this.name,
    required this.asset,
    required this.goldenAsset,
    required this.treeAsset,
    required this.rarity,
    required this.value,
    required this.goldenValue,
    required this.blurb,
  });

  final FruitId id;
  final String name;
  final String asset;
  final String goldenAsset;
  final String treeAsset;
  final FruitRarity rarity;
  final int value;
  final int goldenValue;
  final String blurb;
}

class GardenDef {
  const GardenDef({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.unlockIndex,
    required this.accent,
    required this.fruitPool,
    required this.weathers,
    required this.levels,
  });

  final String id;
  final String name;
  final String subtitle;
  final int unlockIndex;
  final int accent;
  final List<FruitId> fruitPool;
  final List<WeatherKind> weathers;
  final List<LevelDef> levels;
}

class LevelDef {
  const LevelDef({
    required this.goal,
    required this.goalAmount,
    required this.seconds,
    required this.treeCount,
    required this.missLimit,
    this.event = GardenEventKind.none,
  });

  final GoalType goal;
  final int goalAmount;
  final int seconds;
  final int treeCount;
  final int missLimit;
  final GardenEventKind event;
}

class UpgradeDef {
  const UpgradeDef({
    required this.id,
    required this.title,
    required this.hint,
    required this.maxLevel,
    required this.baseCost,
  });

  final UpgradeId id;
  final String title;
  final String hint;
  final int maxLevel;
  final int baseCost;
}

class QuestDef {
  const QuestDef({
    required this.id,
    required this.title,
    required this.target,
    required this.rewardCoins,
    required this.rewardCrystals,
    required this.kind,
  });

  final String id;
  final String title;
  final int target;
  final int rewardCoins;
  final int rewardCrystals;
  final QuestKind kind;
}

enum QuestKind {
  collectFruits,
  reachCombo,
  collectGolden,
  useRain,
  completeLevel,
  noMiss,
}

class ContractDef {
  const ContractDef({
    required this.id,
    required this.title,
    required this.fruit,
    required this.amount,
    required this.rewardCoins,
    this.needGolden = false,
  });

  final String id;
  final String title;
  final FruitId fruit;
  final int amount;
  final int rewardCoins;
  final bool needGolden;
}

class GardenPlotDef {
  const GardenPlotDef({
    required this.id,
    required this.title,
    required this.cost,
    required this.asset,
  });

  final String id;
  final String title;
  final int cost;
  final String asset;
}

class RunResult {
  const RunResult({
    required this.won,
    required this.stars,
    required this.fruits,
    required this.golden,
    required this.maxCombo,
    required this.coins,
    required this.crystals,
    required this.chest,
    required this.missed,
    required this.secondsLeft,
    required this.goalLabel,
  });

  final bool won;
  final int stars;
  final int fruits;
  final int golden;
  final int maxCombo;
  final int coins;
  final int crystals;
  final bool chest;
  final int missed;
  final int secondsLeft;
  final String goalLabel;
}
