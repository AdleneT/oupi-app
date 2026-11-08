import '../../domain/entities/episode.dart';
import '../../domain/entities/interactions.dart';

/// Correspondance entre le JSON des assets et les entités du domaine.

ActivitySheet activityFromJson(Map<String, dynamic> json) => ActivitySheet(
      title: json['title'] as String,
      duration: json['duration'] as String?,
      materials: List<String>.from(json['materials'] as List? ?? const []),
      steps: List<String>.from(json['steps'] as List? ?? const []),
      question: json['question'] as String?,
    );

Episode episodeFromJson(Map<String, dynamic> json) => Episode(
      id: json['id'] as String,
      number: json['number'] as int,
      family: json['family'] as String,
      theme: json['theme'] as String,
      title: json['title'] as String?,
      notion: json['notion'] as String,
      pitch: json['pitch'] as String,
      activity: activityFromJson(json['activity'] as Map<String, dynamic>),
      song: json['song'] as String?,
      premium: json['access'] == 'premium',
      durationSeconds: json['durationSeconds'] as int,
      video: json['video'] as String?,
      interactionsAsset: json['interactions'] as String?,
    );

Catalog catalogFromJson(Map<String, dynamic> json) => Catalog(
      version: json['version'] as int,
      episodes: [for (final e in json['episodes'] as List) episodeFromJson(e as Map<String, dynamic>)],
    );

TouchZone touchZoneFromJson(Map<String, dynamic> json) => TouchZone(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
      correct: json['correct'] as bool? ?? false,
      symbol: json['symbol'] as String?,
    );

TouchPause touchPauseFromJson(Map<String, dynamic> json) => TouchPause(
      id: json['id'] as String,
      atSeconds: (json['atSeconds'] as num).toDouble(),
      timeoutSeconds: (json['timeoutSeconds'] as num? ?? 8).toDouble(),
      zones: [for (final z in json['zones'] as List) touchZoneFromJson(z as Map<String, dynamic>)],
    );

EpisodeInteractions interactionsFromJson(Map<String, dynamic> json) => EpisodeInteractions(
      touchPauses: [
        for (final p in json['touchPauses'] as List? ?? const []) touchPauseFromJson(p as Map<String, dynamic>),
      ],
    );
