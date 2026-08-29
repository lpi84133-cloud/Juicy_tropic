import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/design.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../widgets/ui.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  FruitRarity? filter;
  FruitId selected = FruitId.mango;
  bool goldenView = false;

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final items = GameContent.fruits
        .where((f) => filter == null || f.rarity == filter)
        .toList();
    final def = GameContent.fruit(selected);
    final found = store.discovered.contains(def.id.name);
    final goldFound = store.discovered.contains('gold_${def.id.name}');
    final total = GameContent.fruits.length;
    final owned = GameContent.fruits.where((f) => store.discovered.contains(f.id.name)).length;

    return ScreenShell(
      title: 'Collection',
      eyebrow: '$owned of $total fruits discovered',
      onBack: () => Navigator.pop(context),
      tint: D.gold,
      bottom: _Detail(
        def: def,
        found: found,
        goldFound: goldFound,
        goldenView: goldenView && goldFound,
        owned: store.fruitCounts[def.id.name] ?? 0,
        golden: store.goldenCounts[def.id.name] ?? 0,
        onFlip: goldFound ? () => setState(() => goldenView = !goldenView) : null,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _Chip(label: 'ALL', active: filter == null, onTap: () => setState(() => filter = null)),
                for (final r in FruitRarity.values)
                  if (r != FruitRarity.golden)
                    _Chip(
                      label: r.name.toUpperCase(),
                      active: filter == r,
                      onTap: () => setState(() => filter = r),
                    ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final f = items[i];
                final seen = store.discovered.contains(f.id.name);
                final gold = store.discovered.contains('gold_${f.id.name}');
                final active = f.id == selected;
                return TapScale(
                  onTap: () => setState(() {
                    selected = f.id;
                    goldenView = false;
                  }),
                  child: GlassCard(
                    radius: D.rLg,
                    padding: const EdgeInsets.all(10),
                    borderColor: active ? D.gold.withValues(alpha: 0.5) : D.hairline(0.1),
                    child: Stack(
                      children: [
                        Center(
                          child: Opacity(
                            opacity: seen ? 1 : 0.22,
                            child: SpriteImg(f.asset),
                          ),
                        ),
                        if (gold)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(color: D.gold, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (30 * i).ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? D.gold : D.glass(0.06),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: active ? D.gold : D.hairline(0.12)),
          ),
          child: Text(
            label,
            style: D.label(9.5, color: active ? D.ink : D.textDim, wght: 800, tracking: 1.3),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.def,
    required this.found,
    required this.goldFound,
    required this.goldenView,
    required this.owned,
    required this.golden,
    this.onFlip,
  });

  final FruitDef def;
  final bool found;
  final bool goldFound;
  final bool goldenView;
  final int owned;
  final int golden;
  final VoidCallback? onFlip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: GlassCard(
        child: Row(
          children: [
            TapScale(
              enabled: onFlip != null,
              onTap: onFlip ?? () {},
              child: SizedBox(
                width: 74,
                height: 74,
                child: SpriteImg(goldenView ? def.goldenAsset : def.asset),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(found ? def.name : 'Unknown fruit', style: D.label(14, wght: 800, tracking: 0.2)),
                      const SizedBox(width: 8),
                      Text(
                        found ? def.rarity.name.toUpperCase() : '???',
                        style: D.label(8.5, color: D.gold, wght: 800, tracking: 1.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    found ? def.blurb : 'Harvest this fruit to reveal its notes.',
                    style: D.body(11.5, color: D.textFaint),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${def.value}', style: D.numeric(13, color: D.lime)),
                      Text(' base', style: D.label(8, color: D.textFaint, wght: 700, tracking: 0.8)),
                      const SizedBox(width: 10),
                      Text('${def.goldenValue}', style: D.numeric(13, color: D.gold)),
                      Text(' gold', style: D.label(8, color: D.textFaint, wght: 700, tracking: 0.8)),
                      const Spacer(),
                      Text('$owned/$golden', style: D.numeric(11.5, color: D.textDim)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
