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

  final String id;
  final double x, y, w, h;
  final bool correct;

  /// Symbole de maquette, affiché seulement quand il n'y a pas encore de vidéo.
  final String? symbol;
}

/// Instant où la vidéo se met en pause pour que l'enfant touche le bon objet (GDD §5 et §12).
class TouchPause {
  const TouchPause({required this.id, required this.atSeconds, required this.timeoutSeconds, required this.zones});

  final String id;
  final double atSeconds;
  final double timeoutSeconds;
  final List<TouchZone> zones;
}

class EpisodeInteractions {
  EpisodeInteractions({List<TouchPause> touchPauses = const []})
      : touchPauses = List.unmodifiable([...touchPauses]..sort((a, b) => a.atSeconds.compareTo(b.atSeconds)));

  static final none = EpisodeInteractions();

  /// Dans l'ordre chronologique.
  final List<TouchPause> touchPauses;

  /// La prochaine pause à déclencher à cet instant, en ignorant celles déjà traitées.
  TouchPause? dueAt(double positionSeconds, Set<String> handled) {
    for (final pause in touchPauses) {
      if (!handled.contains(pause.id) && positionSeconds >= pause.atSeconds) return pause;
    }
    return null;
  }
}
