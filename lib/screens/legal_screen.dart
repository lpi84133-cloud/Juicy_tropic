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

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final local = await LegalService.instance.loadLocal(widget.kind);
    final controller = WebViewController()
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.loadHtmlString(local.html);
    if (!mounted) return;
    setState(() => _controller = controller);

    final live = await LegalService.instance.tryNetwork(widget.kind);
    if (!mounted || live == null) return;
    await controller.loadHtmlString(live.html);
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
            child: _controller == null
                ? const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black45),
                    ),
                  )
                : WebViewWidget(controller: _controller!),
          ),
        ),
      ),
    );
  }
}
