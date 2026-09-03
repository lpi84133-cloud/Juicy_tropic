import 'dart:async';
import 'dart:io';

import '../canopy/dew_sense.dart';
import '../canopy/fruit_bell.dart';
import '../canopy/grove_cache.dart';
import '../canopy/grove_probe.dart';
import '../canopy/trail_scent.dart';
import '../grove/grove_mark.dart';
import '../sap/dawn_pick.dart';
import '../sap/grove_verdict.dart';
import '../sap/harvest_lane.dart';

/// Single decide() for Boot. Parallel rebuilds share one run.
/// A new Retry constructs a new DawnGuide → a new steer → a new pass.
class DawnSteer {
  DawnSteer({
    required this.cache,
    required this.dew,
    required this.scent,
    required this.probe,
    required this.bell,
  });

  final GroveCache cache;
  final DewSense dew;
  final TrailScent scent;
  final GroveProbe probe;
  final FruitBell bell;

  Future<DawnPick>? _busy;

  Future<DawnPick> decide({required void Function(double) onFill}) =>
      _busy ??= _decide(onFill).whenComplete(() => _busy = null);

  Future<DawnPick> _decide(void Function(double) fill) async {
    await bell.boot();
    fill(0.18);

    // A) keep → white immediately. Never ask AF/gate again.
    if (cache.readLane() == HarvestLane.grove) {
      fill(1);
      return const GrovePick();
    }

    // B) Offline gate. Returning juice users MUST reach the verdict
    //    endpoint so a config-side URL change lands on the WebView
    //    on the very next boot. A DNS pre-probe (dns.google /
    //    quad9.net) can lie under captive-portal / VPN / carrier
    //    hiccups even though the gate host itself is reachable,
    //    which pinned the WebView to a stale cached URL. So for
    //    the juice lane we only require a live network adapter and
    //    let the POST itself decide reachability — its transport
    //    failure still falls back to cache in _backJuice.
    //    First launch (pending) and grove keep the strict probe.
    final HarvestLane lane = cache.readLane();
    final bool aliveEnough = lane == HarvestLane.juice
        ? await dew.hasAdapter()
        : await dew.pathLive();
    if (!aliveEnough) {
      if (lane == HarvestLane.juice) {
        final String? cached = await cache.readCachedLink();
        if (cached != null &&
            !cache.isLinkStale() &&
            GroveMark.isWebLink(cached)) {
          fill(1);
          return JuicePick(cached);
        }
      }
      return const DryPick();
    }
    fill(0.42);

    // C) parked URL only if this boot is a real notification tap.
    final String? parked = await cache.takePending();
    if (parked != null &&
        GroveMark.isWebLink(parked) &&
        bell.liveTap) {
      await cache.writeLane(HarvestLane.juice);
      unawaited(_quietSync());
      fill(1);
      return JuicePick(parked, fromPush: true);
    }
    if (parked != null) {
      await cache.stashPending(null);
    }

    return switch (lane) {
      HarvestLane.grove => _backGrove(fill),
      HarvestLane.juice => _backJuice(fill),
      HarvestLane.pending => _firstFog(fill),
    };
  }

  /// D) first decision. OneLink lives on AppsFlyer as deferred attribution.
  Future<DawnPick> _firstFog(void Function(double) fill) async {
    fill(0.46);
    await scent.ignite();
    await scent.waitSignals(installSeconds: GroveMark.firstSignalSec);
    fill(0.74);

    final GroveVerdict verdict = await _ask();
    if (verdict.allowed &&
        verdict.hasLink &&
        GroveMark.gateHrefAllowed(verdict.link)) {
      await cache.writeLane(HarvestLane.juice);
      fill(1);
      return JuicePick(verdict.link!);
    }
    if (verdict.transport) {
      return const DryPick();
    }
    await cache.writeLane(HarvestLane.grove);
    fill(1);
    return const GrovePick();
  }

  /// E) repeat gray: ask gate so a config URL change applies, else cache,
  /// else Offline. Never demote to white.
  Future<DawnPick> _backJuice(void Function(double) fill) async {
    final String? cached = await cache.readCachedLink();
    final bool haveCache = cached != null && GroveMark.isWebLink(cached);

    await scent.ignite();
    fill(0.60);
    if (!haveCache) {
      await scent.waitSignals(installSeconds: GroveMark.backSignalSec);
    }
    final GroveVerdict verdict = await _ask();
    if (verdict.allowed &&
        verdict.hasLink &&
        GroveMark.gateHrefAllowed(verdict.link)) {
      fill(1);
      return JuicePick(verdict.link!);
    }
    if (haveCache) {
      fill(1);
      return JuicePick(cached);
    }
    return const DryPick();
  }

  Future<DawnPick> _backGrove(void Function(double) fill) async {
    fill(1);
    return const GrovePick();
  }

  Future<GroveVerdict> _ask({String? token}) async {
    final String locale = Platform.localeName.replaceAll('-', '_');
    final Map<String, dynamic> body = await scent.assembleBody(
      locale: locale,
      pushToken: token ?? bell.token,
    );
    return probe.query(body);
  }

  Future<void> _quietSync() async {
    try {
      await scent.ignite();
      await scent.waitSignals();
      await _ask();
    } catch (_) {}
  }
}
