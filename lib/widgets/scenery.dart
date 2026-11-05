import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';
import 'premium.dart';

bool _reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Le parc en feutrine de l'accueil, en décor fixe pour les autres écrans de l'enfant.
/// De jour : soleil doux et poussières de lumière. De nuit (heure du dodo, repos) : le même parc
/// sous la lune, avec des étoiles qui scintillent lentement et quelques lucioles.
class ParkBackdrop extends StatelessWidget {
  const ParkBackdrop({super.key, this.night = false, this.veil = 0});
  final bool night;

  /// Voile clair (jour) ou sombre (nuit) entre 0 et 1, pour faire ressortir des cartes.
  final double veil;

  static const dayAsset = 'assets/images/park_bg.jpg';
  static const nightAsset = 'assets/images/park_night.jpg';

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        night ? nightAsset : dayAsset,
        fit: BoxFit.cover,
        alignment: const Alignment(0.25, 0.4),
        filterQuality: FilterQuality.medium,
      ),
      if (veil > 0) ColoredBox(color: (night ? Vivid.nightTop : Colors.white).withValues(alpha: veil)),
      if (night) const NightSparkles() else ...[const SunGlow(), const FloatingParticles(count: 14)],
    ],
  );
}

/// Étoiles qui scintillent doucement en haut du ciel et lucioles qui flottent au-dessus de l'herbe.
/// Pas de clignotement : chaque étoile varie lentement (3 à 6 s), sans jamais s'éteindre.
class NightSparkles extends StatefulWidget {
  const NightSparkles({super.key});

  @override
  State<NightSparkles> createState() => _NightSparklesState();
}

class _NightSparklesState extends State<NightSparkles> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6);
  final _t = ValueNotifier<double>(0);
  final _stars = <(Offset, double, double, double)>[];
  final _flies = <(Offset, double, double)>[];

  @override
  void initState() {
    super.initState();
    final r = math.Random(11);
    for (var i = 0; i < 34; i++) {
      // (position, taille, période, phase)
      _stars.add((
        Offset(r.nextDouble(), r.nextDouble() * 0.5),
        1 + r.nextDouble() * 1.8,
        3 + r.nextDouble() * 3,
        r.nextDouble(),
      ));
    }
    for (var i = 0; i < 9; i++) {
      _flies.add((Offset(r.nextDouble(), 0.6 + r.nextDouble() * 0.3), 0.6 + r.nextDouble() * 0.6, r.nextDouble() * 10));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _NightPainter(_stars, _flies, _t), size: Size.infinite),
    ),
  );
}

class _NightPainter extends CustomPainter {
  _NightPainter(this.stars, this.flies, this.t) : super(repaint: t);
  final List<(Offset, double, double, double)> stars;
  final List<(Offset, double, double)> flies;
  final ValueNotifier<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final core = Paint();
    for (final (p, r, period, phase) in stars) {
      final a = 0.45 + 0.4 * math.sin((t.value / period + phase) * 2 * math.pi);
      final c = Offset(p.dx * size.width, p.dy * size.height);
      glow.color = Vivid.moon.withValues(alpha: 0.35 * a);
      core.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(c, r * 2.6, glow);
      canvas.drawCircle(c, r * 0.7, core);
    }
    for (final (p, speed, phase) in flies) {
      final s = t.value * speed + phase;
      final c = Offset((p.dx + math.sin(s * 0.7) * 0.04) * size.width, (p.dy + math.sin(s * 1.1 + 1) * 0.03) * size.height);
      final a = 0.55 + 0.35 * math.sin(s * 1.6);
      glow.color = Vivid.sunny.withValues(alpha: 0.45 * a);
      core.color = const Color(0xFFFFF3B0).withValues(alpha: a);
      canvas.drawCircle(c, 7, glow);
      canvas.drawCircle(c, 2, core);
    }
  }

  @override
  bool shouldRepaint(covariant _NightPainter oldDelegate) => false;
}

/// Hauteur réservée par [CloudSleepers], en multiple de la hauteur de l'image : la place des « z »
/// au-dessus (0,25), le nuage (1) et son ombre sur l'herbe en dessous (0,2).
const cloudBoxFactor = 1.45;

