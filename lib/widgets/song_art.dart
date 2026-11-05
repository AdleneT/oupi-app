import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';
import 'candy.dart';
import 'common.dart';

/// Illustration d'une vignette de chanson : un décor dans la fenêtre de la carte et un personnage
/// détouré devant, qui sort de la fenêtre par le haut (et parfois par les côtés).
class VignetteArt {
  const VignetteArt({
    required this.plate,
    required this.plateView,
    required this.character,
    required this.characterRect,
  });

  /// Le décor seul, carré.
  final String plate;

  /// La partie du décor montrée dans la fenêtre (même rapport largeur/hauteur que la fenêtre).
  final Rect plateView;

  /// Le personnage détouré (PNG transparent).
  final String character;

  /// Où se place le personnage, en largeurs de carte, depuis le coin haut gauche de la carte.
  /// Un haut négatif le fait dépasser au-dessus de la carte.
  final Rect characterRect;
}

/// Vignettes des chansons enregistrées, par épisode.
const vignetteArts = <String, VignetteArt>{
  // « Les couleurs » : Oupi fait coucou avec quatre ballons, rouge, jaune, bleu et vert, devant
  // l'arc-en-ciel en feutrine (Seedream ; détourage sur fond violet avec tool/KeyCutout.cs).
  'ep01': VignetteArt(
    plate: 'assets/images/song_couleurs_plate.jpg',
    plateView: Rect.fromLTWH(0, 0, 1, 0.806),
    character: 'assets/images/song_couleurs_oupi.png',
    characterRect: Rect.fromLTWH(0.084, -0.564, 1.053, 1.63),
  ),
};

/// Proportions de la carte, en largeurs de carte (d'après la maquette de l'utilisateur).
abstract final class _V {
  static const cardHeight = 1.033;
  static const inset = 0.035;
  static const windowTop = 0.037;
  static const windowHeight = 0.75;
  static const radius = 0.083;
  static const windowRadius = 0.054;
}

