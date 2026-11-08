import '../entities/viewing_history.dart';

/// Port : où est conservé l'historique de visionnage.
abstract interface class HistoryRepository {
  Future<ViewingHistory> load();
  Future<void> save(ViewingHistory history);
  Future<void> clear();
}
