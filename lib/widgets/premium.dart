import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../theme.dart';

bool _reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Vidéo générée qui tourne en boucle, en sourdine, en fond d'écran (BoxFit.cover).
/// [assets] est essayé dans l'ordre (4K, puis 1080p si l'appareil ne décode pas la 4K) ;
/// si aucune vidéo ne peut être lue, [fallback] prend le relais. Pendant le chargement,
/// l'affiche (première image de la vidéo) évite tout écran vide. Si le téléphone demande de
/// réduire les animations, l'affiche reste fixe. La vidéo se met en pause quand un autre
/// écran la recouvre (TickerMode), pour ménager la batterie.
class LoopingVideoBackdrop extends StatefulWidget {
  const LoopingVideoBackdrop({
    super.key,
    required this.assets,
    required this.poster,
    required this.fallback,
    this.cues = const [],
  });
  final List<String> assets;
  final String poster;
  final Widget fallback;

  /// Moments de la vidéo où la « vitre » de l'écran réagit (Oupi qui tape sur l'écran).
  final List<VideoCue> cues;

  @override
  State<LoopingVideoBackdrop> createState() => _LoopingVideoBackdropState();
}

class _LoopingVideoBackdropState extends State<LoopingVideoBackdrop> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  int _attempt = -1;
  bool _ready = false;
  bool _visible = true;

  // Horloge de la vidéo, recalée à chaque mise à jour du lecteur, pour caler les ondes à l'image près.
  late final Ticker _ticker = createTicker(_tick);
  final _now = ValueNotifier<double>(0);
  Duration _base = Duration.zero;
  double _baseAt = 0;
  double _lastVideo = 0;
  final List<(Offset, double)> _ripples = [];

  bool get _failed => _attempt >= widget.assets.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    if (_attempt < 0 && !_reduceMotion(context)) {
      _tryNext();
    } else if (_ready) {
      _visible ? _controller?.play() : _controller?.pause();
    }
  }

  void _tryNext() {
    _controller?.dispose();
    _controller = null;
    _ready = false;
    _attempt++;
    if (_failed) {
      if (mounted) setState(() {});
      return;
    }
    final c = VideoPlayerController.asset(widget.assets[_attempt], videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _controller = c;
    c
        .initialize()
        .then((_) async {
          if (!mounted || _controller != c) return;
          await c.setLooping(true);
          await c.setVolume(0);
          if (widget.cues.isNotEmpty) {
            c.addListener(_resync);
            if (!_ticker.isActive) _ticker.start();
          }
          if (_visible) await c.play();
          if (mounted) setState(() => _ready = true);
        })
        .catchError((Object _) {
          if (mounted && _controller == c) _tryNext();
        });
    if (mounted) setState(() {});
  }

  void _resync() {
    final v = _controller?.value;
    if (v == null) return;
    _base = v.position;
    _baseAt = _now.value;
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    _now.value = t;
    _ripples.removeWhere((r) => t - r.$2 > 1.4);
    final c = _controller;
    if (c == null || !_ready) return;
    final total = c.value.duration.inMicroseconds / 1e6;
    if (total <= 0) return;
    final playing = c.value.isPlaying;
    final video = ((_base.inMicroseconds / 1e6) + (playing ? t - _baseAt : 0)) % total;
    // Un petit recul vient du recalage sur le lecteur : on l'ignore. Seul un grand saut en arrière
    // est le retour au début de la boucle.
    final wrapped = _lastVideo - video > total / 2;
    if (video < _lastVideo && !wrapped) return;
    for (final cue in widget.cues) {
      final at = cue.at.inMicroseconds / 1e6;
      final crossed = wrapped ? (at > _lastVideo || at <= video) : (at > _lastVideo && at <= video);
      if (crossed && playing) _ripples.add((cue.spot, t));
    }
    _lastVideo = video;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller?.removeListener(_resync);
    _controller?.dispose();
    _now.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    final c = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(widget.poster, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
        if (c != null && _ready) ...[
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
          ),
          if (widget.cues.isNotEmpty) IgnorePointer(child: CustomPaint(painter: _GlassTapPainter(_ripples, _now, c.value.size))),
        ],
      ],
    );
  }
}

/// Un instant de la vidéo et un point de l'image (en fractions de la largeur et de la hauteur).
class VideoCue {
  const VideoCue(this.at, this.spot);
  final Duration at;
  final Offset spot;
}

/// Ondes douces sur la « vitre », là où la patte d'Oupi touche l'écran. Pas de flash : des anneaux
/// blancs qui s'élargissent et s'effacent en un peu plus d'une seconde.
class _GlassTapPainter extends CustomPainter {
  _GlassTapPainter(this.ripples, this.now, this.video) : super(repaint: now);
  final List<(Offset, double)> ripples;
  final ValueNotifier<double> now;
  final Size video;

