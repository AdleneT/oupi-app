import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Les émotions de la bible (GDD §3) : chacune a sa pousse et la couleur du cœur.
enum Emotion { joy, sadness, fear, anger, sleepy }

/// Couleur du cœur du front selon l'émotion (décision du 4 nov. : bleu tristesse, jaune joie).
Color? heartColorFor(Emotion e) => switch (e) {
  Emotion.joy => Vivid.sunny,
  Emotion.sadness => const Color(0xFF4A90E2),
  Emotion.fear => Vivid.grape,
  Emotion.anger => Vivid.coral,
  Emotion.sleepy => null,
};

/// Description d'un personnage découpé en calques (outil : tool/SpritePrep.cs).
/// Toutes les positions sont des fractions de l'image (0 à 1).
class LiveRig {
  const LiveRig({
    required this.body,
    required this.sprout,
    required this.aspect,
    required this.pivot,
    this.eyes = const [],
    this.heart,
    this.heartSize = 0.13,
    this.lidColor = const Color(0xFFF6A666),
  });

  final String body;
  final String sprout;

  /// Largeur / hauteur de l'image.
  final double aspect;

  /// Base de la tige : la pousse pivote autour de ce point.
  final Offset pivot;
  final List<Rect> eyes;
  final Offset? heart;
  final double heartSize;
  final Color lidColor;
}

/// Oupi debout dans une pose naturelle, bras le long du corps (planche de poses Higgsfield, 4 nov. 2026).
const oupiIdleRig = LiveRig(
  body: 'assets/images/live_oupi_idle_body.png',
  sprout: 'assets/images/live_oupi_idle_sprout.png',
  aspect: 592 / 800,
  pivot: Offset(0.4964, 0.1938),
  eyes: [Rect.fromLTWH(0.3142, 0.3613, 0.1081, 0.0925), Rect.fromLTWH(0.5946, 0.3600, 0.1064, 0.0925)],
  heart: Offset(0.502, 0.277),
  heartSize: 0.12,
);

/// Personnage animé façon « Live 2D », à partir des planches validées :
/// respiration, pousse qui bouge selon l'émotion, cœur qui s'illumine, clignement des yeux,
/// petit saut et cœurs qui s'envolent quand l'enfant le touche.
class LiveCharacter extends StatefulWidget {
  const LiveCharacter({
    super.key,
    required this.rig,
    required this.height,
    this.emotion = Emotion.joy,
    this.entranceDelay = Duration.zero,
    this.label,
    this.interactive = true,
  });

  final LiveRig rig;
  final double height;
  final Emotion emotion;

  /// Apparition en rebond, décalée pour chorégraphier l'arrivée des personnages.
  final Duration entranceDelay;
  final String? label;
  final bool interactive;

  @override
  State<LiveCharacter> createState() => _LiveCharacterState();
}

