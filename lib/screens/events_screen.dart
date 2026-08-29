import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../widgets/ui.dart';
import 'garden_select_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Weather\nevents',
      eyebrow: 'Seasonal modifiers',
      onBack: () => Navigator.pop(context),
      tint: D.violet,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
        children: [
          GlassCard(
            radius: D.rXl,
            padding: const EdgeInsets.all(18),
            borderColor: D.violet.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: D.lime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('LIVE NOW', style: D.label(8.5, color: D.ink, wght: 800, tracking: 1.4)),
                    ),
                    const Spacer(),
                    Icon(LucideIcons.zap, size: 17, color: D.violet),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: SpriteImg(AppAssets.sunburst, size: 108)
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 12.seconds),
                ),
                const SizedBox(height: 16),
                Text('Golden Storm', style: D.display(24)),
                const SizedBox(height: 8),
                Text(
                  'Thunder turns more of the falling harvest golden. Storm gardens pay the most while it runs.',
                  style: D.body(12.5),
                ),
                const SizedBox(height: 18),
                PillButton(
                  label: 'PLAY EVENT',
                  icon: LucideIcons.play,
                  trailing: const SizedBox.shrink(),
                  onTap: () => pushPage(context, const GardenSelectScreen()),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.08),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              children: [
                SizedBox(width: 48, height: 48, child: SpriteImg(AppAssets.stormFx)),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fruit Downpour', style: D.label(13, wght: 800, tracking: 0.2)),
                      const SizedBox(height: 5),
                      Text('Heavy rain drops the harvest in waves.', style: D.body(11.5, color: D.textFaint)),
                    ],
                  ),
                ),
                Text('SOON', style: D.label(9, color: D.textFaint, wght: 800, tracking: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Row(
              children: [
                SizedBox(width: 48, height: 48, child: SpriteImg(AppAssets.windFx)),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wind Burst', style: D.label(13, wght: 800, tracking: 0.2)),
                      const SizedBox(height: 5),
                      Text('Short gusts shake many ripe fruits at once.', style: D.body(11.5, color: D.textFaint)),
                    ],
                  ),
                ),
                Text('SOON', style: D.label(9, color: D.textFaint, wght: 800, tracking: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
