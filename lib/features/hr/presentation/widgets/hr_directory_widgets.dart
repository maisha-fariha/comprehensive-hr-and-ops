import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/surface_card.dart';

/// Shared building blocks for the Manager list/detail screens (Residences,
/// Clients).

PreferredSizeWidget hrSubPageAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppColors.surfaceWhite,
    surfaceTintColor: AppColors.surfaceWhite,
    elevation: 0,
    centerTitle: false,
    iconTheme: const IconThemeData(color: AppColors.textHeading),
    title: Text(
      title,
      style: AppTextStyles.base(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textHeading,
      ),
    ),
  );
}

class HrSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const HrSearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.base(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        fontWeight: AppFontWeight.medium,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.base(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          fontWeight: AppFontWeight.regular,
          color: AppColors.textMuted,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        isDense: true,
        contentPadding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 12,
        ),
        border: _border(context),
        enabledBorder: _border(context),
        focusedBorder: _border(context, color: AppColors.secondaryTeal),
      ),
    );
  }

  OutlineInputBorder _border(BuildContext context, {Color? color}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusInput),
        ),
        borderSide: BorderSide(color: color ?? AppColors.searchBorder),
      );
}

/// Pill that opens a popup menu; `null` value means the "all" option.
class HrFilterPill extends StatelessWidget {
  final String allLabel;
  final String? value;
  final List<String> options;
  final String Function(String option)? labelOf;
  final ValueChanged<String?> onChanged;

  const HrFilterPill({
    super.key,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelOf,
  });

  static const _allSentinel = '\u0000all';

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    final label = active ? (labelOf?.call(value!) ?? value!) : allLabel;
    return PopupMenuButton<String>(
      onSelected: (v) => onChanged(v == _allSentinel ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: _allSentinel, child: Text(allLabel)),
        for (final o in options)
          PopupMenuItem(value: o, child: Text(labelOf?.call(o) ?? o)),
      ],
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? AppColors.quickActionCreateShiftBg
              : AppColors.surfaceWhite,
          border: Border.all(
            color: active ? AppColors.secondaryTeal : AppColors.searchBorder,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusPill),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getResponsiveWidth(context, 150),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.base(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  fontWeight: AppFontWeight.semiBold,
                  color: active ? AppColors.secondaryTeal : AppColors.textBody,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: active ? AppColors.secondaryTeal : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class HrStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const HrStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 36),
            height: ResponsiveHelper.getResponsiveSize(context, 36),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(
                  context,
                  AppDimens.radiusIconBoxSmall,
                ),
              ),
            ),
            child: Icon(
              icon,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: iconColor,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.base(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: AppFontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.base(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    fontWeight: AppFontWeight.medium,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HrSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const HrSectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: AppDimens.cardPaddingHorizontal,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.base(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
              fontWeight: AppFontWeight.semiBold,
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          child,
        ],
      ),
    );
  }
}

class HrInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const HrInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 110),
            child: Text(
              label,
              style: AppTextStyles.base(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                fontWeight: AppFontWeight.medium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.base(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                fontWeight: AppFontWeight.semiBold,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HrChipWrap extends StatelessWidget {
  final List<String> items;
  final String emptyLabel;
  final Color background;
  final Color foreground;

  const HrChipWrap({
    super.key,
    required this.items,
    required this.emptyLabel,
    this.background = AppColors.filterButtonBackground,
    this.foreground = AppColors.textBody,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyLabel,
        style: AppTextStyles.base(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
          fontWeight: AppFontWeight.regular,
          color: AppColors.textMuted,
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in items)
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusPill),
              ),
            ),
            child: Text(
              item,
              style: AppTextStyles.base(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                fontWeight: AppFontWeight.semiBold,
                color: foreground,
              ),
            ),
          ),
      ],
    );
  }
}

class HrMessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const HrMessageView({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.base(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              fontWeight: AppFontWeight.medium,
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

/// "12 Mar 2009" style date used across Manager list screens. Calendar
/// dates (e.g. DOB at UTC midnight) are shown as sent, without a timezone
/// shift.
String hrFormatDate(DateTime? date) {
  if (date == null) return '—';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// "Group home" / "Active" style label from an API enum string.
String hrHumanize(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '—';
  final spaced = text.replaceAll(RegExp(r'[_-]+'), ' ');
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
