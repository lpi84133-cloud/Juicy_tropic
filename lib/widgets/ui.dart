import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/assets.dart';
import '../core/design.dart';
import '../data/progress_store.dart';
import '../services/audio_service.dart';

class ProgressScope extends InheritedNotifier<ProgressStore> {
  const ProgressScope({
    super.key,
    required ProgressStore store,
    required super.child,
  }) : super(notifier: store);

  static ProgressStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProgressScope>();
    assert(scope != null, 'ProgressScope is missing above this widget');
    return scope!.notifier!;
  }
}

void tapFeedback(BuildContext context, {bool strong = false}) {
  AudioService.instance.click();
  final scope = context.getInheritedWidgetOfExactType<ProgressScope>();
  if (scope?.notifier?.hapticsOn ?? false) {
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }
}

/// Press animation that works anywhere, with no Material/InkWell dependency.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.scale = 0.955,
    this.strongHaptic = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final double scale;
  final bool strongHaptic;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.enabled
            ? () {
                tapFeedback(context, strong: widget.strongHaptic);
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.4,
            duration: const Duration(milliseconds: 160),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Soft tropical light blooms behind every screen.
class AuroraBackdrop extends StatelessWidget {
  const AuroraBackdrop({super.key, this.tint = D.teal, this.child});
  final Color tint;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: D.ink),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _AuroraPainter(tint)),
          ?child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.tint);
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset c, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    blob(Offset(size.width * 0.86, size.height * 0.06), size.width * 0.72, tint);
    blob(Offset(size.width * 0.04, size.height * 0.34), size.width * 0.62, D.lime.withValues(alpha: 0.5));
    blob(Offset(size.width * 0.62, size.height * 0.96), size.width * 0.78, D.violet.withValues(alpha: 0.42));
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.tint != tint;
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = D.rLg,
    this.borderColor,
    this.fill = 0.055,
    this.blur = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? borderColor;
  final double fill;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: D.glass(fill),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? D.hairline(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

enum PillKind { primary, ghost, accent, danger }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = PillKind.primary,
    this.icon,
    this.trailing,
    this.height = 58,
    this.enabled = true,
    this.expand = true,
  });

  final String label;
  final VoidCallback onTap;
  final PillKind kind;
  final IconData? icon;
  final Widget? trailing;
  final double height;
  final bool enabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primary = kind == PillKind.primary;
    final accent = kind == PillKind.accent;
    final danger = kind == PillKind.danger;

    final fg = primary ? D.ink : (danger ? D.coral : D.text);
    final bg = primary
        ? D.lime
        : accent
            ? D.teal.withValues(alpha: 0.16)
            : D.glass(0.06);
    final border = primary
        ? D.lime
        : danger
            ? D.coral.withValues(alpha: 0.55)
            : accent
                ? D.teal.withValues(alpha: 0.45)
                : D.hairline(0.14);

    return TapScale(
      enabled: enabled,
      strongHaptic: primary,
      onTap: onTap,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: expand ? 22 : 26),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: border, width: 1.2),
          boxShadow: primary
              ? [BoxShadow(color: D.lime.withValues(alpha: 0.22), blurRadius: 26, offset: const Offset(0, 10))]
              : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: expand ? 1 : 0,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: D.label(14, color: fg, wght: 800, tracking: 1.4),
              ),
            ),
            ?trailing,
            if (trailing == null && expand)
              Icon(Icons.arrow_forward_rounded, size: 18, color: fg.withValues(alpha: 0.75)),
          ],
        ),
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.onTap,
    this.icon,
    this.asset,
    this.caption,
    this.size = 56,
    this.accent = D.teal,
    this.badge = false,
  });

  final VoidCallback onTap;
  final IconData? icon;
  final String? asset;
  final String? caption;
  final double size;
  final Color accent;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                padding: EdgeInsets.all(asset != null ? size * 0.16 : 0),
                decoration: BoxDecoration(
                  color: D.glass(0.06),
                  borderRadius: BorderRadius.circular(size * 0.34),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: asset != null
                    ? Image.asset(asset!, fit: BoxFit.contain)
                    : Icon(icon, color: accent, size: size * 0.44),
              ),
              if (badge)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: D.coral,
                      shape: BoxShape.circle,
                      border: Border.all(color: D.ink, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 7),
            Text(caption!, style: D.label(9.5, color: D.textDim, wght: 700, tracking: 1.1)),
          ],
        ],
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.asset, required this.value, this.accent = D.gold});
  final String asset;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: D.glass(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: D.hairline(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 20, height: 20, fit: BoxFit.contain),
          const SizedBox(width: 7),
          Text(value, style: D.numeric(13, color: accent)),
        ],
      ),
    );
  }
}

