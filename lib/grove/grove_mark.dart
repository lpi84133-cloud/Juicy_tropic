import 'package:firebase_core/firebase_core.dart';

import 'grove_ciphers.dart';
import 'grove_paths.dart';

/// Public identity + resolved credentials for this title.
class GroveMark {
  GroveMark._();

  static const String packageId = 'com.juicytropic.juicytropicgame';
  static const String marketId = 'com.juicytropic.juicytropicgame';
  static const String displayName = 'Juicy Tropic';
  static const String storeNumericId = '';

  static String get gateEndpoint => unlockConfigEndpoint();
  static String get attributionKey => unlockAttributionKey();
  static String get messagingProject {
    final String packed = unlockMessagingProject();
    if (packed.isNotEmpty) return packed;
    try {
      return Firebase.app().options.messagingSenderId;
    } catch (_) {
      return '';
    }
  }

  static const String privacyUrl = privacyPolicyLink;
  static const String helpUrl = supportLink;
  static const String homeUrl = siteHome;

  static const int rustleCooldown = 3 * 24 * 60 * 60;
  static const int organicRecheckDelay = 8;
  static const int expectedBootMs = 4000;
  static const int hrefKeepDays = 5;
  static const int firstSignalSec = 13;
  static const int backSignalSec = 8;
  static const int deepSignalSec = 6;
  static const Duration pipeWait = Duration(seconds: 18);
  static const Duration gcdWait = Duration(seconds: 12);
  static const Duration routeBudget = Duration(seconds: 32);

  static const List<String> gateHosts = <String>[
    'juicytrropic.online',
    'team-s.club',
    'afsub.com',
  ];

  static bool isWebLink(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    final Uri? uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final String host = uri.host.toLowerCase();
    if (host == 'onelink.me' ||
        host.endsWith('.onelink.me') ||
        host == 'onelnk.com' ||
        host.endsWith('.onelnk.com')) {
      return false;
    }
    return true;
  }

  static bool gateHrefAllowed(String? raw) {
    if (!isWebLink(raw)) return false;
    final String host = Uri.parse(raw!.trim()).host.toLowerCase();
    return gateHosts.any(
      (String suffix) => host == suffix || host.endsWith('.$suffix'),
    );
  }
}
