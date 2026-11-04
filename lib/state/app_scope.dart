import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Donne accès à [AppState] dans tout l'arbre de widgets et reconstruit ceux qui l'écoutent.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// À utiliser dans `build` : le widget se reconstruit quand l'état change.
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// À utiliser dans les gestionnaires d'événements : pas d'abonnement.
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
