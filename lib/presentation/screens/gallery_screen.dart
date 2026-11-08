import 'package:flutter/material.dart';

import '../responsive.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Galerie souvenirs (GDD §9, écran 7) : les photos des créations prises par le parent,
/// stockées uniquement sur l'appareil. L'ajout de photos arrive dans une prochaine étape.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.layout;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const KidHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final column = c.maxWidth < 640 || c.maxHeight > c.maxWidth;
                  final polaroid = (c.maxWidth / (column ? 4.2 : 8)).clamp(64.0, 130.0);
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(l.gutter),
                      child: AdaptiveFlex(
                        column: column,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: l.sp(28),
                        children: [
                          BreathingCharacter(
                            asset: oupiImage,
                            height: characterHeight(c, heightFraction: column ? 0.38 : 0.62, widthFraction: column ? 0.5 : 0.35),
                            label: 'Oupi',
                          ),
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
                                        width: polaroid,
                                        height: polaroid * 1.15,
                                        margin: EdgeInsets.symmetric(horizontal: polaroid * 0.06),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: OupiColors.line, width: 2),
                                        ),
                                        child: Icon(Icons.add_photo_alternate_outlined, color: OupiColors.line, size: polaroid * 0.42),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: l.sp(18)),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: (c.maxWidth - 2 * l.gutter).clamp(120, 360)),
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
