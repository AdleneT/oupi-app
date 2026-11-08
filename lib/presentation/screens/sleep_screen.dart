import 'package:flutter/material.dart';

import '../../application/app_state.dart';
import '../navigation.dart';
import '../responsive.dart';
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
    final l = context.layout;
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
                      BreathingCharacter(
                        asset: oupiImage,
                        height: characterHeight(c, heightFraction: 0.6, widthFraction: 0.5),
                        asleep: true,
                        label: 'Oupi dort',
                      ),
                      SizedBox(height: l.sp(20)),
                      NightCaption(message),
                    ],
                  ),
                ),
                if (!isRoot) Positioned(left: l.gutter, top: l.gutter * 0.6, child: const KidBackButton(color: OupiColors.night)),
                Positioned(top: 4, right: 8, child: ParentCornerButton(onDark: true, onTap: () => openParentArea(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
