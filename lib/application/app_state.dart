import 'package:flutter/foundation.dart';

import '../domain/entities/episode.dart';
import '../domain/entities/interactions.dart';
import '../domain/entities/parental_settings.dart';
import '../domain/entities/viewing_history.dart';
import '../domain/ports/catalog_repository.dart';
import '../domain/ports/clock.dart';
import '../domain/ports/history_repository.dart';
import '../domain/ports/settings_repository.dart';
import '../domain/rules/viewing_rules.dart';
import '../domain/usecases/bootstrap_app.dart';
import '../domain/usecases/finish_episode.dart';
import '../domain/usecases/reset_app.dart';
import '../domain/usecases/screen_time_report.dart';
import '../domain/usecases/start_episode.dart';
import '../domain/usecases/update_settings.dart';

export '../domain/rules/viewing_rules.dart' show SleepReason, StartCheck;
export '../domain/usecases/screen_time_report.dart' show DayReport;

/// Façade entre l'interface et le domaine (adaptateur côté « pilote » de l'hexagone).
/// Garde en mémoire l'état courant, appelle les cas d'usage et prévient les widgets.
/// Tout reste sur l'appareil : un seul profil, aucun compte (GDD §12).
class AppState extends ChangeNotifier {
  AppState({
    required this.catalog,
    required this._settings,
    required this._history,
    required Clock clock,
    required this._catalogs,
    required SettingsRepository settingsRepository,
    required HistoryRepository historyRepository,
    ViewingRules rules = const ViewingRules(),
  })  : _clock = clock,
        _rules = rules,
        _startEpisode = StartEpisode(history: historyRepository, clock: clock, rules: rules),
        _finishEpisode = FinishEpisode(history: historyRepository),
        _updateSettings = UpdateSettings(settings: settingsRepository),
        _resetApp = ResetApp(settings: settingsRepository, history: historyRepository);

  /// Charge tout puis construit l'état. C'est la racine de composition appelée par `main`.
  static Future<AppState> bootstrap({
    required CatalogRepository catalogs,
    required SettingsRepository settings,
    required HistoryRepository history,
    required Clock clock,
  }) async {
    final snapshot = await BootstrapApp(catalogs: catalogs, settings: settings, history: history)();
    return AppState(
      catalog: snapshot.catalog,
      settings: snapshot.settings,
      history: snapshot.history,
      clock: clock,
      catalogs: catalogs,
      settingsRepository: settings,
      historyRepository: history,
    );
  }

  final Catalog catalog;
  final Clock _clock;
  final CatalogRepository _catalogs;
  final ViewingRules _rules;
  final StartEpisode _startEpisode;
  final FinishEpisode _finishEpisode;
  final UpdateSettings _updateSettings;
  final ResetApp _resetApp;
  static const _report = ScreenTimeReport();

  ParentalSettings _settings;
  ViewingHistory _history;

  ParentalSettings get settings => _settings;
  ViewingHistory get history => _history;
  DateTime get now => _clock.now();

  // Raccourcis de lecture pour les écrans.
  bool get onboardingDone => _settings.onboardingDone;
  int get dailyLimit => _settings.dailyLimit;
  int get sleepHour => _settings.sleepHour;
  bool get premium => _settings.premium;
  bool get sound => _settings.sound;
  bool get fastPlayback => _settings.fastPlayback;

  bool isSleepTime([DateTime? at]) => _settings.isSleepTime(at ?? now);
  int get startedToday => _history.startedOn(now);
  int get episodesLeftToday => _rules.episodesLeft(_settings, _history, now);
  bool get limitReached => _rules.limitReached(_settings, _history, now);
  bool isLocked(Episode e) => _rules.isLocked(e, _settings);
  bool isWatched(Episode e) => _history.hasWatched(e.id);

  /// Ce qui se passerait si on lançait l'épisode maintenant, sans rien enregistrer.
  StartCheck checkStart(Episode e) => _rules.checkStart(e, _settings, _history, now);

  List<DayReport> lastDays(int days) => _report.lastDays(days, _history, catalog, now);

  Future<EpisodeInteractions> interactionsFor(Episode e) => _catalogs.loadInteractions(e);

  /// Applique les règles et, si l'épisode peut démarrer, compte le lancement.
  Future<StartCheck> startEpisode(Episode e) async {
    final outcome = await _startEpisode(e, _settings, _history);
    if (outcome.check == StartCheck.ok) _setHistory(outcome.history);
    return outcome.check;
  }

  Future<void> finishEpisode(Episode e) async => _setHistory(await _finishEpisode(e, _history));

  Future<void> completeOnboarding({required int dailyLimit, required int sleepHour}) =>
      _save(_settings.copyWith(dailyLimit: dailyLimit, sleepHour: sleepHour, onboardingDone: true));
  Future<void> setDailyLimit(int value) => _save(_settings.copyWith(dailyLimit: value));
  Future<void> setSleepHour(int hour) => _save(_settings.copyWith(sleepHour: hour));
  Future<void> setPremium(bool value) => _save(_settings.copyWith(premium: value));
  Future<void> setSound(bool value) => _save(_settings.copyWith(sound: value));
  Future<void> setFastPlayback(bool value) => _save(_settings.copyWith(fastPlayback: value));

  Future<void> resetAll() async {
    final (s, h) = await _resetApp();
    _settings = s;
    _history = h;
    notifyListeners();
  }

  Future<void> _save(ParentalSettings next) async {
    _settings = await _updateSettings(next);
    notifyListeners();
  }

  void _setHistory(ViewingHistory next) {
    if (identical(next, _history)) return;
    _history = next;
    notifyListeners();
  }
}
