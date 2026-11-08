import 'dart:async';

import 'package:flutter/material.dart';

import '../application/app_scope.dart';
import '../application/app_state.dart';
import '../domain/entities/episode.dart';
import 'responsive.dart';
import 'screens/parent_gate_screen.dart';
import 'screens/parent_space_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/player_screen.dart';
import 'screens/sleep_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Transition lente en fondu : pas de mouvement brusque (GDD §4).
Route<T> gentleRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 550),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut), child: child),
    );

/// Lance un épisode en appliquant les règles : verrou, heure du dodo, limite du jour.
Future<void> openEpisode(BuildContext context, Episode episode) async {
  final state = AppScope.read(context);
  final navigator = Navigator.of(context);
  switch (await state.startEpisode(episode)) {
    case StartCheck.locked:
      if (context.mounted) await askAGrownUp(context, destination: const PaywallScreen());
    case StartCheck.sleepTime:
      await navigator.push(gentleRoute(const SleepScreen(reason: SleepReason.sleepTime)));
    case StartCheck.limitReached:
      await navigator.push(gentleRoute(const SleepScreen(reason: SleepReason.limitReached)));
    case StartCheck.ok:
      await navigator.push(gentleRoute(PlayerScreen(episode: episode)));
  }
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
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(animation), child: child)),
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
  Widget build(BuildContext context) {
    final l = context.layout;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(l.gutter),
          child: LayoutBuilder(
            builder: (context, c) => AdaptiveFlex(
              column: l.isNarrow,
              mainAxisSize: MainAxisSize.min,
              spacing: l.sp(20),
              children: [
                BreathingCharacter(
                  asset: oupiImage,
                  height: characterHeight(c, heightFraction: 0.5, widthFraction: 0.3, max: 260),
                  label: 'Oupi',
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: l.sp(26), vertical: l.sp(20)),
                    decoration: BoxDecoration(color: OupiColors.cream, borderRadius: BorderRadius.circular(28)),
                    child: Text('Oups !\nDemande à papa ou maman.', style: display(l.sp(26), weight: 600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