  @override
  void paint(Canvas canvas, Size size) {
    if (ripples.isEmpty || video.isEmpty) return;
    // Même cadrage que BoxFit.cover centré.
    final s = math.max(size.width / video.width, size.height / video.height);
    final dw = video.width * s, dh = video.height * s;
    final ox = (size.width - dw) / 2, oy = (size.height - dh) / 2;
    final unit = size.shortestSide;
    for (final (spot, born) in ripples) {
      final center = Offset(ox + spot.dx * dw, oy + spot.dy * dh);
      final age = now.value - born;
      final glow = (1 - age / 0.6).clamp(0.0, 1.0);
      if (glow > 0) {
        canvas.drawCircle(
          center,
          unit * 0.06,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35 * glow)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.03),
        );
      }
      for (var k = 0; k < 3; k++) {
        final p = ((age - k * 0.14) / 1.1).clamp(0.0, 1.0);
        if (p <= 0 || p >= 1) continue;
        final e = Curves.easeOut.transform(p);
        canvas.drawCircle(
          center,
          unit * (0.03 + e * 0.2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = unit * 0.012 * (1 - p) + 1
            ..color = Colors.white.withValues(alpha: 0.75 * (1 - p)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlassTapPainter oldDelegate) => true;
}

/// Petits cœurs et étincelles sous le doigt, partout sur la scène.
class TapSparkles extends StatefulWidget {
  const TapSparkles({super.key, required this.child});
  final Widget child;

  @override
  State<TapSparkles> createState() => _TapSparklesState();
}

class _TapSparklesState extends State<TapSparkles> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) {
    _t.value = d.inMicroseconds / 1e6;
    _bursts.removeWhere((b) => _t.value - b.$2 > 1.4);
    if (_bursts.isEmpty) _ticker.stop();
  });
  final _t = ValueNotifier<double>(0);
  final List<(Offset, double)> _bursts = [];
  double _clock = 0;

  void _add(Offset p) {
    if (_reduceMotion(context)) return;
    HapticFeedback.lightImpact();
    if (!_ticker.isActive) {
      _ticker.start();
      _clock = 0;
    }
    _clock = _t.value;
    setState(() => _bursts.add((p, _clock)));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTapDown: (d) => _add(d.localPosition),
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(child: CustomPaint(painter: _SparklePainter(_bursts, _t))),
      ],
    ),
  );
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.bursts, this.t) : super(repaint: t);
  final List<(Offset, double)> bursts;
  final ValueNotifier<double> t;

  static const _colors = [Vivid.berry, Vivid.sunny, Vivid.coral, Colors.white, Vivid.grape, Vivid.teal];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (origin, born) in bursts) {
      final age = ((t.value - born) / 1.4).clamp(0.0, 1.0);
      final ease = Curves.easeOut.transform(age);
      for (var i = 0; i < 7; i++) {
        final a = -math.pi / 2 + (i - 3) * 0.42;
        final d = 26 + ease * 70;
        final p = origin + Offset(math.cos(a) * d, math.sin(a) * d - ease * 30);
        final s = 9.0 * (1 - age * 0.5);
        final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: 1 - age);
        final h = Path()
          ..moveTo(p.dx, p.dy + s * 0.35)
          ..cubicTo(p.dx - s * 0.9, p.dy - s * 0.2, p.dx - s * 0.45, p.dy - s * 0.85, p.dx, p.dy - s * 0.4)
          ..cubicTo(p.dx + s * 0.45, p.dy - s * 0.85, p.dx + s * 0.9, p.dy - s * 0.2, p.dx, p.dy + s * 0.35)
          ..close();
        canvas.drawPath(h, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}

/// Lumière douce du soleil qui pulse lentement en haut à gauche.
class SunGlow extends StatefulWidget {
  const SunGlow({super.key});

  @override
  State<SunGlow> createState() => _SunGlowState();
}

class _SunGlowState extends State<SunGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.95, -1.0),
            radius: 1.1,
            colors: [
              const Color(0xFFFFF4C2).withValues(alpha: 0.38 + _c.value * 0.14),
              const Color(0xFFFFF4C2).withValues(alpha: 0),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Aigrettes de pissenlit et pollen qui montent doucement dans la lumière.
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key, this.count = 22, this.color = Colors.white});
  final int count;
  final Color color;

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6);
  final _t = ValueNotifier<double>(0);
  late final List<(double, double, double, double)> _seeds;

  @override
  void initState() {
    super.initState();
    final r = math.Random(3);
    // (x de départ, vitesse, taille, phase)
    _seeds = List.generate(
      widget.count,
      (_) => (r.nextDouble(), 0.018 + r.nextDouble() * 0.03, 1.5 + r.nextDouble() * 3, r.nextDouble()),
    );
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
      child: CustomPaint(painter: _ParticlePainter(_seeds, _t, widget.color), size: Size.infinite),
    ),
  );
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.seeds, this.t, this.color) : super(repaint: t);
  final List<(double, double, double, double)> seeds;
  final ValueNotifier<double> t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final core = Paint();
    for (final (x0, speed, r, phase) in seeds) {
      final progress = (phase + t.value * speed) % 1.0;
      final y = size.height * (1.05 - progress * 1.1);
      final x = size.width * x0 + math.sin((t.value * 0.6 + phase * 6) * math.pi) * size.width * 0.025;
      // Apparaît en bas, disparaît en haut, sans scintiller.
      final a = math.sin(progress * math.pi).clamp(0.0, 1.0);
      glow.color = color.withValues(alpha: 0.35 * a);
      core.color = color.withValues(alpha: 0.85 * a);
      canvas.drawCircle(Offset(x, y), r * 2.2, glow);
      canvas.drawCircle(Offset(x, y), r * 0.8, core);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => false;
}

