import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/rules/parent_gate.dart';
import '../responsive.dart';
import '../theme.dart';

/// Contrôle parental (GDD §10) : « Écris en chiffres : quarante-sept ».
/// Renvoie `true` quand le parent a répondu juste. La règle est dans [ParentGateChallenge].
class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key, this.random});

  /// Pour les tests : un générateur déterministe.
  final Random? random;

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  late final Random _random = widget.random ?? Random();
  late ParentGateChallenge _challenge = ParentGateChallenge.random(_random);
  String _typed = '';
  bool _wrong = false;

  void _press(String digit) {
    if (_typed.length >= ParentGateChallenge.digits) return;
    setState(() {
      _typed += digit;
      _wrong = false;
    });
    if (_typed.length < ParentGateChallenge.digits) return;
    if (_challenge.accepts(_typed)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _wrong = true;
        _typed = '';
        _challenge = ParentGateChallenge.random(_random);
      });
    }
  }

  void _erase() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.layout;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(l.gutter, l.gutter * 0.5, l.gutter, l.gutter * 0.5),
          child: LayoutBuilder(
            builder: (context, c) {
              final column = c.maxWidth < 640 || c.maxHeight > c.maxWidth;
              final question = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
                  Text(_challenge.question, style: display(l.isCompact ? 32 : 36)),
                  SizedBox(height: l.sp(18)),
                  Row(
                    children: [
                      for (var i = 0; i < ParentGateChallenge.digits; i++)
                        Container(
                          width: l.sp(64),
                          height: l.sp(72),
                          margin: const EdgeInsets.only(right: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _wrong ? OupiColors.bad : OupiColors.line, width: 2),
                          ),
                          child: Text(i < _typed.length ? _typed[i] : '', style: display(l.sp(34))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: _wrong ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Text('Ce n’est pas ça. Voici un nouveau nombre.', style: body(15, weight: 700, color: OupiColors.bad)),
                  ),
                ],
              );
              final keypad = _Keypad(onDigit: _press, onErase: _erase);
              if (column) {
                return Column(
                  children: [
                    Expanded(child: SingleChildScrollView(child: question)),
                    SizedBox(height: l.sp(12)),
                    // Le clavier prend au plus la moitié de la hauteur et se réduit si besoin.
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: c.maxHeight * 0.5),
                      child: FittedBox(fit: BoxFit.scaleDown, child: keypad),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: SingleChildScrollView(child: question)),
                  SizedBox(width: l.sp(16)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.maxWidth * 0.45, maxHeight: c.maxHeight),
                    child: FittedBox(fit: BoxFit.scaleDown, child: keypad),
                  ),
                ],
              );
            },
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
    final scale = context.layout.scale;
    final w = 72 * scale;
    final h = 56 * scale;
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) => Padding(
          padding: EdgeInsets.all(5 * scale),
          child: SizedBox(
            width: w,
            height: h,
            child: OutlinedButton(
              onPressed: onTap ?? () => onDigit(label),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(w, h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: Colors.white,
              ),
              child: icon != null ? Icon(icon) : Text(label, style: display(24 * scale), textScaler: TextScaler.noScaling),
            ),
          ),
        );
    return Column(
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
            SizedBox(width: w + 10 * scale),
            key('0'),
            key('effacer', onTap: onErase, icon: Icons.backspace_outlined),
          ],
        ),
      ],
    );
  }
}
