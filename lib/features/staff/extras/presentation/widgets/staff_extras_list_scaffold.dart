import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Shared list shell for B10 staff screens.
class StaffExtrasListScaffold extends StatelessWidget {
  final String title;
  final bool loading;
  final String? error;
  final List<Map<String, String>> items;
  final Future<void> Function() onRefresh;
  final VoidCallback? onRetry;
  final Widget? floatingActionButton;
  final void Function(Map<String, String> item)? onItemTap;
  final Widget Function(Map<String, String> item)? trailingBuilder;

  const StaffExtrasListScaffold({
    super.key,
    required this.title,
    required this.loading,
    required this.items,
    required this.onRefresh,
    this.error,
    this.onRetry,
    this.floatingActionButton,
    this.onItemTap,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
      ),
      floatingActionButton: floatingActionButton,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: onRetry ?? onRefresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : items.isEmpty
                  ? RefreshIndicator(
                      color: AppColors.secondaryTeal,
                      onRefresh: onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Nothing here yet.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.secondaryTeal,
                      onRefresh: onRefresh,
                      child: ListView.separated(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          all: 16,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(
                            context,
                            8,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final trailing = trailingBuilder?.call(item);
                          return Material(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: onItemTap == null
                                  ? null
                                  : () => onItemTap!(item),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'] ?? '',
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textHeading,
                                            ),
                                          ),
                                          if ((item['subtitle'] ?? '')
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                item['subtitle']!,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          if ((item['status'] ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                item['status']!,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.secondaryTeal,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (trailing != null) trailing,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
