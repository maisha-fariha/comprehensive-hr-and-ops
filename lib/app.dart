import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import 'core/routing/app_pages.dart';
import 'core/routing/app_routes.dart';
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
          title: 'Comprehensive HR & Operations Platform',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.hr,
          getPages: AppPages.routes,
        );
      },
    );
  }
}
