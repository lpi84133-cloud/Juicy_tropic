import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';
import 'garden_dev_screen.dart';

class UpgradesScreen extends StatefulWidget {
  const UpgradesScreen({super.key});

  @override
  State<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends State<UpgradesScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final drone = tab == 0;
    final list = drone ? GameContent.droneUpgrades : GameContent.weatherUpgrades;
    final tint = drone ? D.teal : D.violet;

    return ScreenShell(
      title: drone ? 'Drone lab' : 'Weather lab',
      eyebrow: drone ? 'Tune the harvester' : 'Tune the sky',
      onBack: () => Navigator.pop(context),
      tint: tint,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _Tab(label: 'DRONE', active: drone, onTap: () => setState(() => tab = 0)),
                const SizedBox(width: 8),
                _Tab(label: 'WEATHER', active: !drone, onTap: () => setState(() => tab = 1)),
                const Spacer(),
                TapScale(
                  onTap: () => pushPage(context, const GardenDevScreen()),
                  child: Row(
                    children: [
                      Icon(LucideIcons.flower2, size: 15, color: D.lime),
                      const SizedBox(width: 6),
                      Text('GARDEN', style: D.label(9.5, color: D.lime, wght: 800, tracking: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 118,
            child: SpriteImg(drone ? AppAssets.drone : AppAssets.beacon)
                .animate(key: ValueKey(tab))
                .fadeIn(duration: 380.ms)
                .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _UpgradeRow(def: list[i], tint: tint),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? D.lime : D.glass(0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: active ? D.lime : D.hairline(0.12)),
        ),
        child: Text(
          label,
          style: D.label(9.5, color: active ? D.ink : D.textDim, wght: 800, tracking: 1.4),
        ),
      ),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({required this.def, required this.tint});
  final UpgradeDef def;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final level = store.upgradeLevel(def.id);
    final maxed = level >= def.maxLevel;
    final cost = GameContent.upgradeCost(def, level);
    final affordable = !maxed && store.coins >= cost;

    return GlassCard(
      radius: D.rLg,
      child: Row(
        children: [
          RingMeter(
            value: level / def.maxLevel,
            size: 46,
            color: tint,
            stroke: 3,
            child: Text('$level', style: D.numeric(14, wght: 800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(def.title, style: D.label(13, wght: 800, tracking: 0.2))),
                    Text('LV $level/${def.maxLevel}',
                        style: D.label(8.5, color: D.textFaint, wght: 700, tracking: 1)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(def.hint, style: D.body(11.5, color: D.textFaint)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: MeterBar(value: level / def.maxLevel, color: tint)),
                    const SizedBox(width: 12),
                    TapScale(
                      enabled: affordable,
                      onTap: () async {
                        final ok = await store.buyUpgrade(def);
                        if (ok) AudioService.instance.reward();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: maxed ? D.glass(0.05) : (affordable ? D.lime : D.glass(0.05)),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: maxed
                                ? D.hairline(0.12)
                                : (affordable ? D.lime : D.hairline(0.12)),
                          ),
                        ),
                        child: maxed
                            ? Text('MAX', style: D.label(9.5, color: D.textDim, wght: 800, tracking: 1.2))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SpriteImg(AppAssets.coin, size: 14),
                                  const SizedBox(width: 5),
                                  Text('$cost',
                                      style: D.numeric(12, color: affordable ? D.ink : D.textDim, wght: 800)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
