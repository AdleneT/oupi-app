import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/parental_settings.dart';
import '../../domain/ports/settings_repository.dart';

/// Adaptateur : les réglages dans SharedPreferences, uniquement sur l'appareil.
class SharedPrefsSettingsRepository implements SettingsRepository {
  const SharedPrefsSettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kOnboarding = 'onboardingDone';
  static const _kDailyLimit = 'dailyLimit';
  static const _kSleepHour = 'sleepHour';
  static const _kPremium = 'premium';
  static const _kSound = 'sound';
  static const _kFast = 'fastPlayback';
  static const _keys = [_kOnboarding, _kDailyLimit, _kSleepHour, _kPremium, _kSound, _kFast];

  @override
  Future<ParentalSettings> load() async {
    const d = ParentalSettings.defaults;
    return ParentalSettings(
      onboardingDone: _prefs.getBool(_kOnboarding) ?? d.onboardingDone,
      dailyLimit: _prefs.getInt(_kDailyLimit) ?? d.dailyLimit,
      sleepHour: _prefs.getInt(_kSleepHour) ?? d.sleepHour,
      premium: _prefs.getBool(_kPremium) ?? d.premium,
      sound: _prefs.getBool(_kSound) ?? d.sound,
      fastPlayback: _prefs.getBool(_kFast) ?? d.fastPlayback,
    );
  }

  @override
  Future<void> save(ParentalSettings s) => Future.wait([
        _prefs.setBool(_kOnboarding, s.onboardingDone),
        _prefs.setInt(_kDailyLimit, s.dailyLimit),
        _prefs.setInt(_kSleepHour, s.sleepHour),
        _prefs.setBool(_kPremium, s.premium),
        _prefs.setBool(_kSound, s.sound),
        _prefs.setBool(_kFast, s.fastPlayback),
      ]);

  @override
  Future<void> clear() => Future.wait([for (final k in _keys) _prefs.remove(k)]);
}
