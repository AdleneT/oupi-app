import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Briques des écrans parents, d'après la charte du projet (le dashboard en est la référence) :
/// fond crème, abricot, sauge et bleu des yeux d'Oupi, titres en Fredoka, texte en Nunito,
/// cartes douces à ombre chaude, et la couture en pointillés de la feutrine.

/// Ombre chaude des cartes : un filet net puis un halo brun très diffus.
const parentShadow = [
  BoxShadow(color: Color(0x0A3B2820), offset: Offset(0, 1)),
  BoxShadow(color: Color(0x38784620), offset: Offset(0, 10), blurRadius: 26, spreadRadius: -14),
];

/// Couple de couleurs d'une pastille d'icône : fond doux et encre.
class Tone {
  const Tone(this.soft, this.ink);
  final Color soft;
  final Color ink;

  static const apricot = Tone(OupiColors.apricotSoft, OupiColors.apricotInk);
  static const sage = Tone(OupiColors.sageSoft, OupiColors.sageInk);
  static const eye = Tone(OupiColors.eyeSoft, OupiColors.eye);
  static const bad = Tone(Color(0xFFF8E1DA), OupiColors.bad);
  static const night = Tone(Color(0xFFE2E5F1), OupiColors.night);
  static const neutral = Tone(OupiColors.surface2, OupiColors.ink);
}

/// Petit intitulé en capitales, au-dessus d'un titre ou d'une valeur.
Text eyebrow(String text, {Color color = OupiColors.apricotInk, double size = 12.5}) =>
    Text(text.toUpperCase(), style: body(size, weight: 800, color: color).copyWith(letterSpacing: 1.1));

/// Icône dans une pastille arrondie, comme les puces du dashboard.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.tone = Tone.apricot, this.size = 40});
  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: tone.soft, borderRadius: BorderRadius.circular(size * 0.33)),
    child: Icon(icon, color: tone.ink, size: size * 0.55),
  );
}

/// Carte blanche de l'espace parents, avec un titre facultatif précédé de son icône.
class ParentCard extends StatelessWidget {
  const ParentCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.tone = Tone.apricot,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Tone tone;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: padding,
    decoration: BoxDecoration(
      color: OupiColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: OupiColors.line),
      boxShadow: parentShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (icon != null) ...[IconTile(icon!, tone: tone), const SizedBox(width: 12)],
              Expanded(child: Text(title!, style: display(19, weight: 600))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
        ],
        child,
      ],
    ),
  );
}

/// Couture en pointillés à l'intérieur d'un bord arrondi : le point de feutrine de la charte.
class StitchPainter extends CustomPainter {
  const StitchPainter({
    this.color = const Color(0x99F59A4F),
    this.radius = 22,
    this.inset = 9,
    this.width = 2,
    this.dash = 7,
    this.gap = 5,
  });

  final Color color;
  final double radius;
  final double inset;
  final double width;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(inset);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular((radius - inset).clamp(4, radius))));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final PathMetric m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, (d + dash).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StitchPainter old) => old.color != color || old.radius != radius || old.inset != inset;
}

/// Une valeur clé, comme les tuiles d'état du dashboard, avec une jauge facultative.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.caption, this.progress});
  final String label;
  final String value;
  final String? caption;
  final double? progress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: OupiColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: OupiColors.line),
      boxShadow: parentShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eyebrow(label, color: OupiColors.muted, size: 11.5),
        const SizedBox(height: 4),
        Text(value, style: display(26, weight: 600, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (caption != null)
          Text(
            caption!,
            style: body(13.5, color: OupiColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (progress != null) ...[const SizedBox(height: 10), SoftBar(progress!)],
      ],
    ),
  );
}

/// Jauge arrondie abricot sur fond crème.
class SoftBar extends StatelessWidget {
  const SoftBar(this.value, {super.key, this.color = OupiColors.apricot});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: SizedBox(
      height: 8,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: OupiColors.surface2),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: ColoredBox(color: color),
          ),
        ],
      ),
    ),
  );
}

