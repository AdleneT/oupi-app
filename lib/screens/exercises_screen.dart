import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_character.dart';
import '../widgets/premium.dart';
import '../widgets/scenery.dart';

/// Exercices : la section arrive plus tard. En attendant, Oupi garde la place au chaud dans le parc.
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

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
                return Stack(
                  children: [
                    Positioned(
                      left: c.maxWidth * 0.14,
                      bottom: h * 0.02,
                      child: LiveCharacter(rig: oupiIdleRig, height: h * 0.74, label: 'Oupi'),
                    ),
                    Positioned(
                      right: c.maxWidth * 0.07,
                      top: h * 0.2,
                      child: PopIn(
                        delay: const Duration(milliseconds: 300),
                        child: GlassPanel(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/images/badge_exercises.png', width: h * 0.3, height: h * 0.3),
                              const SizedBox(height: 14),
                              Text('Bientôt, des jeux avec Oupi !', style: display(h * 0.07, weight: 700, color: Vivid.plum)),
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
