import 'package:flutter/material.dart';

/// Palette d'Oupi : abricot, sauge, crème (GDD §4), plus les couleurs de familles
/// d'épisodes, franches et identifiables.
abstract final class OupiColors {
  static const cream = Color(0xFFFDF8EF);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFFAEFE0);
  static const ink = Color(0xFF3B2820);
  static const muted = Color(0xFF86695A);
  static const line = Color(0xFFEEDFCB);
  static const lineStrong = Color(0xFFD8C2A6);
  static const apricot = Color(0xFFF59A4F);
  static const apricotInk = Color(0xFFB0531A);
  static const apricotSoft = Color(0xFFFDE6CF);
  static const sage = Color(0xFFBFC796);
  static const sageSoft = Color(0xFFECEFDA);
  static const sageInk = Color(0xFF55622F);
  static const leaf = Color(0xFF8BAA48);
  static const eye = Color(0xFF235D90);
  static const eyeSoft = Color(0xFFDFEAF5);
  static const sky = Color(0xFFDCEEF8);
  static const meadow = Color(0xFFD4E3AE);
  static const night = Color(0xFF26305A);
  static const nightDeep = Color(0xFF141A33);
  static const onNight = Color(0xFFF4EFE6);
  static const bad = Color(0xFFBE4329);

  static const families = <String, Color>{
    'couleurs': Vivid.coral,
    'formes': Vivid.ocean,
    'chiffres': Vivid.sunny,
    'emotions': Vivid.berry,
    'routines': Vivid.teal,
    'lettres': Vivid.grape,
    'corps': Vivid.lime,
  };

  /// Ordre d'affichage des familles : les épisodes sont rangés par couleur de thème.
  static const familyOrder = ['couleurs', 'formes', 'chiffres', 'emotions', 'routines', 'lettres', 'corps'];

  static Color family(String id) => families[id] ?? apricot;
}

/// Charte vive du côté enfant : un monde de ciel bleu, de collines vertes et de bonbons colorés,
/// inspiré des références UX (cartes colorées, personnage 3D en héros, carte de niveaux).
/// Les écrans parents gardent la palette douce d'[OupiColors].
abstract final class Vivid {
  // Ciel et collines de jour
  static const skyTop = Color(0xFF38B2F5);
  static const skyMid = Color(0xFF7DD3FB);
  static const skyHorizon = Color(0xFFD2F2FF);
  static const hillBack = Color(0xFFA6E36A);
  static const hillMid = Color(0xFF72D054);
  static const hillFront = Color(0xFF46B84A);
  static const sun = Color(0xFFFFD23F);

  // Bonbons : boutons, cartes, familles d'épisodes
  static const mango = Color(0xFFFF9F1C);
  static const coral = Color(0xFFFF5A5F);
  static const berry = Color(0xFFFF4F8B);
  static const ocean = Color(0xFF2F80ED);
  static const grape = Color(0xFF8B5CF6);
  static const lime = Color(0xFF4CC35A);
  static const sunny = Color(0xFFFFB800);
  static const teal = Color(0xFF12BFAE);

  // Texte foncé sur fond clair
  static const plum = Color(0xFF2B1B4A);

  // Nuit : indigo et violet, jamais noir
  static const nightTop = Color(0xFF1A1446);
  static const nightMid = Color(0xFF35288A);
  static const nightLow = Color(0xFF6650CF);
  static const nightHillBack = Color(0xFF3B2E95);
  static const nightHillMid = Color(0xFF2C2178);
  static const nightHillFront = Color(0xFF1F175C);
  static const moon = Color(0xFFFFF1C1);
}

FontWeight _weight(double w) => FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];

/// Polices variables embarquées : on règle l'axe « wght » explicitement.
TextStyle display(double size, {double weight = 600, Color color = OupiColors.ink, double? height}) => TextStyle(
  fontFamily: 'Fredoka',
  fontSize: size,
  fontWeight: _weight(weight),
  fontVariations: [FontVariation('wght', weight)],
  color: color,
  height: height,
);

TextStyle body(double size, {double weight = 500, Color color = OupiColors.ink, double height = 1.4}) => TextStyle(
  fontFamily: 'Nunito',
  fontSize: size,
  fontWeight: _weight(weight),
  fontVariations: [FontVariation('wght', weight)],
  color: color,
  height: height,
);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: OupiColors.apricot,
    primary: OupiColors.apricotInk,
    surface: OupiColors.cream,
    onSurface: OupiColors.ink,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: OupiColors.cream);
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Nunito', bodyColor: OupiColors.ink, displayColor: OupiColors.ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: OupiColors.ink,
        foregroundColor: OupiColors.cream,
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: body(16, weight: 800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: OupiColors.ink,
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: const StadiumBorder(),
        side: const BorderSide(color: OupiColors.lineStrong, width: 1.5),
        backgroundColor: OupiColors.surface,
        textStyle: body(16, weight: 800),
      ),
    ),
    // Interrupteurs : abricot quand c'est activé, crème soutenu sinon, pouce toujours blanc.
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? OupiColors.apricot : OupiColors.lineStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Icon(Icons.check_rounded, size: 16, color: OupiColors.apricotInk)
            : null,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: OupiColors.ink)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: OupiColors.ink,
      contentTextStyle: body(15, color: OupiColors.cream),
    ),
  );
}
