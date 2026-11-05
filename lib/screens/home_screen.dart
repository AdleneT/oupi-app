import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_character.dart';
import '../widgets/premium.dart';
import 'episodes_screen.dart';
import 'exercises_screen.dart';
import 'gallery_screen.dart';
import 'music_screen.dart';
import 'paywall_screen.dart';
import 'sleep_screen.dart';

/// Accueil vivant (GDD §9, écran 2) : toute la bande dans le parc en feutrine.
/// - Fond : la photo de la bande animée en boucle parfaite (10 s, Kling 4.0, 21:9) : Oupi fait coucou
///   et danse au centre, Lala se balance, Totu se dandine en haut du toboggan, Ibou salue de l'aile.
///   Un toucher fait jaillir des cœurs.
/// - Secours (vidéo illisible) : la scène animée dans l'appli, Oupi qui se promène.
/// - Boutons badges illustrés placés autour des personnages, d'après leur position dans la vidéo :
///   Épisodes (halo) et Exercices dans le ciel au-dessus de Lala, Galerie sur l'arbre, Musique en haut
///   à droite au-dessus de la tour du toboggan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _video = Size(2208, 936);

  static const _bg = 'assets/images/park_bg.jpg';
  static const _bgSize = Size(2800, 1188);
  static const _bgAlign = Alignment(0.25, 0.4);

  // Sol du premier plan dans l'image du parc (fractions), pour la scène de secours.
  static const _foreground = Offset(0.5, 0.93);

  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // L'accueil s'endort tout seul à l'heure du dodo, ou à la fin d'un réveil accordé par le parent.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    // Reconstruit l'accueil quand on y revient, pour qu'il s'endorme à temps.
    ModalRoute.of(context);
    final sleeping = state.sleepReason;
    if (sleeping != null) return SleepScreen(reason: sleeping);

    return Scaffold(
      backgroundColor: Vivid.skyMid,
      body: LayoutBuilder(
        builder: (context, c) {
          final screen = c.biggest;
          final scale = math.max(screen.width / _bgSize.width, screen.height / _bgSize.height);
          final bgW = _bgSize.width * scale, bgH = _bgSize.height * scale;
          final ox = (screen.width - bgW) * (_bgAlign.x + 1) / 2;
          final oy = (screen.height - bgH) * (_bgAlign.y + 1) / 2;
          Offset map(Offset f) => Offset(ox + f.dx * bgW, oy + f.dy * bgH);

          final padding = MediaQuery.paddingOf(context);
          final safeH = screen.height - padding.vertical;

          // La vidéo couvre l'écran (BoxFit.cover, centrée) : on retrouve où sont les personnages.
          final vScale = math.max(screen.width / _video.width, screen.height / _video.height);
          final vW = _video.width * vScale, vH = _video.height * vScale;
          final vx = (screen.width - vW) / 2, vy = (screen.height - vH) / 2;
          double vidX(double f) => vx + f * vW;
          double vidY(double f) => vy + f * vH;
          // Repères relevés sur la vidéo (fractions de l'image).
          final lalaTop = vidY(0.33); // pousse de Lala : au-dessus, c'est le ciel
          final oupiLeft = vidX(0.39); // oreille gauche d'Oupi
          final totuRight = vidX(0.77); // Totu en haut du toboggan
          final ibouTop = vidY(0.47); // haut de la tête d'Ibou

          // Boutons ≥ 2 cm (GDD) : 126 dp au minimum.
          final top = padding.top + 6;
          final left = padding.left + 76; // après le cadenas des parents
          var size = (lalaTop - top - 4).clamp(126.0, 150.0);
          size = math.max(126.0, math.min(size, (oupiLeft - 6 - left - 12) / 2));
          final musicLeft = math.max(totuRight + 8, screen.width - padding.right - 12 - size);
          final musicFits = top + size <= ibouTop;
          final margin = screen.width * 0.04 + padding.left;
          final oupiH = safeH * 0.58;
          final oupiHalf = oupiH * 0.38;
          final leftEdge = margin + oupiHalf;
          final rightEdge = screen.width - margin - oupiHalf;
          final groundY = math.min(map(_foreground).dy, screen.height - padding.bottom - 6);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Fond : la vidéo 4K générée qui tourne en boucle. Sinon, la scène animée dans l'appli.
              TapSparkles(
                child: LoopingVideoBackdrop(
                  assets: const ['assets/videos/home_bande.mp4'],
                  poster: 'assets/images/home_bande_poster.jpg',
                  fallback: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(_bg, fit: BoxFit.cover, alignment: _bgAlign, filterQuality: FilterQuality.medium),
                      const SunGlow(),
                      Positioned.fill(
                        child: OupiActor(
                          height: oupiH,
                          groundY: groundY,
                          minX: leftEdge,
                          maxX: math.max(leftEdge, rightEdge),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const FloatingParticles(count: 14),
              SafeArea(
                child: Stack(
                  children: [
                    // Les boutons se posent sur le ciel et l'arbre, jamais sur un personnage.
                    Positioned(
                      left: left - padding.left,
                      top: top - padding.top,
                      child: Row(
                        children: [
                          PopIn(
                            delay: const Duration(milliseconds: 650),
                            child: GlowHalo(
                              size: size,
                              color: Vivid.sunny,
                              child: BadgeButton(
                                asset: 'assets/images/badge_episodes.png',
                                size: size,
                                glow: Vivid.mango,
                                semanticLabel: 'Épisodes',
                                onTap: () => Navigator.of(context).push(kidRoute(const EpisodesScreen())),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopIn(
                            delay: const Duration(milliseconds: 800),
                            child: BadgeButton(
                              asset: 'assets/images/badge_exercises.png',
                              size: size,
                              glow: Vivid.teal,
                              phase: 0.35,
                              semanticLabel: 'Exercices',
                              onTap: () => Navigator.of(context).push(kidRoute(const ExercisesScreen())),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: math.max(top + size + 10, lalaTop + 8) - padding.top,
                      child: PopIn(
                        delay: const Duration(milliseconds: 950),
                        child: BadgeButton(
                          asset: 'assets/images/badge_gallery.png',
                          size: size,
                          glow: Vivid.ocean,
                          phase: 0.85,
                          semanticLabel: 'Galerie souvenirs',
                          onTap: () => Navigator.of(context).push(kidRoute(const GalleryScreen())),
                        ),
                      ),
                    ),
                    Positioned(
                      left: musicLeft - padding.left,
                      // Sur un écran où Ibou monterait trop haut, la Musique descend sous la tour.
                      top: (musicFits ? top : vidY(0.88)) - padding.top,
                      child: PopIn(
                        delay: const Duration(milliseconds: 1100),
                        from: const Offset(0, -0.4),
                        child: BadgeButton(
                          asset: 'assets/images/badge_music.png',
                          size: size,
                          glow: Vivid.grape,
                          phase: 0.6,
                          locked: !state.premium,
                          semanticLabel: 'Musique',
                          onTap: () => state.premium
                              ? Navigator.of(context).push(kidRoute(const MusicScreen()))
                              : askAGrownUp(context, destination: const PaywallScreen()),
                        ),
                      ),
                    ),
                    Positioned(top: 6, left: 8, child: ParentCornerButton(onTap: () => openParentArea(context))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
