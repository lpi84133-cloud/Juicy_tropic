import 'package:flutter/material.dart';

import '../core/design.dart';
import '../data/content.dart';
import '../services/audio_service.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _name = TextEditingController(text: ProgressScope.of(context).playerName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    final total = GameContent.fruits.length;
    final found = store.discovered.where((e) => !e.startsWith('gold_')).length;

    return ScreenShell(
      title: 'Profile',
      eyebrow: 'Your grower card',
      onBack: () => Navigator.pop(context),
      showBalance: false,
      tint: D.lime,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
        children: [
          const Center(child: AvatarRing(size: 104)),
          const SizedBox(height: 22),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GARDEN NAME', style: D.label(9, color: D.textDim, wght: 800, tracking: 1.8)),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  style: D.display(20),
                  cursorColor: D.lime,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                  onSubmitted: (v) => _save(v),
                ),
                const SizedBox(height: 8),
                PillButton(
                  label: 'SAVE',
                  height: 46,
                  onTap: () => _save(_name.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              children: [
                _stat('Levels won', '${store.levelsWon}'),
                Hairline(),
                _stat('Fruits harvested', '${store.totalFruits}'),
                Hairline(),
                _stat('Best combo', 'x${store.bestCombo}'),
                Hairline(),
                _stat('Collection', '$found / $total'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String k, String v) {
    return Row(
      children: [
        Expanded(child: Text(k, style: D.body(12.5, color: D.textDim))),
        Text(v, style: D.numeric(15)),
      ],
    );
  }

  Future<void> _save(String value) async {
    final store = ProgressScope.of(context);
    await store.setName(value.trim().isEmpty ? 'Grower' : value.trim());
    AudioService.instance.reward();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved.')),
    );
  }
}
