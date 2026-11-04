import 'package:flutter/material.dart';

import '../navigation.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'paywall_screen.dart';

/// Espace parents (GDD §10), protégé par le contrôle parental.
class ParentSpaceScreen extends StatefulWidget {
  const ParentSpaceScreen({super.key});

  @override
  State<ParentSpaceScreen> createState() => _ParentSpaceScreenState();
}

class _ParentSpaceScreenState extends State<ParentSpaceScreen> {
  int _index = 0;

  static const _sections = <(IconData, String)>[
    (Icons.schedule_rounded, 'Temps d’écran'),
    (Icons.palette_outlined, 'Activités'),
    (Icons.photo_library_outlined, 'Mur des trésors'),
    (Icons.health_and_safety_outlined, 'Repères écrans'),
    (Icons.favorite_outline_rounded, 'Pourquoi Oupi'),
    (Icons.card_membership_rounded, 'Abonnement'),
    (Icons.tune_rounded, 'Réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _ScreenTime(),
      const _Activities(),
      const _Treasures(),
      const _Guidelines(),
      const _Why(),
      const _Subscription(),
      const _Settings(),
    ];
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Le rail défile s'il manque de hauteur (téléphone à l'horizontale, 7 rubriques).
            LayoutBuilder(
              builder: (context, c) => ColoredBox(
                color: OupiColors.surface2,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: IntrinsicHeight(child: _rail(context)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_sections[_index].$2, style: display(30)),
                    const SizedBox(height: 18),
                    pages[_index],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail(BuildContext context) => NavigationRail(
              backgroundColor: OupiColors.surface2,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.none,
              extended: MediaQuery.sizeOf(context).width > 900,
              minExtendedWidth: 220,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Quitter l’espace parents',
                ),
              ),
              destinations: [
                for (final (icon, label) in _sections)
                  NavigationRailDestination(icon: Icon(icon), label: Text(label, style: body(15, weight: 700))),
              ],
            );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: OupiColors.line),
        ),
        child: child,
      );
}

Widget _label(String text) =>
    Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: body(16, weight: 800)));

Widget _para(String text, {Color color = OupiColors.ink}) =>
    Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: body(16, color: color)));

const _weekdays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
String _dayLabel(DateTime d, int index) =>
    index == 0 ? 'Aujourd’hui' : index == 1 ? 'Hier' : '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

class _ScreenTime extends StatelessWidget {
  const _ScreenTime();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final week = s.lastDays(7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Épisodes par jour'),
              SegmentedButton<int>(
                segments: [
                  for (var v = AppState.minDailyLimit; v <= AppState.maxDailyLimit; v++)
                    ButtonSegment(value: v, label: Text(v == 1 ? '1 (conseillé)' : '$v')),
                ],
                selected: {s.dailyLimit},
                showSelectedIcon: false,
                onSelectionChanged: (v) => s.setDailyLimit(v.first),
              ),
              const SizedBox(height: 10),
              Text(
                'Aujourd’hui : ${s.startedToday} épisode${s.startedToday > 1 ? 's' : ''} lancé${s.startedToday > 1 ? 's' : ''} '
                'sur ${s.dailyLimit}.',
                style: body(15, color: OupiColors.muted),
              ),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Oupi s’endort à'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final h in AppState.sleepHourChoices)
                    ChoiceChip(label: Text('$h h'), selected: h == s.sleepHour, onSelected: (_) => s.setSleepHour(h)),
                ],
              ),
              const SizedBox(height: 10),
              Text('Il se réveille à ${AppState.wakeHour} h. Entre les deux, l’appli affiche Oupi qui dort.',
                  style: body(15, color: OupiColors.muted)),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Cette semaine'),
              for (var i = 0; i < week.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 170, child: Text(_dayLabel(week[i].day, i), style: body(15, weight: 700))),
                      Expanded(
                        child: Text(
                          week[i].episodes.isEmpty
                              ? 'Aucun épisode'
                              : week[i].episodes.map((e) => 'Épisode ${e.number} · ${e.displayTitle}').join(', '),
                          style: body(15, color: week[i].episodes.isEmpty ? OupiColors.muted : OupiColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
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
        for (final e in s.catalog.episodes)
          _Card(
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: e.activity.isDetailed,
                leading: CircleAvatar(
                  backgroundColor: OupiColors.family(e.family),
                  child: Text('${e.number}', style: display(18, color: Colors.white)),
                ),
                title: Text(e.activity.title, style: body(16, weight: 800)),
                subtitle: Text('Épisode ${e.number} · ${e.displayTitle}${s.isLocked(e) ? ' · abonnement' : ''}',
                    style: body(14, color: OupiColors.muted)),
                childrenPadding: const EdgeInsets.only(left: 56, bottom: 8),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: e.activity.isDetailed
                    ? [
                        if (e.activity.duration != null) _para('Durée : ${e.activity.duration}'),
                        if (e.activity.materials.isNotEmpty) _para('Matériel : ${e.activity.materials.join(', ')}.'),
                        for (var i = 0; i < e.activity.steps.length; i++) _para('${i + 1}. ${e.activity.steps[i]}'),
                        if (e.activity.question != null)
                          _para('La question à poser : « ${e.activity.question} »', color: OupiColors.apricotInk),
                      ]
                    : [_para('Fiche détaillée à venir : durée, matériel, 3 étapes illustrées et une question à poser.', color: OupiColors.muted)],
              ),
            ),
          ),
      ],
    );
  }
}

