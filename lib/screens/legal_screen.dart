import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/design.dart';
import '../services/legal_service.dart';
import '../widgets/ui.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.kind});
  final LegalKind kind;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final doc = await LegalService.instance.load(widget.kind);
      final controller = WebViewController()
        ..setBackgroundColor(Colors.white)
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (_) async {
              final fallback = await LegalService.instance.load(widget.kind);
              await _controller?.loadHtmlString(fallback.html);
            },
          ),
        );
      await controller.loadHtmlString(doc.html);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'This page is unavailable right now.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacy = widget.kind == LegalKind.privacy;
    return ScreenShell(
      title: privacy ? 'Privacy' : 'Support',
      eyebrow: 'Works offline',
      showBalance: false,
      onBack: () => Navigator.pop(context),
      tint: D.sky,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(D.rLg),
          child: ColoredBox(
            color: Colors.white,
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: D.body(13, color: Colors.black87),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      if (_controller != null) WebViewWidget(controller: _controller!),
                      if (_loading)
                        const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black45),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
