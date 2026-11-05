import 'package:flutter/material.dart';

import '../theme.dart';
import 'premium.dart';

// Personnages détourés depuis les planches (outil : tool/Cutout.cs).
/// Oupi debout, pose naturelle (bras le long du corps).
const oupiImage = 'assets/images/oupi_idle.png';
const oupiSideLeft = 'assets/images/oupi_side_left.png';
const oupiSideRight = 'assets/images/oupi_side_right.png';
const lalaImage = 'assets/images/lala_front.png';
const lalaSideLeft = 'assets/images/lala_side_left.png';

const _nightFilter = ColorFilter.matrix(<double>[
  0.66, 0, 0, 0, 0, //
  0, 0.68, 0, 0, 0, //
  0, 0, 0.80, 0, 10, //
  0, 0, 0, 1, 0, //
]);

/// Matrice de saturation réduite, pour les contenus verrouillés.
ColorFilter desaturate(double amount) {
  final s = 1 - amount;
  const r = 0.2126, g = 0.7152, b = 0.0722;
  return ColorFilter.matrix(<double>[
    r * (1 - s) + s, g * (1 - s), b * (1 - s), 0, 0, //
    r * (1 - s), g * (1 - s) + s, b * (1 - s), 0, 0, //
    r * (1 - s), g * (1 - s), b * (1 - s) + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
}

/// Personnage détouré posé dans le décor, avec son ombre au sol et une respiration lente.
/// En attendant les boucles vidéo (attente, coucou, dodo), ce sont les poses des planches.
class BreathingCharacter extends StatefulWidget {
  const BreathingCharacter({
    super.key,
    required this.asset,
    required this.height,
    this.asleep = false,
    this.breathing = true,
    this.shadow = true,
    this.label,
  });

  final String asset;
  final double height;
  final bool asleep;
  final bool breathing;
  final bool shadow;
  final String? label;

  @override
  State<BreathingCharacter> createState() => _BreathingCharacterState();
}

class _BreathingCharacterState extends State<BreathingCharacter> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.asleep ? 4200 : 3000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.breathing || reduceMotion) {
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
  Widget build(BuildContext context) {
    final h = widget.height;
    Widget image = Image.asset(widget.asset, height: h, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
    if (widget.asleep) image = ColorFiltered(colorFilter: _nightFilter, child: image);
    final body = AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scaleY: 1 + t * (widget.asleep ? 0.012 : 0.025),
          scaleX: 1 - t * 0.006,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: image,
    );
    Widget result = Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        if (widget.shadow)
          Positioned(
            bottom: -h * 0.012,
            child: Container(
              width: h * 0.5,
              height: h * 0.075,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(h * 0.25, h * 0.0375)),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: widget.asleep ? 0.35 : 0.22),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        body,
      ],
    );
    if (widget.label != null) result = Semantics(label: widget.label, image: true, child: result);
    return result;
  }
}

/// Bouton retour pour les enfants : un bonbon mangue.
/// Bouton retour de l'enfant : un badge illustré (flèche), comme les boutons de l'accueil.
class KidBackButton extends StatelessWidget {
  const KidBackButton({super.key, this.onTap, this.size = 112});
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => BadgeButton(
    asset: 'assets/images/badge_back.png',
    size: size,
    glow: Vivid.mango,
    phase: 0.2,
    semanticLabel: 'Retour',
    onTap: onTap ?? () => Navigator.of(context).maybePop(),
  );
}

/// Petite icône discrète vers l'espace parents (GDD §9).
class ParentCornerButton extends StatelessWidget {
  const ParentCornerButton({super.key, required this.onTap, this.onDark = false});
  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Espace parents',
    child: IconButton(
      onPressed: onTap,
      iconSize: 24,
      // Fond prune translucide : l'icône reste lisible devant le ciel comme devant un nuage.
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: onDark ? Colors.white.withValues(alpha: 0.1) : Vivid.plum.withValues(alpha: 0.28),
      ),
      icon: Icon(Icons.lock_outline_rounded, color: Colors.white.withValues(alpha: onDark ? 0.6 : 0.95)),
    ),
  );
}

