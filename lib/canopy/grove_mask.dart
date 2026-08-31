import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

import '../grove/grove_ciphers.dart';

class GroveMask extends http.BaseClient {
  final http.Client _inner = http.Client();
  String _ua = '';

  String get userAgent => _ua.isEmpty ? unlockUaHead() : _ua;

  Future<void> prime() async {
    final String chrome = unlockChromeVersion();
    final String webkit = unlockWebkitVersion();
    final String head = unlockUaHead();
    final String linux = unlockUaLinux();
    final String kit = unlockUaKit();
    final String gecko = unlockUaGecko();
    final String chromeMark = unlockUaChrome();
    final String safari = unlockUaSafari();

    try {
      final DeviceInfoPlugin plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final AndroidDeviceInfo a = await plugin.androidInfo;
        final String tag = a.display.isNotEmpty ? a.display : a.id;
        _ua = '$head ($linux ${a.version.release}; '
            '${a.brand} ${a.model} Build/$tag) '
            '$kit/$webkit ($gecko) '
            '$chromeMark$chrome $safari$webkit';
      } else if (Platform.isIOS) {
        final IosDeviceInfo i = await plugin.iosInfo;
        final String os = i.systemVersion.replaceAll('.', '_');
        _ua = '$head (${unlockUaIos()} $os ${unlockUaMac()}) '
            '$kit/$webkit ($gecko) '
            'Version/${i.systemVersion} ${unlockUaIosTail()}$webkit';
      }
    } catch (_) {
      _ua = '$head ($linux 14; Pixel 8 Build/AP2A) '
          '$kit/$webkit ($gecko) '
          '$chromeMark$chrome $safari$webkit';
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => userAgent);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final GroveMask groveHttp = GroveMask();
