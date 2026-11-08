import '../../domain/entities/episode.dart';
import '../../domain/entities/interactions.dart';
import '../../domain/entities/parental_settings.dart';
import '../../domain/entities/viewing_history.dart';
import '../../domain/ports/catalog_repository.dart';
import '../../domain/ports/history_repository.dart';
import '../../domain/ports/settings_repository.dart';

/// Adaptateurs en mémoire : pour les tests et les démonstrations, sans disque ni assets.

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([this.current = ParentalSettings.defaults]);
  ParentalSettings current;
  int saves = 0;

  @override
  Future<ParentalSettings> load() async => current;
  @override
  Future<void> save(ParentalSettings settings) async {
    current = settings;
    saves++;
  }

  @override
  Future<void> clear() async => current = ParentalSettings.defaults;
}

class InMemoryHistoryRepository implements HistoryRepository {
  InMemoryHistoryRepository([ViewingHistory? current]) : current = current ?? ViewingHistory.empty;
  ViewingHistory current;
  int saves = 0;

  @override
  Future<ViewingHistory> load() async => current;
  @override
  Future<void> save(ViewingHistory history) async {
    current = history;
    saves++;
  }

  @override
  Future<void> clear() async => current = ViewingHistory.empty;
}

class InMemoryCatalogRepository implements CatalogRepository {
  InMemoryCatalogRepository(this.catalog, {this.interactions = const {}});
  final Catalog catalog;

  /// Interactions par identifiant d'épisode.
  final Map<String, EpisodeInteractions> interactions;

  @override
  Future<Catalog> loadCatalog() async => catalog;
  @override
  Future<EpisodeInteractions> loadInteractions(Episode episode) async => interactions[episode.id] ?? EpisodeInteractions.none;
}