class _LiveCharacterState extends State<LiveCharacter> with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _time = ValueNotifier<double>(0);
  late final AnimationController _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
  final _random = math.Random();
  final List<_Puff> _puffs = [];
  double _nextBlink = 2.2;
  double _blinkStart = -10;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.entranceDelay, () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      _ticker.stop();
      _entrance.value = 1;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    if (t >= _nextBlink) {
      _blinkStart = t;
      // Parfois un double clignement, comme un vrai regard.
      _nextBlink = t + (_random.nextDouble() < 0.2 ? 0.35 : 2.6 + _random.nextDouble() * 3.2);
    }
    _puffs.removeWhere((p) => t - p.born > p.life);
    _time.value = t;
  }

  void _onTap() {
    if (!widget.interactive) return;
    HapticFeedback.lightImpact();
    _hop.forward(from: 0);
    final t = _time.value;
    for (var i = 0; i < 5; i++) {
      _puffs.add(
        _Puff(
          born: t + i * 0.06,
          life: 1.6,
          dx: (_random.nextDouble() - 0.5) * 0.7,
          size: 0.05 + _random.nextDouble() * 0.04,
          color: [Vivid.berry, Vivid.coral, Vivid.sunny, Colors.white][i % 4],
        ),
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _entrance.dispose();
    _hop.dispose();
    _time.dispose();
    super.dispose();
  }

  double _blinkAmount(double t) {
    final dt = t - _blinkStart;
    const dur = 0.18;
    if (dt < 0 || dt > dur) return 0;
    return math.sin(dt / dur * math.pi);
  }

  /// Angle (radians) et étirement de la pousse selon l'émotion.
  (double, double) _sprout(double t, double hopT) {
    final wiggle = hopT > 0 ? math.sin(hopT * math.pi * 6) * 0.35 * (1 - hopT) : 0.0;
    switch (widget.emotion) {
      case Emotion.joy:
        return (math.sin(t * 2 * math.pi / 2.6) * 0.09 + wiggle, 1.0 + math.sin(t * 2 * math.pi / 2.6) * 0.015);
      case Emotion.sadness:
        return (0.78 + math.sin(t * 2 * math.pi / 4) * 0.03 + wiggle * 0.3, 0.94);
      case Emotion.fear:
        return (math.sin(t * 2 * math.pi * 7) * 0.06 + wiggle, 0.98);
      case Emotion.anger:
        return (math.sin(t * 2 * math.pi * 11) * 0.02, 1.1);
      case Emotion.sleepy:
        return (2.5 + math.sin(t * 2 * math.pi / 5) * 0.03, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rig = widget.rig;
    final h = widget.height;
    final w = h * rig.aspect;
    final body = Image.asset(rig.body, width: w, height: h, fit: BoxFit.fill, filterQuality: FilterQuality.medium);
    final sprout = Image.asset(rig.sprout, width: w, height: h, fit: BoxFit.fill, filterQuality: FilterQuality.medium);

    Widget character = AnimatedBuilder(
      animation: Listenable.merge([_time, _hop]),
      builder: (context, _) {
        final t = _reduceMotion ? 0.0 : _time.value;
        final hopT = _hop.isAnimating ? _hop.value : 0.0;
        final breath = (math.sin(t * 2 * math.pi / 3.2) + 1) / 2;
        // Saut : écrasement, détente, retombée.
        final jump = hopT > 0 ? math.sin(hopT * math.pi) : 0.0;
        final squash = hopT > 0 && hopT < 0.18 ? math.sin(hopT / 0.18 * math.pi) * 0.08 : 0.0;
        final (angle, stretch) = _sprout(t, hopT);
        final pivot = Offset(rig.pivot.dx * w, rig.pivot.dy * h);
        final heartColor = heartColorFor(widget.emotion);
        final heartPulse = 0.45 + 0.25 * (math.sin(t * 2 * math.pi / 2.4) + 1) / 2 + (hopT > 0 ? 0.35 * (1 - hopT) : 0);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Ombre au sol : elle rétrécit quand le personnage saute.
            Positioned(
              bottom: -h * 0.015,
              child: Container(
                width: w * 0.68 * (1 - jump * 0.3),
                height: h * 0.07,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(w * 0.34, h * 0.035)),
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.26 - jump * 0.1),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -jump * h * 0.09),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(1 + squash - breath * 0.004, 1 - squash + breath * 0.02, 1),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      body,
                      CustomPaint(
                        size: Size(w, h),
                        painter: _FacePainter(
                          rig: rig,
                          blink: _reduceMotion ? 0 : _blinkAmount(t),
                          heartColor: heartColor,
                          heartAlpha: heartPulse.clamp(0, 1),
                        ),
                      ),
                      Transform(
                        transform: Matrix4.identity()
                          ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
                          ..rotateZ(angle)
                          ..scaleByDouble(1, stretch, 1, 1)
                          ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1),
                        child: sprout,
                      ),
                      IgnorePointer(
                        child: CustomPaint(size: Size(w, h), painter: _PuffPainter(_puffs, t, pivot)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    character = AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final e = Curves.elasticOut.transform(_entrance.value.clamp(0, 1));
        final fade = Curves.easeOut.transform((_entrance.value * 2).clamp(0, 1));
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, (1 - e) * h * 0.25),
            child: Transform.scale(scale: 0.7 + 0.3 * e, alignment: Alignment.bottomCenter, child: child),
          ),
        );
      },
      child: character,
    );

    return Semantics(
      label: widget.label,
      button: widget.interactive,
      child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _onTap, child: character),
    );
  }
}

class _Puff {
  _Puff({required this.born, required this.life, required this.dx, required this.size, required this.color});
  final double born, life, dx, size;
  final Color color;
}

