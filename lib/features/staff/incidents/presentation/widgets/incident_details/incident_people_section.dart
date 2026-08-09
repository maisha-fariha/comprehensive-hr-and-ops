import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/incident_detail.dart';
import 'section_label.dart';

/// "PEOPLE" section: resident, reporter, and assigned reviewer rows.
class IncidentPeopleSection extends StatelessWidget {
  final IncidentDetail detail;

  static const Color _labelColor = Color(0xFF94A3B8);
  static const Color _valueColor = Color(0xFF1E293B);
  static const Color _dividerColor = Color(0xFFEEF2F6);

  /// Assigned Reviewer is not on [IncidentDetail] yet — local UI mock to
  /// match the details reference until the model is extended.
  static const String _reviewerInitials = 'SN';
  static const String _reviewerName = 'Susan N.';
  static const String _reviewerRole = 'Shift Supervisor';

  static const List<({Color background, Color foreground})> _avatarColors = [
    (background: Color(0xFFFCE7F3), foreground: Color(0xFFDB2777)),
    (background: Color(0xFFDBEAFE), foreground: Color(0xFF2563EB)),
    (background: Color(0xFFEDE9FE), foreground: Color(0xFF7C3AED)),
  ];

  const IncidentPeopleSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final gap = ResponsiveHelper.getResponsiveWidth(context, 12);
    final dividerIndent = avatarSize + gap;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 24);

    final rows = [
      _PersonData(
        initials: detail.residentInitials,
        label: 'Resident / Client',
        name: detail.residentName,
        subLabel: detail.residentSubLabel,
        paletteIndex: 0,
      ),
      _PersonData(
        initials: detail.reportedByInitials,
        label: 'Reported By',
        name: detail.reportedByName,
        subLabel: detail.reportedBySubLabel,
        paletteIndex: 1,
      ),
      const _PersonData(
        initials: _reviewerInitials,
        label: 'Assigned Reviewer',
        name: _reviewerName,
        subLabel: _reviewerRole,
        paletteIndex: 2,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('PEOPLE'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.04),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: EdgeInsets.only(
                      left: dividerIndent,
                      top: ResponsiveHelper.getResponsiveHeight(context, 14),
                      bottom: ResponsiveHelper.getResponsiveHeight(context, 14),
                    ),
                    child: const Divider(height: 1, thickness: 1, color: _dividerColor),
                  ),
                _PersonRow(
                  data: rows[i],
                  avatarSize: avatarSize,
                  gap: gap,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonData {
  final String initials;
  final String label;
  final String name;
  final String subLabel;
  final int paletteIndex;

  const _PersonData({
    required this.initials,
    required this.label,
    required this.name,
    required this.subLabel,
    required this.paletteIndex,
  });
}

class _PersonRow extends StatelessWidget {
  final _PersonData data;
  final double avatarSize;
  final double gap;

  const _PersonRow({
    required this.data,
    required this.avatarSize,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = IncidentPeopleSection._avatarColors[
        data.paletteIndex % IncidentPeopleSection._avatarColors.length];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: colors.background,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            data.initials,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: colors.foreground,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: IncidentPeopleSection._labelColor,
                  height: 1.25,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: data.name),
                    TextSpan(
                      text: '  •  ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: IncidentPeopleSection._labelColor,
                      ),
                    ),
                    TextSpan(text: data.subLabel),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: IncidentPeopleSection._valueColor,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
