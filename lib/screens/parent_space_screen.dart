import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/episode.dart';
import '../navigation.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/parent_ui.dart';
import 'paywall_screen.dart';

/// Espace parents (GDD §10), protégé par le contrôle parental. Même charte que le dashboard du
/// projet (abricot, sauge, crème, Fredoka et Nunito), en plus immersif : chaque rubrique a sa
/// couleur, qui teinte tout l'écran, et son bandeau illustré en feutrine où Oupi joue le thème.
class ParentSpaceScreen extends StatefulWidget {
  const ParentSpaceScreen({super.key, this.initialIndex = 0});

  /// Rubrique ouverte à l'arrivée (par exemple les réglages, depuis l'écran « Il fait dodo »).
  final int initialIndex;

  static const settingsIndex = 6;

  @override
  State<ParentSpaceScreen> createState() => _ParentSpaceScreenState();
}

class _Section {
  const _Section({
    required this.icon,
    required this.label,
    required this.eyebrow,
    required this.subtitle,
    required this.hero,
    required this.tint,
    required this.accent,
    required this.heroTop,
    required this.heroBottom,
    this.onDark = false,
  });

  final IconData icon;
  final String label;
  final String eyebrow;
  final String subtitle;

  /// Bandeau illustré (Higgsfield, Seedream 5.0 Pro) : Oupi à droite, place pour le titre à gauche.
  final String hero;

  /// Couleur de fond de la rubrique, éclaircie depuis celle du bandeau.
  final Color tint;

  /// Encre de la rubrique : intitulé du bandeau, icône du rail.
  final Color accent;

  /// Couleurs du bord gauche du bandeau (relevées sur l'image), pour le prolonger sans couture.
  final Color heroTop;
  final Color heroBottom;

  /// Bandeau sombre (crépuscule) : le titre passe en clair.
  final bool onDark;
}

class _ParentSpaceScreenState extends State<ParentSpaceScreen> {
  late int _index = widget.initialIndex;

