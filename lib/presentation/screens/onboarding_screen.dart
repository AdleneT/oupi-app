import 'package:flutter/material.dart';

import '../../application/app_scope.dart';
import '../../domain/entities/parental_settings.dart';
import '../responsive.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Onboarding parent au premier lancement (GDD §9, écran 1) :
/// la philosophie, le visionnage accompagné et la limite quotidienne.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  int _limit = ParentalSettings.defaultDailyLimit;
  int _sleepHour = ParentalSettings.defaultSleepHour;

  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _count - 1) {
      _pages.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    } else {
      AppScope.read(context).completeOnboarding(dailyLimit: _limit, sleepHour: _sleepHour);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.layout;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(l.gutter * 1.5, l.gutter, l.gutter * 1.5, l.gutter),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    const _Page(
                      image: oupiImage,
                      eyebrow: 'Bienvenue dans Oupi',
                      title: '5 minutes d’écran utiles, puis on joue ensemble pour de vrai.',
                      lines: [
                        'Chaque épisode apprend une notion de maternelle en 5 minutes.',
                        'À la fin, Oupi s’endort et propose une activité à faire ensemble, loin de l’écran.',
                        'Pas de lecture automatique, pas de publicité, pas de récompense pour revenir.',
                      ],
                    ),
                    const _Page(
                      image: loloImage,
                      eyebrow: 'Visionnage accompagné',
                      title: 'Regardez avec votre enfant.',
                      lines: [
                        'Les recommandations de santé conseillent, entre 3 et 6 ans, des écrans courts, de qualité et accompagnés par un adulte.',
                        'Oupi pose des questions et laisse le temps de répondre : c’est encore mieux à deux.',
                        'Pas d’écran le soir : l’appli s’endort à l’heure que vous choisissez.',
                      ],
                    ),
                    _SettingsPage(
                      limit: _limit,
                      sleepHour: _sleepHour,
                      onLimit: (v) => setState(() => _limit = v),
                      onSleepHour: (v) => setState(() => _sleepHour = v),
                    ),
                  ],
                ),
              ),
              SizedBox(height: l.sp(8)),
              Row(
                children: [
                  for (var i = 0; i < _count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      width: i == _page ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i == _page ? OupiColors.apricotInk : OupiColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_page == _count - 1 ? 'Commencer' : 'Suivant'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une page d'explication : le personnage à côté du texte, ou au-dessus quand l'écran est étroit.
class _Page extends StatelessWidget {
  const _Page({required this.image, required this.eyebrow, required this.title, required this.lines});
  final String image;
  final String eyebrow;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final l = context.layout;
    return LayoutBuilder(
      builder: (context, c) {
        final column = c.maxWidth < 640 || c.maxHeight > c.maxWidth;
        final text = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eyebrow.toUpperCase(), style: body(13, weight: 800, color: OupiColors.apricotInk)),
              const SizedBox(height: 8),
              Text(title, style: display(l.isCompact ? 26 : 30, height: 1.15)),
              const SizedBox(height: 16),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8, right: 10),
                        child: CircleAvatar(radius: 4, backgroundColor: OupiColors.apricot),
                      ),
                      Expanded(child: Text(line, style: body(l.isCompact ? 16 : 17))),
                    ],
                  ),
                ),
            ],
          ),
        );
        return AdaptiveFlex(
          column: column,
          crossAxisAlignment: column ? CrossAxisAlignment.center : CrossAxisAlignment.center,
          spacing: l.sp(column ? 16 : 36),
          children: [
            BreathingCharacter(
              asset: image,
              height: characterHeight(c, heightFraction: column ? 0.32 : 0.92, widthFraction: column ? 0.5 : 0.36, max: 420),
            ),
            Expanded(child: text),
          ],
        );
      },
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.limit, required this.sleepHour, required this.onLimit, required this.onSleepHour});
  final int limit;
  final int sleepHour;
  final ValueChanged<int> onLimit;
  final ValueChanged<int> onSleepHour;

  @override
  Widget build(BuildContext context) {
    final l = context.layout;
    final limitColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Épisodes par jour', style: body(17, weight: 800)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (var v = ParentalSettings.minDailyLimit; v <= ParentalSettings.maxDailyLimit; v++)
              ButtonSegment(value: v, label: Text('$v')),
          ],
          selected: {limit},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onLimit(s.first),
        ),
        const SizedBox(height: 8),
        Text('1 par jour est conseillé.', style: body(15, color: OupiColors.muted)),
      ],
    );
    final sleepColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Oupi s’endort à', style: body(17, weight: 800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in ParentalSettings.sleepHourChoices)
              ChoiceChip(label: Text('$h h'), selected: h == sleepHour, onSelected: (_) => onSleepHour(h)),
          ],
        ),
        const SizedBox(height: 8),
        Text('19 h est conseillé. Il se réveille à ${ParentalSettings.wakeHour} h.', style: body(15, color: OupiColors.muted)),
      ],
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RÉGLAGES', style: body(13, weight: 800, color: OupiColors.apricotInk)),
          const SizedBox(height: 8),
          Text('Choisissez le rythme d’Oupi.', style: display(l.isCompact ? 26 : 30)),
          const SizedBox(height: 6),
          Text('Vous pourrez tout changer plus tard dans l’espace parents.', style: body(16, color: OupiColors.muted)),
          const SizedBox(height: 22),
          // Deux colonnes quand il y a la place, sinon l'une sous l'autre.
          if (l.isNarrow)
            Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 24, children: [limitColumn, sleepColumn])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 32,
              children: [Expanded(child: limitColumn), Expanded(child: sleepColumn)],
            ),
        ],
      ),
    );
  }
}