String _clock(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Vignette de chanson : carte blanche arrondie, l'image dans sa fenêtre avec le personnage qui en
/// sort, puis le titre, la durée et le badge lecture. Pendant la chanson, le personnage danse et le
/// badge passe en pause. Une chanson pas encore enregistrée garde la carte, avec le symbole de son
/// thème et « Bientôt ».
class SongVignette extends StatefulWidget {
  const SongVignette({
    super.key,
    required this.width,
    required this.title,
    required this.color,
    this.art,
    this.seconds,
    this.family,
    this.playing = false,
    this.loading = false,
  });

  /// Largeur de la carte ; le personnage peut déborder autour.
  final double width;
  final String title;
  final Color color;
  final VignetteArt? art;
  final int? seconds;

  /// Famille du thème, pour le symbole des chansons pas encore enregistrées.
  final String? family;
  final bool playing;
  final bool loading;

  bool get ready => art != null;

  /// Place au-dessus de la carte pour ce qui en dépasse, en largeurs de carte.
  static double popFor(VignetteArt? art) => art == null ? 0 : math.max(0.0, -art.characterRect.top) + 0.02;

  /// Hauteur totale (débordement compris) pour une largeur de carte.
  static double heightFor(VignetteArt? art, double width) => (popFor(art) + _V.cardHeight) * width;

  @override
  State<SongVignette> createState() => _SongVignetteState();
}

class _SongVignetteState extends State<SongVignette> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6);
  final _t = ValueNotifier<double>(0);
  bool _still = false;

  // Fondu entre le mouvement de repos et la danse, pour ne jamais sauter d'une pose à l'autre.
  double _energy = 0;
  double _lastT = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still || !widget.ready) {
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
    final w = widget.width;
    final art = widget.art;
    final cardTop = SongVignette.popFor(art) * w;
    final cardH = _V.cardHeight * w;
    final window = Rect.fromLTWH(_V.inset * w, cardTop + _V.windowTop * w, (1 - 2 * _V.inset) * w, _V.windowHeight * w);
    final infoH = cardTop + cardH - window.bottom;
    final badge = w * 0.19;

    Widget card(double glow) => Positioned(
      left: 0,
      top: cardTop,
      width: w,
      height: cardH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_V.radius * w),
          boxShadow: [
            BoxShadow(color: Vivid.plum.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8)),
            if (glow > 0.01)
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * glow),
                blurRadius: 34,
                spreadRadius: 4 * glow,
              ),
          ],
        ),
      ),
    );

    final info = Positioned(
      left: window.left + w * 0.035,
      right: w - window.right,
      top: window.bottom,
      height: infoH,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: display(w * 0.075, weight: 700, color: OupiColors.ink, height: 1.1),
                ),
                SizedBox(height: w * 0.008),
                Text(
                  widget.seconds != null ? _clock(widget.seconds!) : 'Bientôt',
                  style: body(
                    w * 0.058,
                    weight: 700,
                    color: OupiColors.ink.withValues(alpha: 0.75),
                    height: 1.1,
                  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          SizedBox(
            width: badge,
            height: badge,
            child: !widget.ready
                ? Opacity(
                    opacity: 0.45,
                    child: ColorFiltered(
                      colorFilter: desaturate(0.9),
                      child: Image.asset('assets/images/badge_play.png', excludeFromSemantics: true),
                    ),
                  )
                : widget.loading
                ? Padding(
                    padding: EdgeInsets.all(badge * 0.22),
                    child: CircularProgressIndicator(strokeWidth: badge * 0.08, color: Vivid.mango),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Image.asset(
                      widget.playing ? 'assets/images/badge_pause.png' : 'assets/images/badge_play.png',
                      key: ValueKey(widget.playing),
                      excludeFromSemantics: true,
                    ),
                  ),
          ),
        ],
      ),
    );

    // Chanson pas encore enregistrée : la fenêtre prend la couleur du thème, avec son symbole.
    if (art == null) {
      return SizedBox(
        width: w,
        height: SongVignette.heightFor(null, w),
        child: Stack(
          children: [
            card(0),
            Positioned.fromRect(
              rect: window,
              child: CandyFace(
                color: widget.color,
                width: window.width,
                height: window.height,
                muted: true,
                child: Center(
                  child: widget.family == null ? null : FamilySymbol(family: widget.family!, size: window.height * 0.5),
                ),
              ),
            ),
            info,
          ],
        ),
      );
    }

    final plateW = window.width / art.plateView.width, plateH = window.height / art.plateView.height;
    final c = art.characterRect;
    final charRect = Rect.fromLTWH(c.left * w, cardTop + c.top * w, c.width * w, c.height * w);
    // Pivot du balancement : le bas de la fenêtre, au milieu du personnage.
    final pivot = Alignment(0, ((window.bottom - charRect.top) / charRect.height) * 2 - 1);

    return SizedBox(
      width: w,
      height: SongVignette.heightFor(art, w),
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final t = _t.value;
          final dt = (t - _lastT).clamp(0.0, 0.1);
          _lastT = t;
          _energy += ((widget.playing ? 1.0 : 0.0) - _energy) * (dt * 3).clamp(0.0, 1.0);
          final e = _still ? 0.0 : _energy;
          final calm = _still ? 0.0 : 1.0 - e;

          // Repos : respiration lente et léger balancement. Chanson : rebonds au rythme et dandinement.
          final breathe = 1 + calm * 0.012 * math.sin(t * 2 * math.pi / 3.6);
          final bob = -w * e * 0.025 * math.sin(t * 2 * math.pi / 0.86).abs();
          final rock = calm * 0.014 * math.sin(t * 2 * math.pi / 4.4) + e * 0.04 * math.sin(t * 2 * math.pi / 1.72);
          final drift = (calm + e) * w * 0.01 * math.sin(t * 2 * math.pi / 7);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              card(e),
              // Le décor dans sa fenêtre, qui glisse à peine.
              Positioned.fromRect(
                rect: window,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_V.windowRadius * w),
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Transform.translate(
                      offset: Offset(-art.plateView.left * plateW + drift, -art.plateView.top * plateH),
                      child: Transform.scale(
                        scale: 1.05,
                        child: Image.asset(
                          art.plate,
                          width: plateW,
                          height: plateH,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Le personnage : coupé au bas de la fenêtre, libre partout ailleurs.
              Positioned.fill(
                child: ClipRect(
                  clipper: _AboveLine(window.bottom),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fromRect(
                        rect: charRect.shift(Offset(0, bob)),
                        child: Transform.rotate(
                          angle: rock,
                          alignment: pivot,
                          child: Transform.scale(
                            scaleY: breathe,
                            alignment: pivot,
                            child: Image.asset(
                              art.character,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              info,
            ],
          );
        },
      ),
    );
  }
}

/// Garde tout ce qui est au-dessus d'une ligne horizontale, sans limite sur les côtés ni en haut.
class _AboveLine extends CustomClipper<Rect> {
  const _AboveLine(this.y);
  final double y;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-1e5, -1e5, 1e5, y);

  @override
  bool shouldReclip(covariant _AboveLine old) => old.y != y;
}
