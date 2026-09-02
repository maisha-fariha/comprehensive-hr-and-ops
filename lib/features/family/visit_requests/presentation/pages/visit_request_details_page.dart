import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../../domain/entities/family_visit_requests_enums.dart';
import '../controllers/visit_request_details_controller.dart';
import '../widgets/details/patient_family_info_card.dart';
import '../widgets/details/purpose_notes_card.dart';
import '../widgets/details/visit_request_details_actions.dart';
import '../widgets/details/visit_request_summary_card.dart';
import '../widgets/family_visit_requests_header.dart';

/// Read-only Request Details screen, reached by tapping "View Request
/// Details" on a "My Requests" card.
///
/// Hosts [FamilyBottomNavBar] with "More" selected so the pushed route still
/// matches reference frames that show the family bottom nav.
class VisitRequestDetailsPage extends StatefulWidget {
  final String requestId;

  const VisitRequestDetailsPage({super.key, required this.requestId});

  @override
  State<VisitRequestDetailsPage> createState() => _VisitRequestDetailsPageState();
}

class _VisitRequestDetailsPageState extends State<VisitRequestDetailsPage> {
  /// Index of the "More" slot in [FamilyBottomNavBar.items].
  static const int _moreTabIndex = 4;

  late final VisitRequestDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _resolveController();
    _controller.loadDetail(widget.requestId);
  }

  VisitRequestDetailsController _resolveController() {
    try {
      return Get.find<VisitRequestDetailsController>();
    } catch (_) {
      return Get.put(GetIt.instance<VisitRequestDetailsController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => FamilyShell(initialIndex: index));
  }

  Future<void> _pickReschedule(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
    );
    if (time == null) return;
    await _controller.rescheduleTo(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text(
          'The care team will be notified that this visit is no longer needed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel request')),
        ],
      ),
    );
    if (confirmed == true) await _controller.cancelRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: FamilyBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: FamilyVisitRequestsHeader(onBackTap: Get.back),
            ),
            Expanded(
              child: Obx(() {
                final detail = _controller.state.value.data;

                if (detail == null && _controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.secondaryTeal),
                  );
                }

                if (detail == null) {
                  return Center(
                    child: Padding(
                      padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
                      child: Text(
                        _controller.errorMessage.value.isEmpty
                            ? 'Something went wrong while loading this request.'
                            : _controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      AppDimens.screenPaddingHorizontal,
                    ),
                    ResponsiveHelper.getResponsiveHeight(context, 8),
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      AppDimens.screenPaddingHorizontal,
                    ),
                    ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                  children: [
                    const SectionHeaderRow(title: 'Request Summary'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                    VisitRequestSummaryCard(detail: detail),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'Patient & Family Information'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                    PatientFamilyInfoCard(detail: detail),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                    const SectionHeaderRow(title: 'Purpose & Notes'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                    PurposeNotesCard(detail: detail),
                    if (detail.isCancellable ||
                        detail.status == VisitRequestStatus.rescheduleRequested) ...[
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                      VisitRequestDetailsActions(
                        enabled: !_controller.isActing.value,
                        onReschedule: () => _pickReschedule(context),
                        onCancel: () => _confirmCancel(context),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
