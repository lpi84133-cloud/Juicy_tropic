import 'package:flutter/material.dart';

class DewChip extends StatefulWidget {
  const DewChip({
    super.key,
    required this.label,
    required this.onTap,
    this.compact = false,
    this.width,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;
  final double? width;

  @override
  State<DewChip> createState() => _DewChipState();
}

class _DewChipState extends State<DewChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    const List<Color> colors = <Color>[Color(0xFFC7F94F), Color(0xFF35E0C0)];
    const Color ink = Color(0xFF0B1A10);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: widget.width,
          height: widget.compact ? 48 : 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ink,
                    fontSize: widget.compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: 0.3,
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
