import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

import '../grove/grove_ciphers.dart';
import '../grove/grove_mark.dart';
import 'grove_mask.dart';

class TrailScent {
  AppsflyerSdk? _sdk;

  Map<String, dynamic>? _install;
  Map<String, dynamic>? _deep;
  Map<String, dynamic>? _open;

  final Completer<Map<String, dynamic>> _installReady =
      Completer<Map<String, dynamic>>();
  final Completer<void> _deepReady = Completer<void>();

  bool _lit = false;

  Future<void> ignite() async {
    if (_lit) return;
    _lit = true;

    final String devKey = GroveMark.attributionKey;
    if (devKey.isEmpty) {
      _finishInstall(<String, dynamic>{});
      _finishDeep();
      return;
    }

    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: GroveMark.storeNumericId.isNotEmpty
          ? GroveMark.storeNumericId
          : GroveMark.packageId,
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 10,
    );

    final AppsflyerSdk sdk = AppsflyerSdk(options);
    _sdk = sdk;

    sdk.onInstallConversionData((dynamic res) async {
      final Map<String, dynamic> payload = _unwrap(res);
      if (kDebugMode) {
        debugPrint('[TrailScent] onInstallConversionData: $payload');
      }
      final String? status = payload['af_status']?.toString();
      if (status == null || status.isEmpty || status == 'Organic') {
        if (status == 'Organic') {
          await Future<void>.delayed(
            Duration(seconds: GroveMark.organicRecheckDelay),
          );
        }
        final Map<String, dynamic>? retry = await _gcdRecheck();
        if (kDebugMode && retry != null) {
          debugPrint('[TrailScent] GCD retry data: $retry');
        }
        _install = retry ?? payload;
      } else {
        _install = payload;
      }
      _finishInstall(_install ?? <String, dynamic>{});
    });

    sdk.onAppOpenAttribution((dynamic res) {
      _open = _unwrap(res);
    });

    sdk.onDeepLinking((DeepLinkResult result) {
      final Map<String, dynamic>? click = result.deepLink?.clickEvent;
      if (click != null) {
        _deep = Map<String, dynamic>.from(click);
        if (kDebugMode) {
          debugPrint('[TrailScent] onDeepLinking: $_deep');
        }
      }
      _finishDeep();
    });

    try {
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (_) {
      _finishInstall(<String, dynamic>{});
      _finishDeep();
    }
  }

  Future<Map<String, dynamic>> awaitInstall({int seconds = 13}) {
    return _installReady.future.timeout(
      Duration(seconds: seconds),
      onTimeout: () => <String, dynamic>{},
    );
  }

  Future<void> awaitDeep() {
    return _deepReady.future.timeout(
      Duration(seconds: GroveMark.deepSignalSec),
      onTimeout: () {},
    );
  }

  Future<void> waitSignals({int installSeconds = 13}) {
    return Future.wait<void>(<Future<void>>[
      awaitInstall(seconds: installSeconds),
      awaitDeep(),
    ]);
  }

  Future<String?> uid() async {
    if (_sdk == null) return null;
    try {
      return await _sdk!.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> assembleBody({
    required String locale,
    String? pushToken,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};

    if (_install != null) body.addAll(_install!);
    _open?.forEach((String k, dynamic v) => body.putIfAbsent(k, () => v));
    _deep?.forEach((String k, dynamic v) => body.putIfAbsent(k, () => v));

    String afId = await uid() ?? '';
    if (afId.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      afId = await uid() ?? '';
    }
    body['af_id'] = afId;
    body['bundle_id'] = GroveMark.packageId;
    body['os'] = Platform.isAndroid ? 'Android' : 'iOS';
    body['store_id'] = GroveMark.marketId;
    body['locale'] = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
    }
    final String project = GroveMark.messagingProject;
    if (project.isNotEmpty && pushToken != null && pushToken.isNotEmpty) {
      body['firebase_project_id'] = project;
    }

    if (kDebugMode) {
      debugPrint('[TrailScent] gate body: ${jsonEncode(body)}');
    }
    return body;
  }

  Future<Map<String, dynamic>?> _gcdRecheck() async {
    try {
      final String? deviceId = await uid();
      if (deviceId == null) return null;
      final String appId =
          Platform.isIOS ? GroveMark.storeNumericId : GroveMark.packageId;
      final String url = unlockGcdUrl(appId, deviceId);
      if (url.isEmpty) return null;

      final dynamic response = await groveHttp.get(
        Uri.parse(url),
        headers: <String, String>{
          'Authorization': 'Bearer ${GroveMark.attributionKey}',
        },
      ).timeout(GroveMark.gcdWait);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  void _finishInstall(Map<String, dynamic> data) {
    if (!_installReady.isCompleted) _installReady.complete(data);
  }

  void _finishDeep() {
    if (!_deepReady.isCompleted) _deepReady.complete();
  }

  static Map<String, dynamic> _unwrap(dynamic res) {
    if (res is! Map) return <String, dynamic>{};
    final dynamic inner = res['payload'] ?? res['data'] ?? res;
    if (inner is Map) {
      return inner.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v),
      );
    }
    return <String, dynamic>{};
  }
}
