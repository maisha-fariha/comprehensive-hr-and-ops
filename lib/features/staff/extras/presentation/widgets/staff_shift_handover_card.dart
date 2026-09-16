import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_shift_handover.dart';

/// Shift handover list card matching the Staff reference design.
class StaffShiftHandoverCard extends StatelessWidget {
  final StaffShiftHandover handover;
  final String? residenceFallback;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const StaffShiftHandoverCard({
    super.key,
    required this.handover,
    this.residenceFallback,
    this.onAcknowledge,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      handover.displayResidence(residenceFallback),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          15.5,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: [
                      if (handover.isAcknowledged)
                        const _Chip(
                          label: 'Acknowledged',
                          background: Color(0xFFEAF6F0),
                          foreground: Color(0xFF2E8C58),
                        ),
                      if (handover.attentionLabel.isNotEmpty)
                        _Chip(
                          label: handover.attentionLabel,
                          background: const Color(0xFFFCE8E8),
                          foreground: const Color(0xFFC62828),
                        ),
                    ],
                  ),
                ],
              ),
              if (handover.authorMeta.isNotEmpty) ...[
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Text(
                  handover.authorMeta,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12.5,
                    ),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (handover.summary.isNotEmpty) ...[
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                Text(
                  handover.summary,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      14,
                    ),
                    color: AppColors.textHeading,
                    height: 1.4,
                  ),
                ),
              ],
              if (handover.clientNames.isNotEmpty) ...[
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in handover.clientNames)
                      _Chip(
                        label: name,
                        background: const Color(0xFFFBF1E6),
                        foreground: const Color(0xFFB4791C),
                      ),
                  ],
                ),
              ],
              if (handover.pendingActions.isNotEmpty) ...[
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                for (final action in handover.pendingActions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $action',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              const Divider(height: 1, color: AppColors.dividerLight),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      handover.acknowledgementFooter.isEmpty
                          ? 'No acknowledgements yet'
                          : handover.acknowledgementFooter,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onAcknowledge != null)
                    OutlinedButton(
                      onPressed: onAcknowledge,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textHeading,
                        side: const BorderSide(color: AppColors.searchBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        "I've read and taken this",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.searchBorder),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.criticalRed,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: foreground,
        ),
      ),
    );
  }
}
