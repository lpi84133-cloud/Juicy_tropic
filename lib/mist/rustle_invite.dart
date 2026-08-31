import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../canopy/dew_sense.dart';
import '../canopy/fruit_bell.dart';
import '../canopy/grove_cache.dart';
import '../core/assets.dart';
import '../grove/grove_mark.dart';
import 'dew_chip.dart';
import 'juice_pane.dart';

class RustleInvite extends StatefulWidget {
  const RustleInvite({
    super.key,
    required this.cache,
    required this.bell,
    required this.dew,
    required this.contentLink,
  });

  final GroveCache cache;
  final FruitBell bell;
  final DewSense dew;
  final String contentLink;

  @override
  State<RustleInvite> createState() => _RustleInviteState();
}

class _RustleInviteState extends State<RustleInvite> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bool granted = await widget.bell.askPermission();
    if (!granted) {
      await widget.cache.writeRustleUntil(_until());
    }
    _forward();
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.cache.writeRustleUntil(_until());
    _forward();
  }

  int _until() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + GroveMark.rustleCooldown;

  void _forward() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => JuicePane(
          link: widget.contentLink,
          cache: widget.cache,
          bell: widget.bell,
          dew: widget.dew,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool landscape = media.orientation == Orientation.landscape;
    final Size size = media.size;
    final String bg = landscape
        ? AppAssets.horizontalNotifications
        : AppAssets.verticalNotifications;
    final double chipW = landscape
        ? (size.width * 0.22).clamp(148.0, 210.0)
        : (size.width * 0.70).clamp(220.0, 380.0);

    final Widget accept = DewChip(
      label: 'Accept',
      compact: landscape,
      width: chipW,
      onTap: _accept,
    );
    final Widget skip = DewChip(
      label: 'Skip',
      compact: landscape,
      width: chipW,
      onTap: _skip,
    );

    final Widget buttons = landscape
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              accept,
              const SizedBox(width: 14),
              skip,
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              accept,
              const SizedBox(height: 16),
              skip,
            ],
          );

    final Widget stage = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          bg,
          fit: BoxFit.cover,
          width: size.width,
          height: size.height,
          alignment: Alignment.center,
        ),
        Align(
          alignment: Alignment(0, landscape ? 0.82 : 0.88),
          child: buttons,
        ),
      ],
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF05090C),
        body: landscape
            ? MediaQuery.removeViewPadding(
                context: context,
                removeLeft: true,
                removeRight: true,
                removeTop: true,
                removeBottom: true,
                child: stage,
              )
            : stage,
      ),
    );
  }
}
