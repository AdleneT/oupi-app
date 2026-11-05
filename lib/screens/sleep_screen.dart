import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/scenery.dart';
import 'parent_space_screen.dart';

/// « Il fait dodo » (GDD §9, écran 10) : limite du jour atteinte ou heure du dodo passée.
/// Le parc s'est endormi sous la lune ; Oupi dort sur un nuage qui flotte doucement.
/// Il remplace l'accueil tant qu'Oupi dort : aucun bouton ne ramène aux menus de l'enfant.
/// Seul le coin parent (contrôle parental) ouvre l'espace parents, directement sur les réglages,
/// d'où l'on peut réveiller Oupi.
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key, required this.reason});
  final SleepReason reason;

  @override
  Widget build(BuildContext context) {
    final message = switch (reason) {
      SleepReason.sleepTime => 'Il fait dodo. On se retrouve demain matin !',
      SleepReason.limitReached => 'Il fait dodo, reviens demain !',
    };
    final (asset, aspect, dream) = oupiCloud;
    return Scaffold(
      backgroundColor: Vivid.nightTop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParkBackdrop(night: true),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                // Le nuage, la place des « z » au-dessus et son ombre sur l’herbe tiennent dans 78 % de la hauteur.
                final width = math.min(c.maxWidth * 0.48, c.maxHeight * 0.78 / cloudBoxFactor * aspect);
                return Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0, 0.15),
                      child: CloudSleepers(
                        asset: asset,
                        aspect: aspect,
                        width: width,
                        dreamFrom: dream,
                        label: 'Oupi dort sur son nuage',
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: c.maxHeight * 0.04,
                      child: Center(child: SceneCaption(message, night: true)),
                    ),
                    Positioned(
                      top: 6,
                      left: 8,
                      child: ParentCornerButton(
                        onDark: true,
                        onTap: () => openParentArea(
                          context,
                          destination: const ParentSpaceScreen(initialIndex: ParentSpaceScreen.settingsIndex),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