class _Treasures extends StatelessWidget {
  const _Treasures();

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _para('Photographiez les créations de votre enfant : elles apparaîtront dans sa galerie souvenirs.'),
            _para('Les photos restent uniquement sur ce téléphone. Elles ne sont jamais envoyées sur un serveur.',
                color: OupiColors.muted),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Prendre une photo (prochaine version)'),
            ),
          ],
        ),
      );
}

class _Guidelines extends StatelessWidget {
  const _Guidelines();

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Les recommandations officielles'),
            _para('• Pas d’écran avant 3 ans.'),
            _para('• De 3 à 6 ans : des temps courts, des contenus éducatifs de qualité, regardés avec un adulte.'),
            _para('• Pas d’écran le soir ni au réveil.'),
            const SizedBox(height: 6),
            _para('D’après le carnet de santé de l’enfant (édition 2025).', color: OupiColors.muted),
          ],
        ),
      );
}

class _Why extends StatelessWidget {
  const _Why();

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _para('Oupi propose 5 minutes d’écran utiles, puis invite à jouer ensemble pour de vrai.'),
            _para('Chaque épisode apprend une seule notion de maternelle, répétée et chantée.'),
            _para('Il se termine toujours par le même rituel : Oupi s’endort et propose une activité à faire avec vous.'),
            _para('Pas de lecture automatique, pas de publicité, pas de récompense pour revenir.'),
            _para('Aucun compte, aucune donnée collectée : tout reste sur cet appareil.'),
          ],
        ),
      );
}

class _Subscription extends StatelessWidget {
  const _Subscription();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(s.premium ? 'Abonnement actif (simulé)' : 'Version gratuite : 5 épisodes'),
          _para('Abonnement : 2,99 € par mois ou 19,99 € par an, avec 7 jours d’essai gratuit.', color: OupiColors.muted),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).push(gentleRoute(const PaywallScreen())),
                child: Text(s.premium ? 'Voir l’abonnement' : 'S’abonner'),
              ),
              OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La restauration arrivera avec les achats intégrés.')),
                ),
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
        _Card(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Son', style: body(16, weight: 800)),
                value: s.sound,
                onChanged: s.setSound,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Lecture accélérée ×10 (test du prototype)', style: body(16, weight: 800)),
                subtitle: Text('Pour parcourir un épisode maquette en 30 secondes.', style: body(14, color: OupiColors.muted)),
                value: s.fastPlayback,
                onChanged: s.setFastPlayback,
              ),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Réinitialiser l’appli'),
              _para('Efface les réglages, l’historique et les épisodes vus, puis relance l’accueil des parents.',
                  color: OupiColors.muted),
              if (!_confirmReset)
                OutlinedButton(onPressed: () => setState(() => _confirmReset = true), child: const Text('Réinitialiser'))
              else
                Wrap(
                  spacing: 12,
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
                    OutlinedButton(onPressed: () => setState(() => _confirmReset = false), child: const Text('Annuler')),
                  ],
                ),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Confidentialité'),
              _para('Oupi ne crée aucun compte et ne collecte aucune donnée personnelle. Aucun outil de publicité '
                  'ou de mesure d’audience n’est intégré. Les réglages et les photos restent sur cet appareil.'),
            ],
          ),
        ),
      ],
    );
  }
}
