import '../entities/episode.dart';
import '../entities/parental_settings.dart';
import '../entities/viewing_history.dart';
import '../ports/catalog_repository.dart';
import '../ports/history_repository.dart';
import '../ports/settings_repository.dart';

/// Tout ce qu'il faut charger avant d'afficher le premier écran.
class AppSnapshot {
  const AppSnapshot({required this.catalog, required this.settings, required this.history});
  final Catalog catalog;
  final ParentalSettings settings;
  final ViewingHistory history;
}

class BootstrapApp {
  const BootstrapApp({required this.catalogs, required this.settings, required this.history});
  final CatalogRepository catalogs;
  final SettingsRepository settings;
  final HistoryRepository history;

  Future<AppSnapshot> call() async {
    final (catalog, s, h) = await (catalogs.loadCatalog(), settings.load(), history.load()).wait;
    return AppSnapshot(catalog: catalog, settings: s, history: h);
  }
}