  static const _sections = <_Section>[
    _Section(
      icon: Icons.schedule_rounded,
      label: 'Temps d’écran',
      eyebrow: 'Le rythme d’Oupi',
      subtitle: 'Combien d’épisodes, jusqu’à quelle heure, et ce qui a été regardé.',
      hero: 'assets/images/parent_time.jpg',
      tint: Color(0xFFF5D6BF),
      accent: OupiColors.apricotInk,
      heroTop: Color(0xFFE3C9B8),
      heroBottom: Color(0xFFDBCEBC),
    ),
    _Section(
      icon: Icons.palette_outlined,
      label: 'Activités',
      eyebrow: 'Loin de l’écran',
      subtitle: 'Après chaque épisode, une activité à faire ensemble.',
      hero: 'assets/images/parent_activities.jpg',
      tint: Color(0xFFCFE3CC),
      accent: OupiColors.sageInk,
      heroTop: Color(0xFF99B59E),
      heroBottom: Color(0xFFC6D2BE),
    ),
    _Section(
      icon: Icons.photo_library_outlined,
      label: 'Mur des trésors',
      eyebrow: 'Galerie souvenirs',
      subtitle: 'Les créations de votre enfant, gardées sur ce téléphone.',
      hero: 'assets/images/parent_treasures.jpg',
      tint: Color(0xFFF3CDD3),
      accent: Color(0xFF8E2F50),
      heroTop: Color(0xFFD4A7A9),
      heroBottom: Color(0xFFD6A9A9),
    ),
    _Section(
      icon: Icons.health_and_safety_outlined,
      label: 'Repères écrans',
      eyebrow: 'Santé',
      subtitle: 'Ce que conseillent les recommandations officielles.',
      hero: 'assets/images/parent_guidelines.jpg',
      tint: Color(0xFFC8E0EC),
      accent: Color(0xFF1B4A75),
      heroTop: Color(0xFF8FB6BE),
      heroBottom: Color(0xFFBBD1D7),
    ),
    _Section(
      icon: Icons.favorite_outline_rounded,
      label: 'Pourquoi Oupi',
      eyebrow: 'Notre promesse',
      subtitle: 'Ce qui guide chaque épisode.',
      hero: 'assets/images/parent_why.jpg',
      tint: Color(0xFFEDE3C8),
      accent: OupiColors.sageInk,
      heroTop: Color(0xFFDED4C4),
      heroBottom: Color(0xFFDAD5C4),
    ),
    _Section(
      icon: Icons.card_membership_rounded,
      label: 'Abonnement',
      eyebrow: 'Sans publicité',
      subtitle: 'Tous les épisodes, le juke-box et les fiches activités.',
      hero: 'assets/images/parent_subscription.jpg',
      tint: Color(0xFFDCCDEE),
      accent: Color(0xFF4E3590),
      heroTop: Color(0xFFAF97BC),
      heroBottom: Color(0xFFD1C2D9),
    ),
    _Section(
      icon: Icons.tune_rounded,
      label: 'Réglages',
      eyebrow: 'Espace parents',
      subtitle: 'Mode dodo, son et confidentialité.',
      hero: 'assets/images/parent_settings.jpg',
      tint: Color(0xFFC3C7EA),
      accent: Color(0xFF3B4878),
      heroTop: Color(0xFF4E658F),
      heroBottom: Color(0xFF8390B2),
      onDark: true,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Les bandeaux sont prêts avant qu'on change de rubrique : pas d'image qui arrive en retard.
    for (final s in _sections) {
      precacheImage(AssetImage(s.hero), context);
    }
  }

  Widget _page(int i) => switch (i) {
    0 => const _ScreenTime(),
    1 => const _Activities(),
    2 => const _Treasures(),
    3 => const _Guidelines(),
    4 => const _Why(),
    5 => const _Subscription(),
    _ => const _Settings(),
  };

  @override
  Widget build(BuildContext context) {
    final section = _sections[_index];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [section.tint, Color.lerp(section.tint, OupiColors.cream, 0.3)!],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final extended = c.maxWidth >= 760;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Rail(
                  sections: _sections,
                  index: _index,
                  extended: extended,
                  onSelect: (i) => setState(() => _index = i),
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SafeArea(
                    left: false,
                    bottom: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: SingleChildScrollView(
                        key: ValueKey(_index),
                        padding: const EdgeInsets.fromLTRB(20, 12, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroBanner(section: section),
                            const SizedBox(height: 18),
                            _page(_index),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bandeau de la rubrique : l'illustration en feutrine, cousue comme un écusson, avec le titre posé
/// sur la partie calme de l'image (à gauche).
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.section});
  final _Section section;

  /// Largeur / hauteur des illustrations (3120 × 1328).
  static const _imageAspect = 3120 / 1328;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      // L'image garde toute sa hauteur (pousse et pieds d'Oupi jamais coupés) ; à gauche, le fond
      // de l'image continue en dégradé sous le titre.
      final height = (c.maxWidth / 3.2).clamp(150.0, 210.0);
      final imageWidth = height * _imageAspect;
      final ink = section.onDark ? OupiColors.onNight : OupiColors.ink;
      final veil = section.onDark ? OupiColors.night : Colors.white;
      return CustomPaint(
        foregroundPainter: StitchPainter(
          color: Colors.white.withValues(alpha: section.onDark ? 0.55 : 0.8),
          radius: 26,
          inset: 8,
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [section.heroTop, section.heroBottom],
            ),
            boxShadow: parentShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: imageWidth,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Color(0x00000000), Color(0xFF000000)],
                    stops: [0, 0.22],
                  ).createShader(rect),
                  child: Image.asset(
                    section.hero,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              // Voile doux à gauche : le titre reste lisible quelle que soit l'image.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.5, 0.72],
                    colors: [veil.withValues(alpha: 0.42), veil.withValues(alpha: 0.2), veil.withValues(alpha: 0)],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(30, 0, c.maxWidth * 0.42, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    eyebrow(section.eyebrow, color: section.onDark ? Vivid.moon : section.accent),
                    const SizedBox(height: 4),
                    Text(section.label, style: display(32, weight: 600, height: 1.1, color: ink)),
                    const SizedBox(height: 6),
                    Text(
                      section.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: body(15, weight: 600, color: ink.withValues(alpha: 0.78)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Rail des rubriques, comme celui du dashboard : la marque en haut, puis les rubriques. Il est
/// translucide, pour que la couleur de la rubrique ouverte baigne tout l'écran.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.sections,
    required this.index,
    required this.extended,
    required this.onSelect,
    required this.onClose,
  });

  final List<_Section> sections;
  final int index;
  final bool extended;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final close = Tooltip(
      message: 'Retour à Oupi',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: OupiColors.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onClose,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.close_rounded, size: 22, color: OupiColors.ink, semanticLabel: 'Retour à Oupi'),
          ),
        ),
      ),
    );
    return Container(
      width: extended ? 232 : 84,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.8))),
      ),
      child: SafeArea(
        right: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: extended
                    ? Row(
                        children: [
                          const OupiAvatar(size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Oupi', style: display(21, weight: 600, height: 1)),
                                const SizedBox(height: 3),
                                Text(
                                  'Espace parents',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: body(12, weight: 700, color: OupiColors.muted, height: 1.2),
                                ),
                              ],
                            ),
                          ),
                          close,
                        ],
                      )
                    : Column(children: [const OupiAvatar(size: 40), const SizedBox(height: 10), close]),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < sections.length; i++)
                _RailItem(section: sections[i], selected: i == index, extended: extended, onTap: () => onSelect(i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.section, required this.selected, required this.extended, required this.onTap});
  final _Section section;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget item = Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            height: 42,
            width: extended ? double.infinity : 60,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: selected ? section.accent.withValues(alpha: 0.35) : Colors.transparent),
              boxShadow: selected ? parentShadow : null,
            ),
            child: Row(
              mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                // Pastille de la couleur de la rubrique, pleine quand elle est ouverte.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected ? section.tint : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(section.icon, size: 20, color: selected ? section.accent : OupiColors.muted),
                ),
                if (extended) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(
                        14.5,
                        weight: selected ? 800 : 700,
                        color: selected ? OupiColors.ink : OupiColors.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!extended) item = Tooltip(message: section.label, child: item);
    return Semantics(selected: selected, button: true, label: extended ? null : section.label, child: item);
  }
}

