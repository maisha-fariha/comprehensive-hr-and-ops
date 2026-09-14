import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../../domain/entities/daily_note_client_info.dart';
import '../../staff_daily_logs_constants.dart';
import '../controllers/daily_note_controller.dart';
import '../widgets/daily_note_app_bar.dart';
import '../widgets/daily_note_attachments_section.dart';
import '../widgets/daily_note_client_info_card.dart';
import '../widgets/daily_note_field_row.dart';
import '../widgets/daily_note_handover_section.dart';

/// The "Daily Note" screen: a client-specific care-note form opened from a
/// Staff Daily Logs client row/card.
///
/// Hosts [StaffBottomNavBar] with "Clients" selected so the pushed route
/// still matches frames that show the staff bottom nav.
class DailyNotePage extends StatelessWidget {
  final DailyNoteClientInfo client;

  const DailyNotePage({super.key, this.client = DailyNoteClientInfo.fallback});

  /// Index of the "Clients" slot in [StaffBottomNavBar.items].
  static const int _clientsTabIndex = 2;

  DailyNoteController _resolveController() {
    try {
      return Get.find<DailyNoteController>();
    } catch (_) {
      return Get.put(GetIt.instance<DailyNoteController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    // Kick off entry detail / empty form once the page mounts.
    controller.ensureLoaded(client);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _clientsTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DailyNoteAppBar(
              onSave: () => controller.saveNote(client, submit: false),
            ),
            Expanded(
              child: Obx(() {
                final response = controller.state.value;
                final overview = response.data;

                if (overview == null && controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  );
                }

                if (overview == null) {
                  return _DailyNoteError(
                    message: controller.errorMessage.value.isEmpty
                        ? 'Something went wrong while loading this note.'
                        : controller.errorMessage.value,
                    onRetry: () => controller.loadForClient(client),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: () => controller.loadForClient(client),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(
                        context,
                        AppDimens.screenPaddingHorizontal,
                      ),
                      ResponsiveHelper.getResponsiveHeight(context, 16),
                      ResponsiveHelper.getResponsiveWidth(
                        context,
                        AppDimens.screenPaddingHorizontal,
                      ),
                      ResponsiveHelper.getResponsiveHeight(context, 32),
                    ),
                    children: [
                      DailyNoteClientInfoCard(client: client),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 20),
                      ),
                      SectionHeaderRow(
                        title: 'How is ${client.firstName} today?',
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      _BodyNoteField(controller: controller.bodyController),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      SurfaceCard.card(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          left: 14,
                          right: 14,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < overview.fields.length; i++)
                              DailyNoteFieldRow(
                                field: overview.fields[i],
                                showDivider:
                                    i != overview.fields.length - 1,
                                onTap: () => controller.pickFieldValue(
                                  overview.fields[i],
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 16),
                      ),
                      _ShiftAndFlagRow(
                        shift: controller.selectedShift.value.isNotEmpty
                            ? controller.selectedShift.value
                            : overview.shift,
                        flagForAttention: controller.flagForAttention.value,
                        onShiftTap: () => _pickShift(controller),
                        onFlagChanged: controller.setFlagForAttention,
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 20),
                      ),
                      DailyNoteAttachmentsSection(
                        attachments: controller.attachments.toList(),
                        onAddPhoto: () => controller.pickAndUploadAttachment(
                          imagesOnly: true,
                        ),
                        onAddFiles: () => controller.pickAndUploadAttachment(
                          imagesOnly: false,
                        ),
                        onRemove: controller.removeAttachment,
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 20),
                      ),
                      DailyNoteHandoverSection(
                        controller: controller.handoverController,
                        submitLabel: overview.isSubmitted
                            ? 'Amend Note'
                            : 'Submit Note',
                        onSubmit: () =>
                            controller.saveNote(client, submit: true),
                      ),
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

  Future<void> _pickShift(DailyNoteController controller) async {
    final selected = await showModalBottomSheet<String>(
      context: Get.context!,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in StaffDailyLogsConstants.shiftOptions)
                ListTile(
                  title: Text(option),
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      controller.setShift(selected);
    }
  }
}

class _BodyNoteField extends StatelessWidget {
  final TextEditingController controller;

  const _BodyNoteField({required this.controller});

  static const Color _ink = Color(0xFF1A2533);
  static const Color _muted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);
    final fieldHeight = ResponsiveHelper.getResponsiveHeight(context, 110);

    return Container(
      width: double.infinity,
      height: fieldHeight,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: _ink,
          height: 1.4,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          hintText: 'Write the care note…',
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: _muted,
          ),
        ),
      ),
    );
  }
}

class _ShiftAndFlagRow extends StatelessWidget {
  final String shift;
  final bool flagForAttention;
  final VoidCallback onShiftTap;
  final ValueChanged<bool> onFlagChanged;

  const _ShiftAndFlagRow({
    required this.shift,
    required this.flagForAttention,
    required this.onShiftTap,
    required this.onFlagChanged,
  });

  static const Color _ink = Color(0xFF1A2533);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onShiftTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 14),
              ),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Shift',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: _ink,
                    ),
                  ),
                ),
                Text(
                  shift.isEmpty ? 'Select' : shift,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 14),
            ),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: SwitchListTile(
            contentPadding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 6,
            ),
            title: Text(
              'Flag for manager attention',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: _ink,
              ),
            ),
            value: flagForAttention,
            activeThumbColor: AppColors.secondaryTeal,
            onChanged: onFlagChanged,
          ),
        ),
      ],
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
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: 40,
            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
