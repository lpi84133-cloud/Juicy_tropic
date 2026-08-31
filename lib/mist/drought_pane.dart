import 'package:flutter/material.dart';

import '../core/design.dart';
import 'dew_chip.dart';

class DroughtPane extends StatefulWidget {
  const DroughtPane({super.key, required this.onRetryBuild});

  final WidgetBuilder onRetryBuild;

  @override
  State<DroughtPane> createState() => _DroughtPaneState();
}

class _DroughtPaneState extends State<DroughtPane> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: widget.onRetryBuild),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF0B1A14),
                Color(0xFF05090C),
                Color(0xFF101A12),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: landscape ? 48 : 28,
                vertical: landscape ? 20 : 32,
              ),
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  Text(
                    'NO INTERNET CONNECTION',
                    textAlign: TextAlign.center,
                    style: D.display(28, color: D.text, wght: 800),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Check your connection and try again',
                    textAlign: TextAlign.center,
                    style: D.body(16, color: D.textDim, wght: 500),
                  ),
                  const Spacer(),
                  Center(
                    child: _busy
                        ? Column(
                            children: <Widget>[
                              const SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFC7F94F),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Connecting...',
                                style: D.label(16, color: D.text),
                              ),
                            ],
                          )
                        : DewChip(
                            label: 'Retry',
                            width: landscape
                                ? size.width * 0.35
                                : (size.width * 0.72).clamp(220, 380),
                            onTap: _retry,
                          ),
                  ),
                  SizedBox(height: landscape ? 12 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
