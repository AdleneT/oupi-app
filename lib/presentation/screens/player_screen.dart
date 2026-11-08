import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../application/app_scope.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/interactions.dart';
import '../navigation.dart';
import '../responsive.dart';
import '../theme.dart';
import '../widgets/common.dart';
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

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  VideoPlayerController? _video;
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
    _interactions = await AppScope.read(context).interactionsFor(widget.episode);
    if (!mounted) return;
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
      _ticker = createTicker(_onTick)..start();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_playing || _finished) return;
    setState(() => _position = (_position + dt * _speed).clamp(0, _duration));
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
    final pause = _interactions.dueAt(_position, _handledPauses);
    if (pause == null) return;
    _handledPauses.add(pause.id);
    _enterTouchPause(pause);
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
    await state.finishEpisode(widget.episode);
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = OupiColors.family(widget.episode.family);
    final l = context.layout;
    return PopScope(
      canPop: false,
      // Le geste retour met en pause au lieu de quitter : on sort par le bouton maison.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_userPaused) _togglePause();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, c) => Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: LayoutBuilder(
                    builder: (context, video) => Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_video != null && _video!.value.isInitialized)
                          VideoPlayer(_video!)
                        else
                          _MockScene(episode: widget.episode, position: _position, color: color),
                        if (_activePause != null)
                          _TouchLayer(
                            pause: _activePause!,
                            size: video.biggest,
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
                  child: Semantics(
                    button: true,
                    label: _userPaused ? 'Reprendre' : 'Pause',
                    child: IconButton(
                      onPressed: _togglePause,
                      iconSize: 30,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.25),
                        minimumSize: const Size(52, 52),
                      ),
                      icon: Icon(_userPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: Colors.white.withValues(alpha: 0.7)),
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
                        child: BigRoundButton(
                          icon: Icons.play_arrow_rounded,
                          color: OupiColors.apricot,
                          size: l.bigButton(c, fraction: 0.38, max: 200),
                          semanticLabel: 'Reprendre l’épisode',
                          onTap: _togglePause,
                        ),
                      ),
                      Positioned(
                        left: l.gutter,
                        bottom: l.gutter,
                        child: SafeArea(
                          child: BigRoundButton(
                            icon: Icons.home_rounded,
                            color: OupiColors.leaf,
                            size: l.sp(72).clamp(64, 96),
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
    (225, 'Aventure'),
    (280, 'Chanson'),
    (300, 'Rituel de fin'),
  ];

  @override
  Widget build(BuildContext context) {
    final segment = _segments.firstWhere((s) => position < s.$1, orElse: () => _segments.last).$2;
    final ritual = segment == 'Rituel de fin';
    final withLolo = episode.title != null;
    final minutes = position ~/ 60;
    final seconds = (position % 60).floor().toString().padLeft(2, '0');
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final scene = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BreathingCharacter(asset: oupiImage, height: h * 0.62, asleep: ritual),
            if (withLolo) ...[SizedBox(width: h * 0.06), BreathingCharacter(asset: loloImage, height: h * 0.5, asleep: ritual)],
          ],
        );
        final content = Stack(
          children: [
            Positioned(left: 0, right: 0, bottom: h * 0.08, child: scene),
            Positioned(
              left: h * 0.05,
              top: h * 0.04,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: h * 0.035, vertical: h * 0.02),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(99)),
                child: Text('Maquette · $segment · $minutes:$seconds',
                    style: body((h * 0.035).clamp(11, 16), weight: 800), textScaler: TextScaler.noScaling),
              ),
            ),
            if (ritual)
              Positioned(
                left: h * 0.1,
                right: h * 0.1,
                top: h * 0.14,
                child: Text(
                  '« Merci pour l’aventure ! Mes yeux sont fatigués… et les tiens aussi. On éteint l’écran, et on va jouer pour de vrai ! '
                  'Demande à un grand de t’aider : ${episode.activity.title.toLowerCase()}. À bientôt, mon ami ! »',
                  textAlign: TextAlign.center,
                  style: display(h * 0.045, weight: 500, color: OupiColors.onNight, height: 1.3),
                  textScaler: TextScaler.noScaling,
                ),
              ),
          ],
        );
        if (ritual) return NightSky(child: content);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(color, Colors.white, 0.78)!, Color.lerp(OupiColors.meadow, color, 0.12)!],
            ),
          ),
          child: content,
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
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(size.height * 0.07),
                              boxShadow: [BoxShadow(color: OupiColors.ink.withValues(alpha: 0.2), blurRadius: 12)],
                            ),
                            child: Text(zone.symbol ?? '?',
                                style: TextStyle(fontSize: zone.h * size.height * 0.5), textScaler: TextScaler.noScaling),
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
