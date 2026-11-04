import 'package:flutter/material.dart';

import '../models/episode.dart';
import '../navigation.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Épisodes (GDD §9, écran 3) : grosses vignettes rangées par couleur de thème,
/// une petite pousse sur les épisodes vus, un cadenas doux sur les épisodes abonnés.
class EpisodesScreen extends StatelessWidget {
  const EpisodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final episodes = [...state.catalog.episodes]..sort((a, b) {
        final byFamily = OupiColors.familyOrder.indexOf(a.family).compareTo(OupiColors.familyOrder.indexOf(b.family));
        return byFamily != 0 ? byFamily : a.number.compareTo(b.number);
      });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final cardHeight = (c.maxHeight - 120).clamp(160.0, 300.0);
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Row(children: [KidBackButton()]),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      height: cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: episodes.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 18),
                        itemBuilder: (context, i) => _EpisodeCard(
                          episode: episodes[i],
                          height: cardHeight,
                          watched: state.isWatched(episodes[i]),
                          locked: state.isLocked(episodes[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({required this.episode, required this.height, required this.watched, required this.locked});
  final Episode episode;
  final double height;
  final bool watched;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = OupiColors.family(episode.family);
    final width = height * 0.82;
    return Semantics(
      button: true,
      label: 'Épisode ${episode.number}, ${episode.displayTitle}${locked ? ', verrouillé' : ''}${watched ? ', déjà vu' : ''}',
      child: Material(
        color: locked ? Color.lerp(color, OupiColors.cream, 0.45) : color,
        borderRadius: BorderRadius.circular(32),
        elevation: 4,
        shadowColor: OupiColors.ink.withValues(alpha: 0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => openEpisode(context, episode),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned(
                  left: 16,
                  top: 14,
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                    child: Text('${episode.number}', style: display(24, color: color)),
                  ),
                ),
                if (watched) const Positioned(right: 14, top: 14, child: SproutBadge(size: 46)),
                Center(child: FamilySymbol(family: episode.family, size: width * 0.8)),
                if (episode.title != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Face(asset: oupiImage, size: height * 0.2),
                        const SizedBox(width: 6),
                        _Face(asset: loloImage, size: height * 0.2),
                      ],
                    ),
                  ),
                if (locked) const Positioned(right: 14, bottom: 14, child: SoftLock(size: 46)),
              ],
            ),
          ),
        ),
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
