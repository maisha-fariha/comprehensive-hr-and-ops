import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/medication_dose.dart';
import 'medication_count_badge.dart';
import 'medication_dose_row.dart';

/// The Overview tab's "Due Today" card: a title + count badge, up to 3
/// medication rows, and a "+N more medications due / View all" row when
/// there are additional doses not shown inline.
class DueTodaySection extends StatelessWidget {
  final List<MedicationDose> doses;
  final int moreCount;
  final VoidCallback? onViewAll;
  final ValueChanged<MedicationDose>? onDoseTap;

  const DueTodaySection({
    super.key,
    required this.doses,
    required this.moreCount,
    this.onViewAll,
    this.onDoseTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, left: 17, right: 17, top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderRow(
            title: 'Due Today',
            trailing: MedicationCountBadge(
              count: doses.length + moreCount,
              background: AppColors.infoBackground,
              foreground: AppColors.infoBlue,
            ),
          ),
          for (var i = 0; i < doses.length; i++)
            MedicationDoseRow(
              dose: doses[i],
              showDivider: i != doses.length - 1 || moreCount > 0,
              onTap: onDoseTap == null ? null : () => onDoseTap!(doses[i]),
            ),
          if (moreCount > 0)
            GestureDetector(
              onTap: onViewAll,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, top: 12, bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 22),
                      height: ResponsiveHelper.getResponsiveSize(context, 22),
                      decoration: const BoxDecoration(
                        color: AppColors.infoBackground,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add_rounded,
                        size: ResponsiveHelper.getResponsiveSize(context, 14),
                        color: AppColors.infoBlue,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                    Expanded(
                      child: Text(
                        '$moreCount more medications due',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      'View all',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                        color: AppColors.secondaryTeal,
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
}
