import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/daily_note_client_info.dart';
import '../controllers/daily_note_controller.dart';
import '../widgets/daily_note_app_bar.dart';
import '../widgets/daily_note_attachments_section.dart';
import '../widgets/daily_note_client_info_card.dart';
import '../widgets/daily_note_field_row.dart';

/// The "Daily Note" screen: a client-specific care-note form opened from a
/// Staff Daily Logs client row/card.
///
/// Pixel-accurate reproduction of the "Daily Note" reference screenshot.
/// Built from a reference screenshot (live Figma MCP access was
/// unavailable while this screen was authored - see implementation
/// report).
class DailyNotePage extends StatelessWidget {
  final DailyNoteClientInfo client;

  const DailyNotePage({super.key, this.client = DailyNoteClientInfo.fallback});

  DailyNoteController _resolveController() {
    try {
      return Get.find<DailyNoteController>();
    } catch (_) {
      return Get.put(GetIt.instance<DailyNoteController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            DailyNoteAppBar(onSave: () => Get.back()),
            Expanded(
              child: Obx(() {
                final response = controller.state.value;
                final overview = response.data;

                if (overview == null && controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
                }

                if (overview == null) {
                  return _DailyNoteError(
                    message: controller.errorMessage.value.isEmpty
                        ? 'Something went wrong while loading this note.'
                        : controller.errorMessage.value,
                    onRetry: controller.refresh,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                      ResponsiveHelper.getResponsiveHeight(context, 16),
                      ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                      ResponsiveHelper.getResponsiveHeight(context, 32),
                    ),
                    children: [
                      DailyNoteClientInfoCard(client: client),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                      SectionHeaderRow(title: 'How is ${client.firstName} today?'),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                      SurfaceCard.card(
                        padding: ResponsiveHelper.getResponsivePadding(context, left: 14, right: 14, top: 4, bottom: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < overview.fields.length; i++)
                              DailyNoteFieldRow(
                                field: overview.fields[i],
                                showDivider: i != overview.fields.length - 1,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                      const DailyNoteAttachmentsSection(),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyNoteError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DailyNoteError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.criticalRed, size: 40),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryTeal),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
