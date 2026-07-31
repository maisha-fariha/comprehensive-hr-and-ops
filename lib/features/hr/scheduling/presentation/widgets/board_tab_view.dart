import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/board_overview.dart';
import '../../domain/entities/board_shift.dart';
import '../../domain/entities/coverage_summary.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/staff_avatar.dart';
import '../../scheduling_constants.dart';

/// The Board tab's content: "Today's Coverage" summary tiles and the
/// "Coverage Board" shift cards — matched to the Figma reference.
class BoardTabView extends StatelessWidget {
  final BoardOverview data;

  const BoardTabView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final horizontalPad = ResponsiveHelper.getResponsiveWidth(
      context,
      SchedulingDimens.screenPaddingHorizontal,
    );

    return ColoredBox(
      color: AppColors.scaffoldBackground,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPad,
          ResponsiveHelper.getResponsiveHeight(context, 18),
          horizontalPad,
          ResponsiveHelper.getResponsiveHeight(context, 24),
        ),
        children: [
          _SectionTitle(title: "Today's Coverage"),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < data.coverageSummaries.length; i++) ...[
                  if (i != 0)
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
                  Expanded(
                    child: _CoverageTile(summary: data.coverageSummaries[i]),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
          _SectionTitle(title: 'Coverage Board'),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          for (var i = 0; i < data.shifts.length; i++) ...[
            if (i != 0)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            _BoardShiftCard(shift: data.shifts[i]),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
        color: AppColors.textHeading,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _CoverageStyle {
  final Color accent;
  final Color background;

  const _CoverageStyle({required this.accent, required this.background});
}

_CoverageStyle _statusStyle(CoverageStatus status) {
  switch (status) {
    case CoverageStatus.almostFull:
      return const _CoverageStyle(
        accent: AppColors.urgentAmber,
        background: AppColors.urgentBackground,
      );
    case CoverageStatus.needsAttention:
      return const _CoverageStyle(
        accent: AppColors.criticalRed,
        background: AppColors.criticalBackground,
      );
  }
}

List<BoxShadow> _cardShadow(BuildContext context) => [
      BoxShadow(
        color: AppColors.shadowNavy.withValues(alpha: 0.04),
        offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
        blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
      ),
    ];

// ─────────────────────────────────────────────────────────────────────────────
// Today's Coverage tile
// ─────────────────────────────────────────────────────────────────────────────

class _CoverageTile extends StatelessWidget {
  final CoverageSummary summary;

  const _CoverageTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(summary.status);
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 8);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: _cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: style.accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Expanded(
                child: Text(
                  summary.periodLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            summary.ratioLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              color: AppColors.textHeading,
              letterSpacing: -0.4,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            summary.statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: style.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coverage Board shift card
// ─────────────────────────────────────────────────────────────────────────────

class _BoardShiftCard extends StatelessWidget {
  final BoardShift shift;

  const _BoardShiftCard({required this.shift});

  static const _roleChipStyles = <String, (Color, Color)>{
    'RN': (Color(0xFFE8F1FB), Color(0xFF2A5DA6)),
    'CNA': (Color(0xFFEAF6F0), Color(0xFF2E8C58)),
    'Caregiver': (Color(0xFFF0ECFB), Color(0xFF6A4BC7)),
  };

  static const _avatarPalettes = <String, (Color, Color)>{
    'SJ': (Color(0xFFE6F0FF), Color(0xFF1E3A5F)),
    'MT': (Color(0xFFE6F6EC), Color(0xFF15803D)),
    'PK': (Color(0xFFF0E6FF), Color(0xFF6D28D9)),
    'JL': (Color(0xFFE6F4F1), Color(0xFF0D9488)),
    'NP': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'TM': (Color(0xFFE0E7FF), Color(0xFF4338CA)),
    'DS': (Color(0xFFFCE7F3), Color(0xFFBE185D)),
  };

  static const _fallbackAvatar = (Color(0xFFE6F0FF), Color(0xFF1E3A5F));
  static const _fallbackRole = (Color(0xFFEEF1F5), Color(0xFF647285));

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(shift.status);
    final fill = (shift.filled / shift.total).clamp(0.0, 1.0);
    final barHeight = ResponsiveHelper.getResponsiveHeight(context, 7);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 20),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: _cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shift.periodLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                    Text(
                      shift.timeRange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '${shift.filled} ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                          color: style.accent,
                        ),
                      ),
                      Text(
                        '/ ${shift.total}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
                          color: AppColors.textHeading,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Text(
                    shift.statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                      color: style.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: barHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFFEDF2F7)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    child: ColoredBox(color: style.accent),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          Row(
            children: [
              _AvatarStack(
                avatars: shift.avatars,
                extraCount: shift.extraStaffCount,
                palettes: _avatarPalettes,
                fallback: _fallbackAvatar,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Wrap(
                spacing: ResponsiveHelper.getResponsiveWidth(context, 6),
                runSpacing: ResponsiveHelper.getResponsiveHeight(context, 6),
                alignment: WrapAlignment.end,
                children: [
                  for (final role in shift.roleChips)
                    _RoleChip(
                      label: role,
                      colors: _roleChipStyles[role] ?? _fallbackRole,
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 7),
                height: ResponsiveHelper.getResponsiveSize(context, 7),
                decoration: BoxDecoration(
                  color: style.accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: Text(
                  shift.neededLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              const _FillButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final (Color, Color) colors;

  const _RoleChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: colors.$2,
          height: 1,
        ),
      ),
    );
  }
}

class _FillButton extends StatelessWidget {
  const _FillButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.quickActionCreateShiftBg,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 15),
            color: AppColors.secondaryTeal,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 2)),
          Text(
            'Fill',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.secondaryTeal,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<StaffAvatar> avatars;
  final int extraCount;
  final Map<String, (Color, Color)> palettes;
  final (Color, Color) fallback;

  const _AvatarStack({
    required this.avatars,
    required this.extraCount,
    required this.palettes,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(
      context,
      SchedulingDimens.boardAvatarSize - 4,
    );
    final overlap = ResponsiveHelper.getResponsiveWidth(context, 10);
    final bubbleCount = avatars.length + (extraCount > 0 ? 1 : 0);
    final totalWidth =
        size + (bubbleCount > 1 ? (bubbleCount - 1) * (size - overlap) : 0);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < avatars.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: _AvatarBubble(
                label: avatars[i].initials,
                size: size,
                background: (palettes[avatars[i].initials] ?? fallback).$1,
                foreground: (palettes[avatars[i].initials] ?? fallback).$2,
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: avatars.length * (size - overlap),
              child: _AvatarBubble(
                label: '+$extraCount',
                size: size,
                background: AppColors.dividerLight,
                foreground: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final String label;
  final double size;
  final Color background;
  final Color foreground;

  const _AvatarBubble({
    required this.label,
    required this.size,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}
