import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../grove/grove_mark.dart';
import '../sap/grove_verdict.dart';
import 'grove_cache.dart';
import 'grove_mask.dart';

class GroveProbe {
  GroveProbe(this._cache);

  final GroveCache _cache;

  Future<GroveVerdict> query(Map<String, dynamic> body) async {
    final String endpoint = GroveMark.gateEndpoint;
    if (endpoint.isEmpty) {
      return GroveVerdict.denied('no-endpoint');
    }

    try {
      final dynamic response = await groveHttp
          .post(
            Uri.parse(endpoint),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(GroveMark.pipeWait);

      if (kDebugMode) {
        debugPrint(
          '[GroveProbe] Response: ${response.statusCode} ${response.body}',
        );
      }

      if (response.statusCode != 200) {
        return GroveVerdict.denied('http-${response.statusCode}');
      }

      final Map<String, dynamic> map =
          jsonDecode(response.body) as Map<String, dynamic>;
      final GroveVerdict verdict = GroveVerdict.fromMap(map);
      if (verdict.allowed &&
          verdict.hasLink &&
          !GroveMark.gateHrefAllowed(verdict.link)) {
        return GroveVerdict.denied('host');
      }

      if (verdict.allowed && verdict.hasLink) {
        await _cache.writeCachedLink(verdict.link!);
        if (verdict.ttl != null) {
          await _cache.writeLinkTtl(verdict.ttl!);
        }
      }
      return verdict;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GroveProbe] transport: $e');
      }
      return GroveVerdict.dropped(e.toString());
    }
  }
}
