import 'package:flutter/material.dart';

import '../navigation.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// « Il fait dodo » (GDD §9, écran 10) : limite du jour atteinte ou heure du dodo passée.
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key, required this.reason, this.isRoot = false});
  final SleepReason reason;

  /// Vrai quand l'écran remplace l'accueil (le soir) : pas de bouton retour.
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    final message = switch (reason) {
      SleepReason.sleepTime => 'Il fait dodo. On se retrouve demain matin !',
      SleepReason.limitReached => 'Il fait dodo, reviens demain !',
    };
    return Scaffold(
      body: NightSky(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BreathingCharacter(asset: oupiImage, height: c.maxHeight * 0.6, asleep: true, label: 'Oupi dort'),
                      const SizedBox(height: 20),
                      NightCaption(message),
                    ],
                  ),
                ),
                if (!isRoot)
                  Positioned(
                    left: 20,
                    top: 14,
                    child: BigRoundButton(
                      icon: Icons.arrow_back_rounded,
                      color: OupiColors.night,
                      size: 64,
                      semanticLabel: 'Retour',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 8,
                  child: ParentCornerButton(onDark: true, onTap: () => openParentArea(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