/// Bloc de citation à filet sauge (la « promesse parent » du dashboard).
class PromiseBlock extends StatelessWidget {
  const PromiseBlock({super.key, required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: OupiColors.sageSoft.withValues(alpha: 0.7),
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
      border: const Border(left: BorderSide(color: OupiColors.sage, width: 4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eyebrow(label, color: OupiColors.sageInk, size: 11.5),
        const SizedBox(height: 2),
        Text(text, style: body(16, weight: 600)),
      ],
    ),
  );
}

/// Petite étiquette arrondie (statut, durée, matériel).
class SoftChip extends StatelessWidget {
  const SoftChip(this.text, {super.key, this.icon, this.tone = Tone.sage, this.dot});
  final String text;
  final IconData? icon;
  final Tone tone;

  /// Pastille de couleur à gauche du texte (couleur d'une famille d'épisodes).
  final Color? dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: tone.soft, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
        ],
        if (icon != null) ...[Icon(icon, size: 16, color: tone.ink), const SizedBox(width: 6)],
        Flexible(
          child: Text(
            text,
            style: body(13.5, weight: 700, color: tone.ink),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// Choix unique en pastilles arrondies : la pastille choisie passe en abricot doux, cochée.
/// Sur fond de nuit ([onNight]), les pastilles sont translucides et la choisie prend la couleur de la lune.
class ChoicePills<T> extends StatelessWidget {
  const ChoicePills({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.recommended,
    this.onNight = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  /// La valeur conseillée, signalée par une petite étiquette sauge.
  final T? recommended;
  final bool onNight;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final v in values)
        _Pill(
          text: label(v),
          selected: v == selected,
          recommended: v == recommended,
          onNight: onNight,
          onTap: () {
            if (v == selected) return;
            HapticFeedback.selectionClick();
            onSelected(v);
          },
        ),
    ],
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.selected,
    required this.recommended,
    required this.onNight,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool recommended;
  final bool onNight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg, border, ink;
    if (onNight) {
      bg = selected ? Vivid.moon : Colors.white.withValues(alpha: 0.1);
      border = selected ? Vivid.moon : Colors.white.withValues(alpha: 0.32);
      ink = selected ? OupiColors.ink : OupiColors.onNight;
    } else {
      bg = selected ? OupiColors.apricotSoft : OupiColors.surface;
      border = selected ? OupiColors.apricot : OupiColors.lineStrong;
      ink = selected ? OupiColors.apricotInk : OupiColors.ink;
    }
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
            padding: EdgeInsets.only(left: selected ? 14 : 18, right: 18),
            decoration: ShapeDecoration(
              color: bg,
              shape: StadiumBorder(
                side: BorderSide(color: border, width: selected ? 2 : 1.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[Icon(Icons.check_rounded, size: 18, color: ink), const SizedBox(width: 6)],
                Text(
                  text,
                  style: body(16, weight: selected ? 800 : 700, color: ink),
                ),
                if (recommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: onNight ? Colors.white.withValues(alpha: 0.16) : OupiColors.sageSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'conseillé',
                      style: body(
                        12,
                        weight: 800,
                        color: onNight && !selected ? OupiColors.onNight : OupiColors.sageInk,
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
  }
}

/// Ligne de réglage avec un interrupteur : pastille d'icône, intitulé, explication.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.tone = Tone.apricot,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Tone tone;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            IconTile(icon, tone: tone),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: body(16, weight: 800)),
                  if (subtitle != null) Text(subtitle!, style: body(14, color: OupiColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    ),
  );
}

/// Visage d'Oupi dans un carré arrondi, recadré dans la pose debout (le logo du dashboard).
class OupiAvatar extends StatelessWidget {
  const OupiAvatar({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: OupiColors.cream,
      borderRadius: BorderRadius.circular(size * 0.34),
      border: Border.all(color: OupiColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: OverflowBox(
      maxWidth: size * 1.6,
      maxHeight: size * 1.6 * 800 / 592,
      alignment: const Alignment(0, -0.36),
      child: Image.asset('assets/images/oupi_idle.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
    ),
  );
}
