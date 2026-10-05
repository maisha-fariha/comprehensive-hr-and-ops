import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document_row.dart';

/// Web chart palette for the categories donut.
const List<Color> hrCategoryColors = [
  Color(0xFF2E90FA),
  Color(0xFF12B76A),
  Color(0xFFF79009),
  Color(0xFF7656D6),
  Color(0xFFF04438),
  Color(0xFF06AED4),
  Color(0xFF98A2B3),
];

/// `1234` → `1,234` (the web `toLocaleString`).
String hrCount(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

AttendanceTone hrStatusTone(HrDocTone tone) => switch (tone) {
      HrDocTone.success => AttendanceTone.success,
      HrDocTone.warning => AttendanceTone.warning,
      HrDocTone.danger => AttendanceTone.danger,
      HrDocTone.neutral => AttendanceTone.neutral,
    };

/// Owner type pill colours: resident info, staff cyan, residence purple.
(Color, Color) hrOwnerColors(String ownerType) => switch (ownerType) {
      'client' => (AppColors.infoBlue, AppColors.infoBackground),
      'staff' => (AppColors.secondaryTeal, AppColors.quickActionCreateShiftBg),
      'residence' => (AppColors.nightPurple, AppColors.nightBackground),
      _ => (AppColors.textSecondary, AppColors.filterButtonBackground),
    };

(IconData, Color, Color) hrFileStyle(HrFileKind kind) => switch (kind) {
      HrFileKind.pdf => (
          Icons.picture_as_pdf_outlined,
          AppColors.criticalRed,
          AppColors.criticalBackgroundSoft,
        ),
      HrFileKind.sheet => (
          Icons.table_chart_outlined,
          AppColors.activeGreen,
          AppColors.activeBackground,
        ),
      HrFileKind.doc => (
          Icons.description_outlined,
          AppColors.secondaryTeal,
          AppColors.quickActionCreateShiftBg,
        ),
      HrFileKind.image => (
          Icons.image_outlined,
          AppColors.urgentAmber,
          AppColors.urgentBackground,
        ),
      HrFileKind.file => (
          Icons.insert_drive_file_outlined,
          AppColors.textMuted,
          AppColors.filterButtonBackground,
        ),
    };

(IconData, Color) hrVisibilityStyle(String visibility) => switch (visibility) {
      'family' => (Icons.visibility_outlined, AppColors.secondaryTeal),
      'staff_only' => (Icons.people_outline_rounded, AppColors.textMuted),
      'management_only' => (Icons.visibility_off_outlined, AppColors.criticalRed),
      _ => (Icons.visibility_outlined, AppColors.activeGreen),
    };

class HrDocPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const HrDocPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  factory HrDocPill.owner(String ownerType, String label, {Key? key}) {
    final (fg, bg) = hrOwnerColors(ownerType);
    return HrDocPill(key: key, label: label, foreground: fg, background: bg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: handoverText(context, 11.5, weight: FontWeight.w600, color: foreground),
      ),
    );
  }
}

/// Rounded square icon used for file types and modal headers.
class HrIconTile extends StatelessWidget {
  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;

  const HrIconTile({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.48, color: foreground),
    );
  }
}

/// Bottom-sheet version of the web modal: header with icon, title, badges
/// and description; a scrolling body; a footer of buttons.
class HrSheetFrame extends StatelessWidget {
  final IconData icon;
  final Color iconForeground;
  final Color iconBackground;
  final String title;
  final List<Widget> badges;
  final String? description;
  final Widget body;
  final List<Widget> footer;

  const HrSheetFrame({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.iconForeground = AppColors.surfaceWhite,
    this.iconBackground = AppColors.secondaryTeal,
    this.badges = const [],
    this.description,
    this.footer = const [],
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        child: Material(
          color: AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 8, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HrIconTile(
                      icon: icon,
                      foreground: iconForeground,
                      background: iconBackground,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: handoverText(context, 17, weight: FontWeight.w700)),
                          if (badges.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(spacing: 6, runSpacing: 6, children: badges),
                          ],
                          if (description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              description!,
                              style: handoverText(context, 13, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: body,
                ),
              ),
              if (footer.isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.cardBorder),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: footer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showHrSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: builder,
    );

/// Label / value pair of the detail and success views.
class HrFactRow extends StatelessWidget {
  final String label;
  final String value;

  const HrFactRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Text(label, style: handoverText(context, 12, color: AppColors.navInactive)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: handoverText(context, 13, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
