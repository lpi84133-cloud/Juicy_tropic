import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../grove/grove_mark.dart';
import '../sap/harvest_lane.dart';
import 'grove_cache.dart';
import 'grove_mask.dart';

const String kChimeId = 'jt_grove_chime_v3';
const String kChimeTitle = 'Orchard notices';
const String _tinyIcon = '@drawable/ic_notification';

@pragma('vm:entry-point')
Future<void> groveQuietBell(RemoteMessage message) async {}

class FruitBell {
  FruitBell(this._cache);

  final GroveCache _cache;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _fm;
  String? _token;
  bool _ready = false;

  void Function(String link)? onLink;
  void Function(String token)? onTokenRotated;

  String? get token => _token;

  Future<void> boot() async {
    if (_ready) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _fm = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(groveQuietBell);

      const MethodChannel('orchard/away').setMethodCallHandler(
        (MethodCall call) async {
          if (call.method == 'awayTap') {
            deliver(call.arguments?.toString() ?? '');
          }
        },
      );

      await _prepLocal();

      final NotificationAppLaunchDetails? launched =
          await _local.getNotificationAppLaunchDetails();
      if (launched?.didNotificationLaunchApp == true) {
        final String? raw = launched!.notificationResponse?.payload;
        if (raw != null && raw.isNotEmpty) {
          try {
            deliver(
              pickHref(jsonDecode(raw) as Map<String, dynamic>) ?? '',
            );
          } catch (_) {}
        }
      }

      final RemoteMessage? initial = await _fm!.getInitialMessage().timeout(
        const Duration(seconds: 6),
        onTimeout: () => null,
      );
      if (initial != null) _onCold(initial);

      FirebaseMessaging.onMessage.listen(_onFront);
      FirebaseMessaging.onMessageOpenedApp.listen(_onWarm);
      _fm!.onTokenRefresh.listen((String t) {
        _token = t;
        onTokenRotated?.call(t);
      });
      _token = await _awaitToken();

      _ready = true;
    } catch (_) {}
  }

  Future<String?> _awaitToken() async {
    String? next = await _fm!.getToken();
    if (next != null && next.isNotEmpty) return next;
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      next = await _fm!.getToken();
      if (next != null && next.isNotEmpty) return next;
    }
    return next;
  }

  Future<void> _prepLocal() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings(_tinyIcon);
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        final String? payload = r.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final Map<String, dynamic> data =
              jsonDecode(payload) as Map<String, dynamic>;
          deliver(pickHref(data) ?? '');
        } catch (_) {}
      },
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? plugin =
          _local.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          kChimeId,
          kChimeTitle,
          description: 'Garden updates',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<bool> askPermission() async {
    if (_fm == null) return false;
    final NotificationSettings settings = await _fm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final AuthorizationStatus status = settings.authorizationStatus;
    final bool granted = status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;

    await _cache.markBellAllowed(granted);
    if (status == AuthorizationStatus.denied) {
      await _cache.markBellBlockedByOs();
    }
    if (granted) {
      _token = await _fm!.getToken() ?? _token;
      final String? ready = _token;
      if (ready != null && ready.isNotEmpty) {
        onTokenRotated?.call(ready);
      }
    }
    return granted;
  }

  void _onFront(RemoteMessage message) async {
    final RemoteNotification? n = message.notification;
    if (n == null || !Platform.isAndroid) return;

    AndroidNotificationDetails? details;
    final String? imageUrl = n.android?.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final Uint8List? bytes = await _fetchImage(imageUrl);
      if (bytes != null) {
        details = AndroidNotificationDetails(
          kChimeId,
          kChimeTitle,
          importance: Importance.high,
          priority: Priority.high,
          icon: _tinyIcon,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon:
                const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }

    details ??= const AndroidNotificationDetails(
      kChimeId,
      kChimeTitle,
      importance: Importance.high,
      priority: Priority.high,
      icon: _tinyIcon,
    );

    await _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(android: details),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  /// Live listener wins; otherwise the link waits for the next juice open.
  void deliver(String link) {
    if (!GroveMark.isWebLink(link) ||
        _cache.readLane() == HarvestLane.grove) {
      return;
    }
    if (onLink != null) {
      onLink!(link);
    } else {
      _cache.stashPending(link);
    }
  }

  void _onCold(RemoteMessage message) {
    deliver(pickHref(message.data) ?? '');
  }

  void _onWarm(RemoteMessage message) {
    deliver(pickHref(message.data) ?? '');
  }

  static const List<String> _hrefKeys = <String>[
    'deep_link',
    'target',
    'url',
    'deeplink',
    'link',
    'landing',
    'goto',
    'open_url',
    'push_url',
    'href',
  ];

  static String? pickHref(Map<String, dynamic> data) {
    for (final String key in _hrefKeys) {
      final Object? raw = data[key];
      if (raw is String && GroveMark.isWebLink(raw)) return raw.trim();
    }
    for (final Object? raw in data.values) {
      if (raw is String && GroveMark.isWebLink(raw)) return raw.trim();
    }
    return null;
  }

  Future<Uint8List?> _fetchImage(String url) async {
    try {
      final dynamic res = await groveHttp
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return res.bodyBytes as Uint8List;
    } catch (_) {}
    return null;
  }
}
