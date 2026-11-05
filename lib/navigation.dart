import 'dart:async';

import 'package:flutter/material.dart';

import 'models/episode.dart';
import 'screens/paywall_screen.dart';
import 'screens/parent_gate_screen.dart';
import 'screens/parent_space_screen.dart';
import 'screens/player_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Transition lente en fondu : pas de mouvement brusque (GDD §4).
Route<T> gentleRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 550),
  reverseTransitionDuration: const Duration(milliseconds: 380),
  pageBuilder: (context, animation, secondaryAnimation) => page,
  transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  ),
);

/// Lance un épisode en appliquant les règles : verrou, heure du dodo, limite du jour.
Future<void> openEpisode(BuildContext context, Episode episode) async {
  final state = AppScope.read(context);
  final navigator = Navigator.of(context);
  switch (state.checkStart(episode)) {
    case StartCheck.locked:
      await askAGrownUp(context, destination: const PaywallScreen());
    case StartCheck.sleepTime || StartCheck.limitReached:
      // L'accueil se transforme en écran « Il fait dodo », sans bouton retour.
      navigator.popUntil((route) => route.isFirst);
    case StartCheck.ok:
      // Le lecteur passe devant avant que l'épisode soit compté : si c'était le dernier du jour,
      // l'épisode se regarde jusqu'au bout et Oupi s'endort à la fin.
      final playing = navigator.push(gentleRoute(PlayerScreen(episode: episode)));
      await state.recordStart(episode);
      await playing;
  }
}

/// Route d'un menu de l'enfant (épisodes, musique, galerie, exercices) : elle se referme d'elle-même
/// quand Oupi s'endort, et l'appli revient à l'écran « Il fait dodo ».
Route<T> kidRoute<T>(Widget page) => gentleRoute<T>(SleepGuard(child: page));

/// Ramène à l'accueil endormi dès qu'Oupi s'endort (heure du dodo ou limite du jour) pendant que
/// l'enfant est dans ce menu. Ne fait rien tant qu'un autre écran est devant (épisode en cours,
/// espace parents) : l'épisode se termine, puis Oupi s'endort.
class SleepGuard extends StatefulWidget {
  const SleepGuard({super.key, required this.child});
  final Widget child;

  @override
  State<SleepGuard> createState() => _SleepGuardState();
}

class _SleepGuardState extends State<SleepGuard> {
  Timer? _clock;
  ModalRoute<Object?>? _route;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context);
    _route = ModalRoute.of(context);
    _check();
  }

  void _check() {
    if (_leaving || !mounted || _route?.isCurrent != true) return;
    if (AppScope.read(context).sleepReason == null) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Contrôle parental puis destination (espace parents par défaut).
Future<void> openParentArea(BuildContext context, {Widget? destination}) async {
  final navigator = Navigator.of(context);
  final passed = await navigator.push<bool>(gentleRoute(const ParentGateScreen()));
  if (passed == true) await navigator.push(gentleRoute(destination ?? const ParentSpaceScreen()));
}

/// « Oups ! Demande à papa ou maman », puis le contrôle parental s'ouvre (GDD §9).
/// Jamais d'écran d'achat accessible directement à l'enfant.
Future<void> askAGrownUp(BuildContext context, {required Widget destination}) async {
  final navigator = Navigator.of(context);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: OupiColors.ink.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (dialogContext, animation, secondaryAnimation) => const _OupsBubble(),
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(animation), child: child),
    ),
  );
  final passed = await navigator.push<bool>(gentleRoute(const ParentGateScreen()));
  if (passed == true) await navigator.push(gentleRoute(destination));
}

class _OupsBubble extends StatefulWidget {
  const _OupsBubble();

  @override
  State<_OupsBubble> createState() => _OupsBubbleState();
}

class _OupsBubbleState extends State<_OupsBubble> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // La voix d'Oupi dira la phrase ; la bulle se ferme seule ensuite.
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BreathingCharacter(
            asset: 'assets/images/oupi_wave.png',
            height: MediaQuery.sizeOf(context).height * 0.6,
            label: 'Oupi',
            shadow: false,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Vivid.mango, width: 6),
              boxShadow: [BoxShadow(color: Vivid.plum.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Text('Oups !\nDemande à papa ou maman.', style: display(28, weight: 700, color: Vivid.plum)),
          ),
        ],
      ),
    ),
  );
}