String _plural(int n, String word) => n > 1 ? '${word}s' : word;

const _weekdays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
String _dayLabel(DateTime d, int index) => index == 0
    ? 'Aujourd’hui'
    : index == 1
    ? 'Hier'
    : '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

class _ScreenTime extends StatelessWidget {
  const _ScreenTime();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final week = s.lastDays(7);
    final weekCount = week.fold<int>(0, (n, d) => n + d.episodes.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  label: 'Aujourd’hui',
                  value: '${s.startedToday} / ${s.dailyLimit}',
                  caption: '${_plural(s.startedToday, 'épisode')} ${_plural(s.startedToday, 'lancé')}',
                  progress: s.startedToday / s.dailyLimit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Cette semaine',
                  value: '$weekCount',
                  caption: '${_plural(weekCount, 'épisode')} en 7 jours',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(label: 'Dodo', value: '${s.sleepHour} h', caption: 'réveil à ${AppState.wakeHour} h'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ParentCard(
          title: 'Épisodes par jour',
          icon: Icons.play_circle_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChoicePills<int>(
                values: [for (var v = AppState.minDailyLimit; v <= AppState.maxDailyLimit; v++) v],
                selected: s.dailyLimit,
                recommended: AppState.defaultDailyLimit,
                label: (v) => '$v',
                onSelected: s.setDailyLimit,
              ),
              const SizedBox(height: 10),
              Text(
                'Un épisode dure 5 minutes et se termine par une activité à faire ensemble.',
                style: body(14.5, color: OupiColors.muted),
              ),
            ],
          ),
        ),
        ParentCard(
          title: 'Oupi s’endort à',
          icon: Icons.bedtime_outlined,
          tone: Tone.eye,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChoicePills<int>(
                values: AppState.sleepHourChoices,
                selected: s.sleepHour,
                recommended: AppState.defaultSleepHour,
                label: (h) => '$h h',
                onSelected: s.setSleepHour,
              ),
              const SizedBox(height: 10),
              Text(
                'Il se réveille à ${AppState.wakeHour} h. Entre les deux, l’appli affiche Oupi qui dort.',
                style: body(14.5, color: OupiColors.muted),
              ),
            ],
          ),
        ),
        ParentCard(
          title: 'Cette semaine',
          icon: Icons.calendar_month_outlined,
          tone: Tone.sage,
          child: Column(
            children: [
              for (var i = 0; i < week.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: OupiColors.line),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(_dayLabel(week[i].day, i), style: body(15, weight: i == 0 ? 800 : 700)),
                      ),
                      Expanded(
                        child: week[i].episodes.isEmpty
                            ? Text('Aucun épisode', style: body(15, color: OupiColors.muted))
                            : Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  for (final e in week[i].episodes)
                                    SoftChip(
                                      'Épisode ${e.number} · ${e.displayTitle}',
                                      tone: Tone.neutral,
                                      dot: OupiColors.family(e.family),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Activities extends StatelessWidget {
  const _Activities();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        for (final e in s.catalog.episodes) _ActivityCard(key: ValueKey(e.id), episode: e, locked: s.isLocked(e)),
      ],
    );
  }
}

/// Fiche activité d'un épisode : on la déplie pour lire la durée, le matériel, les étapes et la question.
class _ActivityCard extends StatefulWidget {
  const _ActivityCard({super.key, required this.episode, required this.locked});
  final Episode episode;
  final bool locked;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  late bool _open = widget.episode.activity.isDetailed;

  @override
  Widget build(BuildContext context) {
    final e = widget.episode;
    final a = e.activity;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: OupiColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OupiColors.line),
        boxShadow: parentShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: OupiColors.family(e.family), shape: BoxShape.circle),
                      child: Text('${e.number}', style: display(20, weight: 600, color: Colors.white)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: display(18, weight: 600, height: 1.2)),
                          const SizedBox(height: 2),
                          Text('Épisode ${e.number} · ${e.displayTitle}', style: body(14, color: OupiColors.muted)),
                        ],
                      ),
                    ),
                    if (widget.locked) ...[
                      const SizedBox(width: 8),
                      const SoftChip('Abonnement', icon: Icons.lock_outline_rounded, tone: Tone.apricot),
                    ],
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 260),
                      child: const Icon(Icons.expand_more_rounded, size: 28, color: OupiColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(padding: const EdgeInsets.fromLTRB(76, 0, 20, 18), child: _details(a))
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _details(ActivitySheet a) {
    if (!a.isDetailed) {
      return CustomPaint(
        foregroundPainter: const StitchPainter(color: OupiColors.lineStrong, radius: 16, inset: 1),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: OupiColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fiche détaillée à venir : durée, matériel, 3 étapes illustrées et une question à poser.',
                  style: body(14.5, color: OupiColors.muted),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (a.duration != null) SoftChip(a.duration!, icon: Icons.timer_outlined, tone: Tone.eye),
            for (final m in a.materials) SoftChip(m, tone: Tone.neutral),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < a.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: OupiColors.apricotSoft, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: display(15, weight: 600, color: OupiColors.apricotInk)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(a.steps[i], style: body(15.5)),
                  ),
                ),
              ],
            ),
          ),
        if (a.question != null) ...[
          const SizedBox(height: 4),
          PromiseBlock(label: 'La question à poser', text: '« ${a.question} »'),
        ],
      ],
    );
  }
}

