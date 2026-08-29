import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/app_links.dart';
import '../core/assets.dart';

enum LegalKind { privacy, support }

class LegalDocument {
  const LegalDocument({required this.html, required this.fromNetwork});
  final String html;
  final bool fromNetwork;
}

class LegalService {
  LegalService._();
  static final LegalService instance = LegalService._();

  String? urlFor(LegalKind kind) {
    switch (kind) {
      case LegalKind.privacy:
        return AppLinks.privacyPolicyUrl;
      case LegalKind.support:
        return AppLinks.supportUrl;
    }
  }

  String assetFor(LegalKind kind) {
    switch (kind) {
      case LegalKind.privacy:
        return AppAssets.privacyHtml;
      case LegalKind.support:
        return AppAssets.supportHtml;
    }
  }

  Future<LegalDocument> load(LegalKind kind) async {
    final fallback = await rootBundle.loadString(assetFor(kind));
    final url = urlFor(kind);
    final cache = await _cacheFile(kind);

    if (url == null || url.trim().isEmpty) {
      return LegalDocument(html: fallback, fromNetwork: false);
    }

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final html = _ensureReadable(response.body);
        await cache.writeAsString(html);
        return LegalDocument(html: html, fromNetwork: true);
      }
    } catch (_) {}

    if (await cache.exists()) {
      return LegalDocument(html: await cache.readAsString(), fromNetwork: false);
    }
    return LegalDocument(html: fallback, fromNetwork: false);
  }

  String _ensureReadable(String html) {
    if (html.contains('<html')) return html;
    return '''
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<style>html,body{background:#fff;color:#000;font-family:sans-serif;padding:16px;}</style>
</head><body>$html</body></html>
''';
  }

  Future<File> _cacheFile(LegalKind kind) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/legal_${kind.name}.html');
  }
}
