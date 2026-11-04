import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme.dart';

class OupiApp extends StatelessWidget {
  const OupiApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
        state: state,
        child: MaterialApp(
          title: 'Oupi',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: const RootGate(),
        ),
      );
}

/// Premier lancement : onboarding parent. Ensuite : l'accueil.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) =>
      AppScope.of(context).onboardingDone ? const HomeScreen() : const OnboardingScreen();
}