class _Treasures extends StatelessWidget {
  const _Treasures();

  @override
  Widget build(BuildContext context) => ParentCard(
    child: Row(
      children: [
        const SizedBox(width: 170, height: 132, child: _Polaroids()),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photographiez les créations de votre enfant : elles apparaîtront dans sa galerie souvenirs.',
                style: body(16),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.lock_outline_rounded, size: 18, color: OupiColors.sageInk),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les photos restent uniquement sur ce téléphone. Elles ne sont jamais envoyées sur un serveur.',
                      style: body(14.5, color: OupiColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Prendre une photo'),
                  ),
                  const SoftChip('Prochaine version', tone: Tone.eye),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Trois polaroïds vides, de travers, comme sur un mur de dessins.
class _Polaroids extends StatelessWidget {
  const _Polaroids();

  @override
  Widget build(BuildContext context) {
    Widget photo(double angle, Offset at, List<Color> colors, IconData icon) => Positioned(
      left: at.dx,
      top: at.dy,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 84,
          height: 98,
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OupiColors.line),
            boxShadow: parentShadow,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            ),
            child: Center(child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 26)),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        photo(-0.12, const Offset(0, 22), const [OupiColors.sageSoft, OupiColors.sage], Icons.eco_rounded),
        photo(0.08, const Offset(80, 14), const [OupiColors.eyeSoft, Color(0xFF8DB8DE)], Icons.brush_rounded),
        photo(-0.03, const Offset(40, 0), const [OupiColors.apricotSoft, OupiColors.apricot], Icons.favorite_rounded),
      ],
    );
  }
}

