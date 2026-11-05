import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../util/french_numbers.dart';

/// Contrôle parental (GDD §10) : une question qu'un enfant de 3 à 5 ans ne peut pas résoudre.
/// Renvoie `true` quand le parent a répondu juste.
class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key, this.random});

  /// Pour les tests : un générateur déterministe.
  final Random? random;

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  late final Random _random = widget.random ?? Random();
  late int _target = _newTarget();
  String _typed = '';
  bool _wrong = false;

  int _newTarget() => 21 + _random.nextInt(79); // 21 à 99 : deux chiffres, écrits en toutes lettres.

  void _press(String digit) {
    if (_typed.length >= 2) return;
    setState(() {
      _typed += digit;
      _wrong = false;
    });
    if (_typed.length == 2) {
      if (int.parse(_typed) == _target) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _wrong = true;
          _typed = '';
          _target = _newTarget();
        });
      }
    }
  }

  void _erase() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Fermer',
                    ),
                    const SizedBox(height: 8),
                    Text('ESPACE PARENTS', style: body(13, weight: 800, color: OupiColors.apricotInk)),
                    const SizedBox(height: 6),
                    Text('Écris en chiffres :', style: body(18, color: OupiColors.muted)),
                    const SizedBox(height: 4),
                    Text(frenchNumber(_target), style: display(36)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        for (var i = 0; i < 2; i++)
                          Container(
                            width: 64,
                            height: 72,
                            margin: const EdgeInsets.only(right: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _wrong ? OupiColors.bad : OupiColors.line, width: 2),
                            ),
                            child: Text(i < _typed.length ? _typed[i] : '', style: display(34)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedOpacity(
                      opacity: _wrong ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        'Ce n’est pas ça. Voici un nouveau nombre.',
                        style: body(15, weight: 700, color: OupiColors.bad),
                      ),
                    ),
                  ],
                ),
              ),
              _Keypad(onDigit: _press, onErase: _erase),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onErase});
  final ValueChanged<String> onDigit;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) => Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: 72,
        height: 56,
        child: OutlinedButton(
          onPressed: onTap ?? () => onDigit(label),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(72, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
          ),
          child: icon != null ? Icon(icon) : Text(label, style: display(24)),
        ),
      ),
    );
    return FittedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) key(d)]),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 82),
              key('0'),
              key('effacer', onTap: onErase, icon: Icons.backspace_outlined),
            ],
          ),
        ],
      ),
    );
  }
}
