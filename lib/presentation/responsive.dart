import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Classes de taille, selon le côté le plus court de l'écran (repères Material 3).
enum ScreenClass { compact, medium, expanded }

/// Mesures de l'écran pour que chaque écran s'adapte : téléphone à l'horizontale,
/// tablette, fenêtre redimensionnée, ou portrait forcé (écran partagé, première image
/// avant le verrouillage de l'orientation). Les écrans partent de ces valeurs, jamais
/// de pixels fixes.
class Layout {
  const Layout(this.size);

  factory Layout.of(BuildContext context) => Layout(MediaQuery.sizeOf(context));

  /// Hauteur de référence : un téléphone à l'horizontale (≈ 390 pt de haut).
  static const referenceShortSide = 390.0;

  final Size size;

  double get width => size.width;
  double get height => size.height;
  double get shortestSide => size.shortestSide;

  ScreenClass get screenClass => shortestSide < 600
      ? ScreenClass.compact
      : shortestSide < 900
          ? ScreenClass.medium
          : ScreenClass.expanded;

  bool get isCompact => screenClass == ScreenClass.compact;
  bool get isExpanded => screenClass == ScreenClass.expanded;

  /// Plus haut que large : les rangées deviennent des colonnes.
  bool get isPortrait => height > width;

  /// Trop peu de largeur pour deux colonnes côte à côte.
  bool get isNarrow => width < 640;

  /// Facteur d'échelle borné : 1 sur un téléphone à l'horizontale, jusqu'à 1,5 sur une grande tablette.
  double get scale => (shortestSide / referenceShortSide).clamp(0.8, 1.5);

  /// Facteur appliqué aux textes : plus doux que [scale], pour que les blocs de texte restent lisibles sans déborder.
  double get textScale => (shortestSide / referenceShortSide).clamp(1.0, 1.2);

  /// Met une taille à l'échelle de l'écran.
  double sp(double value) => value * scale;

  /// Marge extérieure des écrans.
  double get gutter => switch (screenClass) {
        ScreenClass.compact => 16,
        ScreenClass.medium => 24,
        ScreenClass.expanded => 32,
      };

  /// Largeur maximale d'une colonne de lecture (textes des parents).
  double get readingWidth => math.min(width - 2 * gutter, 760);

  /// Un gros bouton rond pour l'enfant : au moins 2 cm (GDD §4), jamais plus d'un cinquième de la largeur.
  double bigButton(BoxConstraints c, {double fraction = 0.4, double min = 96, double max = 190}) =>
      math.min(c.maxHeight * fraction, c.maxWidth * 0.2).clamp(min, max);
}

extension LayoutContext on BuildContext {
  Layout get layout => Layout.of(this);
}

/// Hauteur d'un personnage qui doit tenir dans une zone : bornée par la hauteur et par la largeur
/// (la carte d'un personnage fait 0,72 fois sa hauteur).
double characterHeight(
  BoxConstraints c, {
  double heightFraction = 0.8,
  double widthFraction = 0.45,
  double min = 90,
  double max = 560,
}) {
  final byHeight = c.maxHeight.isFinite ? c.maxHeight * heightFraction : max;
  final byWidth = c.maxWidth.isFinite ? c.maxWidth * widthFraction / 0.72 : max;
  return math.min(byHeight, byWidth).clamp(min, max);
}

/// Une rangée quand il y a de la place, une colonne sinon. Les [Expanded] des enfants
/// restent valables dans les deux sens.
class AdaptiveFlex extends StatelessWidget {
  const AdaptiveFlex({
    super.key,
    required this.children,
    this.column = false,
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;

  /// Vrai pour empiler verticalement.
  final bool column;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => Flex(
        direction: column ? Axis.vertical : Axis.horizontal,
        spacing: spacing,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
}

/// Centre un contenu de lecture et borne sa largeur sur les grands écrans.
class ReadingColumn extends StatelessWidget {
  const ReadingColumn({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}
