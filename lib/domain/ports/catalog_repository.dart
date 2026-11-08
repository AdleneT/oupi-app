import '../entities/episode.dart';
import '../entities/interactions.dart';

/// Port : d'où viennent les épisodes et leurs fichiers d'interactions.
abstract interface class CatalogRepository {
  Future<Catalog> loadCatalog();

  /// Les pauses tactiles d'un épisode ; [EpisodeInteractions.none] s'il n'en a pas.
  Future<EpisodeInteractions> loadInteractions(Episode episode);
}
