import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_search_record.dart';
import '../controllers/staff_search_controller.dart';
import '../staff_search_destinations.dart';

/// Mobile counterpart of the web header "Search" / "Jump to any page" palette.
class StaffSearchPage extends StatefulWidget {
  final StaffSearchController? controller;

  /// Defaults to [openStaffSearchRecord].
  final ValueChanged<StaffSearchRecord>? onRecordTap;

  const StaffSearchPage({super.key, this.controller, this.onRecordTap});

  static Future<void> open() async {
    await Get.to(() => const StaffSearchPage());
  }

  @override
  State<StaffSearchPage> createState() => _StaffSearchPageState();
}

class _StaffSearchPageState extends State<StaffSearchPage> {
  late final StaffSearchController _controller;
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<StaffSearchController>()) {
      Get.delete<StaffSearchController>(force: true);
    }
    _controller = Get.put(widget.controller ?? StaffSearchController());
  }

  @override
  void dispose() {
    _query.dispose();
    if (Get.isRegistered<StaffSearchController>()) {
      Get.delete<StaffSearchController>(force: true);
    }
    super.dispose();
  }

  void _openDestination(StaffSearchDestination destination) {
    final open = destination.open;
    if (open == null) return;
    Get.back();
    open();
  }

  void _openRecord(StaffSearchRecord record) {
    Get.back();
    (widget.onRecordTap ?? openStaffSearchRecord)(record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, right: 16),
          child: TextField(
            key: const Key('staff-search-input'),
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _controller.onQueryChanged,
            style: AppTextStyles.base(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
              fontWeight: AppFontWeight.regular,
              color: AppColors.textHeading,
            ),
            decoration: InputDecoration(
              hintText: 'Search pages...',
              hintStyle: AppTextStyles.base(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                fontWeight: AppFontWeight.regular,
                color: AppColors.textPlaceholder,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: AppSvgIcon(
                  AppAssets.search,
                  size: 18,
                  color: AppColors.textFaint,
                ),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Obx(
            () => _controller.recordsLoading.value
                ? const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.secondaryTeal,
                    backgroundColor: Colors.transparent,
                  )
                : const SizedBox(height: 2),
          ),
        ),
      ),
      body: Obx(() {
        final pages = _controller.matchingDestinations;
        final groups = [
          for (final type in StaffSearchRecordType.values)
            (type, _controller.recordsOf(type)),
        ].where((g) => g.$2.isNotEmpty).toList();
        final error = _controller.recordsError.value;

        if (pages.isEmpty && groups.isEmpty) {
          if (_controller.recordsLoading.value) return const SizedBox.shrink();
          return Center(
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
              child: Text(
                'No matching pages found.',
                textAlign: TextAlign.center,
                style: AppTextStyles.base(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: AppFontWeight.regular,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
            vertical: 12,
          ),
          children: [
            if (pages.isNotEmpty) ...[
              const _GroupHeading('Pages'),
              for (final page in pages)
                _ResultTile(
                  key: ValueKey('staff-search-page-${page.label}'),
                  icon: page.icon,
                  iconBackground: page.iconBackground,
                  iconColor: page.iconColor,
                  title: page.label,
                  enabled: page.hasStaffPage,
                  onTap: () => _openDestination(page),
                ),
            ],
            for (final group in groups) ...[
              _GroupHeading(staffSearchRecordGroupLabel(group.$1)),
              for (final record in group.$2)
                _ResultTile(
                  key: ValueKey('staff-search-record-${record.id}'),
                  icon: _recordIcon(record.type),
                  iconBackground: AppColors.infoBackground,
                  iconColor: AppColors.infoBlue,
                  title: record.title,
                  subtitle: record.subtitle,
                  enabled: true,
                  onTap: () => _openRecord(record),
                ),
            ],
            if (error.isNotEmpty)
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Text(
                  error,
                  style: AppTextStyles.base(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    fontWeight: AppFontWeight.regular,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  static IconData _recordIcon(StaffSearchRecordType type) {
    switch (type) {
      case StaffSearchRecordType.client:
        return Icons.person_outline_rounded;
      case StaffSearchRecordType.document:
        return Icons.description_outlined;
      case StaffSearchRecordType.medication:
        return Icons.medication_outlined;
    }
  }
}

class _GroupHeading extends StatelessWidget {
  final String label;

  const _GroupHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        top: 10,
        bottom: 6,
      ),
      child: Text(
        label,
        style: AppTextStyles.base(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          fontWeight: AppFontWeight.semiBold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _ResultTile({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.enabled,
    required this.onTap,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: ListTile(
        enabled: enabled,
        onTap: enabled ? onTap : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: iconColor),
        ),
        title: Text(
          title,
          style: AppTextStyles.base(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
            fontWeight: AppFontWeight.semiBold,
            color: AppColors.textHeading,
          ),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: AppTextStyles.base(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  fontWeight: AppFontWeight.regular,
                  color: AppColors.textSecondary,
                ),
              ),
        trailing: enabled
            ? const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconChevron,
              )
            : null,
      ),
    );
  }
}
