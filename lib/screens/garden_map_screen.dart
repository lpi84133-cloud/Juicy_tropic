import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/content.dart';
import '../widgets/ui.dart';
import 'contracts_screen.dart';
import 'events_screen.dart';
import 'gameplay_screen.dart';

class GardenMapScreen extends StatelessWidget {
  const GardenMapScreen({super.key, required this.gardenId});
  final String gardenId;

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final garden = GameContent.gardenById(gardenId);
    final accent = Color(garden.accent);
    var next = (store.clearedIn(gardenId) + 1).clamp(0, garden.levels.length - 1);
    if (!store.levelOpen(gardenId, next)) next = 0;

    return ScreenShell(
      title: garden.name,
      eyebrow: '${store.gardenStars(gardenId)} of ${garden.levels.length * 3} stars collected',
      onBack: () => Navigator.pop(context),
      tint: accent,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Row(
          children: [
            IconTile(
              asset: AppAssets.coin,
              size: 52,
              accent: D.gold,
              caption: 'CONTRACTS',
              onTap: () => pushPage(context, const ContractsScreen()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: PillButton(
                label: 'PLAY STAGE ${next + 1}',
                icon: LucideIcons.play,
                trailing: const SizedBox.shrink(),
                onTap: () => pushPage(
                  context,
                  GameplayScreen(gardenId: gardenId, levelIndex: next),
                ),
              ),
            ),
            const SizedBox(width: 14),
            IconTile(
              asset: AppAssets.sunburst,
              size: 52,
              accent: D.violet,
              caption: 'EVENTS',
              onTap: () => pushPage(context, const EventsScreen()),
            ),
          ],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        itemCount: garden.levels.length,
        itemBuilder: (context, i) {
          final level = garden.levels[i];
          final open = store.levelOpen(gardenId, i);
          final stars = store.starsOf(gardenId, i);
          final isNext = i == next;
          final alignRight = i.isOdd;

          return Padding(
            padding: EdgeInsets.only(
              left: alignRight ? 46 : 0,
              right: alignRight ? 0 : 46,
              bottom: 12,
            ),
            child: TapScale(
              enabled: open,
              onTap: () => pushPage(
                context,
                GameplayScreen(gardenId: gardenId, levelIndex: i),
              ),
              child: GlassCard(
                radius: D.rLg,
                padding: const EdgeInsets.all(14),
                borderColor: isNext ? accent.withValues(alpha: 0.5) : D.hairline(0.1),
                child: Row(
                  children: [
                    RingMeter(
                      value: stars / 3,
                      size: 44,
                      color: open ? accent : D.textFaint,
                      stroke: 3,
                      child: open
                          ? Text('${i + 1}', style: D.numeric(14, wght: 800))
                          : Icon(LucideIcons.lock, size: 14, color: D.textFaint),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            open ? GameContent.goalText(level) : 'Locked stage',
                            style: D.label(12.5, color: open ? D.text : D.textFaint, wght: 700, tracking: 0.2),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            open
                                ? '${level.treeCount} trees · ${level.seconds}s'
                                    '${GameContent.eventTitle(level.event).isEmpty ? '' : ' · ${GameContent.eventTitle(level.event)}'}'
                                : 'Clear the stage before it',
                            style: D.body(11, color: D.textFaint),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(3, (s) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            LucideIcons.star,
                            size: 12,
                            color: s < stars ? D.gold : D.hairline(0.2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (40 * i).ms, duration: 320.ms).slideY(begin: 0.1);
        },
      ),
    );
  }
}
