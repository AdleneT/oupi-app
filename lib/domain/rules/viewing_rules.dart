import 'dart:math';

import '../entities/episode.dart';
import '../entities/parental_settings.dart';
import '../entities/viewing_history.dart';

/// Pourquoi un épisode ne peut pas démarrer.
enum StartCheck { ok, locked, sleepTime, limitReached }

/// Pourquoi Oupi dort.
enum SleepReason { sleepTime, limitReached }

/// Les règles du GDD qui décident si l'enfant peut regarder. Fonctions pures, sans état.
class ViewingRules {
  const ViewingRules();

  bool isLocked(Episode e, ParentalSettings s) => e.premium && !s.premium;

  int episodesLeft(ParentalSettings s, ViewingHistory h, DateTime now) => max(0, s.dailyLimit - h.startedOn(now));

  bool limitReached(ParentalSettings s, ViewingHistory h, DateTime now) => episodesLeft(s, h, now) == 0;

  /// Un épisode verrouillé passe toujours par le contrôle parental, jamais par un écran d'achat (GDD §9).
  /// Le verrou passe avant l'heure du dodo, qui passe avant la limite du jour.
  StartCheck checkStart(Episode e, ParentalSettings s, ViewingHistory h, DateTime now) {
    if (isLocked(e, s)) return StartCheck.locked;
    if (s.isSleepTime(now)) return StartCheck.sleepTime;
    if (limitReached(s, h, now)) return StartCheck.limitReached;
    return StartCheck.ok;
  }
}
