import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oupi/application/app_state.dart';
import 'package:oupi/domain/entities/parental_settings.dart';
import 'package:oupi/presentation/responsive.dart';
import 'package:oupi/presentation/screens/episodes_screen.dart';
import 'package:oupi/presentation/screens/gallery_screen.dart';
import 'package:oupi/presentation/screens/home_screen.dart';
import 'package:oupi/presentation/screens/music_screen.dart';
import 'package:oupi/presentation/screens/onboarding_screen.dart';
import 'package:oupi/presentation/screens/parent_gate_screen.dart';
import 'package:oupi/presentation/screens/parent_space_screen.dart';
import 'package:oupi/presentation/screens/paywall_screen.dart';
import 'package:oupi/presentation/screens/rest_screen.dart';
import 'package:oupi/presentation/screens/sleep_screen.dart';

import 'helpers.dart';

/// Les tailles d'écran à couvrir : téléphones et tablettes, dans les deux sens, grand écran.
const sizes = <String, Size>{
  'téléphone compact à l’horizontale': Size(640, 320),
  'iPhone à l’horizontale': Size(844, 390),
  'iPhone 17 à l’horizontale': Size(874, 402),
  'iPhone en portrait (première image, écran partagé)': Size(402, 874),
  'iPad à l’horizontale': Size(1194, 834),
  'iPad en portrait': Size(834, 1194),
  'tablette Android 10"': Size(1280, 800),
  'grand écran': Size(1920, 1080),
};

void main() {
  group('Layout', () {
    test('classe les écrans selon leur côté le plus court', () {
      expect(const Layout(Size(844, 390)).screenClass, ScreenClass.compact);
      expect(const Layout(Size(1194, 834)).screenClass, ScreenClass.medium);
      expect(const Layout(Size(1920, 1080)).screenClass, ScreenClass.expanded);
      expect(const Layout(Size(402, 874)).isPortrait, isTrue);
      expect(const Layout(Size(402, 874)).isNarrow, isTrue);
    });

    test('met à l’échelle sans jamais devenir illisible ni démesuré', () {
      expect(const Layout(Size(640, 320)).scale, 0.8205128205128205);
      expect(const Layout(Size(844, 390)).scale, 1);
      expect(const Layout(Size(1920, 1080)).scale, 1.5);
      expect(const Layout(Size(1920, 1080)).textScale, 1.2);
    });

    test('un personnage est borné par la hauteur et par la largeur', () {
      // Peu de largeur : c'est la largeur qui décide.
      expect(characterHeight(const BoxConstraints(maxWidth: 338, maxHeight: 690), heightFraction: 0.92, widthFraction: 0.36),
          closeTo(338 * 0.36 / 0.72, 0.01));
      // Beaucoup de largeur : c'est la hauteur.
      expect(characterHeight(const BoxConstraints(maxWidth: 1600, maxHeight: 400), heightFraction: 0.5), 200);
    });
  });

  group('Aucun débordement, sur toutes les tailles d’écran', () {
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      group(name, () {
        testWidgets('onboarding, ses trois pages', (tester) async {
          final h = TestHarness();
          await pumpScreen(tester, const OnboardingScreen(), state: h.state, size: size);
          for (var i = 0; i < 2; i++) {
            await tester.tap(find.text('Suivant'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 700));
          }
          expect(find.text('Commencer'), findsOneWidget);
        });

        testWidgets('accueil le jour', (tester) async {
          final h = TestHarness(settings: onboarded);
          await pumpScreen(tester, const HomeScreen(), state: h.state, size: size);
          expect(find.bySemanticsLabel('Épisodes'), findsOneWidget);
        });

        testWidgets('il fait dodo', (tester) async {
          final h = TestHarness(settings: onboarded);
          await pumpScreen(tester, const SleepScreen(reason: SleepReason.limitReached), state: h.state, size: size);
        });

        testWidgets('écran de repos avec Lolo', (tester) async {
          final h = TestHarness(settings: onboarded);
          await pumpScreen(tester, RestScreen(episode: h.episode('ep04')), state: h.state, size: size);
        });

        testWidgets('épisodes', (tester) async {
          final h = TestHarness(settings: onboarded);
          await pumpScreen(tester, const EpisodesScreen(), state: h.state, size: size);
          expect(find.bySemanticsLabel(RegExp('Épisode 1,')), findsOneWidget);
        });

        testWidgets('musique', (tester) async {
          final h = TestHarness(settings: const ParentalSettings(onboardingDone: true, premium: true));
          await pumpScreen(tester, const MusicScreen(), state: h.state, size: size);
        });

        testWidgets('galerie', (tester) async {
          final h = TestHarness(settings: onboarded);
          await pumpScreen(tester, const GalleryScreen(), state: h.state, size: size);
        });

        testWidgets('contrôle parental', (tester) async {
          final h = TestHarness(settings: onboarded);
          await pumpScreen(tester, const ParentGateScreen(), state: h.state, size: size);
          expect(find.text('Écris en chiffres :'), findsOneWidget);
        });

        testWidgets('abonnement', (tester) async {
          final h = TestHarness(settings: onboarded);
          await pumpScreen(tester, const PaywallScreen(), state: h.state, size: size);
        });

        testWidgets('espace parents, chaque rubrique', (tester) async {
          final h = TestHarness(settings: onboarded);
          await h.state.startEpisode(h.episode('ep04'));
          for (var i = 0; i < 7; i++) {
            await pumpScreen(tester, ParentSpaceScreen(initialSection: i), state: h.state, size: size);
          }
        });
      });
    }
  });
}
