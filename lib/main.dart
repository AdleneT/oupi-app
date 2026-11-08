import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'application/app_state.dart';
import 'infrastructure/assets/asset_catalog_repository.dart';
import 'infrastructure/clock.dart';
import 'infrastructure/persistence/shared_prefs_history_repository.dart';
import 'infrastructure/persistence/shared_prefs_settings_repository.dart';

/// Racine de composition : c'est le seul endroit qui branche les adaptateurs sur les ports.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Les épisodes sont en 16:9 : l'appli reste à l'horizontale sur téléphone et tablette.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  final prefs = await SharedPreferences.getInstance();
  final state = await AppState.bootstrap(
    catalogs: AssetCatalogRepository(rootBundle),
    settings: SharedPrefsSettingsRepository(prefs),
    history: SharedPrefsHistoryRepository(prefs),
    clock: const SystemClock(),
  );
  runApp(OupiApp(state: state));
}
