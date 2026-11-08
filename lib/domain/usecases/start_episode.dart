import '../entities/episode.dart';
import '../entities/parental_settings.dart';
import '../entities/viewing_history.dart';
import '../ports/clock.dart';
import '../ports/history_repository.dart';
import '../rules/viewing_rules.dart';

class StartOutcome {
  const StartOutcome(this.check, this.history);
  final StartCheck check;

  /// L'historique après le lancement (inchangé si l'épisode n'a pas pu démarrer).
  final ViewingHistory history;
}

/// Lance un épisode : applique les règles puis compte le lancement dans la journée.
class StartEpisode {
  const StartEpisode({required this.history, required this.clock, this.rules = const ViewingRules()});
  final HistoryRepository history;
  final Clock clock;
  final ViewingRules rules;

  Future<StartOutcome> call(Episode episode, ParentalSettings settings, ViewingHistory current) async {
    final now = clock.now();
    final check = rules.checkStart(episode, settings, current, now);
    if (check != StartCheck.ok) return StartOutcome(check, current);
    final next = current.recordStart(episode.id, now);
    await history.save(next);
    return StartOutcome(check, next);
  }
}
