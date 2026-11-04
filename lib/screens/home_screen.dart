import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'episodes_screen.dart';
import 'gallery_screen.dart';
import 'music_screen.dart';
import 'paywall_screen.dart';
import 'sleep_screen.dart';

/// Accueil (GDD §9, écran 2) : Oupi au centre, trois gros boutons sans texte,
/// une petite icône discrète pour les parents.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // Si l'appli reste ouverte au passage de l'heure du dodo, l'accueil s'endort tout seul.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.isSleepTime()) return const SleepScreen(reason: SleepReason.sleepTime, isRoot: true);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OupiColors.sky, Color(0xFFEFF5E4), OupiColors.meadow],
            stops: [0, 0.62, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final h = c.maxHeight;
              final big = (h * 0.42).clamp(126.0, 170.0);
              final small = (h * 0.34).clamp(126.0, 150.0);
              return Stack(
                children: [
                  Positioned(
                    top: 4,
                    right: 8,
                    child: ParentCornerButton(onTap: () => openParentArea(context)),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        BigRoundButton(
                          icon: Icons.play_arrow_rounded,
                          color: OupiColors.apricot,
                          size: big,
                          semanticLabel: 'Épisodes',
                          onTap: () => Navigator.of(context).push(gentleRoute(const EpisodesScreen())),
                        ),
                        BreathingCharacter(asset: oupiImage, height: h * 0.82, label: 'Oupi te dit bonjour'),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BigRoundButton(
                              icon: Icons.music_note_rounded,
                              color: OupiColors.eye,
                              size: small,
                              locked: !state.premium,
                              semanticLabel: 'Musique',
                              onTap: () => state.premium
                                  ? Navigator.of(context).push(gentleRoute(const MusicScreen()))
                                  : askAGrownUp(context, destination: const PaywallScreen()),
                            ),
                            SizedBox(height: h * 0.06),
                            BigRoundButton(
                              icon: Icons.photo_library_rounded,
                              color: OupiColors.leaf,
                              size: small,
                              semanticLabel: 'Galerie souvenirs',
                              onTap: () => Navigator.of(context).push(gentleRoute(const GalleryScreen())),
                            ),
                          ],
                        ),
                      ],
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
