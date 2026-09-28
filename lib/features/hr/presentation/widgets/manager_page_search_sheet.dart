import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../manager_destinations.dart';
import 'hr_directory_widgets.dart';

/// "Search pages…" sheet opened from the dashboard search bar's filter
/// button — the mobile counterpart of the web ⌘K page palette.
Future<void> showManagerPageSearchSheet(BuildContext context) async {
  final destination = await showModalBottomSheet<ManagerDestination>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ManagerPageSearchSheet(),
  );
  destination?.open();
}

class _ManagerPageSearchSheet extends StatefulWidget {
  const _ManagerPageSearchSheet();

  @override
  State<_ManagerPageSearchSheet> createState() =>
      _ManagerPageSearchSheetState();
}

class _ManagerPageSearchSheetState extends State<_ManagerPageSearchSheet> {
  final _all = managerDestinations();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _all.where((d) => d.matches(_query)).toList();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                top: 16,
              ),
              child: Text(
                'Jump to',
                style: AppTextStyles.base(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                vertical: 12,
              ),
              child: HrSearchField(
                hint: 'Search pages…',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: results.isEmpty
                  ? const HrMessageView(
                      icon: Icons.search_off_rounded,
                      message: 'No pages match your search.',
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 12,
                        bottom: 16,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final d = results[index];
                        return ListTile(
                          onTap: () => Navigator.of(context).pop(d),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: d.iconBackground,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(d.icon, size: 19, color: d.iconColor),
                          ),
                          title: Text(
                            d.title,
                            style: AppTextStyles.base(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                14.5,
                              ),
                              fontWeight: AppFontWeight.semiBold,
                              color: AppColors.textHeading,
                            ),
                          ),
                          subtitle: Text(
                            d.subtitle,
                            style: AppTextStyles.base(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12,
                              ),
                              fontWeight: AppFontWeight.regular,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.iconChevron,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
