import 'package:flutter/material.dart';

import 'application/app_scope.dart';
import 'application/app_state.dart';
import 'presentation/responsive.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/theme.dart';

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
          builder: (context, child) => ResponsiveRoot(child: child!),
          home: const RootGate(),
        ),
      );
}

/// Agrandit doucement les textes sur tablette, en respectant le réglage d'accessibilité du système.
class ResponsiveRoot extends StatelessWidget {
  const ResponsiveRoot({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final factor = Layout(media.size).textScale;
    if (factor == 1) return child;
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(media.textScaler.scale(factor))),
      child: child,
    );
  }
}

/// Premier lancement : onboarding parent. Ensuite : l'accueil.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) =>
      AppScope.of(context).onboardingDone ? const HomeScreen() : const OnboardingScreen();
}
