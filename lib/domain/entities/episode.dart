/// Fiche activité côté parent (GDD §8). Seul l'épisode 4 a une fiche détaillée pour l'instant.
class ActivitySheet {
  const ActivitySheet({
    required this.title,
    this.duration,
    this.materials = const [],
    this.steps = const [],
    this.question,
  });

  final String title;
  final String? duration;
  final List<String> materials;
  final List<String> steps;
  final String? question;

  bool get isDetailed => steps.isNotEmpty;
}

/// Un épisode du catalogue. Entité pure : aucune dépendance à Flutter ni au format JSON.
class Episode {
  const Episode({
    required this.id,
    required this.number,
    required this.family,
    required this.theme,
    required this.notion,
    required this.pitch,
    required this.activity,
    required this.premium,
    required this.durationSeconds,
    this.title,
    this.song,
    this.video,
    this.interactionsAsset,
  });

  final String id;
  final int number;
  final String family;
  final String theme;
  final String? title;
  final String notion;
  final String pitch;
  final ActivitySheet activity;
  final String? song;
  final bool premium;
  final int durationSeconds;

  /// Vidéo MP4 (asset ou URL). `null` tant que l'épisode n'est pas produit :
  /// le lecteur affiche alors une maquette minutée.
  final String? video;
  final String? interactionsAsset;

  String get displayTitle => title ?? theme;
  bool get hasVideo => video != null;
  bool get hasSong => song != null;

  @override
  bool operator ==(Object other) => other is Episode && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Ordre d'affichage des familles : les épisodes sont rangés par couleur de thème (GDD §9).
const familyOrder = ['couleurs', 'formes', 'chiffres', 'emotions', 'routines', 'lettres', 'corps'];

class Catalog {
  Catalog({required this.version, required List<Episode> episodes})
      : episodes = List.unmodifiable([...episodes]..sort((a, b) => a.number.compareTo(b.number)));

  final int version;

  /// Dans l'ordre des numéros.
  final List<Episode> episodes;

  Episode? byId(String id) {
    for (final e in episodes) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<Episode> get songs => episodes.where((e) => e.hasSong).toList();

  /// Rangés par famille (couleur de thème) puis par numéro.
  List<Episode> get byFamily => [...episodes]..sort((a, b) {
      final fa = familyOrder.indexOf(a.family);
      final fb = familyOrder.indexOf(b.family);
      return fa != fb ? fa.compareTo(fb) : a.number.compareTo(b.number);
    });
}
