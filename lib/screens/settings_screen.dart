import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_links.dart';
import '../core/design.dart';
import '../services/audio_service.dart';
import '../services/legal_service.dart';
import '../widgets/ui.dart';
import 'legal_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    return ScreenShell(
      title: 'Settings',
      eyebrow: 'Sound, profile and legal',
      onBack: () => Navigator.pop(context),
      showBalance: false,
      tint: D.teal,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
        children: [
          GlassCard(
            padding: const EdgeInsets.fromLTRB(18, 8, 14, 8),
            child: Column(
              children: [
                _Row(
                  icon: LucideIcons.music,
                  label: 'Music',
                  value: store.musicOn,
                  onChanged: store.setMusic,
                ),
                Hairline(),
                _Row(
                  icon: LucideIcons.volume2,
                  label: 'Sound effects',
                  value: store.soundOn,
                  onChanged: store.setSound,
                ),
                Hairline(),
                _Row(
                  icon: LucideIcons.vibrate,
                  label: 'Haptics',
                  value: store.hapticsOn,
                  onChanged: store.setHaptics,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Link(
            icon: LucideIcons.circleUser,
            label: 'Profile',
            hint: 'Garden name and harvest stats',
            onTap: () => pushPage(context, const ProfileScreen()),
          ),
          const SizedBox(height: 10),
          _Link(
            icon: LucideIcons.shieldCheck,
            label: 'Privacy Policy',
            hint: 'Readable without a connection',
            onTap: () => pushPage(context, const LegalScreen(kind: LegalKind.privacy)),
          ),
          const SizedBox(height: 10),
          _Link(
            icon: LucideIcons.lifeBuoy,
            label: 'Support',
            hint: 'Contact and FAQ',
            onTap: () => pushPage(context, const LegalScreen(kind: LegalKind.support)),
          ),
          const SizedBox(height: 22),
          Text(
            AppLinks.hasPrivacyPolicy || AppLinks.hasSupport
                ? 'Legal pages load the live site first, then fall back to a saved or built-in copy.'
                : 'Legal pages use the built-in offline copy until live URLs are added.',
            style: D.body(11.5, color: D.textFaint),
          ),
          const SizedBox(height: 10),
          Text('Juicy Tropic · v1.0.0', style: D.label(9, color: D.textFaint, wght: 700, tracking: 1.4)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: value ? D.lime : D.textFaint),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: D.label(13, wght: 700, tracking: 0.2))),
        Switch(
          value: value,
          activeThumbColor: D.ink,
          activeTrackColor: D.lime,
          inactiveThumbColor: D.textDim,
          inactiveTrackColor: D.glass(0.08),
          trackOutlineColor: WidgetStatePropertyAll(D.hairline(0.14)),
          onChanged: (v) {
            AudioService.instance.click();
            onChanged(v);
          },
        ),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: D.glass(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 17, color: D.teal),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: D.label(12.5, wght: 700, tracking: 0.2)),
                  const SizedBox(height: 4),
                  Text(hint, style: D.body(11, color: D.textFaint)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: D.textFaint),
          ],
        ),
      ),
    );
  }
}
