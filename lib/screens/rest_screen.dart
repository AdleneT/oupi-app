import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/episode.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/premium.dart';
import '../widgets/scenery.dart';

/// Écran de repos après le rituel de fin (GDD §7) : le parc s'est endormi, Oupi (et Lala, dans ses
/// épisodes) dorment sur un nuage qui flotte. Aucune vignette d'un autre épisode, aucune lecture
/// automatique, un seul bouton discret aux couleurs de la nuit pour revenir à l'accueil.
class RestScreen extends StatelessWidget {
  const RestScreen({super.key, required this.episode});
  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final withLala = episode.title != null;
    final (asset, aspect, dream) = withLala ? duoCloud : oupiCloud;
    return Scaffold(
      backgroundColor: Vivid.nightTop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParkBackdrop(night: true),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
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
                        label: withLala ? 'Oupi et Lala dorment sur leur nuage' : 'Oupi dort sur son nuage',
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: c.maxHeight * 0.04,
                      child: Center(
                        child: SceneCaption(
                          state.limitReached ? 'Il fait dodo, reviens demain !' : 'Chut… Oupi fait dodo.',
                          night: true,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: BadgeButton(
                        asset: 'assets/images/badge_home_night.png',
                        size: 112,
                        glow: Vivid.nightLow,
                        semanticLabel: 'Retour à l’accueil',
                        onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
