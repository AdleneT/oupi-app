import 'package:flutter/material.dart';

import '../models/episode.dart';
import '../navigation.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/candy.dart';
import '../widgets/common.dart';
import '../widgets/premium.dart';
import '../widgets/scenery.dart';

/// Épisodes (GDD §9, écran 3) : dans le parc de l'accueil, de grosses cartes bonbons rangées par
/// couleur de thème. Les personnages sortent du cadre, une petite pousse marque les épisodes vus,
/// un cadenas doux les épisodes abonnés. Les cartes arrivent en rebond, flottent et rebondissent
/// sous le doigt, comme les badges.
class EpisodesScreen extends StatelessWidget {
  const EpisodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final episodes = [...state.catalog.episodes]
      ..sort((a, b) {
        final byFamily = OupiColors.familyOrder.indexOf(a.family).compareTo(OupiColors.familyOrder.indexOf(b.family));
        return byFamily != 0 ? byFamily : a.number.compareTo(b.number);
      });
    const back = 112.0;

    return Scaffold(
      backgroundColor: Vivid.skyMid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParkBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                // La carte et la tête du personnage qui dépasse doivent tenir dans la hauteur.
                final cardH = (c.maxHeight / 1.6).clamp(150.0, 300.0);
                final pop = cardH * 0.34;
                return Stack(
                  children: [
                    ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(
                        16 + back + 20,
                        (c.maxHeight - cardH - pop) / 2,
                        32,
                        (c.maxHeight - cardH - pop) / 2,
                      ),
                      itemCount: episodes.length,
                      separatorBuilder: (_, _) => SizedBox(width: cardH * 0.12),
                      itemBuilder: (context, i) => PopIn(
                        delay: Duration(milliseconds: 120 + 70 * i.clamp(0, 6)),
                        child: _EpisodeCard(
                          episode: episodes[i],
                          cardHeight: cardH,
                          pop: pop,
                          phase: i * 0.17,
                          watched: state.isWatched(episodes[i]),
                          locked: state.isLocked(episodes[i]),
                        ),
                      ),
                    ),
                    const Positioned(left: 16, top: 8, child: KidBackButton(size: back)),
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

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.episode,
    required this.cardHeight,
    required this.pop,
    required this.phase,
    required this.watched,
    required this.locked,
  });
  final Episode episode;
  final double cardHeight;
  final double pop;
  final double phase;
  final bool watched;
  final bool locked;

  /// Qui sort de la carte : Lala dans ses épisodes, Oupi ailleurs, les deux face à face dans l'épisode 4.
  List<(String, Alignment)> get _cast {
    final n = episode.number;
    if (n == 4) return const [(oupiSideRight, Alignment.bottomLeft), (lalaSideLeft, Alignment.bottomRight)];
    if (n == 2 || n == 8) return const [(lalaSideLeft, Alignment.bottomRight)];
    return const [(oupiSideLeft, Alignment.bottomRight)];
  }

  @override
  Widget build(BuildContext context) {
    final e = episode;
    final h = cardHeight;
    final w = h * 0.92;
    final color = OupiColors.family(e.family);
    final pair = _cast.length == 2;

    return Springy(
      phase: phase,
      semanticLabel: 'Épisode ${e.number}, ${e.displayTitle}${locked ? ', verrouillé' : ''}${watched ? ', déjà vu' : ''}',
      onTap: () => openEpisode(context, e),
      child: SizedBox(
        width: w,
        height: h + pop,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: h,
              // Carte verrouillée : seule la carte pâlit, le personnage garde ses couleurs.
              child: CandyFace(
                color: color,
                width: w,
                height: h,
                muted: locked,
                child: Stack(
                  children: [
                    Positioned(
                      left: h * 0.05,
                      top: h * 0.05,
                      child: Container(
                        width: h * 0.19,
                        height: h * 0.19,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Vivid.plum.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Text('${e.number}', style: display(h * 0.11, weight: 700, color: color)),
                      ),
                    ),
                    Positioned(
                      left: pair ? 0 : h * 0.05,
                      right: pair ? 0 : null,
                      bottom: h * 0.07,
                      child: Center(
                        child: FamilySymbol(family: e.family, size: h * (pair ? 0.42 : 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Les personnages sortent par le haut de la carte.
            for (final (asset, align) in _cast)
              Positioned(
                bottom: h * (pair ? 0.42 : 0.3),
                left: align == Alignment.bottomLeft ? w * 0.02 : null,
                right: align == Alignment.bottomRight ? -w * 0.04 : null,
                child: BreathingCharacter(asset: asset, height: h * (pair ? 0.66 : 0.92), breathing: false, shadow: false),
              ),
            if (watched)
              Positioned(
                right: -h * 0.03,
                top: pop - h * 0.02,
                child: SproutBadge(size: h * 0.19),
              ),
            if (locked)
              Positioned(
                right: h * 0.05,
                bottom: h * 0.09,
                child: SoftLock(size: h * 0.19),
              ),
          ],
        ),
      ),
    );
  }
}
