import 'dart:convert';

import 'package:flutter/services.dart';

/// Zone à toucher pendant une pause tactile. Coordonnées en fractions de l'image (0 à 1).
class TouchZone {
  const TouchZone({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.correct,
    this.symbol,
  });

  factory TouchZone.fromJson(Map<String, dynamic> json) => TouchZone(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    w: (json['w'] as num).toDouble(),
    h: (json['h'] as num).toDouble(),
    correct: json['correct'] as bool? ?? false,
    symbol: json['symbol'] as String?,
  );

  final String id;
  final double x, y, w, h;
  final bool correct;

  /// Symbole de maquette, affiché seulement quand il n'y a pas encore de vidéo.
  final String? symbol;
}

/// Instant où la vidéo se met en pause pour que l'enfant touche le bon objet (GDD §5 et §12).
class TouchPause {
  const TouchPause({required this.id, required this.atSeconds, required this.timeoutSeconds, required this.zones});

  factory TouchPause.fromJson(Map<String, dynamic> json) => TouchPause(
    id: json['id'] as String,
    atSeconds: (json['atSeconds'] as num).toDouble(),
    timeoutSeconds: (json['timeoutSeconds'] as num? ?? 8).toDouble(),
    zones: [for (final z in json['zones'] as List) TouchZone.fromJson(z as Map<String, dynamic>)],
  );

  final String id;
  final double atSeconds;
  final double timeoutSeconds;
  final List<TouchZone> zones;
}

class EpisodeInteractions {
  const EpisodeInteractions({this.touchPauses = const []});

  factory EpisodeInteractions.fromJson(Map<String, dynamic> json) => EpisodeInteractions(
    touchPauses: [for (final p in json['touchPauses'] as List? ?? const []) TouchPause.fromJson(p as Map<String, dynamic>)]
      ..sort((a, b) => a.atSeconds.compareTo(b.atSeconds)),
  );

  static const none = EpisodeInteractions();

  static Future<EpisodeInteractions> load(AssetBundle bundle, String? path) async {
    if (path == null) return none;
    return EpisodeInteractions.fromJson(jsonDecode(await bundle.loadString(path)) as Map<String, dynamic>);
  }

  final List<TouchPause> touchPauses;
}
