import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';

class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    store.refreshTimedContent();
    final list = GameContent.contractPool()
        .where((c) => store.contractIds.contains(c.id))
        .toList();
    final left = Duration(
      milliseconds: (store.contractsAt + const Duration(hours: 8).inMilliseconds) -
          DateTime.now().millisecondsSinceEpoch,
    );
    final clock = left.isNegative ? 'refreshing soon' : '${left.inHours}h ${left.inMinutes % 60}m left';

    return ScreenShell(
      title: 'Contracts',
      eyebrow: clock,
      onBack: () => Navigator.pop(context),
      tint: D.gold,
      child: list.isEmpty
          ? const EmptyHint(text: 'New contracts will appear shortly.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _ContractCard(def: list[i]).animate().fadeIn(delay: (60 * i).ms).slideY(begin: 0.08),
            ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.def});
  final ContractDef def;

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final fruit = GameContent.fruit(def.fruit);
    final progress = store.contractProgress[def.id] ?? 0;
    final claimed = store.contractClaimed.contains(def.id);
    final done = progress >= def.amount;

    return GlassCard(
      radius: D.rLg,
      borderColor: done && !claimed ? D.gold.withValues(alpha: 0.5) : D.hairline(0.1),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: SpriteImg(def.needGolden ? fruit.goldenAsset : fruit.asset),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(def.title, style: D.label(12.5, wght: 800, tracking: 0.2)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        SpriteImg(AppAssets.coin, size: 13),
                        const SizedBox(width: 5),
                        Text('${def.rewardCoins}', style: D.numeric(12, color: D.gold)),
                        const SizedBox(width: 10),
                        Text('$progress / ${def.amount}', style: D.numeric(11, color: D.textDim)),
                      ],
                    ),
                  ],
                ),
              ),
              TapScale(
                enabled: done && !claimed,
                onTap: () async {
                  final ok = await store.claimContract(def);
                  if (ok) AudioService.instance.reward();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: done && !claimed ? D.gold : D.glass(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: done && !claimed ? D.gold : D.hairline(0.12)),
                  ),
                  child: Text(
                    claimed ? 'DONE' : 'CLAIM',
                    style: D.label(9.5, color: done && !claimed ? D.ink : D.textDim, wght: 800, tracking: 1.2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MeterBar(value: progress / def.amount, color: D.gold, glow: done),
        ],
      ),
    );
  }
}
