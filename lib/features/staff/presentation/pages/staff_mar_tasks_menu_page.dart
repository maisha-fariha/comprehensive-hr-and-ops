import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/roles/user_session.dart';
import '../../medication/presentation/pages/staff_medication_page.dart';
import '../../tasks_messages/presentation/pages/staff_tasks_messages_page.dart';
import '../widgets/staff_menu_entry.dart';

class StaffMarTasksMenuPage extends StatelessWidget {
  const StaffMarTasksMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSession>();

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
        child: Obx(() {
          final entries = <StaffMenuEntry>[
            if (session.canAccessMar)
              const StaffMenuEntry(
                icon: Icons.medication_outlined,
                iconBackground: AppColors.activeBackground,
                iconColor: AppColors.activeGreen,
                title: 'Medication MAR',
                subtitle: 'Due, administered, missed & refused doses',
              ),
            const StaffMenuEntry(
              icon: Icons.fact_check_outlined,
              iconBackground: AppColors.urgentBackground,
              iconColor: AppColors.urgentAmber,
              title: 'Tasks & Messages',
              subtitle: 'Your to-dos and team conversations',
            ),
          ];

          return ListView.separated(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: AppDimens.screenPaddingHorizontal,
              vertical: 20,
            ),
            itemCount: entries.length,
            separatorBuilder: (context, index) => SizedBox(
              height: ResponsiveHelper.getResponsiveHeight(context, 12),
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return StaffMenuTile(
                entry: entry,
                onTap: () => _open(entry.title),
              );
            },
          );
        }),
      ),
    );
  }

  void _open(String title) {
    if (title == 'Medication MAR') {
      Get.to(() => const StaffMedicationPage());
    } else if (title == 'Tasks & Messages') {
      Get.to(() => const StaffTasksMessagesPage());
    }
  }
}
