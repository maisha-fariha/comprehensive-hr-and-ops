import 'package:flutter/material.dart';

import '../../../../../core/widgets/section_header_row.dart';

/// "Open Shift Requests" heading + a "View all" trailing link.
///
/// The reference screenshot cuts off before the actual request list is
/// shown — only the section header and its trailing link are confirmed by
/// the design, so this widget intentionally renders just that.
class OpenShiftRequestsSection extends StatelessWidget {
  final VoidCallback? onViewAll;

  const OpenShiftRequestsSection({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return SectionHeaderRow(
      title: 'Open Shift Requests',
      trailing: ViewAllLink(onTap: onViewAll),
    );
  }
}
