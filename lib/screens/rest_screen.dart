import 'package:flutter/material.dart';

import '../models/episode.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Écran de repos après le rituel de fin (GDD §7) : Oupi dort sous le ciel étoilé.
/// Aucune vignette d'un autre épisode, aucune lecture automatique, un bouton discret pour l'accueil.
class RestScreen extends StatelessWidget {
  const RestScreen({super.key, required this.episode});
  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final asleepUntilTomorrow = state.limitReached;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          BreathingCharacter(asset: oupiImage, height: c.maxHeight * 0.56, asleep: true, label: 'Oupi dort'),
                          if (episode.title != null) ...[
                            const SizedBox(width: 18),
                            BreathingCharacter(asset: loloImage, height: c.maxHeight * 0.44, asleep: true, label: 'Lolo dort'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      NightCaption(asleepUntilTomorrow ? 'Il fait dodo, reviens demain !' : 'Chut… Oupi fait dodo.'),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  child: Semantics(
                    button: true,
                    label: 'Retour à l’accueil',
                    child: IconButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        minimumSize: const Size(56, 56),
                      ),
                      icon: Icon(Icons.home_rounded, color: OupiColors.onNight.withValues(alpha: 0.6)),
                    ),
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