class _Guidelines extends StatelessWidget {
  const _Guidelines();

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Tone tone, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconTile(icon, tone: tone),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: body(16))),
        ],
      ),
    );
    return Column(
      children: [
        ParentCard(
          title: 'Les recommandations officielles',
          icon: Icons.health_and_safety_outlined,
          tone: Tone.sage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(Icons.child_care_rounded, Tone.apricot, 'Pas d’écran avant 3 ans.'),
              row(
                Icons.timer_outlined,
                Tone.eye,
                'De 3 à 6 ans : des temps courts, des contenus éducatifs de qualité, regardés avec un adulte.',
              ),
              row(Icons.nights_stay_outlined, Tone.night, 'Pas d’écran le soir ni au réveil.'),
              Text('D’après le carnet de santé de l’enfant (édition 2025).', style: body(14, color: OupiColors.muted)),
            ],
          ),
        ),
        const PromiseBlock(
          label: 'Avec Oupi',
          text: 'Un épisode de 5 minutes, à regarder ensemble, puis on joue pour de vrai. Le soir, l’appli dort.',
        ),
      ],
    );
  }
}

class _Why extends StatelessWidget {
  const _Why();

  @override
  Widget build(BuildContext context) {
    Widget bullet(Color dot, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          Expanded(child: Text(text, style: body(16))),
        ],
      ),
    );
    return Column(
      children: [
        _HeroPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eyebrow('Promesse parent'),
              const SizedBox(height: 6),
              Text(
                '« 5 minutes d’écran utiles, puis on joue ensemble pour de vrai. »',
                style: display(24, weight: 500, height: 1.25),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ParentCard(
          child: Column(
            children: [
              bullet(OupiColors.apricot, 'Chaque épisode apprend une seule notion de maternelle, répétée et chantée.'),
              bullet(
                OupiColors.leaf,
                'Il se termine toujours par le même rituel : Oupi s’endort et propose une activité à faire avec vous.',
              ),
              bullet(OupiColors.eye, 'Pas de lecture automatique, pas de publicité, pas de récompense pour revenir.'),
              bullet(OupiColors.sage, 'Aucun compte, aucune donnée collectée : tout reste sur cet appareil.'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bandeau en dégradé abricot vers sauge, avec sa couture (le héros du dashboard).
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: const StitchPainter(radius: 26),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 24, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: OupiColors.line),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OupiColors.apricotSoft, Color.lerp(OupiColors.sageSoft, OupiColors.cream, 0.45)!],
        ),
        boxShadow: parentShadow,
      ),
      child: child,
    ),
  );
}

