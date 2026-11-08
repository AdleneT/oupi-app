import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/episode.dart';
import '../../domain/entities/interactions.dart';
import '../../domain/ports/catalog_repository.dart';
import 'catalog_json.dart';

/// Adaptateur : le catalogue et les interactions sont des fichiers JSON embarqués dans l'appli.
class AssetCatalogRepository implements CatalogRepository {
  const AssetCatalogRepository(this.bundle, {this.catalogPath = defaultCatalogPath});

  static const defaultCatalogPath = 'assets/data/catalog.json';

  final AssetBundle bundle;
  final String catalogPath;

  @override
  Future<Catalog> loadCatalog() async => catalogFromJson(_decode(await bundle.loadString(catalogPath)));

  @override
  Future<EpisodeInteractions> loadInteractions(Episode episode) async {
    final path = episode.interactionsAsset;
    if (path == null) return EpisodeInteractions.none;
    try {
      return interactionsFromJson(_decode(await bundle.loadString(path)));
    } on Exception {
      // Fichier absent ou illisible : l'épisode se joue sans pause tactile plutôt que de planter.
      return EpisodeInteractions.none;
    }
  }

  static Map<String, dynamic> _decode(String raw) => jsonDecode(raw) as Map<String, dynamic>;
}
