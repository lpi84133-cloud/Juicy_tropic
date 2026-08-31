import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class DewSense {
  DewSense({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static const Set<ConnectivityResult> _live = <ConnectivityResult>{
    ConnectivityResult.wifi,
    ConnectivityResult.mobile,
    ConnectivityResult.ethernet,
    ConnectivityResult.vpn,
    ConnectivityResult.bluetooth,
    ConnectivityResult.other,
  };

  Future<bool> hasAdapter() async {
    final List<ConnectivityResult> states =
        await _connectivity.checkConnectivity();
    return states.any(_live.contains);
  }

  /// Stage 1 (carrier) and stage 2 (DNS). Both must pass.
  Future<bool> pathLive() async {
    if (!await hasAdapter()) return false;
    return isReachable();
  }

  Future<bool> isReachable() async {
    if (!await hasAdapter()) return false;
    const List<String> hosts = <String>['cloudflare.com', 'one.one.one.one'];
    for (final String host in hosts) {
      try {
        final List<InternetAddress> probe = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 4));
        if (probe.isNotEmpty && probe.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;
}
