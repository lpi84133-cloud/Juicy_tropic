import 'package:audioplayers/audioplayers.dart';

import '../core/assets.dart';
import '../data/progress_store.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final List<AudioPlayer> _pool = [];
  ProgressStore? _store;
  int _cursor = 0;

  Future<void> attach(ProgressStore store) async {
    _store = store;
    if (_pool.isEmpty) {
      try {
        for (var i = 0; i < 4; i++) {
          _pool.add(AudioPlayer());
        }
      } catch (_) {
        _pool.clear();
      }
    }
  }

  Future<void> warm() async {
    // Touch players so the first in-game tap is not delayed.
    for (final p in _pool) {
      try {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
    }
  }

  Future<void> play(String asset) async {
    if (_store?.soundOn == false) return;
    if (_pool.isEmpty) return;
    final player = _pool[_cursor % _pool.length];
    _cursor++;
    try {
      await player.stop();
      await player.play(AssetSource(asset.replaceFirst('assets/', '')));
    } catch (_) {}
  }

  Future<void> click() => play(AppAssets.sfxClick);
  Future<void> open() => play(AppAssets.sfxMenuOpen);
  Future<void> close() => play(AppAssets.sfxMenuClose);
  Future<void> fruit() => play(AppAssets.sfxFruit);
  Future<void> coin() => play(AppAssets.sfxCoin);
  Future<void> gold() => play(AppAssets.sfxGold);
  Future<void> combo() => play(AppAssets.sfxCombo);
  Future<void> weather() => play(AppAssets.sfxWeather);
  Future<void> win() => play(AppAssets.sfxWin);
  Future<void> fail() => play(AppAssets.sfxFail);
  Future<void> reward() => play(AppAssets.sfxReward);
  Future<void> chest() => play(AppAssets.sfxChest);
  Future<void> lightning() => play(AppAssets.sfxLightning);
}
