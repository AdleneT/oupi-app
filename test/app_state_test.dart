import 'package:flutter_test/flutter_test.dart';
import 'package:oupi/application/app_state.dart';
import 'package:oupi/domain/entities/parental_settings.dart';
import 'package:oupi/domain/entities/viewing_history.dart';
import 'package:oupi/infrastructure/persistence/shared_prefs_history_repository.dart';
import 'package:oupi/infrastructure/persistence/shared_prefs_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  group('AppState et cas d’usage', () {
    test('limite quotidienne : 1 épisode par défaut, compté au lancement', () async {
      final h = TestHarness();
      expect(await h.state.startEpisode(h.episode('ep01')), StartCheck.ok);
      expect(h.state.limitReached, isTrue);
      expect(h.historyRepo.saves, 1);
      expect(await h.state.startEpisode(h.episode('ep02')), StartCheck.limitReached);
      expect(h.historyRepo.saves, 1, reason: 'un refus n’écrit rien');
    });

    test('la limite repart le lendemain', () async {
      final h = TestHarness();
      await h.state.startEpisode(h.episode('ep01'));
      expect(h.state.limitReached, isTrue);
      h.clock.current = DateTime(2026, 11, 5, 9);
      expect(h.state.limitReached, isFalse);
      expect(h.state.lastDays(2)[1].episodes.single.id, 'ep01');
    });

    test('un épisode abonné est verrouillé tant qu’il n’y a pas d’abonnement', () async {
      final h = TestHarness();
      expect(h.state.checkStart(h.episode('ep06')), StartCheck.locked);
      await h.state.setPremium(true);
      expect(h.state.checkStart(h.episode('ep06')), StartCheck.ok);
      expect(h.settingsRepo.current.premium, isTrue);
    });

    test('le soir, on ne peut rien lancer', () async {
      final h = TestHarness(at: DateTime(2026, 11, 4, 20));
      expect(await h.state.startEpisode(h.episode('ep01')), StartCheck.sleepTime);
      expect(h.state.isSleepTime(), isTrue);
    });

    test('terminer un épisode lui donne sa pousse, une seule fois', () async {
      final h = TestHarness();
      var notified = 0;
      h.state.addListener(() => notified++);
      await h.state.finishEpisode(h.episode('ep04'));
      await h.state.finishEpisode(h.episode('ep04'));
      expect(h.state.isWatched(h.episode('ep04')), isTrue);
      expect(h.historyRepo.saves, 1);
      expect(notified, 1);
    });

    test('réinitialiser remet les réglages par défaut et vide l’historique', () async {
      final h = TestHarness(settings: const ParentalSettings(onboardingDone: true, dailyLimit: 3, premium: true));
      await h.state.startEpisode(h.episode('ep01'));
      await h.state.resetAll();
      expect(h.state.settings, ParentalSettings.defaults);
      expect(h.state.startedToday, 0);
      expect(h.settingsRepo.current, ParentalSettings.defaults);
      expect(h.historyRepo.current.startsByDay, isEmpty);
    });
  });

  group('Adaptateurs SharedPreferences', () {
    test('les réglages et l’historique survivent à un redémarrage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsRepo = SharedPrefsSettingsRepository(prefs);
      final historyRepo = SharedPrefsHistoryRepository(prefs);

      await settingsRepo.save(const ParentalSettings(onboardingDone: true, dailyLimit: 2, sleepHour: 20));
      await historyRepo.save(ViewingHistory.empty.recordStart('ep04', morning).markWatched('ep04'));

      final again = await SharedPreferences.getInstance();
      final s = await SharedPrefsSettingsRepository(again).load();
      final h = await SharedPrefsHistoryRepository(again).load();
      expect(s.onboardingDone, isTrue);
      expect(s.dailyLimit, 2);
      expect(s.sleepHour, 20);
      expect(h.startedOn(morning), 1);
      expect(h.hasWatched('ep04'), isTrue);
    });

    test('un historique illisible ne bloque pas l’appli', () async {
      SharedPreferences.setMockInitialValues({'history': '{pas du json', 'watched': <String>['ep01']});
      final prefs = await SharedPreferences.getInstance();
      final h = await SharedPrefsHistoryRepository(prefs).load();
      expect(h.startsByDay, isEmpty);
      expect(h.hasWatched('ep01'), isTrue);
    });

    test('effacer ne touche que ses propres clés', () async {
      SharedPreferences.setMockInitialValues({'autre': 'x'});
      final prefs = await SharedPreferences.getInstance();
      await SharedPrefsSettingsRepository(prefs).save(const ParentalSettings(premium: true));
      await SharedPrefsSettingsRepository(prefs).clear();
      expect(prefs.getBool('premium'), isNull);
      expect(prefs.getString('autre'), 'x');
    });

    test('les anciennes clés du prototype sont relues telles quelles', () async {
      SharedPreferences.setMockInitialValues({'onboardingDone': true, 'dailyLimit': 3, 'sleepHour': 21});
      final prefs = await SharedPreferences.getInstance();
      final s = await SharedPrefsSettingsRepository(prefs).load();
      expect(s, const ParentalSettings(onboardingDone: true, dailyLimit: 3, sleepHour: 21));
    });
  });
}
