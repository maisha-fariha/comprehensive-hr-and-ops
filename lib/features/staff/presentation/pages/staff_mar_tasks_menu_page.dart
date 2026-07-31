import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../medication/presentation/pages/staff_medication_page.dart';
import '../../tasks_messages/presentation/pages/staff_tasks_messages_page.dart';
import '../widgets/staff_menu_entry.dart';

/// "MAR / Tasks" tab of the Staff bottom navigation — a navigation hub for
/// the two feature areas that share this single bottom-nav slot in the
/// Figma bottom bar (Home/Schedule/Clients/MAR-Tasks/More only has 5 slots).
///
/// This menu itself isn't a distinct Figma frame; it's a pragmatic way to
/// make both the Medication MAR and Tasks & Messages screens reachable
/// end-to-end from a single bottom-nav destination.
class StaffMarTasksMenuPage extends StatelessWidget {
  const StaffMarTasksMenuPage({super.key});

  static const _entries = <StaffMenuEntry>[
    StaffMenuEntry(
      icon: Icons.medication_outlined,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      title: 'Medication MAR',
      subtitle: 'Due, administered, missed & refused doses',
    ),
    StaffMenuEntry(
      icon: Icons.fact_check_outlined,
      iconBackground: AppColors.urgentBackground,
      iconColor: AppColors.urgentAmber,
      title: 'Tasks & Messages',
      subtitle: 'Your to-dos and team conversations',
    ),
  ];

  void _open(BuildContext context, int index) {
    switch (index) {
      case 0:
        Get.to(() => const StaffMedicationPage());
        break;
      case 1:
        Get.to(() => const StaffTasksMessagesPage());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'MAR / Tasks',
          style: AppTextStyles.base(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: AppFontWeight.semiBold,
            color: AppColors.textHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: AppDimens.screenPaddingHorizontal,
            vertical: 20,
          ),
          itemCount: _entries.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return StaffMenuTile(
              entry: entry,
              onTap: () => _open(context, index),
            );
          },
        ),
      ),
    );
  }
}
