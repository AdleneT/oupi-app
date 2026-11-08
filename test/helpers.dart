import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oupi/app.dart';
import 'package:oupi/application/app_scope.dart';
import 'package:oupi/application/app_state.dart';
import 'package:oupi/domain/entities/episode.dart';
import 'package:oupi/domain/entities/parental_settings.dart';
import 'package:oupi/domain/entities/viewing_history.dart';
import 'package:oupi/infrastructure/assets/catalog_json.dart';
import 'package:oupi/infrastructure/clock.dart';
import 'package:oupi/infrastructure/memory/in_memory_repositories.dart';
import 'package:oupi/presentation/theme.dart';

/// Le vrai catalogue des assets, lu sur le disque (les tests n'ont pas de bundle).
Catalog testCatalog() => catalogFromJson(jsonDecode(File('assets/data/catalog.json').readAsStringSync()) as Map<String, dynamic>);

/// Un mardi matin, hors de l'heure du dodo.
final morning = DateTime(2026, 11, 4, 10);

/// Un état complet branché sur des adaptateurs en mémoire.
class TestHarness {
  TestHarness({DateTime? at, ParentalSettings settings = const ParentalSettings(), ViewingHistory? history})
      : clock = FakeClock(at ?? morning),
        settingsRepo = InMemorySettingsRepository(settings),
        historyRepo = InMemoryHistoryRepository(history) {
    catalogRepo = InMemoryCatalogRepository(testCatalog());
    state = AppState(
      catalog: catalogRepo.catalog,
      settings: settingsRepo.current,
      history: historyRepo.current,
      clock: clock,
      catalogs: catalogRepo,
      settingsRepository: settingsRepo,
      historyRepository: historyRepo,
    );
  }

  final FakeClock clock;
  final InMemorySettingsRepository settingsRepo;
  final InMemoryHistoryRepository historyRepo;
  late final InMemoryCatalogRepository catalogRepo;
  late final AppState state;

  Episode episode(String id) => state.catalog.byId(id)!;
}

const onboarded = ParentalSettings(onboardingDone: true);

/// Monte un écran seul, dans le thème et l'état de l'appli, à une taille d'écran donnée.
Future<void> pumpScreen(WidgetTester tester, Widget screen, {required AppState state, required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        theme: buildTheme(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ResponsiveRoot(child: child!),
        home: screen,
      ),
    ),
  );
  // Les personnages respirent en boucle : on avance le temps au lieu d'attendre la fin des animations.
  await tester.pump(const Duration(milliseconds: 700));
}
