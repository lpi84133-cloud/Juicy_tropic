import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'canopy/dew_sense.dart';
import 'canopy/fruit_bell.dart';
import 'canopy/grove_cache.dart';
import 'canopy/grove_probe.dart';
import 'canopy/trail_scent.dart';
import 'mist/drought_pane.dart';
import 'sap/harvest_lane.dart';
import 'trellis/dawn_guide.dart';
import 'trellis/orchard_root.dart';
import 'trellis/prime_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final GroveCache cache = GroveCache();
  await cache.warm();

  final DewSense dew = DewSense();
  final TrailScent scent = TrailScent();
  final GroveProbe probe = GroveProbe(cache);
  final FruitBell bell = FruitBell(cache);

  // Capture cold tap before later awaits swallow getInitialMessage.
  await bell.boot();

  bell.onTokenRotated = (String token) async {
    if (cache.readLane() == HarvestLane.grove) return;
    final String locale = Platform.localeName.replaceAll('-', '_');
    final Map<String, dynamic> body = await scent.assembleBody(
      locale: locale,
      pushToken: token,
    );
    await probe.query(body);
  };

  DawnGuide guide() => DawnGuide(
        cache: cache,
        dew: dew,
        scent: scent,
        probe: probe,
        bell: bell,
      );

  final bool dryFirst =
      cache.readLane() == HarvestLane.pending && !await dew.hasAdapter();

  if (dryFirst) {
    runApp(
      OrchardRoot(
        home: DroughtPane(onRetryBuild: (_) => guide()),
      ),
    );
    return;
  }

  await primeShell();
  runApp(OrchardRoot(home: guide()));
}
