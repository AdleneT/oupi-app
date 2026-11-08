import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oupi/app.dart';
import 'package:oupi/application/app_state.dart';
import 'package:oupi/domain/rules/parent_gate.dart';
import 'package:oupi/presentation/screens/episodes_screen.dart';
import 'package:oupi/presentation/screens/home_screen.dart';
import 'package:oupi/presentation/screens/parent_gate_screen.dart';
import 'package:oupi/presentation/screens/sleep_screen.dart';

import 'helpers.dart';

void main() {
  group('Interface', () {
    testWidgets('premier lancement : onboarding puis accueil', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final h = TestHarness();
      await tester.pumpWidget(OupiApp(state: h.state));
      expect(find.text('Suivant'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
      }
      await tester.tap(find.text('Commencer'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Épisodes'), findsOneWidget);
      expect(h.settingsRepo.current.onboardingDone, isTrue);
    });

    testWidgets('le soir, l’accueil montre Oupi qui dort', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final h = TestHarness(at: DateTime(2026, 11, 4, 20), settings: onboarded);
      await tester.pumpWidget(OupiApp(state: h.state));
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
      final expected = ParentGateChallenge.random(Random(3)).target;
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

    testWidgets('lancer un épisode verrouillé ouvre « Oups » puis le contrôle parental, jamais l’achat', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final h = TestHarness(settings: onboarded);
      await tester.pumpWidget(OupiApp(state: h.state));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.bySemanticsLabel('Épisodes'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(EpisodesScreen), findsOneWidget);
      // La vignette 6 est plus loin dans la rangée : on fait défiler jusqu'à elle.
      final locked = find.bySemanticsLabel(RegExp('Épisode 6.*verrouillé'));
      await tester.dragUntilVisible(locked, find.byType(ListView), const Offset(-250, 0));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(locked);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Demande à papa ou maman'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ParentGateScreen), findsOneWidget);
      expect(h.state.startedToday, 0, reason: 'un refus ne compte pas comme un lancement');
    });
  });

  group('Règles vues par l’interface', () {
    test('StartCheck et SleepReason sont exposés par la couche application', () {
      expect(StartCheck.values, hasLength(4));
      expect(SleepReason.values, hasLength(2));
    });
  });
}
