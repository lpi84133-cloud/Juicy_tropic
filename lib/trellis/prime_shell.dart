import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../canopy/fruit_bell.dart';
import '../canopy/grove_mask.dart';

bool _primed = false;

/// Firebase + device UA. Safe to call more than once.
Future<void> primeShell() async {
  if (_primed) return;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(groveQuietBell);
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  } catch (_) {}
  await groveHttp.prime();
  _primed = true;
}
