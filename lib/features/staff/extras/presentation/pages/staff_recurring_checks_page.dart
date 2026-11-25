import 'package:flutter/material.dart';

import '../../../../hr/recurring_checks/presentation/pages/recurring_checks_page.dart';

/// Staff portal entry for Recurring Checks.
///
/// Uses the same Due / Schedules / Checks UI as web (filters, Assign,
/// Record, Skip) — the previous staff-only stub hid actions for
/// `needs_assignment` and used Complete instead of Record.
class StaffRecurringChecksPage extends StatelessWidget {
  const StaffRecurringChecksPage({super.key});

  @override
  Widget build(BuildContext context) => const RecurringChecksPage();
}
