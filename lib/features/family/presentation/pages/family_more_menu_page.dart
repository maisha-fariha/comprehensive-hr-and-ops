import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/roles/user_session.dart';
import '../../documents/presentation/pages/family_documents_page.dart';
import '../../profile_settings/presentation/pages/family_profile_settings_page.dart';
import '../../visit_requests/presentation/pages/family_visit_requests_list_page.dart';
import '../widgets/family_menu_entry.dart';

class FamilyMoreMenuPage extends StatelessWidget {
  const FamilyMoreMenuPage({super.key});

  static const _visitRequests = FamilyMenuEntry(
    icon: Icons.event_available_outlined,
    iconBackground: AppColors.activeBackground,
    iconColor: AppColors.activeGreen,
    title: 'Visit Requests',
    subtitle: 'Your pending visits and history',
  );

  static const _documents = FamilyMenuEntry(
    icon: Icons.folder_outlined,
    iconBackground: AppColors.infoBackground,
    iconColor: AppColors.infoBlue,
    title: 'Documents',
    subtitle: 'Approved care documents & downloads',
  );

  static const _profile = FamilyMenuEntry(
    icon: Icons.person_outline_rounded,
    iconBackground: AppColors.nightBackground,
    iconColor: AppColors.nightPurple,
    title: 'Profile & Settings',
    subtitle: 'Account, linked clients & preferences',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'More',
          style: AppTextStyles.base(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: AppFontWeight.semiBold,
            color: AppColors.textHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final visibility = Get.find<UserSession>().familyVisibility;
          final entries = <({FamilyMenuEntry entry, VoidCallback onTap})>[
            if (visibility.appointments)
              (
                entry: _visitRequests,
                onTap: () => Get.to(() => const FamilyVisitRequestsListPage()),
              ),
            if (visibility.documents)
              (
                entry: _documents,
                onTap: () => Get.to(() => const FamilyDocumentsPage()),
              ),
            (
              entry: _profile,
              onTap: () => Get.to(() => const FamilyProfileSettingsPage()),
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
              final item = entries[index];
              return FamilyMenuTile(entry: item.entry, onTap: item.onTap);
            },
          );
        }),
      ),
    );
  }
}