/// Oupi seul endormi sur son nuage, et Oupi avec Lala (épisodes où elle joue).
const oupiCloud = ('assets/images/oupi_cloud.png', 1400 / 1043, Offset(0.5, 0.16));
const duoCloud = ('assets/images/duo_cloud.png', 1400 / 985, Offset(0.52, 0.08));

/// Oupi (et Lala) qui dorment sur un nuage qui flotte : le nuage monte et descend lentement, se balance
/// à peine et respire ; de petits « z » s'envolent de la tête d'Oupi. Le nuage est une illustration
/// détourée : la pousse est repliée et le cœur éteint, comme le veut l'émotion « sommeil ».
class CloudSleepers extends StatefulWidget {
  const CloudSleepers({
    super.key,
    required this.asset,
    required this.aspect,
    required this.width,
    required this.dreamFrom,
    required this.label,
  });

  final String asset;

  /// Largeur / hauteur de l'image.
  final double aspect;
  final double width;

  /// D'où partent les « z », en fractions de l'image (la tête d'Oupi).
  final Offset dreamFrom;
  final String label;

  @override
  State<CloudSleepers> createState() => _CloudSleepersState();
}

class _CloudSleepersState extends State<CloudSleepers> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6);
  final _t = ValueNotifier<double>(0);
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = _reduceMotion(context);
    if (_still) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width, h = w / widget.aspect;
    return Semantics(
      image: true,
      label: widget.label,
      child: SizedBox(
        width: w,
        height: h * cloudBoxFactor,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final t = _t.value;
            // Entrée douce : le nuage monte et apparaît en une seconde.
            final enter = _still ? 1.0 : Curves.easeOutCubic.transform((t / 1.1).clamp(0.0, 1.0));
            final wave = math.sin(t * 2 * math.pi / 6.5);
            final bob = wave * h * 0.035;
            final drift = math.sin(t * 2 * math.pi / 15) * w * 0.035;
            final tilt = math.sin(t * 2 * math.pi / 9 + 1) * 0.022;
            final breathe = 1 + math.sin(t * 2 * math.pi / 4.2) * 0.01;
            // Ombre sur l'herbe : plus petite et plus pâle quand le nuage monte, pour qu'on le voie flotter.
            final lift = (1 - wave) / 2;
            return Opacity(
              opacity: enter,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: w * (0.17 + lift * 0.04) + drift,
                    width: w * (0.66 - lift * 0.08),
                    top: h * 1.36,
                    height: h * 0.08,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(w, h * 0.08)),
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.32 - lift * 0.1),
                            Colors.black.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(drift, bob + (1 - enter) * h * 0.15),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Halo de lune derrière le nuage.
                        Positioned(
                          left: w * 0.05,
                          right: w * 0.05,
                          top: h * 0.3,
                          height: h * 0.8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.elliptical(w, h)),
                              gradient: RadialGradient(
                                colors: [Vivid.moon.withValues(alpha: 0.28), Vivid.moon.withValues(alpha: 0)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: h * 0.25,
                          width: w,
                          height: h,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.rotationZ(tilt)..scaleByDouble(1, breathe, 1, 1),
                            child: Image.asset(widget.asset, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                          ),
                        ),
                        if (!_still)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _DreamPainter(
                                  t: t,
                                  from: Offset(widget.dreamFrom.dx * w, h * 0.25 + widget.dreamFrom.dy * h),
                                  unit: h,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Trois petits « z » qui montent en boucle, en grandissant et en s'effaçant.
class _DreamPainter extends CustomPainter {
  _DreamPainter({required this.t, required this.from, required this.unit});
  final double t;
  final Offset from;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    const period = 3.6;
    for (var k = 0; k < 3; k++) {
      final p = ((t + k * period / 3) % period) / period;
      final a = math.sin(p * math.pi);
      final s = unit * (0.07 + p * 0.07);
      final pos = from + Offset(unit * (0.06 + p * 0.22 + math.sin(p * 5) * 0.03), -unit * p * 0.3);
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: display(s, weight: 700, color: Colors.white.withValues(alpha: 0.85 * a)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DreamPainter oldDelegate) => true;
}
