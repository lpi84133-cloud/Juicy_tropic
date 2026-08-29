import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';
import 'gameplay_screen.dart';
import 'reward_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.gardenId,
    required this.levelIndex,
    required this.result,
    required this.collected,
    required this.golden,
    required this.rainUses,
    required this.usedStorm,
  });

  final String gardenId;
  final int levelIndex;
  final RunResult result;
  final Map<FruitId, int> collected;
  final Map<FruitId, int> golden;
  final int rainUses;
  final bool usedStorm;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  var _saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_saved) return;
    _saved = true;
    ProgressScope.of(context).applyRun(
      gardenId: widget.gardenId,
      levelIndex: widget.levelIndex,
      result: widget.result,
      collected: widget.collected,
      golden: widget.golden,
      rainUses: widget.rainUses,
      usedStorm: widget.usedStorm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final tint = r.won ? D.lime : D.coral;

    return ScreenShell(
      title: r.won ? 'Harvest\ncomplete' : 'Harvest\nlost',
      eyebrow: r.goalLabel,
      onBack: () => Navigator.pop(context),
      tint: tint,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: Column(
          children: [
            PillButton(
              label: r.won && r.chest ? 'OPEN CHEST' : 'CONTINUE',
              onTap: () {
                if (r.won && r.chest) {
                  AudioService.instance.chest();
                  pushPage(context, RewardScreen(result: r), replace: true);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            if (!r.won) ...[
              const SizedBox(height: 10),
              PillButton(
                label: 'TRY AGAIN',
                kind: PillKind.ghost,
                height: 50,
                trailing: const SizedBox.shrink(),
                onTap: () => pushPage(
                  context,
                  GameplayScreen(gardenId: widget.gardenId, levelIndex: widget.levelIndex),
                  replace: true,
                ),
              ),
            ],
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        children: [
          Row(
            children: List.generate(3, (i) {
              final earned = i < r.stars;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  LucideIcons.star,
                  size: 34,
                  color: earned ? D.gold : D.hairline(0.18),
                ).animate().scale(delay: (120 * i).ms, curve: Curves.easeOutBack),
              );
            }),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              children: [
                _big('COINS EARNED', '${r.coins}', D.gold),
                Hairline(),
                Row(
                  children: [
                    Expanded(child: _small('FRUIT', '${r.fruits}')),
                    Expanded(child: _small('GOLDEN', '${r.golden}')),
                    Expanded(child: _small('BEST COMBO', 'x${r.maxCombo}')),
                  ],
                ),
                Hairline(),
                Row(
                  children: [
                    Expanded(child: _small('MISSED', '${r.missed}')),
                    Expanded(child: _small('TIME LEFT', '${r.secondsLeft}s')),
                    Expanded(child: _small('CRYSTALS', '${r.crystals}')),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.08),
          const SizedBox(height: 14),
          Row(
            children: [
              _loot(AppAssets.coin, '${r.coins}'),
              const SizedBox(width: 10),
              _loot(AppAssets.crystal, '${r.crystals}'),
              if (r.chest) ...[
                const SizedBox(width: 10),
                _loot(AppAssets.chest, 'x1'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _big(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(label, style: D.label(9.5, color: D.textDim, wght: 800, tracking: 1.6))),
        Text(value, style: D.numeric(30, color: color, wght: 800)),
      ],
    );
  }

  Widget _small(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: D.label(8.5, color: D.textFaint, wght: 700, tracking: 1.2)),
        const SizedBox(height: 6),
        Text(value, style: D.numeric(17)),
      ],
    );
  }

  Widget _loot(String asset, String value) {
    return Expanded(
      child: GlassCard(
        radius: D.rMd,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            SpriteImg(asset, size: 40),
            const SizedBox(height: 8),
            Text(value, style: D.numeric(13)),
          ],
        ),
      ),
    );
  }
}