class _Subscription extends StatelessWidget {
  const _Subscription();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ParentCard(
      title: s.premium ? 'Abonnement actif' : 'Version gratuite',
      icon: s.premium ? Icons.verified_rounded : Icons.card_membership_rounded,
      tone: s.premium ? Tone.sage : Tone.apricot,
      trailing: SoftChip(s.premium ? 'Simulé' : '5 épisodes', tone: s.premium ? Tone.sage : Tone.neutral),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.premium
                ? 'Tous les épisodes, le juke-box et les fiches activités sont débloqués.'
                : 'Les 5 premiers épisodes sont gratuits. L’abonnement débloque les autres, le juke-box et les fiches.',
            style: body(15.5),
          ),
          const SizedBox(height: 14),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PriceTile(title: 'Mensuel', price: '2,99 €', unit: '/ mois'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _PriceTile(title: 'Annuel', price: '19,99 €', unit: '/ an', note: 'Le plus avantageux'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '7 jours d’essai gratuit. Le contrôle du temps d’écran reste gratuit, et il n’y a jamais de publicité.',
            style: body(14, color: OupiColors.muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).push(gentleRoute(const PaywallScreen())),
                child: Text(s.premium ? 'Voir l’abonnement' : 'S’abonner'),
              ),
              OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('La restauration arrivera avec les achats intégrés.'))),
                child: const Text('Restaurer un achat'),
              ),
              if (s.premium)
                OutlinedButton(onPressed: () => s.setPremium(false), child: const Text('Annuler la simulation')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({required this.title, required this.price, required this.unit, this.note});
  final String title;
  final String price;
  final String unit;
  final String? note;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: OupiColors.cream,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OupiColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eyebrow(title, color: OupiColors.muted, size: 11.5),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(price, style: display(24, weight: 600)),
            const SizedBox(width: 6),
            Text(unit, style: body(14, color: OupiColors.muted)),
          ],
        ),
        if (note != null) Text(note!, style: body(13, weight: 800, color: OupiColors.sageInk)),
      ],
    ),
  );
}

String _clock(DateTime t) => '${t.hour} h ${t.minute.toString().padLeft(2, '0')}';

String _durationLabel(Duration d) => d.inMinutes < 60 ? '${d.inMinutes} min' : '${d.inHours} h';

/// Mode dodo : la carte prend la couleur de la nuit quand Oupi dort, et on peut le réveiller pour
/// une durée choisie (l'heure du dodo et la limite du jour sont suspendues, puis il se rendort).
/// De jour, elle dit jusqu'à quand il reste éveillé.
class _DodoCard extends StatefulWidget {
  const _DodoCard();

  @override
  State<_DodoCard> createState() => _DodoCardState();
}

