import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

import '../models/episode.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/candy.dart';
import '../widgets/common.dart';
import '../widgets/premium.dart';
import '../widgets/scenery.dart';
import '../widgets/song_art.dart';

/// Juke-box (GDD §9, écran 6) : toutes les chansons, à tout moment, pour les abonnés.
/// Dans le parc, une vignette par chanson : carte blanche, image dont le personnage sort du cadre,
/// titre, durée et badge lecture. On la touche pour écouter, on la retouche pour mettre en pause.
/// Une seule chanson à la fois, et jamais d'enchaînement automatique. Les chansons pas encore
/// enregistrées gardent la vignette, adoucie, à la couleur de leur thème, avec « Bientôt ».
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  VideoPlayerController? _player;
  String? _current;
  bool _playing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Un écran passe devant (Oupi s'endort, contrôle parental) : la musique s'arrête.
    if (!TickerMode.valuesOf(context).enabled && _player?.value.isPlaying == true) _player!.pause();
  }

  Future<void> _toggle(Episode e) async {
    final audio = e.songAudio;
    if (audio == null) return;
    final current = _player;
    if (_current == e.id && current != null && current.value.isInitialized) {
      if (current.value.isPlaying) {
        await current.pause();
      } else {
        if (current.value.position >= current.value.duration) await current.seekTo(Duration.zero);
        await current.play();
      }
      return;
    }
    await _stop();
    final player = VideoPlayerController.asset(audio);
    setState(() {
      _player = player;
      _current = e.id;
    });
    try {
      await player.initialize();
    } on Exception {
      if (_player == player) setState(() => _player = _current = null);
      await player.dispose();
      return;
    }
    if (!mounted || _player != player) {
      await player.dispose();
      return;
    }
    player.addListener(_onPlayer);
    // Le réglage « Son » de l'espace parents coupe aussi les chansons.
    await player.setVolume(AppScope.read(context).sound ? 1 : 0);
    await player.play();
  }

  void _onPlayer() {
    final playing = _player?.value.isPlaying ?? false;
    if (playing != _playing && mounted) setState(() => _playing = playing);
  }

  Future<void> _stop() async {
    final player = _player;
    _player = null;
    _current = null;
    _playing = false;
    if (player != null) {
      player.removeListener(_onPlayer);
      await player.pause();
      await player.dispose();
    }
  }

  @override
  void dispose() {
    final player = _player;
    _player = null;
    player?.removeListener(_onPlayer);
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = AppScope.of(context).catalog.episodes;
    const back = 112.0;
    return Scaffold(
      backgroundColor: Vivid.skyMid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParkBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                // Toutes les vignettes ont la même hauteur, débordement du personnage compris ; les cartes
                // s'alignent par le bas.
                final itemH = c.maxHeight * 0.94;
                final cardW = itemH / (SongVignette.popFor(vignetteArts['ep01']) + 1.033);
                return Stack(
                  children: [
                    ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(
                        16 + back + 20,
                        (c.maxHeight - itemH) / 2,
                        48,
                        (c.maxHeight - itemH) / 2,
                      ),
                      itemCount: songs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 28),
                      itemBuilder: (context, i) {
                        final e = songs[i];
                        final title = e.song ?? e.theme;
                        final art = e.songAudio != null ? vignetteArts[e.id] : null;
                        final ready = art != null;
                        final playingThis = _current == e.id && _playing;
                        final loadingThis = _current == e.id && !(_player?.value.isInitialized ?? false);
                        final color = OupiColors.family(e.family);
                        return PopIn(
                          delay: Duration(milliseconds: 120 + 70 * i.clamp(0, 6)),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Springy(
                              phase: i * 0.19,
                              semanticLabel: ready
                                  ? (playingThis ? 'Pause, $title' : 'Écouter $title')
                                  : 'Chanson $title, bientôt',
                              onTap: ready ? () => _toggle(e) : null,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  SongVignette(
                                    width: cardW,
                                    title: title,
                                    color: color,
                                    art: art,
                                    seconds: e.songSeconds,
                                    family: e.family,
                                    playing: playingThis,
                                    loading: loadingThis,
                                  ),
                                  if (playingThis)
                                    Positioned.fill(
                                      child: IgnorePointer(child: _RisingNotes(color: color)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const Positioned(left: 16, top: 8, child: KidBackButton(size: back)),
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

/// Trois notes qui montent lentement au-dessus de la carte pendant l'écoute (sans clignoter).
class _RisingNotes extends StatefulWidget {
  const _RisingNotes({required this.color});
  final Color color;

  @override
  State<_RisingNotes> createState() => _RisingNotesState();
}

class _RisingNotesState extends State<_RisingNotes> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6);
  final _t = ValueNotifier<double>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final w = c.maxWidth, h = c.maxHeight;
        const period = 3.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var k = 0; k < 3; k++)
              () {
                final p = ((_t.value + k * period / 3) % period) / period;
                final x = w * (0.2 + 0.3 * k) + math.sin(p * math.pi * 2 + k) * w * 0.04;
                final y = h * 0.34 - p * h * 0.3;
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: math.sin(p * math.pi).clamp(0.0, 1.0),
                    child: Icon(
                      k.isEven ? Icons.music_note_rounded : Icons.audiotrack_rounded,
                      size: w * (0.13 + 0.03 * k),
                      color: Colors.white,
                      shadows: [Shadow(color: widget.color.withValues(alpha: 0.8), blurRadius: 10)],
                    ),
                  ),
                );
              }(),
          ],
        );
      },
    ),
  );
}
