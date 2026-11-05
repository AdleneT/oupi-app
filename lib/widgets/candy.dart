import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

bool _reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Face de carte « bonbon premium », dans le style des badges : anneau en dégradé, intérieur avec une
/// bande plus claire à l'horizon, petites étincelles et reflet. [muted] pâlit la carte (verrou).
class CandyFace extends StatelessWidget {
  const CandyFace({
    super.key,
    required this.color,
    required this.width,
    required this.height,
    required this.child,
    this.muted = false,
  });

  final Color color;
  final double width;
  final double height;
  final Widget child;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final h = height;
    final radius = h * 0.14;
    final ring = h * 0.035;
    Widget face = Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.2)!, Color.lerp(color, Colors.black, 0.22)!],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - ring),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color, Colors.white, 0.5)!,
                Color.lerp(color, Colors.white, 0.12)!,
                Color.lerp(color, Colors.white, 0.34)!,
                color,
              ],
              stops: const [0, 0.6, 0.62, 1],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const IgnorePointer(child: CustomPaint(painter: _SparklePattern())),
              // Reflet en haut, comme sur un bonbon.
              Positioned(
                left: width * 0.08,
                right: width * 0.3,
                top: h * 0.03,
                height: h * 0.16,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(h),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
    if (muted) face = ColorFiltered(colorFilter: _desaturate(0.55), child: face);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: muted ? 0.15 : 0.45),
            blurRadius: h * 0.12,
            offset: Offset(0, h * 0.05),
          ),
          BoxShadow(color: Vivid.plum.withValues(alpha: 0.2), blurRadius: h * 0.05, offset: Offset(0, h * 0.025)),
        ],
      ),
      child: face,
    );
  }
}

ColorFilter _desaturate(double amount) {
  final a = 1 - amount;
  const r = 0.2126, g = 0.7152, b = 0.0722;
  return ColorFilter.matrix(<double>[
    r + a * (1 - r), g - a * g, b - a * b, 0, 0, //
    r - a * r, g + a * (1 - g), b - a * b, 0, 0,
    r - a * r, g - a * g, b + a * (1 - b), 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// Étincelles à quatre branches et petits points blancs, toujours aux mêmes places.
class _SparklePattern extends CustomPainter {
  const _SparklePattern();

  static const _stars = [(0.84, 0.14, 0.05), (0.12, 0.42, 0.035), (0.9, 0.55, 0.03), (0.74, 0.3, 0.022)];
  static const _dots = [(0.28, 0.18, 0.012), (0.62, 0.1, 0.01), (0.18, 0.72, 0.01), (0.8, 0.8, 0.012)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final u = size.shortestSide;
    for (final (x, y, s) in _stars) {
      final c = Offset(x * size.width, y * size.height);
      final r = s * u;
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, paint);
    }
    for (final (x, y, s) in _dots) {
      canvas.drawCircle(Offset(x * size.width, y * size.height), s * u, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePattern oldDelegate) => false;
}

/// Le geste des badges pour n'importe quelle carte : elle s'enfonce sous le doigt, rebondit comme un
/// ressort et flotte lentement (décalage [phase], amplitude [float] en pixels).
class Springy extends StatefulWidget {
  const Springy({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.phase = 0,
    this.float = 4,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double phase;
  final double float;

  @override
  State<Springy> createState() => _SpringyState();
}

class _SpringyState extends State<Springy> with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.value = widget.phase % 1;
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return Semantics(
      button: onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTap == null ? null : (_) => _set(true),
        onTapUp: onTap == null ? null : (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, (Curves.easeInOut.transform(_float.value) - 0.5) * 2 * widget.float),
            child: child,
          ),
          child: AnimatedScale(
            scale: _down ? 0.93 : 1.0,
            duration: Duration(milliseconds: _down ? 90 : 520),
            curve: _down ? Curves.easeOut : Curves.elasticOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
