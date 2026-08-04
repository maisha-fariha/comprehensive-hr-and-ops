import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../incidents_constants.dart';

/// "Witness Information" chip wrap on the wizard's "People" step: one
/// filled/selected chip per added witness (checkmark + name) plus a dashed
/// outline "+ Add witness" chip — matched to the Step 2 reference.
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
      crossAxisAlignment: WrapCrossAlignment.center,
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
    final radius = ResponsiveHelper.getResponsiveRadius(context, 999);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.getResponsiveWidth(context, 153),
        ),
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: IncidentsColors.evidenceAccentBackground,
          border: Border.all(color: AppColors.secondaryTeal),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 15),
              color: AppColors.secondaryTeal,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.secondaryTeal,
                ),
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

  /// Light muted teal for the dashed outline (reference ~#A8DADA).
  static const Color _borderTeal = Color(0xFFA8DADA);

  /// Foreground teal for icon + label (reference ~#1D7F7D).
  static const Color _foregroundTeal = Color(0xFF1D7F7D);

  const _AddWitnessChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DottedBorderChip(
        borderColor: _borderTeal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 16),
              color: _foregroundTeal,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            Text(
              'Add witness',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: _foregroundTeal,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stadium-shaped white chip shell with a light dashed teal border.
class DottedBorderChip extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const DottedBorderChip({
    super.key,
    required this.child,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      // Draw dashes above the fill so the outline stays visible.
      foregroundPainter: _DashedStadiumPainter(color: borderColor),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: StadiumBorder()),
        child: ColoredBox(
          color: AppColors.surfaceWhite,
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 16,
              vertical: 10,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DashedStadiumPainter extends CustomPainter {
  final Color color;

  const _DashedStadiumPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // True stadium: corner radius = half the chip height.
    final radius = size.height / 2;
    final inset = 0.75;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    const dashWidth = 3.5;
    const dashGap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedStadiumPainter oldDelegate) =>
      oldDelegate.color != color;
}
