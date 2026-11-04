import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

const oupiImage = 'assets/images/oupi_face.jpg';
const loloImage = 'assets/images/lolo_face.jpg';

const _nightFilter = ColorFilter.matrix(<double>[
  0.66, 0, 0, 0, 0, //
  0, 0.68, 0, 0, 0, //
  0, 0, 0.80, 0, 10, //
  0, 0, 0, 1, 0, //
]);

/// Personnage posé sur sa feutrine crème, qui respire doucement.
/// En attendant les boucles vidéo (attente, coucou, dodo), c'est l'image de la planche.
class BreathingCharacter extends StatefulWidget {
  const BreathingCharacter({super.key, required this.asset, required this.height, this.asleep = false, this.label});

  final String asset;
  final double height;
  final bool asleep;
  final String? label;

  @override
  State<BreathingCharacter> createState() => _BreathingCharacterState();
}

class _BreathingCharacterState extends State<BreathingCharacter> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.asleep ? 4200 : 3000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * 0.72;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Widget card = Container(
      width: width,
      height: widget.height,
      padding: EdgeInsets.fromLTRB(width * 0.04, widget.height * 0.04, width * 0.04, 0),
      decoration: BoxDecoration(
        color: OupiColors.cream,
        borderRadius: BorderRadius.circular(widget.height * 0.1),
        boxShadow: [BoxShadow(color: OupiColors.ink.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(widget.asset, fit: BoxFit.cover, alignment: Alignment.topCenter),
    );
    // La nuit, toute la carte baisse en luminosité et tire un peu vers le bleu, sans voile gris.
    if (widget.asleep) card = ColorFiltered(colorFilter: _nightFilter, child: card);
    if (widget.label != null) card = Semantics(label: widget.label, image: true, child: card);
    if (reduceMotion) return card;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(scale: 1 + t * (widget.asleep ? 0.015 : 0.03), alignment: Alignment.bottomCenter, child: child);
      },
      child: card,
    );
  }
}

/// Gros bouton rond, sans texte côté enfant (GDD §4 : au moins 2 cm).
class BigRoundButton extends StatelessWidget {
  const BigRoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    this.size = 132,
    this.locked = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String semanticLabel;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: OupiColors.ink.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: size * 0.48, color: Colors.white),
                if (locked) Positioned(right: size * 0.08, bottom: size * 0.08, child: SoftLock(size: size * 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton retour pour les enfants : grand et rond.
class KidBackButton extends StatelessWidget {
  const KidBackButton({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => BigRoundButton(
        icon: Icons.arrow_back_rounded,
        color: OupiColors.apricot,
        size: 76,
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
          iconSize: 26,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: Icon(Icons.lock_outline_rounded,
              color: (onDark ? OupiColors.onNight : OupiColors.ink).withValues(alpha: 0.45)),
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
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: OupiColors.ink.withValues(alpha: 0.2), blurRadius: 6)],
        ),
        child: Icon(Icons.lock_rounded, size: size * 0.55, color: OupiColors.muted),
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
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          padding: EdgeInsets.all(size * 0.14),
          child: CustomPaint(painter: _SproutPainter()),
        ),
      );
}

class _SproutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final stem = Paint()
      ..color = OupiColors.leaf
      ..strokeWidth = s.width * 0.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leaf = Paint()..color = OupiColors.leaf;
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

/// Ciel de nuit étoilé, immobile : pas de scintillement (GDD §4, aucun clignotement).
class NightSky extends StatelessWidget {
  const NightSky({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OupiColors.nightDeep, OupiColors.night, Color(0xFF3B4778)],
          ),
        ),
        child: CustomPaint(painter: _StarsPainter(), child: child),
      );
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final p = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height * 0.75);
      final r = 0.8 + random.nextDouble() * 1.8;
      paint.color = OupiColors.onNight.withValues(alpha: 0.35 + random.nextDouble() * 0.55);
      canvas.drawCircle(p, r, paint);
    }
    final moon = Offset(size.width * 0.86, size.height * 0.18);
    canvas.drawCircle(moon, 26, Paint()..color = const Color(0xFFFFF3D6));
    canvas.drawCircle(moon.translate(12, -8), 24, Paint()..color = OupiColors.nightDeep);
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
    final white = Colors.white.withValues(alpha: 0.95);
    switch (family) {
      case 'couleurs':
        // Sur une pastille blanche : le rond rouge reste visible sur la carte rouge.
        return Container(
          padding: EdgeInsets.symmetric(horizontal: size * 0.05, vertical: size * 0.04),
          decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(size)),
          child: _row([
            _dot(const Color(0xFFE5533D)),
            _dot(const Color(0xFFF2C230)),
            _dot(const Color(0xFF3D7DD8)),
          ]),
        );
      case 'formes':
        return _row([
          Container(width: size * 0.26, height: size * 0.26, decoration: BoxDecoration(color: white, shape: BoxShape.circle)),
          Container(width: size * 0.24, height: size * 0.24, color: white),
          CustomPaint(size: Size.square(size * 0.28), painter: _TrianglePainter(white)),
        ]);
      case 'chiffres':
        return Text('1 2 3', style: display(size * 0.32, color: white));
      case 'emotions':
        return Icon(Icons.favorite_rounded, size: size * 0.6, color: white);
      case 'routines':
        return Icon(Icons.brush_rounded, size: size * 0.55, color: white);
      case 'lettres':
        return Text('A E I', style: display(size * 0.32, color: white));
      case 'corps':
        return Icon(Icons.back_hand_rounded, size: size * 0.55, color: white);
      default:
        return Icon(Icons.play_arrow_rounded, size: size * 0.55, color: white);
    }
  }

  Widget _dot(Color c) => Container(
        width: size * 0.24,
        height: size * 0.24,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
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

/// Bulle de texte pour les parents, sur les écrans de nuit.
class NightCaption extends StatelessWidget {
  const NightCaption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, textAlign: TextAlign.center, style: display(22, weight: 500, color: OupiColors.onNight)),
      );
}
