import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oupi/app.dart';
import 'package:oupi/models/episode.dart';
import 'package:oupi/screens/home_screen.dart';
import 'package:oupi/screens/parent_gate_screen.dart';
import 'package:oupi/screens/sleep_screen.dart';
import 'package:oupi/state/app_state.dart';
import 'package:oupi/util/french_numbers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Catalog _catalog() => Catalog.fromJson(jsonDecode(File('assets/data/catalog.json').readAsStringSync()) as Map<String, dynamic>);

Future<AppState> _state({DateTime? at, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  return AppState(prefs: p, catalog: _catalog(), clock: () => at ?? DateTime(2026, 11, 4, 10));
}

void main() {
  group('frenchNumber', () {
    test('écrit les nombres comme en France', () {
      expect(frenchNumber(21), 'vingt et un');
      expect(frenchNumber(47), 'quarante-sept');
      expect(frenchNumber(70), 'soixante-dix');
      expect(frenchNumber(71), 'soixante et onze');
      expect(frenchNumber(77), 'soixante-dix-sept');
      expect(frenchNumber(80), 'quatre-vingts');
      expect(frenchNumber(81), 'quatre-vingt-un');
      expect(frenchNumber(91), 'quatre-vingt-onze');
      expect(frenchNumber(99), 'quatre-vingt-dix-neuf');
    });

    test('refuse les nombres hors de 0 à 99', () {
      expect(() => frenchNumber(100), throwsRangeError);
    });
  });

  group('Catalogue', () {
    test('10 épisodes, 5 gratuits et 5 abonnés, l’épisode 4 a ses interactions', () {
      final c = _catalog();
      expect(c.episodes, hasLength(10));
      expect(c.episodes.where((e) => !e.premium), hasLength(5));
      final ep4 = c.byId('ep04')!;
      expect(ep4.title, 'Un cadeau pour Lolo');
      expect(ep4.activity.isDetailed, isTrue);
      expect(ep4.interactionsAsset, 'assets/data/interactions/ep04.json');
      expect(File(ep4.interactionsAsset!).existsSync(), isTrue);
    });
  });

  group('Règles de l’appli', () {
    test('limite quotidienne : 1 épisode par défaut, compté au lancement', () async {
      final s = await _state();
      final ep1 = s.catalog.byId('ep01')!;
      expect(s.checkStart(ep1), StartCheck.ok);
      await s.recordStart(ep1);
      expect(s.limitReached, isTrue);
      expect(s.checkStart(s.catalog.byId('ep02')!), StartCheck.limitReached);
    });

    test('la limite repart le lendemain', () async {
      var now = DateTime(2026, 11, 4, 10);
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      final s = AppState(prefs: p, catalog: _catalog(), clock: () => now);
      await s.recordStart(s.catalog.byId('ep01')!);
      expect(s.limitReached, isTrue);
      now = DateTime(2026, 11, 5, 9);
      expect(s.limitReached, isFalse);
      expect(s.lastDays(2)[1].episodes.single.id, 'ep01');
    });

    test('l’appli dort de 19 h à 7 h par défaut', () async {
      final s = await _state();
      expect(s.isSleepTime(DateTime(2026, 11, 4, 18, 59)), isFalse);
      expect(s.isSleepTime(DateTime(2026, 11, 4, 19)), isTrue);
      expect(s.isSleepTime(DateTime(2026, 11, 5, 6, 30)), isTrue);
      expect(s.isSleepTime(DateTime(2026, 11, 5, 7)), isFalse);
    });

    test('un épisode abonné est verrouillé tant qu’il n’y a pas d’abonnement', () async {
      final s = await _state();
      final ep6 = s.catalog.byId('ep06')!;
      expect(s.checkStart(ep6), StartCheck.locked);
      await s.setPremium(true);
      expect(s.checkStart(ep6), StartCheck.ok);
    });

    test('le verrou passe avant l’heure du dodo', () async {
      final s = await _state(at: DateTime(2026, 11, 4, 20));
      expect(s.checkStart(s.catalog.byId('ep06')!), StartCheck.locked);
      expect(s.checkStart(s.catalog.byId('ep01')!), StartCheck.sleepTime);
    });

    test('les réglages et l’historique survivent à un redémarrage', () async {
      final s = await _state();
      await s.completeOnboarding(dailyLimit: 2, sleepHour: 20);
      await s.recordStart(s.catalog.byId('ep04')!);
      await s.markWatched(s.catalog.byId('ep04')!);
      final p = await SharedPreferences.getInstance();
      final again = AppState(prefs: p, catalog: _catalog(), clock: () => DateTime(2026, 11, 4, 11));
      expect(again.onboardingDone, isTrue);
      expect(again.dailyLimit, 2);
      expect(again.sleepHour, 20);
      expect(again.startedToday, 1);
      expect(again.isWatched(again.catalog.byId('ep04')!), isTrue);
    });
  });

  group('Interface', () {
    testWidgets('premier lancement : onboarding puis accueil', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final s = await _state();
      await tester.pumpWidget(OupiApp(state: s));
      expect(find.text('Suivant'), findsOneWidget);
      // Oupi respire en boucle : on avance le temps au lieu d'attendre la fin des animations.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
      }
      await tester.tap(find.text('Commencer'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Épisodes'), findsOneWidget);
    });

    testWidgets('le soir, l’accueil montre Oupi qui dort', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final s = await _state(at: DateTime(2026, 11, 4, 20), prefs: {'onboardingDone': true});
      await tester.pumpWidget(OupiApp(state: s));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SleepScreen), findsOneWidget);
      expect(find.text('Il fait dodo. On se retrouve demain matin !'), findsOneWidget);
    });

    testWidgets('contrôle parental : la bonne réponse en chiffres ouvre l’accès', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      bool? result;
      // Même graine que l'écran : on connaît le nombre demandé.
      final expected = 21 + Random(3).nextInt(79);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => ParentGateScreen(random: Random(3))),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text(frenchNumber(expected)), findsOneWidget);
      final digits = expected.toString();
      await tester.tap(find.text(digits[0]).last);
      await tester.pump();
      await tester.tap(find.text(digits[1]).last);
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });
}
