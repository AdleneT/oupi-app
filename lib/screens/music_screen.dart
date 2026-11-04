import 'package:flutter/material.dart';

import '../state/app_scope.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(children: [KidBackButton()]),
            ),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: songs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final e = songs[i];
                  final color = OupiColors.family(e.family);
                  final ready = e.song != null;
                  return Container(
                    width: 190,
                    decoration: BoxDecoration(
                      color: Color.lerp(color, OupiColors.cream, ready ? 0.15 : 0.55),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Expanded(child: Center(child: FamilySymbol(family: e.family, size: 150))),
                        Text(e.song ?? e.theme, textAlign: TextAlign.center, style: display(18, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(ready ? 'Chanson écrite, à enregistrer' : 'Bientôt',
                            style: body(13, weight: 700, color: Colors.white.withValues(alpha: 0.85))),
                      ],
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