/// Panneau en verre dépoli (inspiration : interfaces « glass » des références UX).
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 40});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withValues(alpha: 0.42), Colors.white.withValues(alpha: 0.16)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
        ),
        child: child,
      ),
    ),
  );
}

/// Halo qui s'élargit et s'efface lentement autour du bouton principal : il invite à toucher, sans clignoter.
class GlowHalo extends StatefulWidget {
  const GlowHalo({super.key, required this.child, required this.size, this.color = Vivid.sunny});
  final Widget child;
  final double size;
  final Color color;

  @override
  State<GlowHalo> createState() => _GlowHaloState();
}

class _GlowHaloState extends State<GlowHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Le halo déborde du bouton sans agrandir sa place dans la mise en page.
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        OverflowBox(
          maxWidth: widget.size * 1.5,
          maxHeight: widget.size * 1.5,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_c.value);
                return Container(
                  width: widget.size * (0.95 + t * 0.35),
                  height: widget.size * (0.95 + t * 0.35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.7 * (1 - t)),
                      width: widget.size * 0.04 * (1 - t) + 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                        blurRadius: widget.size * 0.2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    ),
  );
}

/// Bouton badge illustré (style des références : anneau en dégradé, étincelles, illustration au centre).
/// Il flotte doucement, s'enfonce sous le doigt et rebondit comme un ressort. Sans texte côté enfant.
class BadgeButton extends StatefulWidget {
  const BadgeButton({
    super.key,
    required this.asset,
    required this.size,
    required this.glow,
    required this.onTap,
    required this.semanticLabel,
    this.locked = false,
    this.phase = 0,
  });

  final String asset;
  final double size;

  /// Couleur du halo sous le badge.
  final Color glow;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool locked;

  /// Décalage du flottement, pour que les badges ne bougent pas tous ensemble.
  final double phase;

  @override
  State<BadgeButton> createState() => _BadgeButtonState();
}

class _BadgeButtonState extends State<BadgeButton> with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.value = widget.phase;
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
    final s = widget.size;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, child) =>
              Transform.translate(offset: Offset(0, (Curves.easeInOut.transform(_float.value) - 0.5) * s * 0.05), child: child),
          child: AnimatedScale(
            scale: _down ? 0.88 : 1.0,
            duration: Duration(milliseconds: _down ? 90 : 520),
            curve: _down ? Curves.easeOut : Curves.elasticOut,
            child: SizedBox.square(
              dimension: s,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.glow.withValues(alpha: 0.55),
                            blurRadius: s * 0.22,
                            offset: Offset(0, s * 0.08),
                          ),
                          BoxShadow(color: Vivid.plum.withValues(alpha: 0.18), blurRadius: s * 0.08, offset: Offset(0, s * 0.04)),
                        ],
                      ),
                    ),
                  ),
                  Image.asset(widget.asset, width: s, height: s, filterQuality: FilterQuality.medium),
                  if (widget.locked)
                    Positioned(
                      right: -s * 0.02,
                      bottom: -s * 0.02,
                      child: Container(
                        width: s * 0.32,
                        height: s * 0.32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Vivid.sunny, width: s * 0.025),
                          boxShadow: [
                            BoxShadow(color: Vivid.plum.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(Icons.lock_rounded, size: s * 0.16, color: Vivid.plum.withValues(alpha: 0.7)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Apparition en rebond, décalée : chorégraphie l'arrivée des boutons.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero, this.from = const Offset(0, 0.3)});
  final Widget child;
  final Duration delay;

  /// Décalage de départ, en fraction de la taille du widget.
  final Offset from;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final e = Curves.elasticOut.transform(_c.value);
      return Opacity(
        opacity: Curves.easeOut.transform((_c.value * 2.5).clamp(0, 1)),
        child: FractionalTranslation(
          translation: widget.from * (1 - e),
          child: Transform.scale(scale: 0.6 + 0.4 * e, child: child),
        ),
      );
    },
    child: widget.child,
  );
}
