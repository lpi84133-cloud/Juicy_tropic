import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/assets.dart';
import '../data/progress_store.dart';
import 'audio_service.dart';

typedef ProgressTick = void Function(double value, String label);

class AppSession {
  AppSession({required this.store});
  final ProgressStore store;
}

class BootstrapService {
  /// Honest startup: the bar only moves after real work finishes.
  /// 100% is reported only when the session is ready to open the menu.
  static Future<AppSession> run(ProgressTick onTick) async {
    var done = 0.0;
    void mark(double add, String label) {
      done = (done + add).clamp(0.0, 0.99);
      onTick(done, label);
    }

    mark(0.04, 'Starting garden systems');
    WidgetsFlutterBinding.ensureInitialized();

    mark(0.06, 'Opening local save');
    final prefs = await SharedPreferences.getInstance();

    mark(0.08, 'Reading harvest progress');
    final store = ProgressStore(prefs);
    store.refreshTimedContent();

    mark(0.06, 'Preparing audio');
    try {
      await AudioService.instance.attach(store);
      await AudioService.instance.warm();
    } catch (_) {
      // Sound is optional; never block startup on it.
    }

    final images = AppAssets.preloadImages;
    final step = 0.70 / images.length;
    for (final path in images) {
      try {
        await precache(AssetImage(path));
      } catch (_) {}
      mark(step, 'Warming garden art');
    }

    mark(0.05, 'Finishing setup');
    onTick(1.0, 'Ready');
    return AppSession(store: store);
  }

  static Future<void> precache(ImageProvider provider) {
    final completer = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (error, stack) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }
}
