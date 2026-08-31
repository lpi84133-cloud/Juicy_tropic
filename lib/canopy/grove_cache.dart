import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../grove/grove_mark.dart';
import '../sap/harvest_lane.dart';

class GroveCache {
  GroveCache({FlutterSecureStorage? secure})
      : _secure = secure ?? const FlutterSecureStorage();

  static const String _kLane = 'lane_flag_q';
  static const String _kCached = 'hx_blob';
  static const String _kTtl = 'hx_ttl';
  static const String _kKept = 'hx_kept';
  static const String _kRustle = 'rustle_until';
  static const String _kBellOk = 'bell_ok';
  static const String _kBellOs = 'bell_os_no';
  static const String _kPending = 'px_blob';
  static const String _kPark = 'px_park';
  static const String _kLiveTap = 'px_live_tap';
  static const String _kLiveTapAt = 'px_live_tap_at';

  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;
  late final int _bootAt;

  Future<void> warm() async {
    _prefs = await SharedPreferences.getInstance();
    // Pick up anything native wrote in onCreate before Flutter started.
    await _prefs.reload();
    _bootAt = DateTime.now().millisecondsSinceEpoch;
  }

  HarvestLane readLane() => HarvestLane.decode(_prefs.getString(_kLane));

  Future<void> writeLane(HarvestLane lane) =>
      _prefs.setString(_kLane, lane.encode());

  Future<String?> readCachedLink() => _secure.read(key: _kCached);

  Future<void> writeCachedLink(String link) async {
    await _secure.write(key: _kCached, value: link);
    await _prefs.setInt(_kKept, _now());
  }

  int? readLinkTtl() => _prefs.getInt(_kTtl);

  Future<void> writeLinkTtl(int unixSeconds) =>
      _prefs.setInt(_kTtl, unixSeconds);

  bool isLinkStale() {
    final int? kept = _prefs.getInt(_kKept);
    if (kept == null && readLinkTtl() == null) return true;
    if (kept != null) {
      final int cap = kept + GroveMark.hrefKeepDays * 24 * 60 * 60;
      if (_now() >= cap) return true;
    }
    final int? ttl = readLinkTtl();
    return ttl != null && _now() >= ttl;
  }

  bool isBellAllowed() => _prefs.getBool(_kBellOk) ?? false;

  Future<void> markBellAllowed(bool value) =>
      _prefs.setBool(_kBellOk, value);

  bool isBellBlockedByOs() => _prefs.getBool(_kBellOs) ?? false;

  Future<void> markBellBlockedByOs() => _prefs.setBool(_kBellOs, true);

  int? readRustleUntil() => _prefs.getInt(_kRustle);

  Future<void> writeRustleUntil(int unixSeconds) =>
      _prefs.setInt(_kRustle, unixSeconds);

  bool shouldOfferRustle() {
    if (isBellAllowed()) return false;
    if (isBellBlockedByOs()) return false;
    final int? until = readRustleUntil();
    if (until == null) return true;
    return _now() >= until;
  }

  /// True only when native just parked a brand-new notification tap
  /// during THIS process boot. Stale flags from an earlier launch that
  /// died before Dart flushed the reset are rejected by the timestamp.
  bool takeLiveTap() {
    final bool live = _prefs.getBool(_kLiveTap) ?? false;
    final int at = _prefs.getInt(_kLiveTapAt) ?? 0;
    // Clear regardless so a re-entrant boot cannot see it twice.
    if (live) _prefs.remove(_kLiveTap);
    if (at != 0) _prefs.remove(_kLiveTapAt);
    // Native writes with commit() just before Flutter starts, so `at`
    // must be within a small window before this boot's Dart start.
    return live && at >= _bootAt - 4000;
  }

  Future<void> stashPending(String? link) async {
    if (link == null || !GroveMark.isWebLink(link)) {
      await _prefs.remove(_kPark);
      await _secure.delete(key: _kPending);
      return;
    }
    await _prefs.setString(_kPark, link);
    await _secure.write(key: _kPending, value: link);
  }

  Future<String?> takePending() async {
    try {
      await _prefs.reload();
      String? link = _prefs.getString(_kPark);
      if (link != null) await _prefs.remove(_kPark);
      if (link == null || link.isEmpty) {
        link = await _secure.read(key: _kPending);
        if (link != null) await _secure.delete(key: _kPending);
      }
      return GroveMark.isWebLink(link) ? link : null;
    } catch (_) {
      return null;
    }
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
