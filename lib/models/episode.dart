import 'dart:convert';

import 'package:flutter/services.dart';

/// Fiche activité côté parent (GDD §8). Seul l'épisode 4 a une fiche détaillée pour l'instant.
class ActivitySheet {
  const ActivitySheet({
    required this.title,
    this.duration,
    this.materials = const [],
    this.steps = const [],
    this.question,
  });

  factory ActivitySheet.fromJson(Map<String, dynamic> json) => ActivitySheet(
    title: json['title'] as String,
    duration: json['duration'] as String?,
    materials: List<String>.from(json['materials'] as List? ?? const []),
    steps: List<String>.from(json['steps'] as List? ?? const []),
    question: json['question'] as String?,
  );

  final String title;
  final String? duration;
  final List<String> materials;
  final List<String> steps;
  final String? question;

  bool get isDetailed => steps.isNotEmpty;
}

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
    this.songSeconds,
    this.songAudio,
    this.songCover,
    this.video,
    this.interactionsAsset,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: json['id'] as String,
    number: json['number'] as int,
    family: json['family'] as String,
    theme: json['theme'] as String,
    title: json['title'] as String?,
    notion: json['notion'] as String,
    pitch: json['pitch'] as String,
    activity: ActivitySheet.fromJson(json['activity'] as Map<String, dynamic>),
    song: json['song'] as String?,
    songSeconds: json['songSeconds'] as int?,
    songAudio: json['songAudio'] as String?,
    songCover: json['songCover'] as String?,
    premium: json['access'] == 'premium',
    durationSeconds: json['durationSeconds'] as int,
    video: json['video'] as String?,
    interactionsAsset: json['interactions'] as String?,
  );

  final String id;
  final int number;
  final String family;
  final String theme;
  final String? title;
  final String notion;
  final String pitch;
  final ActivitySheet activity;
  final String? song;

  /// Chanson de l'épisode (MP3 embarqué) et sa miniature carrée, quand elles existent.
  final int? songSeconds;
  final String? songAudio;
  final String? songCover;
  final bool premium;
  final int durationSeconds;

  /// Vidéo MP4 (asset ou URL). `null` tant que l'épisode n'est pas produit :
  /// le lecteur affiche alors une maquette minutée.
  final String? video;
  final String? interactionsAsset;

  String get displayTitle => title ?? theme;
  bool get hasVideo => video != null;
}

class Catalog {
  const Catalog({required this.version, required this.episodes});

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
    version: json['version'] as int,
    episodes: [for (final e in json['episodes'] as List) Episode.fromJson(e as Map<String, dynamic>)]
      ..sort((a, b) => a.number.compareTo(b.number)),
  );

  static const assetPath = 'assets/data/catalog.json';

  static Future<Catalog> load(AssetBundle bundle) async =>
      Catalog.fromJson(jsonDecode(await bundle.loadString(assetPath)) as Map<String, dynamic>);

  final int version;
  final List<Episode> episodes;

  Episode? byId(String id) {
    for (final e in episodes) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<Episode> get songs => episodes.where((e) => e.song != null).toList();
}
