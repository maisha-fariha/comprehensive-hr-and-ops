import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../daily_logs_constants.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../../domain/entities/handover_entry.dart';
import '../../domain/entities/handover_note.dart';

/// A single card in the Handover tab's "Handover Timeline" list — matched
/// to the "Handover - Daily-logs" Figma reference.
class HandoverEntryCard extends StatelessWidget {
  final HandoverEntry entry;
  final VoidCallback? onAcknowledge;

  const HandoverEntryCard({
    super.key,
    required this.entry,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final accentColor =
        entry.isUrgent ? AppColors.criticalRed : AppColors.secondaryTeal;
    final accentWidth = ResponsiveHelper.getResponsiveWidth(context, 4);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.03),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: accentWidth, color: accentColor),
            Expanded(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderRow(entry: entry),
                    if (entry.fromStaffName != null &&
                        entry.toStaffName != null) ...[
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      _FromToRow(entry: entry),
                    ],
                    if (entry.notes.isNotEmpty) ...[
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      Text(
                        'IMPORTANT NOTES',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            10,
                          ),
                          color: AppColors.textFaint,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 10),
                      ),
                      for (var i = 0; i < entry.notes.length; i++) ...[
                        if (i != 0)
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              10,
                            ),
                          ),
                        _NoteRow(note: entry.notes[i]),
                      ],
                    ],
                    if (entry.acknowledgementCaption != null) ...[
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      _AcknowledgementRow(
                        caption: entry.acknowledgementCaption!,
                        onAcknowledge: onAcknowledge,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: shift pills + Urgent / Routine tag
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  final HandoverEntry entry;

  const _HeaderRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Row(
            children: [
              Flexible(child: _ShiftChip(label: entry.fromShiftLabel)),
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 6,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 14),
                  color: AppColors.secondaryTeal,
                ),
              ),
              Flexible(child: _ShiftChip(label: entry.toShiftLabel)),
            ],
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        if (entry.isUrgent)
          const _StatusTag(
            label: 'Urgent',
            background: AppColors.criticalIconBackground,
            foreground: AppColors.criticalRed,
            iconAsset: AppAssets.alertTriangle,
          )
        else if (entry.tagLabel != null)
          _StatusTag(
            label: entry.tagLabel!.replaceFirst(RegExp(r'^\$\s*'), ''),
            background: AppColors.activeBackground,
            foreground: AppColors.activeGreen,
            iconAsset: 'assets/icons/daily_logs/dollar.svg',
          ),
      ],
    );
  }
}

class _ShiftChip extends StatelessWidget {
  final String label;

  const _ShiftChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 8),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          color: AppColors.textHeading,
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final String? iconAsset;

  const _StatusTag({
    required this.label,
    required this.background,
    required this.foreground,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 999),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            AppSvgIcon(iconAsset!, size: 11, color: foreground),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: foreground,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FROM → TO staff row
// ─────────────────────────────────────────────────────────────────────────────

class _FromToRow extends StatelessWidget {
  final HandoverEntry entry;

  const _FromToRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PersonChip(
            roleLabel: 'FROM',
            initials: entry.fromStaffInitials!,
            name: entry.fromStaffName!,
            colorPair: DailyLogsConstants.avatarPalette[0],
          ),
        ),
        Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 14),
            color: AppColors.iconChevron,
          ),
        ),
        Expanded(
          child: _PersonChip(
            roleLabel: 'TO',
            initials: entry.toStaffInitials!,
            name: entry.toStaffName!,
            colorPair: DailyLogsConstants.avatarPalette[2],
          ),
        ),
      ],
    );
  }
}

class _PersonChip extends StatelessWidget {
  final String roleLabel;
  final String initials;
  final String name;
  final AvatarColorPair colorPair;

  const _PersonChip({
    required this.roleLabel,
    required this.initials,
    required this.name,
    required this.colorPair,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 28);

    return Row(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: colorPair.background,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
              color: colorPair.foreground,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$roleLabel ',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      11,
                    ),
                    color: AppColors.textMuted,
                  ),
                ),
                TextSpan(
                  text: name,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12.5,
                    ),
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Important notes
// ─────────────────────────────────────────────────────────────────────────────

class _NoteRow extends StatelessWidget {
  final HandoverNote note;

  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    final (iconWidget, iconBg) = _iconFor(context, note.type);
    final boxSize = ResponsiveHelper.getResponsiveSize(context, 28);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 8),
            ),
          ),
          alignment: Alignment.center,
          child: iconWidget,
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${note.title} — ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
                TextSpan(
                  text: note.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  (Widget, Color) _iconFor(BuildContext context, HandoverNoteType type) {
    switch (type) {
      case HandoverNoteType.medication:
        return (
          AppSvgIcon(
            AppAssets.pill,
            size: 14,
            color: AppColors.criticalRed,
          ),
          AppColors.criticalIconBackground,
        );
      case HandoverNoteType.observation:
        return (
          Icon(
            Icons.visibility_outlined,
            size: ResponsiveHelper.getResponsiveSize(context, 14),
            color: AppColors.urgentAmber,
          ),
          AppColors.urgentIconBackground,
        );
      case HandoverNoteType.task:
        return (
          AppSvgIcon(
            AppAssets.clipboardCheck,
            size: 14,
            color: AppColors.infoBlue,
          ),
          AppColors.infoIconBackground,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Acknowledgement footer
// ─────────────────────────────────────────────────────────────────────────────

class _AcknowledgementRow extends StatelessWidget {
  final String caption;
  final VoidCallback? onAcknowledge;

  const _AcknowledgementRow({
    required this.caption,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: ResponsiveHelper.getResponsiveSize(context, 7),
          height: ResponsiveHelper.getResponsiveSize(context, 7),
          decoration: const BoxDecoration(
            color: AppColors.urgentAmber,
            shape: BoxShape.circle,
          ),
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
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.urgentAmber,
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        GestureDetector(
          onTap: onAcknowledge,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 15),
                  color: Colors.white,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                Text(
                  'Acknowledge',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12.5,
                    ),
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
