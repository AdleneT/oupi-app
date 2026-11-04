import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/episode.dart';

/// Pourquoi un épisode ne peut pas démarrer.
enum StartCheck { ok, locked, sleepTime, limitReached }

/// Pourquoi Oupi dort.
enum SleepReason { sleepTime, limitReached }

class DayHistory {
  const DayHistory(this.day, this.episodes);
  final DateTime day;
  final List<Episode> episodes;
}

/// Tout l'état de l'appli, stocké uniquement sur l'appareil (GDD §12 : un seul profil, aucun compte).
class AppState extends ChangeNotifier {
  AppState({required this._prefs, required this.catalog, DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _load();
  }

  static const minDailyLimit = 1;
  static const maxDailyLimit = 3;
  static const defaultDailyLimit = 1;
  static const defaultSleepHour = 19;
  static const sleepHourChoices = [17, 18, 19, 20, 21];

  /// Heure du réveil : l'appli dort entre l'heure du dodo et 7 h.
  static const wakeHour = 7;
  static const _historyDays = 30;

  static const _kOnboarding = 'onboardingDone';
  static const _kDailyLimit = 'dailyLimit';
  static const _kSleepHour = 'sleepHour';
  static const _kPremium = 'premium';
  static const _kSound = 'sound';
  static const _kFast = 'fastPlayback';
  static const _kWatched = 'watched';
  static const _kHistory = 'history';

  final SharedPreferences _prefs;
  final Catalog catalog;
  final DateTime Function() _clock;

  bool _onboardingDone = false;
  int _dailyLimit = defaultDailyLimit;
  int _sleepHour = defaultSleepHour;
  bool _premium = false;
  bool _sound = true;
  bool _fastPlayback = false;
  final Set<String> _watched = {};
  final Map<String, List<String>> _history = {};

  bool get onboardingDone => _onboardingDone;
  int get dailyLimit => _dailyLimit;
  int get sleepHour => _sleepHour;
  bool get premium => _premium;
  bool get sound => _sound;

  /// Mode test du prototype : la maquette d'épisode défile dix fois plus vite.
  bool get fastPlayback => _fastPlayback;

  DateTime get now => _clock();

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isSleepTime([DateTime? at]) {
    final hour = (at ?? now).hour;
    return hour >= _sleepHour || hour < wakeHour;
  }

  int startedOn(DateTime day) => _history[dayKey(day)]?.length ?? 0;
  int get startedToday => startedOn(now);
  int get episodesLeftToday => max(0, _dailyLimit - startedToday);
  bool get limitReached => episodesLeftToday == 0;

  bool isLocked(Episode e) => e.premium && !_premium;
  bool isWatched(Episode e) => _watched.contains(e.id);

  /// Un épisode verrouillé passe toujours par le contrôle parental, jamais par un écran d'achat (GDD §9).
  StartCheck checkStart(Episode e) {
    if (isLocked(e)) return StartCheck.locked;
    if (isSleepTime()) return StartCheck.sleepTime;
    if (limitReached) return StartCheck.limitReached;
    return StartCheck.ok;
  }

  /// La limite compte les épisodes lancés, pour qu'on ne puisse pas la contourner en quittant avant la fin.
  Future<void> recordStart(Episode e) async {
    _history.putIfAbsent(dayKey(now), () => []).add(e.id);
    _pruneHistory();
    await _prefs.setString(_kHistory, jsonEncode(_history));
    notifyListeners();
  }

  Future<void> markWatched(Episode e) async {
    if (_watched.add(e.id)) {
      await _prefs.setStringList(_kWatched, _watched.toList()..sort());
      notifyListeners();
    }
  }

  /// Les `days` derniers jours, du plus récent au plus ancien.
  List<DayHistory> lastDays(int days) {
    final today = now;
    return [
      for (var i = 0; i < days; i++)
        () {
          final day = DateTime(today.year, today.month, today.day - i);
          final ids = _history[dayKey(day)] ?? const <String>[];
          return DayHistory(day, [for (final id in ids) ?catalog.byId(id)]);
        }(),
    ];
  }

  Future<void> completeOnboarding({required int dailyLimit, required int sleepHour}) async {
    _dailyLimit = dailyLimit.clamp(minDailyLimit, maxDailyLimit);
    _sleepHour = sleepHour;
    _onboardingDone = true;
    await _prefs.setInt(_kDailyLimit, _dailyLimit);
    await _prefs.setInt(_kSleepHour, _sleepHour);
    await _prefs.setBool(_kOnboarding, true);
    notifyListeners();
  }

  Future<void> setDailyLimit(int value) async {
    _dailyLimit = value.clamp(minDailyLimit, maxDailyLimit);
    await _prefs.setInt(_kDailyLimit, _dailyLimit);
    notifyListeners();
  }

  Future<void> setSleepHour(int hour) async {
    _sleepHour = hour;
    await _prefs.setInt(_kSleepHour, hour);
    notifyListeners();
  }

  /// Prototype : simule l'abonnement. Les vrais achats intégrés viendront avec `in_app_purchase`.
  Future<void> setPremium(bool value) async {
    _premium = value;
    await _prefs.setBool(_kPremium, value);
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    _sound = value;
    await _prefs.setBool(_kSound, value);
    notifyListeners();
  }

  Future<void> setFastPlayback(bool value) async {
    _fastPlayback = value;
    await _prefs.setBool(_kFast, value);
    notifyListeners();
  }

  /// Réinitialise tout : réglages, historique, épisodes vus et onboarding.
  Future<void> resetAll() async {
    await _prefs.clear();
    _onboardingDone = false;
    _dailyLimit = defaultDailyLimit;
    _sleepHour = defaultSleepHour;
    _premium = false;
    _sound = true;
    _fastPlayback = false;
    _watched.clear();
    _history.clear();
    notifyListeners();
  }

  void _load() {
    _onboardingDone = _prefs.getBool(_kOnboarding) ?? false;
    _dailyLimit = (_prefs.getInt(_kDailyLimit) ?? defaultDailyLimit).clamp(minDailyLimit, maxDailyLimit);
    _sleepHour = _prefs.getInt(_kSleepHour) ?? defaultSleepHour;
    _premium = _prefs.getBool(_kPremium) ?? false;
    _sound = _prefs.getBool(_kSound) ?? true;
    _fastPlayback = _prefs.getBool(_kFast) ?? false;
    _watched
      ..clear()
      ..addAll(_prefs.getStringList(_kWatched) ?? const []);
    _history.clear();
    final raw = _prefs.getString(_kHistory);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((day, ids) => _history[day] = List<String>.from(ids as List));
      } on FormatException {
        // Historique illisible : on repart d'une semaine vide plutôt que de bloquer l'appli.
      }
    }
  }

  void _pruneHistory() {
    final today = now;
    final oldest = dayKey(DateTime(today.year, today.month, today.day - _historyDays));
    _history.removeWhere((day, _) => day.compareTo(oldest) < 0);
  }
}
