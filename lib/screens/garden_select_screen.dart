import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/design.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../widgets/ui.dart';
import 'garden_map_screen.dart';

class GardenSelectScreen extends StatefulWidget {
  const GardenSelectScreen({super.key});

  @override
  State<GardenSelectScreen> createState() => _GardenSelectScreenState();
}

class _GardenSelectScreenState extends State<GardenSelectScreen> {
  late final PageController _pages;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pages = PageController(viewportFraction: 0.78)
      ..addListener(() => setState(() => _page = _pages.page ?? 0));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final gardens = GameContent.gardens;
    final index = _page.round().clamp(0, gardens.length - 1);
    final current = gardens[index];
    final open = store.gardenUnlocked(current.id);

    return ScreenShell(
      title: 'Gardens',
      eyebrow: 'Swipe to choose a plot',
      onBack: () => Navigator.pop(context),
      tint: Color(current.accent),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(gardens.length, (i) {
                final active = i == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Color(current.accent) : D.hairline(0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: open ? 'ENTER ${current.name.toUpperCase()}' : 'LOCKED',
              enabled: open,
              icon: open ? LucideIcons.arrowRight : LucideIcons.lock,
              trailing: const SizedBox.shrink(),
              onTap: () => pushPage(context, GardenMapScreen(gardenId: current.id)),
            ),
          ],
        ),
      ),
      child: PageView.builder(
        controller: _pages,
        itemCount: gardens.length,
        padEnds: true,
        itemBuilder: (context, i) {
          final g = gardens[i];
          final delta = (_page - i).abs().clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, delta * 26),
            child: Transform.scale(
              scale: 1 - delta * 0.06,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 22),
                child: _GardenCard(garden: g),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GardenCard extends StatelessWidget {
  const _GardenCard({required this.garden});
  final GardenDef garden;

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final open = store.gardenUnlocked(garden.id);
    final stars = store.gardenStars(garden.id);
    final maxStars = garden.levels.length * 3;
    final accent = Color(garden.accent);

    return GlassCard(
      radius: D.rXl,
      padding: const EdgeInsets.all(18),
      borderColor: open ? accent.withValues(alpha: 0.34) : D.hairline(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('0${garden.unlockIndex + 1}', style: D.numeric(15, color: accent, wght: 800)),
              const Spacer(),
              if (!open)
                Icon(LucideIcons.lock, size: 17, color: D.textFaint)
              else
                Row(
                  children: [
                    Icon(LucideIcons.star, size: 13, color: D.gold),
                    const SizedBox(width: 5),
                    Text('$stars/$maxStars', style: D.numeric(12, color: D.gold)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Center(
              child: Opacity(
                opacity: open ? 1 : 0.32,
                child: _FruitCluster(fruits: garden.fruitPool),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(garden.name, style: D.display(21)),
          const SizedBox(height: 7),
          Text(
            open ? garden.subtitle : 'Finish the previous garden to open this plot.',
            style: D.body(12.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final w in garden.weathers) ...[
                _WeatherPip(kind: w),
                const SizedBox(width: 6),
              ],
            ],
          ),
          if (open) ...[
            const SizedBox(height: 14),
            MeterBar(value: maxStars == 0 ? 0 : stars / maxStars, color: accent, glow: true),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 380.ms);
  }
}

class _FruitCluster extends StatelessWidget {
  const _FruitCluster({required this.fruits});
  final List<FruitId> fruits;

  @override
  Widget build(BuildContext context) {
    final items = fruits.take(4).toList();
    return SizedBox(
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < items.length; i++)
            Transform.translate(
              offset: Offset(
                (i - (items.length - 1) / 2) * 44,
                i.isEven ? -8 : 14,
              ),
              child: SpriteImg(
                GameContent.fruit(items[i]).asset,
                size: i == 0 ? 96 : 74,
              ),
            ),
        ],
      ),
    );
  }
}

class _WeatherPip extends StatelessWidget {
  const _WeatherPip({required this.kind});
  final WeatherKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: weatherColor(kind).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: weatherColor(kind).withValues(alpha: 0.3)),
      ),
      child: Icon(weatherIcon(kind), size: 15, color: weatherColor(kind)),
    );
  }
}

IconData weatherIcon(WeatherKind w) {
  switch (w) {
    case WeatherKind.calm:
      return LucideIcons.cloud;
    case WeatherKind.sun:
      return LucideIcons.sun;
    case WeatherKind.rain:
      return LucideIcons.cloudRain;
    case WeatherKind.wind:
      return LucideIcons.wind;
    case WeatherKind.storm:
      return LucideIcons.cloudLightning;
  }
}

Color weatherColor(WeatherKind w) {
  switch (w) {
    case WeatherKind.calm:
      return D.textDim;
    case WeatherKind.sun:
      return D.gold;
    case WeatherKind.rain:
      return D.sky;
    case WeatherKind.wind:
      return D.teal;
    case WeatherKind.storm:
      return D.violet;
  }
}