class _DodoCardState extends State<_DodoCard> {
  Duration _duration = AppState.wakeDurations.first;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = s.now;
    final until = s.wakeUntil;
    final sleepHours = s.isWithinSleepHours(now);
    final asleep = until == null && (sleepHours || s.limitReached);
    return asleep ? _night(s, now, sleepHours) : _day(s, until);
  }

  Widget _night(AppState s, DateTime now, bool sleepHours) {
    final why = !sleepHours
        ? 'La limite de ${s.dailyLimit} ${_plural(s.dailyLimit, 'épisode')} par jour est atteinte.'
        : now.hour < AppState.wakeHour
        ? 'C’est la nuit : il se réveillera à ${AppState.wakeHour} h.'
        : 'Il est plus de ${s.sleepHour} h : il se réveillera demain à ${AppState.wakeHour} h.';
    final onNightMuted = OupiColors.onNight.withValues(alpha: 0.78);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B4878), OupiColors.night],
        ),
        boxShadow: parentShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 14, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bedtime_rounded, color: Vivid.moon, size: 20),
                          const SizedBox(width: 8),
                          eyebrow('Mode dodo', color: Vivid.moon),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Oupi dort', style: display(26, weight: 600, color: OupiColors.onNight)),
                      const SizedBox(height: 2),
                      Text(why, style: body(15, color: onNightMuted)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChoicePills<Duration>(
                            values: AppState.wakeDurations,
                            selected: _duration,
                            label: _durationLabel,
                            onNight: true,
                            onSelected: (d) => setState(() => _duration = d),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Vivid.moon, foregroundColor: OupiColors.ink),
                            onPressed: () => s.wakeUp(_duration),
                            icon: const Icon(Icons.wb_sunny_rounded),
                            label: const Text('Réveiller Oupi'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'À utiliser avec modération : les écrans le soir gênent l’endormissement.',
                        style: body(13.5, color: onNightMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ExcludeSemantics(
                  child: Image.asset('assets/images/oupi_cloud.png', width: 190, filterQuality: FilterQuality.medium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _day(AppState s, DateTime? until) {
    final woken = until != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _HeroPanel(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_rounded, color: OupiColors.apricotInk, size: 20),
                      const SizedBox(width: 8),
                      eyebrow('Mode dodo'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    woken ? 'Oupi est réveillé jusqu’à ${_clock(until)}' : 'Oupi est réveillé',
                    style: display(24, weight: 600, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    woken
                        ? 'L’heure du dodo et la limite du jour sont suspendues jusque-là, puis il se rendort tout seul.'
                        : 'Il s’endormira à ${s.sleepHour} h, ou dès que la limite du jour sera atteinte. '
                              'Vous pourrez alors le réveiller ici.',
                    style: body(15, color: OupiColors.muted),
                  ),
                  if (woken) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: s.sendBackToSleep,
                      icon: const Icon(Icons.bedtime_outlined),
                      label: const Text('Rendormir Oupi maintenant'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            ExcludeSemantics(
              child: Image.asset('assets/images/oupi_wave.png', height: 150, filterQuality: FilterQuality.medium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quelques étoiles fixes sur la carte de nuit (pas de scintillement côté parents).
class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(5);
    final paint = Paint();
    for (var i = 0; i < 22; i++) {
      final c = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.8);
      paint.color = Vivid.moon.withValues(alpha: 0.25 + r.nextDouble() * 0.45);
      canvas.drawCircle(c, 0.8 + r.nextDouble() * 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}

class _Settings extends StatefulWidget {
  const _Settings();

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  bool _confirmReset = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        const _DodoCard(),
        ParentCard(
          title: 'Son et lecture',
          icon: Icons.graphic_eq_rounded,
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
          child: Column(
            children: [
              SwitchRow(
                icon: Icons.volume_up_rounded,
                title: 'Son',
                subtitle: 'La voix d’Oupi, les chansons et la musique.',
                value: s.sound,
                onChanged: s.setSound,
              ),
              const Divider(height: 12, color: OupiColors.line),
              SwitchRow(
                icon: Icons.fast_forward_rounded,
                tone: Tone.eye,
                title: 'Lecture accélérée ×10',
                subtitle: 'Test du prototype : un épisode maquette en 30 secondes.',
                value: s.fastPlayback,
                onChanged: s.setFastPlayback,
              ),
            ],
          ),
        ),
        ParentCard(
          title: 'Confidentialité',
          icon: Icons.verified_user_outlined,
          tone: Tone.sage,
          child: Text(
            'Oupi ne crée aucun compte et ne collecte aucune donnée personnelle. Aucun outil de publicité '
            'ou de mesure d’audience n’est intégré. Les réglages et les photos restent sur cet appareil.',
            style: body(15.5),
          ),
        ),
        ParentCard(
          title: 'Réinitialiser l’appli',
          icon: Icons.restart_alt_rounded,
          tone: Tone.bad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Efface les réglages, l’historique et les épisodes vus, puis relance l’accueil des parents.',
                style: body(15, color: OupiColors.muted),
              ),
              const SizedBox(height: 12),
              if (!_confirmReset)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: OupiColors.bad),
                  onPressed: () => setState(() => _confirmReset = true),
                  child: const Text('Réinitialiser'),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: OupiColors.bad),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await s.resetAll();
                        navigator.popUntil((route) => route.isFirst);
                      },
                      child: const Text('Oui, tout effacer'),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() => _confirmReset = false),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
