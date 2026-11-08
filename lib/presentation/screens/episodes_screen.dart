import 'package:flutter/material.dart';

import '../../application/app_scope.dart';
import '../../domain/entities/episode.dart';
import '../navigation.dart';
import '../responsive.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Épisodes (GDD §9, écran 3) : grosses vignettes rangées par couleur de thème,
/// une petite pousse sur les épisodes vus, un cadenas doux sur les épisodes abonnés.
/// À l'horizontale, une rangée qui défile ; en portrait, une grille de deux colonnes.
class EpisodesScreen extends StatelessWidget {
  const EpisodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final episodes = state.catalog.byFamily;
    final l = context.layout;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KidHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  Widget card(Episode e) => _EpisodeCard(episode: e, watched: state.isWatched(e), locked: state.isLocked(e));
                  if (c.maxHeight > c.maxWidth) {
                    return GridView.builder(
                      padding: EdgeInsets.all(l.gutter),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: c.maxWidth < 900 ? 2 : 3,
                        childAspectRatio: 0.82,
                        mainAxisSpacing: l.sp(16),
                        crossAxisSpacing: l.sp(16),
                      ),
                      itemCount: episodes.length,
                      itemBuilder: (context, i) => card(episodes[i]),
                    );
                  }
                  final cardHeight = (c.maxHeight - 2 * l.gutter).clamp(140.0, 360.0);
                  return Center(
                    child: SizedBox(
                      height: cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: l.gutter),
                        itemCount: episodes.length,
                        separatorBuilder: (_, _) => SizedBox(width: l.sp(18)),
                        itemBuilder: (context, i) => AspectRatio(aspectRatio: 0.82, child: card(episodes[i])),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une vignette qui prend toute la place qu'on lui donne : tous ses éléments sont en proportion.
class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({required this.episode, required this.watched, required this.locked});
  final Episode episode;
  final bool watched;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = OupiColors.family(episode.family);
    return Semantics(
      button: true,
      label: 'Épisode ${episode.number}, ${episode.displayTitle}${locked ? ', verrouillé' : ''}${watched ? ', déjà vu' : ''}',
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight;
          final w = c.maxWidth;
          final radius = h * 0.12;
          final badge = (h * 0.18).clamp(32.0, 56.0);
          final inset = h * 0.055;
          return Material(
            color: locked ? Color.lerp(color, OupiColors.cream, 0.45) : color,
            borderRadius: BorderRadius.circular(radius),
            elevation: 4,
            shadowColor: OupiColors.ink.withValues(alpha: 0.3),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: () => openEpisode(context, episode),
              child: Stack(
                children: [
                  Positioned(
                    left: inset,
                    top: inset,
                    child: Container(
                      width: badge,
                      height: badge,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                      child: Text('${episode.number}', style: display(badge * 0.52, color: color), textScaler: TextScaler.noScaling),
                    ),
                  ),
                  if (watched) Positioned(right: inset, top: inset, child: SproutBadge(size: badge)),
                  Center(child: FamilySymbol(family: episode.family, size: w * 0.8)),
                  if (episode.title != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: inset,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Face(asset: oupiImage, size: h * 0.2),
                          SizedBox(width: h * 0.025),
                          _Face(asset: loloImage, size: h * 0.2),
                        ],
                      ),
                    ),
                  if (locked) Positioned(right: inset, bottom: inset, child: SoftLock(size: badge)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.asset, required this.size});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: OupiColors.cream,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover, alignment: const Alignment(0, -0.55)),
        ),
      );
}
