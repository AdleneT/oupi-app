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
    'couleurs': Color(0xFFE5533D),
    'formes': Color(0xFF3D7DD8),
    'chiffres': Color(0xFFD9A010),
    'emotions': Color(0xFFE2689A),
    'routines': Color(0xFF22A094),
    'lettres': Color(0xFF8A63D2),
    'corps': Color(0xFF6FA14A),
  };

  static Color family(String id) => families[id] ?? apricot;
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
        side: const BorderSide(color: OupiColors.line, width: 1.5),
        textStyle: body(16, weight: 800),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: OupiColors.ink,
      contentTextStyle: body(15, color: OupiColors.cream),
    ),
  );
}