/// Petits cœurs qui s'envolent de la tête quand on touche le personnage.
class _PuffPainter extends CustomPainter {
  _PuffPainter(this.puffs, this.t, this.origin);
  final List<_Puff> puffs;
  final double t;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in puffs) {
      final age = (t - p.born) / p.life;
      if (age < 0 || age > 1) continue;
      final ease = Curves.easeOut.transform(age);
      final pos = origin + Offset(p.dx * size.width * ease + math.sin(age * 6) * size.width * 0.03, -size.height * 0.35 * ease);
      final s = size.width * p.size * (0.6 + ease * 0.6);
      final paint = Paint()..color = p.color.withValues(alpha: (1 - age).clamp(0, 1));
      canvas.drawPath(_heartPath(pos, s), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PuffPainter oldDelegate) => true;
}

Path _heartPath(Offset c, double s) {
  final p = Path();
  p.moveTo(c.dx, c.dy + s * 0.35);
  p.cubicTo(c.dx - s * 0.9, c.dy - s * 0.2, c.dx - s * 0.45, c.dy - s * 0.85, c.dx, c.dy - s * 0.4);
  p.cubicTo(c.dx + s * 0.45, c.dy - s * 0.85, c.dx + s * 0.9, c.dy - s * 0.2, c.dx, c.dy + s * 0.35);
  p.close();
  return p;
}

/// Cœur lumineux et paupières par-dessus le corps.
class _FacePainter extends CustomPainter {
  _FacePainter({required this.rig, required this.blink, required this.heartColor, required this.heartAlpha});
  final LiveRig rig;
  final double blink;
  final Color? heartColor;
  final double heartAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final heart = rig.heart;
    if (heart != null && heartColor != null) {
      final c = Offset(heart.dx * size.width, heart.dy * size.height);
      final s = rig.heartSize * size.width;
      canvas.drawPath(
        _heartPath(c, s * 0.95),
        Paint()
          ..color = heartColor!.withValues(alpha: heartAlpha * 0.75)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.35),
      );
      canvas.drawPath(_heartPath(c, s * 0.62), Paint()..color = heartColor!.withValues(alpha: heartAlpha * 0.55));
    }
    if (blink <= 0.02) return;
    for (final e in rig.eyes) {
      final r = Rect.fromLTWH(
        e.left * size.width,
        e.top * size.height,
        e.width * size.width,
        e.height * size.height,
      ).inflate(size.width * 0.012);
      canvas.save();
      canvas.clipPath(Path()..addOval(r));
      final lidBottom = r.top + r.height * blink;
      canvas.drawRect(
        Rect.fromLTRB(r.left, r.top, r.right, lidBottom),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rig.lidColor, Color.lerp(rig.lidColor, Colors.brown, 0.18)!],
          ).createShader(Rect.fromLTRB(r.left, r.top, r.right, lidBottom + 1)),
      );
      canvas.restore();
      // Cils : un trait courbe au bord de la paupière.
      final lash = Path()
        ..moveTo(r.left + r.width * 0.05, lidBottom - r.height * 0.05)
        ..quadraticBezierTo(
          r.center.dx,
          lidBottom + r.height * 0.08 * blink,
          r.right - r.width * 0.05,
          lidBottom - r.height * 0.05,
        );
      canvas.drawPath(
        lash,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.009
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF4A2A1C).withValues(alpha: blink.clamp(0, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) =>
      oldDelegate.blink != blink || oldDelegate.heartAlpha != heartAlpha || oldDelegate.heartColor != heartColor;
}

enum _Act { idle, wave, walk }

/// Oupi vivant sur l'accueil : il se promène (vrai pas en deux images), s'arrête, se tourne vers
/// l'enfant, fait coucou, respire, cligne des yeux ; la pousse et le cœur suivent l'émotion.
/// À placer dans un `Positioned.fill` : il se déplace entre [minX] et [maxX], pieds sur [groundY].
class OupiActor extends StatefulWidget {
  const OupiActor({
    super.key,
    required this.height,
    required this.groundY,
    required this.minX,
    required this.maxX,
    this.emotion = Emotion.joy,
  });

  final double height;
  final double groundY;
  final double minX;
  final double maxX;
  final Emotion emotion;

  @override
  State<OupiActor> createState() => _OupiActorState();
}

class _OupiActorState extends State<OupiActor> with TickerProviderStateMixin {
  static const _wave = 'assets/images/oupi_wave.png';
  static const _walk = ['assets/images/oupi_walk1.png', 'assets/images/oupi_walk2.png'];
  static const _waveAspect = 583 / 800;
  static const _walkAspect = 357 / 800;

