import 'package:flutter/material.dart';

import '../../application/app_scope.dart';
import '../../domain/entities/episode.dart';
import '../responsive.dart';
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
    final withLolo = episode.title != null;
    final l = context.layout;
    return Scaffold(
      body: NightSky(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              // Les deux personnages côte à côte doivent tenir dans la largeur : 0,72 × (0,56 + 0,44) de la hauteur.
              final oupi = characterHeight(c, heightFraction: 0.56, widthFraction: withLolo ? 0.4 : 0.6);
              final lolo = oupi * 0.78;
              return Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            BreathingCharacter(asset: oupiImage, height: oupi, asleep: true, label: 'Oupi dort'),
                            if (withLolo) ...[
                              SizedBox(width: l.sp(18)),
                              BreathingCharacter(asset: loloImage, height: lolo, asleep: true, label: 'Lolo dort'),
                            ],
                          ],
                        ),
                        SizedBox(height: l.sp(20)),
                        NightCaption(asleepUntilTomorrow ? 'Il fait dodo, reviens demain !' : 'Chut… Oupi fait dodo.'),
                      ],
                    ),
                  ),
                  Positioned(
                    left: l.gutter,
                    bottom: l.gutter,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
