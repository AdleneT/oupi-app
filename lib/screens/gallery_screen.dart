import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_character.dart';
import '../widgets/premium.dart';
import '../widgets/scenery.dart';

/// Galerie souvenirs (GDD §9, écran 7) : les photos des créations prises par le parent,
/// stockées uniquement sur l'appareil. L'ajout de photos arrive dans une prochaine étape.
/// Dans le parc, Oupi garde les cadres photo, posés dans un panneau en verre.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vivid.skyMid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParkBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final h = c.maxHeight;
                final frame = (h * 0.3).clamp(90.0, 190.0);
                return Stack(
                  children: [
                    Positioned(
                      left: c.maxWidth * 0.13,
                      bottom: h * 0.02,
                      child: LiveCharacter(rig: oupiIdleRig, height: h * 0.74, label: 'Oupi'),
                    ),
                    Positioned(
                      right: c.maxWidth * 0.05,
                      top: h * 0.14,
                      child: PopIn(
                        delay: const Duration(milliseconds: 300),
                        child: GlassPanel(
                          padding: EdgeInsets.fromLTRB(frame * 0.18, frame * 0.2, frame * 0.18, frame * 0.16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final (angle, color) in [(-0.08, Vivid.berry), (0.05, Vivid.sunny), (-0.03, Vivid.teal)])
                                    Transform.rotate(
                                      angle: angle,
                                      child: Container(
                                        width: frame,
                                        height: frame * 1.18,
                                        margin: EdgeInsets.symmetric(horizontal: frame * 0.06),
                                        padding: EdgeInsets.fromLTRB(frame * 0.07, frame * 0.07, frame * 0.07, frame * 0.25),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(frame * 0.06),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Vivid.plum.withValues(alpha: 0.25),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(frame * 0.04),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.3)],
                                            ),
                                          ),
                                          child: Icon(Icons.add_photo_alternate_rounded, color: color, size: frame * 0.36),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: frame * 0.2),
                              Text('Tes créations viendront ici !', style: display(frame * 0.13, weight: 700, color: Vivid.plum)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(left: 16, top: 8, child: KidBackButton()),
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
