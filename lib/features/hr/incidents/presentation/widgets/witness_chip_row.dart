import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../incidents_constants.dart';

/// "Witness Information" chip wrap on the wizard's "People" step: one
/// filled/selected chip per added witness (with a checkmark + remove-on-tap)
/// plus a dashed-outline "+ Add witness" chip.
class WitnessChipRow extends StatelessWidget {
  final List<String> witnesses;
  final VoidCallback onAddWitness;
  final ValueChanged<String> onRemoveWitness;

  const WitnessChipRow({
    super.key,
    required this.witnesses,
    required this.onAddWitness,
    required this.onRemoveWitness,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ResponsiveHelper.getResponsiveWidth(context, 10),
      runSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
      children: [
        for (final witness in witnesses)
          _SelectedWitnessChip(name: witness, onTap: () => onRemoveWitness(witness)),
        _AddWitnessChip(onTap: onAddWitness),
      ],
    );
  }
}

class _SelectedWitnessChip extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _SelectedWitnessChip({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: IncidentsColors.evidenceAccentBackground,
          border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: ResponsiveHelper.getResponsiveSize(context, 15), color: AppColors.secondaryTeal),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Text(
              name,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.secondaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWitnessChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddWitnessChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DottedBorderChip(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: ResponsiveHelper.getResponsiveSize(context, 15), color: AppColors.secondaryTeal),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Text(
              'Add witness',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.secondaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin dashed-border pill "shell" reused for the "+ Add witness" chip.
/// Flutter has no built-in dashed border, so this hand-paints one with a
/// `CustomPainter` instead of approximating with a solid border.
class DottedBorderChip extends StatelessWidget {
  final Widget child;

  const DottedBorderChip({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: AppColors.secondaryTeal.withValues(alpha: 0.5)),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 9),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;

  const _DashedRRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(999));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const dashWidth = 4.0;
    const dashGap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) => oldDelegate.color != color;
}
