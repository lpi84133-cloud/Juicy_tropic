import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key, required this.result});
  final RunResult result;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Harvest\nchest',
      eyebrow: 'Bonus for a clean run',
      onBack: () => Navigator.pop(context),
      tint: D.gold,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: PillButton(
          label: 'COLLECT',
          onTap: () {
            AudioService.instance.reward();
            Navigator.pop(context);
          },
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          SpriteImg(AppAssets.chest, size: 190)
              .animate()
              .scale(duration: 520.ms, curve: Curves.easeOutBack)
              .then()
              .shimmer(duration: 1400.ms, color: D.gold.withValues(alpha: 0.5)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              child: Row(
                children: [
                  _loot(AppAssets.coin, '${result.coins}', 'COINS'),
                  _loot(AppAssets.crystal, '${result.crystals}', 'CRYSTALS'),
                  _loot(AppAssets.largeCoin, 'x1', 'BONUS'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _loot(String asset, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          SpriteImg(asset, size: 44),
          const SizedBox(height: 8),
          Text(value, style: D.numeric(16, color: D.gold)),
          const SizedBox(height: 4),
          Text(label, style: D.label(8, color: D.textFaint, wght: 700, tracking: 1.2)),
        ],
      ),
    );
  }
}