class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.value,
    this.color = D.lime,
    this.height = 6,
    this.glow = false,
  });

  final double value;
  final Color color;
  final double height;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final v = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: D.glass(0.08),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v == 0 ? 0.0001 : v,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.75), color]),
                borderRadius: BorderRadius.circular(height),
                boxShadow: glow
                    ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12)]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RingMeter extends StatelessWidget {
  const RingMeter({
    super.key,
    required this.value,
    required this.size,
    this.color = D.lime,
    this.stroke = 4,
    this.child,
  });

  final double value;
  final double size;
  final Color color;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value.isFinite ? value.clamp(0.0, 1.0) : 0.0, color, stroke),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.stroke);
  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = D.glass(0.1);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [color.withValues(alpha: 0.55), color],
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, fill);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.stroke != stroke;
}

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.inset = 0});
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: inset),
      child: Container(height: 1, color: D.hairline(0.08)),
    );
  }
}

/// Screens share this shell: oversized left-aligned title, chevron above it,
/// balances floating on the right. Deliberately off the usual centered AppBar.
class ScreenShell extends StatelessWidget {
  const ScreenShell({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.onBack,
    this.showBalance = true,
    this.tint = D.teal,
    this.trailing,
    this.bottom,
  });

  final String title;
  final Widget child;
  final String? eyebrow;
  final VoidCallback? onBack;
  final bool showBalance;
  final Color tint;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);
    return Scaffold(
      backgroundColor: D.ink,
      body: AuroraBackdrop(
        tint: tint,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (onBack != null)
                            TapScale(
                              onTap: () {
                                AudioService.instance.close();
                                onBack!();
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chevron_left_rounded, size: 18, color: tint),
                                  const SizedBox(width: 2),
                                  Text('BACK', style: D.label(9.5, color: tint, wght: 800, tracking: 1.6)),
                                ],
                              ),
                            ),
                          if (eyebrow != null && onBack == null)
                            Text(eyebrow!.toUpperCase(),
                                style: D.label(9.5, color: tint, wght: 800, tracking: 1.6)),
                          const SizedBox(height: 6),
                          Text(title, style: D.display(27)),
                          if (eyebrow != null && onBack != null) ...[
                            const SizedBox(height: 4),
                            Text(eyebrow!, style: D.body(12, color: D.textFaint)),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null)
                      trailing!
                    else if (showBalance)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatChip(asset: AppAssets.coin, value: '${store.coins}'),
                          const SizedBox(height: 6),
                          StatChip(asset: AppAssets.crystal, value: '${store.crystals}', accent: D.teal),
                        ],
                      ),
                  ],
                ),
              ),
              Expanded(child: child),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared soft page transition so navigation feels consistent everywhere.
Future<T?> pushPage<T>(BuildContext context, Widget page, {bool replace = false}) {
  AudioService.instance.open();
  final route = PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
  final navigator = Navigator.of(context);
  return replace ? navigator.pushReplacement(route) : navigator.push(route);
}

class SpriteImg extends StatelessWidget {
  const SpriteImg(this.asset, {super.key, this.size, this.fit = BoxFit.contain});
  final String asset;
  final double? size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
    );
  }
}

class AvatarRing extends StatelessWidget {
  const AvatarRing({super.key, this.size = 54, this.ring = D.lime});
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [ring, D.teal.withValues(alpha: 0.6)]),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: D.inkLift,
          border: Border.all(color: D.ink, width: 2),
        ),
        child: Icon(Icons.person_rounded, color: D.text, size: size * 0.52),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(text, textAlign: TextAlign.center, style: D.body(13)),
      ),
    );
  }
}
