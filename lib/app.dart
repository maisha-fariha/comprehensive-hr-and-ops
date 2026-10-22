import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import 'core/network/offline_banner.dart';
import 'core/roles/user_session.dart';
import 'core/routing/app_pages.dart';
import 'core/theme/app_theme.dart';

/// Application root widget: wires up responsive scaling, the Material 3
/// theme and GetX routing.
class ComprehensiveHrAndOpsApp extends StatelessWidget {
  const ComprehensiveHrAndOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(ResponsiveHelper.baseWidth, ResponsiveHelper.baseHeight),
      minTextAdapt: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Care House',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: Get.find<UserSession>().portalRoute,
          getPages: AppPages.routes,
          builder: (context, child) {
            // Colored headers still draw under the status bar and pad their
            // own content. The bottom inset keeps every screen's content
            // above the system navigation bar.
            return SafeArea(
              top: false,
              child: OfflineAwareApp(child: child ?? const SizedBox.shrink()),
            );
          },
        );
      },
    );
  }
}
