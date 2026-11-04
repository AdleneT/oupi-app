import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Galerie souvenirs (GDD §9, écran 7) : les photos des créations prises par le parent,
/// stockées uniquement sur l'appareil. L'ajout de photos arrive dans une prochaine étape.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BreathingCharacter(asset: oupiImage, height: c.maxHeight * 0.62, label: 'Oupi'),
                    const SizedBox(width: 32),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final angle in [-0.08, 0.05, -0.03])
                              Transform.rotate(
                                angle: angle,
                                child: Container(
                                  width: 96,
                                  height: 110,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: OupiColors.line, width: 2),
                                  ),
                                  child: const Icon(Icons.add_photo_alternate_outlined, color: OupiColors.line, size: 40),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 320,
                          child: Text(
                            'Les photos de vos créations apparaîtront ici. Elles restent sur cet appareil.',
                            textAlign: TextAlign.center,
                            style: body(15, color: OupiColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Positioned(left: 20, top: 14, child: KidBackButton()),
            ],
          ),
        ),
      ),
    );
  }
}
