import '../entities/parental_settings.dart';
import '../ports/settings_repository.dart';

/// Enregistre de nouveaux réglages parent. Le bornage (1 à 3 épisodes) est fait par l'entité.
class UpdateSettings {
  const UpdateSettings({required this.settings});
  final SettingsRepository settings;

  Future<ParentalSettings> call(ParentalSettings next) async {
    await settings.save(next);
    return next;
  }
}
