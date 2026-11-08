import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/app_scope.dart';
import '../../application/app_state.dart';
import '../navigation.dart';
import '../responsive.dart';
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
    final l = context.layout;

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
              final portrait = c.maxHeight > c.maxWidth;
              final big = l.bigButton(c, fraction: portrait ? 0.2 : 0.42, max: 190);
              final small = l.bigButton(c, fraction: portrait ? 0.16 : 0.34, max: 160);

              final episodes = BigRoundButton(
                icon: Icons.play_arrow_rounded,
                color: OupiColors.apricot,
                size: big,
                semanticLabel: 'Épisodes',
                onTap: () => Navigator.of(context).push(gentleRoute(const EpisodesScreen())),
              );
              final music = BigRoundButton(
                icon: Icons.music_note_rounded,
                color: OupiColors.eye,
                size: small,
                locked: !state.premium,
                semanticLabel: 'Musique',
                onTap: () => state.premium
                    ? Navigator.of(context).push(gentleRoute(const MusicScreen()))
                    : askAGrownUp(context, destination: const PaywallScreen()),
              );
              final gallery = BigRoundButton(
                icon: Icons.photo_library_rounded,
                color: OupiColors.leaf,
                size: small,
                semanticLabel: 'Galerie souvenirs',
                onTap: () => Navigator.of(context).push(gentleRoute(const GalleryScreen())),
              );

              final Widget scene;
              if (portrait) {
                // Écran plus haut que large (écran partagé, première image) : Oupi en haut, les boutons en bas.
                scene = Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    BreathingCharacter(
                      asset: oupiImage,
                      height: characterHeight(c, heightFraction: 0.5, widthFraction: 0.7),
                      label: 'Oupi te dit bonjour',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [music, episodes, gallery],
                    ),
                  ],
                );
              } else {
                scene = Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    episodes,
                    BreathingCharacter(
                      asset: oupiImage,
                      height: characterHeight(c, heightFraction: 0.82, widthFraction: 0.34),
                      label: 'Oupi te dit bonjour',
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [music, SizedBox(height: c.maxHeight * 0.06), gallery],
                    ),
                  ],
                );
              }

              return Stack(
                children: [
                  Positioned(top: 4, right: 8, child: ParentCornerButton(onTap: () => openParentArea(context))),
                  Positioned.fill(child: Padding(padding: EdgeInsets.all(l.gutter), child: scene)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
