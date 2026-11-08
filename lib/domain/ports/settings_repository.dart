import '../entities/parental_settings.dart';

/// Port : où sont conservés les réglages du parent (GDD §12 : uniquement sur l'appareil).
abstract interface class SettingsRepository {
  Future<ParentalSettings> load();
  Future<void> save(ParentalSettings settings);
  Future<void> clear();
}
