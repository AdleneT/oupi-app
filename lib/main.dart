import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'models/episode.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Les épisodes sont en 16:9 : l'appli reste à l'horizontale sur téléphone et tablette.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  final prefs = await SharedPreferences.getInstance();
  final catalog = await Catalog.load(rootBundle);
  runApp(
    OupiApp(
      state: AppState(prefs: prefs, catalog: catalog),
    ),
  );
}
