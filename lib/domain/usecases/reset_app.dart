import '../entities/parental_settings.dart';
import '../entities/viewing_history.dart';
import '../ports/history_repository.dart';
import '../ports/settings_repository.dart';

/// Réinitialise tout : réglages, historique, épisodes vus et onboarding.
class ResetApp {
  const ResetApp({required this.settings, required this.history});
  final SettingsRepository settings;
  final HistoryRepository history;

  Future<(ParentalSettings, ViewingHistory)> call() async {
    await Future.wait([settings.clear(), history.clear()]);
    return (ParentalSettings.defaults, ViewingHistory.empty);
  }
}
