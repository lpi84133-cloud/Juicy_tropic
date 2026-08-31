import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

import '../grove/grove_ciphers.dart';

// GAME THEME CATEGORY: harvest arcade (no appid/appname suffix)
// Juicy Tropic is a weather-driven tropical harvest game, not a slot
// skin and not a crash/multiplier title.

class GroveMask extends http.BaseClient {
  final http.Client _inner = http.Client();
  String _ua = 'Mozilla/5.0';

  String get userAgent => _ua;

  Future<void> prime() async {
    final String chrome = _or(unlockChromeVersion(), '149.0.7884.203');
    final String webkit = _or(unlockWebkitVersion(), '537.36');

    try {
      final DeviceInfoPlugin plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final AndroidDeviceInfo a = await plugin.androidInfo;
        final String tag = a.display.isNotEmpty ? a.display : a.id;
        _ua = 'Mozilla/5.0 (Linux; Android ${a.version.release}; '
            '${a.brand} ${a.model} Build/$tag) '
            'AppleWebKit/$webkit (KHTML, like Gecko) '
            'Chrome/$chrome Mobile Safari/$webkit';
      } else if (Platform.isIOS) {
        final IosDeviceInfo i = await plugin.iosInfo;
        final String os = i.systemVersion.replaceAll('.', '_');
        _ua = 'Mozilla/5.0 (iPhone; CPU iPhone OS $os like Mac OS X) '
            'AppleWebKit/$webkit (KHTML, like Gecko) '
            'Version/${i.systemVersion} Mobile/15E148 Safari/$webkit';
      }
    } catch (_) {
      _ua = 'Mozilla/5.0 (Linux; Android 14; Pixel 8 Build/AP2A) '
          'AppleWebKit/$webkit (KHTML, like Gecko) '
          'Chrome/$chrome Mobile Safari/$webkit';
    }
  }

  static String _or(String value, String fallback) =>
      value.isNotEmpty ? value : fallback;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => _ua);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final GroveMask groveHttp = GroveMask();
