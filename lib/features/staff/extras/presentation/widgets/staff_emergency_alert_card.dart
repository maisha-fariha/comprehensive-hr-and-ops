import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_emergency_alert.dart';

/// Emergency list card matching the Staff Emergency reference.
class StaffEmergencyAlertCard extends StatelessWidget {
  final StaffEmergencyAlert alert;
  final VoidCallback? onOpen;

  const StaffEmergencyAlertCard({
    super.key,
    required this.alert,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final active = alert.isActive;
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFF8F8) : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(
          color: active ? const Color(0xFFE57373) : AppColors.cardBorder,
          width: active ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusChip(label: alert.statusLabel, active: alert.isActive),
              if (alert.priorityLabel.isNotEmpty)
                _PriorityChip(label: alert.priorityLabel),
              _CategoryChip(label: alert.typeLabel),
              if (alert.residenceName.isNotEmpty)
                Text(
                  alert.residenceName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      13.5,
                    ),
                    color: AppColors.textHeading,
                  ),
                ),
            ],
          ),
          if (alert.raisedMeta.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Text(
              alert.raisedMeta,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (alert.timeLabel.isNotEmpty)
            Text(
              alert.timeLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textSecondary,
              ),
            ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          OutlinedButton(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textHeading,
              backgroundColor: AppColors.surfaceWhite,
              side: const BorderSide(color: AppColors.searchBorder),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (alert.note.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              alert.note,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textHeading,
                height: 1.4,
              ),
            ),
          ],
          if (alert.locationNote.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            Text(
              alert.locationNote,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (alert.houseLine.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Text(
              'House line: ${alert.houseLine}',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFFCE8E8) : const Color(0xFFEEF1F4);
    final fg = active ? const Color(0xFFC62828) : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;

  const _PriorityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Color(0xFFB4791C),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.textBody,
        ),
      ),
    );
  }
}
