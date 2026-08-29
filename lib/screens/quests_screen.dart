import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  bool daily = true;

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    store.refreshTimedContent();
    final quests = daily
        ? GameContent.dailyQuestPool.where((q) => store.dailyQuestIds.contains(q.id)).toList()
        : GameContent.permanentQuests;
    final ready = quests
        .where((q) => (store.questProgress[q.id] ?? 0) >= q.target && !store.questClaimed.contains(q.id))
        .length;

    return ScreenShell(
      title: 'Quests',
      eyebrow: ready > 0 ? '$ready ready to claim' : 'Play runs to move the bars',
      onBack: () => Navigator.pop(context),
      tint: D.lime,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                _Toggle(label: 'DAILY', active: daily, onTap: () => setState(() => daily = true)),
                const SizedBox(width: 8),
                _Toggle(label: 'ONGOING', active: !daily, onTap: () => setState(() => daily = false)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              itemCount: quests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _QuestCard(quest: quests[i]).animate().fadeIn(delay: (50 * i).ms),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? D.lime : D.glass(0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: active ? D.lime : D.hairline(0.12)),
        ),
        child: Text(label, style: D.label(9.5, color: active ? D.ink : D.textDim, wght: 800, tracking: 1.4)),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});
  final QuestDef quest;

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final progress = store.questProgress[quest.id] ?? 0;
    final claimed = store.questClaimed.contains(quest.id);
    final done = progress >= quest.target;

    return GlassCard(
      borderColor: done && !claimed ? D.lime.withValues(alpha: 0.45) : D.hairline(0.1),
      child: Row(
        children: [
          RingMeter(
            value: progress / quest.target,
            size: 46,
            color: done ? D.lime : D.teal,
            stroke: 3,
            child: claimed
                ? Icon(LucideIcons.check, size: 15, color: D.lime)
                : Text('${((progress / quest.target) * 100).clamp(0, 100).floor()}',
                    style: D.numeric(11, wght: 800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, style: D.label(12.5, wght: 700, tracking: 0.2)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('$progress / ${quest.target}', style: D.numeric(11, color: D.textDim)),
                    const SizedBox(width: 10),
                    SpriteImg(AppAssets.coin, size: 13),
                    const SizedBox(width: 4),
                    Text('${quest.rewardCoins}', style: D.numeric(11, color: D.gold)),
                    if (quest.rewardCrystals > 0) ...[
                      const SizedBox(width: 8),
                      SpriteImg(AppAssets.crystal, size: 13),
                      const SizedBox(width: 4),
                      Text('${quest.rewardCrystals}', style: D.numeric(11, color: D.teal)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TapScale(
            enabled: done && !claimed,
            onTap: () async {
              final ok = await store.claimQuest(quest);
              if (ok) AudioService.instance.reward();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: done && !claimed ? D.lime : D.glass(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: done && !claimed ? D.lime : D.hairline(0.12)),
              ),
              child: Text(
                claimed ? 'DONE' : 'CLAIM',
                style: D.label(9.5, color: done && !claimed ? D.ink : D.textDim, wght: 800, tracking: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
