// Rend la vignette d'une chanson dans un PNG transparent (outil, lancé à la main) :
//   flutter test test/render_song_art_test.dart --dart-define=OUT=<chemin.png>
// Sans OUT, le test ne fait rien, pour ne pas ralentir la suite habituelle.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oupi/theme.dart';
import 'package:oupi/widgets/song_art.dart';

const _out = String.fromEnvironment('OUT');

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

void main() {
  testWidgets('vignette de chanson en PNG', (tester) async {
    if (_out.isEmpty) return;
    final art = vignetteArts['ep01']!;
    const cardW = 600.0;
    final height = SongVignette.heightFor(art, cardW);
    // Place sur les côtés pour les ballons qui dépassent.
    final width = cardW * 1.2;
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await _loadFont('Fredoka', 'assets/fonts/Fredoka.ttf');
      await _loadFont('Nunito', 'assets/fonts/Nunito.ttf');
    });
    final key = GlobalKey();
    await tester.pumpWidget(
      MediaQuery(
        // Image au repos : pas d'animation.
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: width,
                height: height,
                child: Align(
                  alignment: const Alignment(-0.6, 0),
                  child: SongVignette(
                    width: cardW,
                    title: 'Les couleurs',
                    color: OupiColors.family('couleurs'),
                    art: art,
                    seconds: 46,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final a in [art.plate, art.character, 'assets/images/badge_play.png']) {
        await precacheImage(AssetImage(a), tester.element(find.byKey(key)));
      }
    });
    await tester.pump();
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(_out).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