/// Cadenas doux sur les contenus abonnés.
class SoftLock extends StatelessWidget {
  const SoftLock({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: Vivid.sunny, width: size * 0.08),
      boxShadow: [BoxShadow(color: Vivid.plum.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Icon(Icons.lock_rounded, size: size * 0.5, color: Vivid.plum.withValues(alpha: 0.7)),
  );
}

/// Petite pousse en cœur : marque les épisodes déjà vus (GDD §9).
class SproutBadge extends StatelessWidget {
  const SproutBadge({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Déjà vu',
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Vivid.plum.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: EdgeInsets.all(size * 0.14),
      child: CustomPaint(painter: _SproutPainter()),
    ),
  );
}

class _SproutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final stem = Paint()
      ..color = Vivid.lime
      ..strokeWidth = s.width * 0.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leaf = Paint()..color = Vivid.lime;
    final base = Offset(s.width / 2, s.height * 0.95);
    final top = Offset(s.width / 2, s.height * 0.5);
    canvas.drawLine(base, top, stem);
    for (final dir in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(top.dx, top.dy);
      canvas.scale(dir, 1);
      canvas.rotate(-0.5);
      final path = Path()
        ..moveTo(0, 0)
        ..cubicTo(s.width * 0.08, -s.height * 0.42, s.width * 0.5, -s.height * 0.45, s.width * 0.52, -s.height * 0.12)
        ..cubicTo(s.width * 0.53, s.height * 0.05, s.width * 0.25, s.height * 0.1, 0, 0)
        ..close();
      canvas.drawPath(path, leaf);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Symbole de famille d'épisode, en attendant les vignettes illustrées.
class FamilySymbol extends StatelessWidget {
  const FamilySymbol({super.key, required this.family, required this.size});
  final String family;
  final double size;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final shadow = [Shadow(color: Vivid.plum.withValues(alpha: 0.25), offset: Offset(0, size * 0.02))];
    switch (family) {
      case 'couleurs':
        // Sur une pastille blanche : le rond rouge reste visible sur la carte rouge.
        return Container(
          padding: EdgeInsets.symmetric(horizontal: size * 0.05, vertical: size * 0.04),
          decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(size)),
          child: _row([_dot(Vivid.coral), _dot(Vivid.sunny), _dot(Vivid.ocean)]),
        );
      case 'formes':
        return _row([
          Container(
            width: size * 0.26,
            height: size * 0.26,
            decoration: const BoxDecoration(color: white, shape: BoxShape.circle),
          ),
          Container(
            width: size * 0.24,
            height: size * 0.24,
            decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(size * 0.03)),
          ),
          CustomPaint(size: Size.square(size * 0.28), painter: _TrianglePainter(white)),
        ]);
      case 'chiffres':
        return Text(
          '1 2 3',
          style: display(size * 0.32, weight: 700, color: white).copyWith(shadows: shadow),
        );
      case 'emotions':
        return Icon(Icons.favorite_rounded, size: size * 0.6, color: white, shadows: shadow);
      case 'routines':
        return Icon(Icons.brush_rounded, size: size * 0.55, color: white, shadows: shadow);
      case 'lettres':
        return Text(
          'A E I',
          style: display(size * 0.32, weight: 700, color: white).copyWith(shadows: shadow),
        );
      case 'corps':
        return Icon(Icons.back_hand_rounded, size: size * 0.55, color: white, shadows: shadow);
      default:
        return Icon(Icons.play_arrow_rounded, size: size * 0.55, color: white, shadows: shadow);
    }
  }

  Widget _dot(Color c) => Container(
    width: size * 0.22,
    height: size * 0.22,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _row(List<Widget> children) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(width: size * 0.05), children[i]],
    ],
  );
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawPath(
      Path()
        ..moveTo(s.width / 2, 0)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}

/// Bulle de texte pour les parents, posée sur le décor.
class SceneCaption extends StatelessWidget {
  const SceneCaption(this.text, {super.key, this.size = 22, this.night = false});
  final String text;
  final double size;

  /// La nuit : pilule bleu nuit translucide, texte couleur de lune, liseré clair.
  final bool night;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: size * 1.0, vertical: size * 0.5),
    decoration: BoxDecoration(
      color: night ? Vivid.nightTop.withValues(alpha: 0.62) : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
      border: night ? Border.all(color: Vivid.moon.withValues(alpha: 0.35), width: 1.5) : null,
      boxShadow: [
        BoxShadow(color: (night ? Colors.black : Vivid.plum).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
      ],
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: display(size, weight: 600, color: night ? Vivid.moon : Vivid.plum),
    ),
  );
}
