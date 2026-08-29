import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/content.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';

class GardenDevScreen extends StatelessWidget {
  const GardenDevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final built = store.gardenDev.length;
    final plots = GameContent.gardenPlots;

    return ScreenShell(
      title: 'Build the\ngarden',
      eyebrow: '$built of ${plots.length} structures placed',
      onBack: () => Navigator.pop(context),
      tint: D.lime,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
        itemCount: plots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final plot = plots[i];
          final owned = store.gardenDev.contains(plot.id);
          final affordable = !owned && store.coins >= plot.cost;
          // Alternating inset keeps the list from reading like a stock table.
          return Padding(
            padding: EdgeInsets.only(left: i.isOdd ? 28 : 0, right: i.isOdd ? 0 : 28),
            child: GlassCard(
              radius: D.rLg,
              padding: const EdgeInsets.all(14),
              borderColor: owned ? D.lime.withValues(alpha: 0.32) : D.hairline(0.1),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: D.glass(0.05),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SpriteImg(plot.asset),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plot.title, style: D.label(13, wght: 800, tracking: 0.2)),
                        const SizedBox(height: 5),
                        Text(
                          owned ? 'Placed in your garden' : 'Adds flair to every run',
                          style: D.body(11.5, color: D.textFaint),
                        ),
                      ],
                    ),
                  ),
                  TapScale(
                    enabled: affordable,
                    onTap: () async {
                      final ok = await store.buyPlot(plot);
                      if (ok) AudioService.instance.reward();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(
                        color: owned ? D.glass(0.05) : (affordable ? D.lime : D.glass(0.05)),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: owned
                              ? D.lime.withValues(alpha: 0.4)
                              : (affordable ? D.lime : D.hairline(0.12)),
                        ),
                      ),
                      child: owned
                          ? Icon(LucideIcons.check, size: 15, color: D.lime)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SpriteImg(AppAssets.coin, size: 14),
                                const SizedBox(width: 5),
                                Text('${plot.cost}',
                                    style: D.numeric(12, color: affordable ? D.ink : D.textDim, wght: 800)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (40 * i).ms).slideY(begin: 0.1);
        },
      ),
    );
  }
}
