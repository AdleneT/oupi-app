import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/episode.dart';
import '../models/interactions.dart';
import '../navigation.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/premium.dart';
import '../widgets/scenery.dart';
import 'rest_screen.dart';

/// Lecteur d'épisode (GDD §9, écran 4) : plein écran, un seul bouton pause discret,
/// pas de barre de progression manipulable. Gère les pauses tactiles du fichier d'interactions.
///
/// Tant qu'un épisode n'a pas de vidéo, le lecteur affiche une maquette minutée
/// qui suit la structure du GDD (générique, mise en situation, aventure, chanson, rituel).
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.episode});
  final Episode episode;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

/// Place de la chanson dans la maquette (secondes), selon la structure du GDD.
const _songStart = 225.0;
const _songEnd = 280.0;

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  VideoPlayerController? _video;

  /// Chanson de l'épisode, jouée pendant la séquence « Chanson » de la maquette.
  VideoPlayerController? _song;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  EpisodeInteractions _interactions = EpisodeInteractions.none;
  final Set<String> _handledPauses = {};
  TouchPause? _activePause;
  String? _wrongZone;
  Timer? _pauseTimeout;

  double _position = 0;
  bool _playing = true;
  bool _userPaused = false;
  bool _finished = false;
  bool _loading = true;

  double get _speed => AppScope.read(context).fastPlayback ? 10 : 1;
  double get _duration {
    final d = _video?.value.duration;
    if (d != null && d > Duration.zero) return d.inMilliseconds / 1000;
    return widget.episode.durationSeconds.toDouble();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _start();
  }

  Future<void> _start() async {
    try {
      _interactions = await EpisodeInteractions.load(rootBundle, widget.episode.interactionsAsset);
    } on Exception {
      _interactions = EpisodeInteractions.none;
    }
    final source = widget.episode.video;
    if (source != null) {
      final controller = source.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(source))
          : VideoPlayerController.asset(source);
      _video = controller;
      await controller.initialize();
      controller.addListener(_onVideoTick);
      await controller.play();
    } else {
      final audio = widget.episode.songAudio;
      if (audio != null) {
        final song = VideoPlayerController.asset(audio);
        try {
          await song.initialize();
          if (!mounted) {
            await song.dispose();
            return;
          }
          await song.setVolume(AppScope.read(context).sound ? 1 : 0);
          _song = song;
        } on Exception {
          await song.dispose();
        }
      }
      _ticker = createTicker(_onTick)..start();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_playing || _finished) return;
    setState(() => _position = (_position + dt * _speed).clamp(0, _duration));
    _syncSong();
    _checkPauses();
    if (_position >= _duration) _finish();
  }

  void _onVideoTick() {
    final v = _video!.value;
    _position = v.position.inMilliseconds / 1000;
    _checkPauses();
    if (v.isInitialized && !v.isPlaying && v.position >= v.duration && v.duration > Duration.zero) _finish();
  }

  void _checkPauses() {
    if (_activePause != null) return;
    for (final pause in _interactions.touchPauses) {
      if (!_handledPauses.contains(pause.id) && _position >= pause.atSeconds) {
        _handledPauses.add(pause.id);
        _enterTouchPause(pause);
        break;
      }
    }
  }

  void _enterTouchPause(TouchPause pause) {
    _setPlaying(false);
    setState(() => _activePause = pause);
    // Sans réponse, la vidéo reprend seule (GDD §5 : 8 secondes).
    _pauseTimeout = Timer(Duration(milliseconds: (pause.timeoutSeconds * 1000).round()), _leaveTouchPause);
  }

  void _onZoneTap(TouchZone zone) {
    if (zone.correct) {
      _leaveTouchPause();
    } else {
      setState(() => _wrongZone = zone.id);
      Timer(const Duration(milliseconds: 600), () {
        if (mounted && _wrongZone == zone.id) setState(() => _wrongZone = null);
      });
    }
  }

  void _leaveTouchPause() {
    _pauseTimeout?.cancel();
    if (!mounted || _activePause == null) return;
    setState(() {
      _activePause = null;
      _wrongZone = null;
    });
    if (!_userPaused) _setPlaying(true);
  }

  void _setPlaying(bool value) {
    _playing = value;
    final v = _video;
    if (v != null) value ? v.play() : v.pause();
    _syncSong();
  }

  /// La chanson suit la maquette : elle démarre au bon endroit quand on entre dans la séquence,
  /// s'arrête en pause et à la fin de la séquence. En lecture accélérée (test), elle reste muette.
  void _syncSong() {
    final song = _song;
    if (song == null) return;
    final inSong = _playing && !_finished && _speed == 1 && _position >= _songStart && _position < _songEnd;
    final offset = Duration(milliseconds: ((_position - _songStart) * 1000).round());
    if (inSong && !song.value.isPlaying && offset < song.value.duration - const Duration(milliseconds: 300)) {
      song.seekTo(offset).then((_) {
        if (mounted && _playing) song.play();
      });
    } else if (!inSong && song.value.isPlaying) {
      song.pause();
    }
  }

  void _togglePause() {
    setState(() => _userPaused = !_userPaused);
    if (_activePause == null) _setPlaying(!_userPaused);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _ticker?.stop();
    final state = AppScope.read(context);
    final navigator = Navigator.of(context);
    await state.markWatched(widget.episode);
    if (!mounted) return;
    navigator.pushReplacement(gentleRoute(RestScreen(episode: widget.episode)));
  }

  void _goHome() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  void dispose() {
    _pauseTimeout?.cancel();
    _ticker?.dispose();
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _song?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = OupiColors.family(widget.episode.family);
    return PopScope(
      canPop: false,
      // Le geste retour met en pause au lieu de quitter : on sort par le bouton maison.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_userPaused) _togglePause();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: LayoutBuilder(
                  builder: (context, c) => Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_video != null && _video!.value.isInitialized)
                        VideoPlayer(_video!)
                      else
                        _MockScene(episode: widget.episode, position: _position, color: color),
                      if (_activePause != null)
                        _TouchLayer(
                          pause: _activePause!,
                          size: c.biggest,
                          wrongZone: _wrongZone,
                          showSymbols: _video == null,
                          onTap: _onZoneTap,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_loading) const Center(child: CircularProgressIndicator(color: OupiColors.apricot)),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                // Un seul bouton pause, discret (GDD §9) : le badge pause, à demi transparent.
                child: Opacity(
                  opacity: 0.72,
                  child: BadgeButton(
                    asset: 'assets/images/badge_pause.png',
                    size: 92,
                    glow: Vivid.grape,
                    phase: 0.6,
                    semanticLabel: _userPaused ? 'Reprendre' : 'Pause',
                    onTap: _togglePause,
                  ),
                ),
              ),
            ),
            if (_userPaused)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Stack(
                  children: [
                    Center(
                      child: GlowHalo(
                        size: 160,
                        color: Vivid.sunny,
                        child: BadgeButton(
                          asset: 'assets/images/badge_play.png',
                          size: 160,
                          glow: Vivid.mango,
                          semanticLabel: 'Reprendre l’épisode',
                          onTap: _togglePause,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: SafeArea(
                        child: BadgeButton(
                          asset: 'assets/images/badge_home.png',
                          size: 112,
                          glow: Vivid.coral,
                          phase: 0.4,
                          semanticLabel: 'Retour à l’accueil',
                          onTap: _goHome,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Maquette d'épisode : la séquence en cours selon la structure du GDD (§5 et script de l'épisode 4).
class _MockScene extends StatelessWidget {
  const _MockScene({required this.episode, required this.position, required this.color});
  final Episode episode;
  final double position;
  final Color color;

  static const _segments = <(double, String)>[
    (15, 'Générique'),
    (45, 'Mise en situation'),
    (_songStart, 'Aventure'),
    (_songEnd, 'Chanson'),
    (300, 'Rituel de fin'),
  ];

  @override
  Widget build(BuildContext context) {
    final segment = _segments.firstWhere((s) => position < s.$1, orElse: () => _segments.last).$2;
    final ritual = segment == 'Rituel de fin';
    final cover = segment == 'Chanson' ? episode.songCover : null;
    final withLala = episode.title != null;
    final minutes = position ~/ 60;
    final seconds = (position % 60).floor().toString().padLeft(2, '0');
    final (cloud, cloudAspect, dream) = withLala ? duoCloud : oupiCloud;
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        // Le jour dans le parc ; pour le rituel de fin, le parc s'endort et Oupi rejoint son nuage.
        return Stack(
          fit: StackFit.expand,
          children: [
            ParkBackdrop(night: ritual),
            if (cover != null)
              Center(
                child: Semantics(
                  image: true,
                  label: episode.song,
                  child: Container(
                    width: h * 0.7,
                    height: h * 0.7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(h * 0.08),
                      border: Border.all(color: Colors.white, width: h * 0.014),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 10)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(cover, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                  ),
                ),
              )
            else if (ritual)
              Align(
                alignment: const Alignment(0, 0.9),
                child: CloudSleepers(
                  asset: cloud,
                  aspect: cloudAspect,
                  width: h * 0.55 / cloudBoxFactor * cloudAspect,
                  dreamFrom: dream,
                  label: withLala ? 'Oupi et Lala s’endorment' : 'Oupi s’endort',
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                bottom: h * 0.06,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    BreathingCharacter(asset: withLala ? oupiSideRight : oupiImage, height: h * 0.66),
                    if (withLala) ...[
                      SizedBox(width: h * 0.08),
                      BreathingCharacter(asset: lalaSideLeft, height: h * 0.54),
                    ],
                  ],
                ),
              ),
            Positioned(
              left: 20,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Maquette · $segment · $minutes:$seconds', style: body(14, weight: 800, color: Vivid.plum)),
              ),
            ),
            if (ritual)
              Positioned(
                left: 40,
                right: 40,
                top: h * 0.14,
                child: Text(
                  '« Merci pour l’aventure ! Mes yeux sont fatigués… et les tiens aussi. On éteint l’écran, et on va jouer pour de vrai ! '
                  'Demande à un grand de t’aider : ${episode.activity.title.toLowerCase()}. À bientôt, mon ami ! »',
                  textAlign: TextAlign.center,
                  style: display(h * 0.045, weight: 500, color: Colors.white, height: 1.3),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Zones à toucher pendant une pause tactile. Un mauvais choix fait juste gigoter l'objet.
class _TouchLayer extends StatelessWidget {
  const _TouchLayer({
    required this.pause,
    required this.size,
    required this.wrongZone,
    required this.showSymbols,
    required this.onTap,
  });
  final TouchPause pause;
  final Size size;
  final String? wrongZone;
  final bool showSymbols;
  final ValueChanged<TouchZone> onTap;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final zone in pause.zones)
        Positioned(
          left: zone.x * size.width,
          top: zone.y * size.height,
          width: zone.w * size.width,
          height: zone.h * size.height,
          child: _Wiggle(
            active: wrongZone == zone.id,
            child: Semantics(
              button: true,
              label: zone.id,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(zone),
                child: showSymbols
                    ? Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Vivid.sunny, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: Vivid.plum.withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(zone.symbol ?? '?', style: TextStyle(fontSize: zone.h * size.height * 0.5)),
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ),
        ),
    ],
  );
}

class _Wiggle extends StatelessWidget {
  const _Wiggle({required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(active),
    tween: Tween(begin: 0, end: active ? 1 : 0),
    duration: const Duration(milliseconds: 600),
    builder: (context, t, child) {
      final angle = active ? 0.06 * (1 - t) * math.sin(t * 6 * math.pi) : 0.0;
      return Transform.rotate(angle: angle, child: child);
    },
    child: child,
  );
}
