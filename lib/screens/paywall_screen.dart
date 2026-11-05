import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme.dart';

/// Abonnement, côté parent uniquement (on y arrive toujours après le contrôle parental).
/// Décision du 4 nov. 2026 : abonnement dès le lancement, 2,99 €/mois ou 19,99 €/an, essai de 7 jours.
///
/// Prototype : aucun paiement réel. Les achats intégrés natifs (`in_app_purchase`) restent à brancher.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearly = true;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded), tooltip: 'Fermer'),
              Text('ABONNEMENT', style: body(13, weight: 800, color: OupiColors.apricotInk)),
              const SizedBox(height: 6),
              Text(state.premium ? 'Vous êtes abonné.' : 'Tous les épisodes d’Oupi, sans publicité.', style: display(30)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in const [
                          'Les 10 épisodes, puis les nouveaux dès leur sortie',
                          'Toutes les chansons dans le juke-box, à tout moment',
                          'Toutes les fiches activités et les PDF à imprimer',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: OupiColors.leaf, size: 22),
                                const SizedBox(width: 10),
                                Expanded(child: Text(line, style: body(16))),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Le contrôle du temps d’écran reste gratuit, et il n’y a jamais de publicité.',
                          style: body(14, color: OupiColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _Plan(
                          selected: !_yearly,
                          title: 'Mensuel',
                          price: '2,99 € / mois',
                          onTap: () => setState(() => _yearly = false),
                        ),
                        const SizedBox(height: 10),
                        _Plan(
                          selected: _yearly,
                          title: 'Annuel',
                          price: '19,99 € / an',
                          note: 'Le plus avantageux',
                          onTap: () => setState(() => _yearly = true),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.premium
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(context);
                                    await state.setPremium(true);
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Abonnement simulé : tous les épisodes sont débloqués.')),
                                    );
                                    navigator.pop();
                                  },
                            child: const Text('Commencer l’essai gratuit de 7 jours'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prototype : aucun paiement réel n’est effectué.',
                          style: body(13, weight: 700, color: OupiColors.muted),
                        ),
                      ],
                    ),
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

class _Plan extends StatelessWidget {
  const _Plan({required this.selected, required this.title, required this.price, required this.onTap, this.note});
  final bool selected;
  final String title;
  final String price;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? OupiColors.apricotSoft : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: selected ? OupiColors.apricot : OupiColors.line, width: 2),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? OupiColors.apricotInk : OupiColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: body(16, weight: 800)),
                  if (note != null) Text(note!, style: body(13, weight: 700, color: OupiColors.sageInk)),
                ],
              ),
            ),
            Text(price, style: display(20)),
          ],
        ),
      ),
    ),
  );
}