  late final Ticker _ticker = createTicker(_tick);
  final _time = ValueNotifier<double>(0);
  late final AnimationController _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
  final _random = math.Random();
  final List<_Puff> _puffs = [];

  _Act _act = _Act.idle;
  double _actStart = 0;
  double _idleFor = 1.4; // Premier geste : un coucou peu après l'arrivée.
  bool _waveNext = true;
  double? _x;
  double _target = 0;
  int _facing = 1;
  double _last = 0;
  double _switchedAt = -1;
  double _nextBlink = 2.0;
  double _blinkStart = -10;
  double _hopStart = -10;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      _ticker.stop();
      _entrance.value = 1;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _entrance.dispose();
    _time.dispose();
    super.dispose();
  }

  void _go(_Act act, double t) {
    _act = act;
    _actStart = t;
    _switchedAt = t;
  }

  void _decide(double t) {
    final span = widget.maxX - widget.minX;
    if (_waveNext || span < widget.height * 0.2) {
      _waveNext = false;
      _go(_Act.wave, t);
      return;
    }
    // Une destination assez loin pour que la marche se voie.
    double target;
    var tries = 0;
    do {
      target = widget.minX + _random.nextDouble() * span;
      tries++;
    } while ((target - (_x ?? target)).abs() < span * 0.3 && tries < 8);
    _target = target;
    _facing = target >= (_x ?? target) ? 1 : -1;
    _waveNext = _random.nextDouble() < 0.5;
    _go(_Act.walk, t);
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = (t - _last).clamp(0.0, 0.1);
    _last = t;
    _x ??= (widget.minX + widget.maxX) / 2;
    switch (_act) {
      case _Act.idle:
        if (t - _actStart > _idleFor) _decide(t);
      case _Act.wave:
        if (t - _actStart > 2.6) {
          _idleFor = 2.2 + _random.nextDouble() * 2.5;
          _go(_Act.idle, t);
        }
      case _Act.walk:
        _x = _x! + _facing * widget.height * 0.34 * dt;
        if ((_facing > 0 && _x! >= _target) || (_facing < 0 && _x! <= _target)) {
          _x = _target;
          _idleFor = 1.6 + _random.nextDouble() * 2.4;
          _go(_Act.idle, t);
        }
    }
    _x = _x!.clamp(widget.minX, widget.maxX);
    if (_act == _Act.idle && t >= _nextBlink) {
      _blinkStart = t;
      _nextBlink = t + (_random.nextDouble() < 0.2 ? 0.35 : 2.4 + _random.nextDouble() * 3);
    }
    _puffs.removeWhere((p) => t - p.born > p.life);
    _time.value = t;
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    final t = _time.value;
    _hopStart = t;
    if (_act != _Act.wave) _go(_Act.wave, t);
    for (var i = 0; i < 5; i++) {
      _puffs.add(
        _Puff(
          born: t + i * 0.06,
          life: 1.6,
          dx: (_random.nextDouble() - 0.5) * 0.7,
          size: 0.05 + _random.nextDouble() * 0.04,
          color: [Vivid.berry, Vivid.coral, Vivid.sunny, Colors.white][i % 4],
        ),
      );
    }
  }

  double _blink(double t) {
    final dt = t - _blinkStart;
    const dur = 0.18;
    if (dt < 0 || dt > dur) return 0;
    return math.sin(dt / dur * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    return AnimatedBuilder(
      animation: Listenable.merge([_time, _entrance]),
      builder: (context, _) {
        final t = _reduceMotion ? 0.0 : _time.value;
        final x = _x ?? (widget.minX + widget.maxX) / 2;
        final act = _reduceMotion ? _Act.idle : _act;
        final since = t - _actStart;
        final squash = (1 - (t - _switchedAt) / 0.16).clamp(0.0, 1.0) * 0.05;
        final hopT = ((t - _hopStart) / 0.6).clamp(0.0, 1.0);
        final hop = hopT < 1 ? math.sin(hopT * math.pi) : 0.0;

        final Widget pose;
        final double w;
        double bob = 0;
        double rock = 0;
        switch (act) {
          case _Act.idle:
            w = h * oupiIdleRig.aspect;
            pose = _IdleBody(
              rig: oupiIdleRig,
              height: h,
              t: t,
              emotion: widget.emotion,
              blink: _blink(t),
              wiggle: hopT < 1 ? hopT : 0,
              puffs: _puffs,
            );
          case _Act.wave:
            w = h * _waveAspect;
            rock = math.sin(since * 2 * math.pi * 1.6) * 0.045;
            bob = -math.sin(since * 2 * math.pi * 1.6).abs() * h * 0.012;
            pose = Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  _wave,
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
                IgnorePointer(
                  child: CustomPaint(size: Size(w, h), painter: _PuffPainter(_puffs, t, Offset(w * 0.5, h * 0.2))),
                ),
              ],
            );
          case _Act.walk:
            w = h * _walkAspect;
            final frame = (since * 4).floor() % 2;
            bob = -math.sin(since * math.pi * 4).abs() * h * 0.02;
            final img = Image.asset(
              _walk[frame],
              width: w,
              height: h,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            );
            pose = _facing < 0 ? Transform.flip(flipX: true, child: img) : img;
        }

        final e = Curves.elasticOut.transform(_entrance.value.clamp(0, 1));
        final fade = Curves.easeOut.transform((_entrance.value * 2).clamp(0, 1));
        final breathe = act == _Act.idle ? (math.sin(t * 2 * math.pi / 3.2) + 1) / 2 * 0.02 : 0.0;
        final grow = 0.7 + 0.3 * e;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Ombre au sol.
            Positioned(
              left: x - h * 0.24,
              top: widget.groundY - h * 0.04,
              child: Container(
                width: h * 0.48 * (1 - hop * 0.3),
                height: h * 0.07,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(h * 0.24, h * 0.035)),
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.26 * fade),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: x - w / 2,
              top: widget.groundY - h,
              child: Opacity(
                opacity: fade,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _onTap,
                  child: Semantics(
                    label: 'Oupi',
                    button: true,
                    child: Transform.translate(
                      offset: Offset(0, bob - hop * h * 0.09 + (1 - e) * h * 0.25),
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.identity()
                          ..rotateZ(rock)
                          ..scaleByDouble(grow * (1 + squash), grow * (1 - squash + breathe), 1, 1),
                        child: SizedBox(width: w, height: h, child: pose),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Corps « Live 2D » de la pose naturelle : calques corps et pousse, cœur, paupières, petits cœurs.
class _IdleBody extends StatelessWidget {
  const _IdleBody({
    required this.rig,
    required this.height,
    required this.t,
    required this.emotion,
    required this.blink,
    required this.wiggle,
    required this.puffs,
  });

  final LiveRig rig;
  final double height;
  final double t;
  final Emotion emotion;
  final double blink;
  final double wiggle;
  final List<_Puff> puffs;

  @override
  Widget build(BuildContext context) {
    final h = height;
    final w = h * rig.aspect;
    final pivot = Offset(rig.pivot.dx * w, rig.pivot.dy * h);
    final sway = math.sin(t * 2 * math.pi / 2.6);
    final extra = wiggle > 0 ? math.sin(wiggle * math.pi * 6) * 0.35 * (1 - wiggle) : 0.0;
    final (angle, stretch) = switch (emotion) {
      Emotion.joy => (sway * 0.09 + extra, 1.0 + sway * 0.015),
      Emotion.sadness => (0.78 + sway * 0.03, 0.94),
      Emotion.fear => (math.sin(t * 2 * math.pi * 7) * 0.06, 0.98),
      Emotion.anger => (math.sin(t * 2 * math.pi * 11) * 0.02, 1.1),
      Emotion.sleepy => (2.5 + sway * 0.03, 1.0),
    };
    final heartPulse = 0.45 + 0.25 * (math.sin(t * 2 * math.pi / 2.4) + 1) / 2 + (wiggle > 0 ? 0.35 * (1 - wiggle) : 0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset(rig.body, width: w, height: h, fit: BoxFit.fill, filterQuality: FilterQuality.medium, gaplessPlayback: true),
        CustomPaint(
          size: Size(w, h),
          painter: _FacePainter(rig: rig, blink: blink, heartColor: heartColorFor(emotion), heartAlpha: heartPulse.clamp(0, 1)),
        ),
        Transform(
          transform: Matrix4.identity()
            ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
            ..rotateZ(angle)
            ..scaleByDouble(1, stretch, 1, 1)
            ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1),
          child: Image.asset(
            rig.sprout,
            width: w,
            height: h,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        ),
        IgnorePointer(
          child: CustomPaint(size: Size(w, h), painter: _PuffPainter(puffs, t, pivot)),
        ),
      ],
    );
  }
}
