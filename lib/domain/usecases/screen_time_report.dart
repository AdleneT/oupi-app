import '../entities/episode.dart';
import '../entities/viewing_history.dart';

class DayReport {
  const DayReport(this.day, this.episodes);
  final DateTime day;
  final List<Episode> episodes;
}

/// Le temps d'écran des derniers jours, pour l'espace parents (GDD §10).
class ScreenTimeReport {
  const ScreenTimeReport();

  /// Les [days] derniers jours, du plus récent au plus ancien.
  List<DayReport> lastDays(int days, ViewingHistory history, Catalog catalog, DateTime now) => [
        for (var i = 0; i < days; i++)
          () {
            final day = DateTime(now.year, now.month, now.day - i);
            return DayReport(day, [for (final id in history.startsOn(day)) ?catalog.byId(id)]);
          }(),
      ];
}
