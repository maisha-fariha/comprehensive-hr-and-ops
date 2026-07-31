import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../daily_logs_constants.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/handover_entry.dart';
import '../../domain/entities/handover_note.dart';
import 'initials_avatar.dart';

class _NoteStyle {
  final String svgAsset;
  final Color iconColor;
  final Color iconBackground;

  const _NoteStyle({required this.svgAsset, required this.iconColor, required this.iconBackground});
}

// The "observation" note type has no matching eye-glyph SVG in
// `assets/icons/*` - `Icons.visibility_rounded` is used as a temporary
// stand-in there (flagged in the final report).
const Map<HandoverNoteType, _NoteStyle> _noteIconStyles = {
  HandoverNoteType.medication: _NoteStyle(
    svgAsset: AppAssets.pill,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  HandoverNoteType.task: _NoteStyle(
    svgAsset: AppAssets.clipboardCheck,
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.infoIconBackground,
  ),
};

/// A single card in the Handover tab's "Handover Timeline" list.
///
/// Renders a colored left accent bar, a "From → To" shift-transition
/// header, an optional FROM/TO staff row, an optional bulleted
/// "Important Notes" list, and an optional acknowledgement caption/button.
class HandoverEntryCard extends StatelessWidget {
  final HandoverEntry entry;
  final VoidCallback? onAcknowledge;

  const HandoverEntryCard({super.key, required this.entry, this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusCard);
    final accentColor = entry.isUrgent ? AppColors.criticalRed : AppColors.cardBorder;

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 12)),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowNavy.withValues(alpha: 0.04),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
            ),
            BoxShadow(
              color: AppColors.shadowNavy.withValues(alpha: 0.04),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveWidth(context, DailyLogsConstants.handoverAccentBarWidth),
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderRow(entry: entry),
                      if (entry.fromStaffName != null && entry.toStaffName != null) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                        _FromToRow(entry: entry),
                      ],
                      if (entry.notes.isNotEmpty) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                        Text(
                          'Important Notes',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                        for (var i = 0; i < entry.notes.length; i++) ...[
                          if (i != 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                          _NoteRow(note: entry.notes[i]),
                        ],
                      ],
                      if (entry.acknowledgementCaption != null) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                        _AcknowledgementRow(caption: entry.acknowledgementCaption!, onAcknowledge: onAcknowledge),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final HandoverEntry entry;

  const _HeaderRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: entry.fromShiftLabel),
                const TextSpan(text: '  →  '),
                TextSpan(text: entry.toShiftLabel),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (entry.isUrgent)
          const StatusBadge.chip(
            label: 'Urgent',
            background: AppColors.criticalBackgroundSoft,
            foreground: AppColors.criticalRed,
          )
        else if (entry.tagLabel != null)
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.quickActionCreateShiftBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              entry.tagLabel!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
      ],
    );
  }
}

class _FromToRow extends StatelessWidget {
  final HandoverEntry entry;

  const _FromToRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PersonColumn(
            label: 'FROM',
            initials: entry.fromStaffInitials!,
            name: entry.fromStaffName!,
            colorPair: DailyLogsConstants.avatarPalette[0],
          ),
        ),
        Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 8),
          child: Text(
            '→',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: AppColors.textFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: _PersonColumn(
            label: 'TO',
            initials: entry.toStaffInitials!,
            name: entry.toStaffName!,
            colorPair: DailyLogsConstants.avatarPalette[2],
          ),
        ),
      ],
    );
  }
}

class _PersonColumn extends StatelessWidget {
  final String label;
  final String initials;
  final String name;
  final AvatarColorPair colorPair;

  const _PersonColumn({
    required this.label,
    required this.initials,
    required this.name,
    required this.colorPair,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9.5),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
        Row(
          children: [
            InitialsAvatar(
              initials: initials,
              background: colorPair.background,
              foreground: colorPair.foreground,
              size: 24,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  final HandoverNote note;

  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    final style = _noteIconStyles[note.type];
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 20);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: style?.iconBackground ?? AppColors.urgentIconBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: style != null
              ? AppSvgIcon(style.svgAsset, size: 11, color: style.iconColor)
              : Icon(Icons.visibility_rounded, size: ResponsiveHelper.getResponsiveSize(context, 11), color: AppColors.urgentAmber),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${note.title} — ',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: note.description,
                  style: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.textBody),
                ),
              ],
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _AcknowledgementRow extends StatelessWidget {
  final String caption;
  final VoidCallback? onAcknowledge;

  const _AcknowledgementRow({required this.caption, this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: ResponsiveHelper.getResponsiveSize(context, 6),
          height: ResponsiveHelper.getResponsiveSize(context, 6),
          decoration: const BoxDecoration(color: AppColors.urgentAmber, shape: BoxShape.circle),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
        Expanded(
          child: Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
              color: AppColors.urgentAmber,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        GestureDetector(
          onTap: onAcknowledge,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusButton)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppSvgIcon(AppAssets.checkCircle, size: 13, color: Colors.white),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                Text(
                  'Acknowledge',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
