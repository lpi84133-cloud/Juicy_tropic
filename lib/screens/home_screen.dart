import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/content.dart';
import '../data/progress_store.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';
import 'collection_screen.dart';
import 'contracts_screen.dart';
import 'events_screen.dart';
import 'garden_dev_screen.dart';
import 'garden_map_screen.dart';
import 'garden_select_screen.dart';
import 'profile_screen.dart';
import 'quests_screen.dart';
import 'settings_screen.dart';
import 'upgrades_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final unlocked = GameContent.gardens.where((g) => store.gardenUnlocked(g.id)).length;

    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: D.ink,
      body: AuroraBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _HomeHeader(store: store),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      width: width * 0.76,
                      child: IgnorePointer(
                        child: SpriteImg(AppAssets.gameName, fit: BoxFit.contain)
                            .animate()
                            .fadeIn(duration: 700.ms)
                            .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOutBack),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 0,
                      bottom: 0,
                      child: Center(child: _Dock(store: store)),
                    ),
                  ],
                ),
              ),
              const _ResumeCard(),
              _HomeActions(unlocked: unlocked),
            ],
          ),
        ),
      ),
    );
  }
}

/// Jump straight back into the stage the player is on.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard();

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final garden = GameContent.gardens.firstWhere(
      (g) => store.gardenUnlocked(g.id) && store.clearedIn(g.id) + 1 < g.levels.length,
      orElse: () => GameContent.gardens.first,
    );
    var next = (store.clearedIn(garden.id) + 1).clamp(0, garden.levels.length - 1);
    if (!store.levelOpen(garden.id, next)) next = 0;
    final stars = store.gardenStars(garden.id);
    final maxStars = garden.levels.length * 3;
    final accent = Color(garden.accent);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: TapScale(
        onTap: () => _push(context, GardenMapScreen(gardenId: garden.id)),
        child: GlassCard(
          radius: D.rLg,
          padding: const EdgeInsets.all(14),
          borderColor: accent.withValues(alpha: 0.3),
          child: Row(
            children: [
              RingMeter(
                value: maxStars == 0 ? 0 : stars / maxStars,
                size: 42,
                color: accent,
                stroke: 3,
                child: Text('${next + 1}', style: D.numeric(13, wght: 800)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONTINUE', style: D.label(8.5, color: accent, wght: 800, tracking: 1.8)),
                    const SizedBox(height: 5),
                    Text(
                      '${garden.name} · Stage ${next + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: D.label(12.5, wght: 700, tracking: 0.2),
                    ),
                  ],
                ),
              ),
              Text('$stars/$maxStars', style: D.numeric(12, color: D.gold)),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 18, color: D.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.store});
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final vip = 1 + store.levelsWon ~/ 6;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TapScale(
              onTap: () => _push(context, const ProfileScreen()),
              child: Row(
                children: [
                  const AvatarRing(size: 50),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          store.playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: D.label(14, wght: 800, tracking: 0.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TIER $vip · ${store.totalFruits} HARVESTED',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: D.label(8.5, color: D.textFaint, wght: 700, tracking: 1.1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatChip(asset: AppAssets.coin, value: '${store.coins}'),
              const SizedBox(height: 6),
              StatChip(asset: AppAssets.crystal, value: '${store.crystals}', accent: D.teal),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.store});
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: D.rXl,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTile(
            asset: AppAssets.gift,
            size: 50,
            accent: D.coral,
            badge: store.giftAvailable,
            onTap: () => _gift(context, store),
          ),
          const SizedBox(height: 14),
          IconTile(
            icon: LucideIcons.listChecks,
            size: 50,
            accent: D.lime,
            onTap: () => _push(context, const QuestsScreen()),
          ),
          const SizedBox(height: 14),
          IconTile(
            asset: AppAssets.crystal,
            size: 50,
            accent: D.teal,
            onTap: () => _push(context, const CollectionScreen()),
          ),
          const SizedBox(height: 14),
          IconTile(
            asset: AppAssets.coin,
            size: 50,
            accent: D.gold,
            onTap: () => _push(context, const ContractsScreen()),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 160.ms, duration: 500.ms).slideX(begin: -0.25, curve: Curves.easeOutCubic);
  }
}

class _HomeActions extends StatelessWidget {
  const _HomeActions({required this.unlocked});
  final int unlocked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 22, height: 2, color: D.lime),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$unlocked ${unlocked == 1 ? 'GARDEN' : 'GARDENS'} OPEN · WEATHER CONTROL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D.label(9, color: D.textDim, wght: 800, tracking: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Bend the weather,\nharvest the tropics.', style: D.display(24, wght: 600)),
          const SizedBox(height: 18),
          PillButton(
            label: 'PLAY',
            icon: LucideIcons.play,
            onTap: () => _push(context, const GardenSelectScreen()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'GARDEN',
                  kind: PillKind.ghost,
                  height: 50,
                  icon: LucideIcons.flower2,
                  trailing: const SizedBox.shrink(),
                  onTap: () => _push(context, const GardenDevScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  label: 'UPGRADES',
                  kind: PillKind.accent,
                  height: 50,
                  icon: LucideIcons.slidersHorizontal,
                  trailing: const SizedBox.shrink(),
                  onTap: () => _push(context, const UpgradesScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TextLink(
                label: 'EVENTS',
                icon: LucideIcons.zap,
                onTap: () => _push(context, const EventsScreen()),
              ),
              const SizedBox(width: 20),
              _TextLink(
                label: 'SETTINGS',
                icon: LucideIcons.settings,
                onTap: () => _push(context, const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 240.ms, duration: 520.ms).slideY(begin: 0.16, curve: Curves.easeOutCubic);
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: D.textDim),
          const SizedBox(width: 6),
          Text(label, style: D.label(10, color: D.textDim, wght: 800, tracking: 1.4)),
        ],
      ),
    );
  }
}

void _push(BuildContext context, Widget page) {
  AudioService.instance.open();
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

Future<void> _gift(BuildContext context, ProgressStore store) async {
  if (!store.giftAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Today\'s harvest gift is already collected.')),
    );
    return;
  }
  final coins = await store.claimDailyGift();
  AudioService.instance.reward();
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierColor: D.ink.withValues(alpha: 0.72),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DAILY GIFT', style: D.label(9.5, color: D.lime, wght: 800, tracking: 2)),
            const SizedBox(height: 10),
            Row(
              children: [
                SpriteImg(AppAssets.gift, size: 56),
                const SizedBox(width: 14),
                Text('+$coins', style: D.numeric(34, color: D.gold, wght: 800)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Coins added to your garden balance.', style: D.body(12)),
            const SizedBox(height: 16),
            PillButton(label: 'COLLECT', height: 48, onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    ),
  );
}
