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

  /// Always returns readable HTML. Never depends on the network.
  Future<LegalDocument> loadLocal(LegalKind kind) async {
    final cache = await _cacheFile(kind);
    if (await cache.exists()) {
      final text = await cache.readAsString();
      if (text.trim().isNotEmpty) {
        return LegalDocument(html: _ensureReadable(text), fromNetwork: false);
      }
    }
    final fallback = await rootBundle.loadString(assetFor(kind));
    return LegalDocument(html: fallback, fromNetwork: false);
  }

  /// Tries the live page. Returns null when offline or the request fails.
  Future<LegalDocument?> tryNetwork(LegalKind kind) async {
    final url = urlFor(kind);
    if (url == null || url.trim().isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
      if (response.statusCode != 200 || response.body.trim().isEmpty) return null;
      final html = _ensureReadable(response.body);
      final cache = await _cacheFile(kind);
      await cache.writeAsString(html);
      return LegalDocument(html: html, fromNetwork: true);
    } catch (_) {
      return null;
    }
  }

  String _ensureReadable(String html) {
    const inject = '''
<style id="jt-readable">html,body{background:#ffffff !important;color:#000000 !important;} body,p,li,h1,h2,h3,a,span,div,label,input,textarea{color:#000000 !important;} a{color:#000000 !important;text-decoration:underline;}</style>
''';
    if (html.contains('id="jt-readable"')) return html;
    if (html.contains('</head>')) {
      return html.replaceFirst('</head>', '$inject</head>');
    }
    if (html.contains('<html')) {
      return html.replaceFirst('<html', '<html><head>$inject</head>');
    }
    return '''
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
$inject
</head><body>$html</body></html>
''';
  }

  Future<File> _cacheFile(LegalKind kind) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/legal_${kind.name}.html');
  }
}
