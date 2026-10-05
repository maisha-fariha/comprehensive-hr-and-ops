import 'package:flutter/material.dart';

import '../../../daily_activity/presentation/pages/staff_daily_activity_page.dart';

/// Legacy entry — redirects to web-parity [StaffDailyActivityPage].
@Deprecated('Use StaffDailyActivityPage')
class StaffClientActivitiesPage extends StatelessWidget {
  const StaffClientActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) => const StaffDailyActivityPage();
}
