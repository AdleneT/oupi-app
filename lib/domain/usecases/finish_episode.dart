import '../entities/episode.dart';
import '../entities/viewing_history.dart';
import '../ports/history_repository.dart';

/// L'épisode est allé jusqu'au rituel de fin : il gagne sa pousse.
class FinishEpisode {
  const FinishEpisode({required this.history});
  final HistoryRepository history;

  Future<ViewingHistory> call(Episode episode, ViewingHistory current) async {
    final next = current.markWatched(episode.id);
    if (!identical(next, current)) await history.save(next);
    return next;
  }
}
