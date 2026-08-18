import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../domain/entities/incident_detail.dart';
import 'section_label.dart';

/// Incident info card: Category / Date & Time / Detected During / Location.
class IncidentInfoSection extends StatelessWidget {
  final IncidentDetail detail;

  static const Color _iconBoxBackground = Color(0xFFF0FDFA);
  static const Color _iconColor = Color(0xFF0E7C7B);
  static const Color _labelColor = Color(0xFF64748B);
  static const Color _valueColor = Color(0xFF1E293B);
  static const Color _timeColor = Color(0xFF94A3B8);
  static const Color _dividerColor = Color(0xFFEEF2F6);

  const IncidentInfoSection({super.key, required this.detail});

  String get _categoryDisplay {
    final raw = detail.categoryLabel.trim();
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  (String date, String time) get _dateTimeParts {
    final raw = detail.dateTimeLabel;
    final separators = [' • ', ' · ', '•', '·', '  •  ', '  ·  '];
    for (final sep in separators) {
      final index = raw.indexOf(sep);
      if (index != -1) {
        final date = raw.substring(0, index).trim();
        final time = raw.substring(index + sep.length).trim();
        if (date.isNotEmpty && time.isNotEmpty) return (date, time);
      }
    }
    return (raw, '');
  }

  @override
  Widget build(BuildContext context) {
    final parts = _dateTimeParts;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('INCIDENT INFORMATION'),
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
              _InfoRow(
                assetPath: 'assets/icons/staff_incidents/category.svg',
                label: 'Category',
                value: Text(
                  _categoryDisplay,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: _valueColor,
                    height: 1.25,
                  ),
                ),
              ),
              _rowDivider(context),
              _InfoRow(
                assetPath: 'assets/icons/staff_incidents/clock.svg',
                label: 'Date & Time',
                value: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parts.$1,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: _valueColor,
                        height: 1.25,
                      ),
                    ),
                    if (parts.$2.isNotEmpty) ...[
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      Text(
                        parts.$2,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: _timeColor,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _rowDivider(context),
              _InfoRow(
                assetPath: 'assets/icons/staff_incidents/detected.svg',
                label: 'Detected During',
                value: Text(
                  detail.detectedDuring,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: _valueColor,
                    height: 1.25,
                  ),
                ),
              ),
              _rowDivider(context),
              _InfoRow(
                assetPath: 'assets/icons/staff_incidents/location.svg',
                label: 'Location',
                value: Text(
                  detail.location,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: _valueColor,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
      ),
      child: const Divider(height: 1, thickness: 1, color: _dividerColor),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String assetPath;
  final String label;
  final Widget value;

  const _InfoRow({
    required this.assetPath,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: IncidentInfoSection._iconBoxBackground,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
          ),
          alignment: Alignment.center,
          child: AppSvgIcon(
            assetPath,
            size: ResponsiveHelper.getResponsiveSize(context, 18),
            color: IncidentInfoSection._iconColor,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: IncidentInfoSection._labelColor,
              height: 1.25,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: value,
          ),
        ),
      ],
    );
  }
}
