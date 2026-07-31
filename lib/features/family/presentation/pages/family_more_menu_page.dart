import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../documents/presentation/pages/family_documents_page.dart';
import '../../profile_settings/presentation/pages/family_profile_settings_page.dart';
import '../../visit_requests/presentation/pages/family_visit_requests_list_page.dart';
import '../widgets/family_menu_entry.dart';

/// "More" tab of the Family bottom navigation — a navigation hub for the
/// feature areas that don't have a dedicated bottom-nav slot in the Figma
/// bottom bar (Home/Updates/Appointments/Messages/More only has 5 slots).
///
/// This menu itself isn't a distinct Figma frame; it's a pragmatic way to
/// make Visit Requests, Documents and Profile & Settings reachable
/// end-to-end from a single bottom-nav destination.
class FamilyMoreMenuPage extends StatelessWidget {
  const FamilyMoreMenuPage({super.key});

  static const _entries = <FamilyMenuEntry>[
    FamilyMenuEntry(
      icon: Icons.event_available_outlined,
      iconBackground: AppColors.activeBackground,
      iconColor: AppColors.activeGreen,
      title: 'Visit Requests',
      subtitle: 'All requests, my requests & history',
    ),
    FamilyMenuEntry(
      icon: Icons.folder_outlined,
      iconBackground: AppColors.infoBackground,
      iconColor: AppColors.infoBlue,
      title: 'Documents',
      subtitle: 'Approved care documents & downloads',
    ),
    FamilyMenuEntry(
      icon: Icons.person_outline_rounded,
      iconBackground: AppColors.nightBackground,
      iconColor: AppColors.nightPurple,
      title: 'Profile & Settings',
      subtitle: 'Account, linked clients & preferences',
    ),
  ];

  void _open(BuildContext context, int index) {
    switch (index) {
      case 0:
        Get.to(() => const FamilyVisitRequestsListPage());
        break;
      case 1:
        Get.to(() => const FamilyDocumentsPage());
        break;
      case 2:
        Get.to(() => const FamilyProfileSettingsPage());
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
          'More',
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
          separatorBuilder: (context, index) => SizedBox(
            height: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return FamilyMenuTile(
              entry: entry,
              onTap: () => _open(context, index),
            );
          },
        ),
      ),
    );
  }
}
