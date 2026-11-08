import 'package:flutter/material.dart';

import '../../application/app_scope.dart';
import '../../domain/entities/episode.dart';
import '../responsive.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Juke-box (GDD §9, écran 6) : toutes les chansons, à tout moment, pour les abonnés.
/// Les chansons ne sont pas encore produites : les cartes sont en attente.
class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final songs = state.catalog.episodes;
    final l = context.layout;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KidHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final portrait = c.maxHeight > c.maxWidth;
                  if (portrait) {
                    return GridView.builder(
                      padding: EdgeInsets.all(l.gutter),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: c.maxWidth < 900 ? 2 : 3,
                        childAspectRatio: 0.75,
                        mainAxisSpacing: l.sp(16),
                        crossAxisSpacing: l.sp(16),
                      ),
                      itemCount: songs.length,
                      itemBuilder: (context, i) => _SongCard(episode: songs[i]),
                    );
                  }
                  final cardHeight = (c.maxHeight - 2 * l.gutter).clamp(140.0, 360.0);
                  return Center(
                    child: SizedBox(
                      height: cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: l.gutter),
                        itemCount: songs.length,
                        separatorBuilder: (_, _) => SizedBox(width: l.sp(16)),
                        itemBuilder: (context, i) => AspectRatio(aspectRatio: 0.75, child: _SongCard(episode: songs[i])),
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

class _SongCard extends StatelessWidget {
  const _SongCard({required this.episode});
  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final color = OupiColors.family(episode.family);
    final ready = episode.song != null;
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        return Container(
          decoration: BoxDecoration(
            color: Color.lerp(color, OupiColors.cream, ready ? 0.15 : 0.55),
            borderRadius: BorderRadius.circular(h * 0.11),
          ),
          padding: EdgeInsets.all(h * 0.06),
          child: Column(
            children: [
              Expanded(child: Center(child: FamilySymbol(family: episode.family, size: c.maxWidth * 0.78))),
              Text(
                episode.song ?? episode.theme,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: display((h * 0.075).clamp(14, 24), color: Colors.white),
              ),
              SizedBox(height: h * 0.015),
              Text(
                ready ? 'Chanson écrite, à enregistrer' : 'Bientôt',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body((h * 0.055).clamp(11, 15), weight: 700, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        );
      },
    );
  }
}
