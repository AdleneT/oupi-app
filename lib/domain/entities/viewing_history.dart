/// Ce que l'enfant a regardé : les lancements par jour (pour la limite quotidienne)
/// et les épisodes vus jusqu'au bout (pour la pousse). Entité immuable.
class ViewingHistory {
  ViewingHistory({Map<String, List<String>> startsByDay = const {}, Set<String> watched = const {}})
      : startsByDay = Map.unmodifiable({for (final e in startsByDay.entries) e.key: List<String>.unmodifiable(e.value)}),
        watched = Set.unmodifiable(watched);

  static final empty = ViewingHistory();

  /// Au-delà, les journées sont oubliées : on ne garde pas de trace longue de l'enfant.
  static const retentionDays = 30;

  /// Clé « AAAA-MM-JJ » → identifiants des épisodes lancés ce jour-là, dans l'ordre.
  final Map<String, List<String>> startsByDay;
  final Set<String> watched;

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<String> startsOn(DateTime day) => startsByDay[dayKey(day)] ?? const [];
  int startedOn(DateTime day) => startsOn(day).length;
  bool hasWatched(String episodeId) => watched.contains(episodeId);

  /// La limite compte les épisodes lancés, pour qu'on ne puisse pas la contourner en quittant avant la fin.
  ViewingHistory recordStart(String episodeId, DateTime at) {
    final key = dayKey(at);
    final next = {for (final e in startsByDay.entries) e.key: [...e.value]};
    next.putIfAbsent(key, () => []).add(episodeId);
    final oldest = dayKey(DateTime(at.year, at.month, at.day - retentionDays));
    next.removeWhere((day, _) => day.compareTo(oldest) < 0);
    return ViewingHistory(startsByDay: next, watched: watched);
  }

  ViewingHistory markWatched(String episodeId) =>
      hasWatched(episodeId) ? this : ViewingHistory(startsByDay: startsByDay, watched: {...watched, episodeId});
}
