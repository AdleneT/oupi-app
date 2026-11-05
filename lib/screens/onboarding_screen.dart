import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/parent_ui.dart';

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
  int _limit = AppState.defaultDailyLimit;
  int _sleepHour = AppState.defaultSleepHour;

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
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
                      image: lalaImage,
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
                  FilledButton(onPressed: _next, child: Text(_page == _count - 1 ? 'Commencer' : 'Suivant')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.image, required this.eyebrow, required this.title, required this.lines});
  final String image;
  final String eyebrow;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Row(
      children: [
        // Le personnage détouré se tient devant un soleil, un clin d'œil au monde côté enfant.
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: c.maxHeight * 0.06,
              child: Container(
                width: c.maxHeight * 0.72,
                height: c.maxHeight * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Vivid.sunny.withValues(alpha: 0.45), Vivid.mango.withValues(alpha: 0.12)]),
                ),
              ),
            ),
            BreathingCharacter(asset: image, height: (c.maxHeight * 0.92).clamp(140, 420)),
          ],
        ),
        const SizedBox(width: 36),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(eyebrow.toUpperCase(), style: body(13, weight: 800, color: OupiColors.apricotInk)),
                const SizedBox(height: 8),
                Text(title, style: display(30, height: 1.15)),
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
                        Expanded(child: Text(line, style: body(17))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.limit, required this.sleepHour, required this.onLimit, required this.onSleepHour});
  final int limit;
  final int sleepHour;
  final ValueChanged<int> onLimit;
  final ValueChanged<int> onSleepHour;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RÉGLAGES', style: body(13, weight: 800, color: OupiColors.apricotInk)),
        const SizedBox(height: 8),
        Text('Choisissez le rythme d’Oupi.', style: display(30)),
        const SizedBox(height: 6),
        Text('Vous pourrez tout changer plus tard dans l’espace parents.', style: body(16, color: OupiColors.muted)),
        const SizedBox(height: 22),
        // Deux colonnes : tout tient sur un téléphone à l'horizontale.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Épisodes par jour', style: body(17, weight: 800)),
                  const SizedBox(height: 8),
                  ChoicePills<int>(
                    values: [for (var v = AppState.minDailyLimit; v <= AppState.maxDailyLimit; v++) v],
                    selected: limit,
                    recommended: AppState.defaultDailyLimit,
                    label: (v) => '$v',
                    onSelected: onLimit,
                  ),
                  const SizedBox(height: 8),
                  Text('Un épisode dure 5 minutes.', style: body(15, color: OupiColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Oupi s’endort à', style: body(17, weight: 800)),
                  const SizedBox(height: 8),
                  ChoicePills<int>(
                    values: AppState.sleepHourChoices,
                    selected: sleepHour,
                    recommended: AppState.defaultSleepHour,
                    label: (h) => '$h h',
                    onSelected: onSleepHour,
                  ),
                  const SizedBox(height: 8),
                  Text('Il se réveille à ${AppState.wakeHour} h.', style: body(15, color: OupiColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
