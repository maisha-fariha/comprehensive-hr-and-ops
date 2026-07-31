import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../controllers/visit_request_details_controller.dart';
import '../widgets/details/cancel_request_button.dart';
import '../widgets/details/patient_family_info_card.dart';
import '../widgets/details/purpose_notes_card.dart';
import '../widgets/details/visit_request_summary_card.dart';
import '../widgets/family_visit_requests_header.dart';

/// Read-only Request Details screen, reached by tapping "View Request
/// Details" on a "My Requests" card.
///
/// Reproduction of the Figma "Details - My Requests - Visit Requests"
/// screenshot, built without Figma MCP access (monthly quota exhausted) -
/// see the feature's final report for details on any approximated content
/// and icon placeholders.
class VisitRequestDetailsPage extends StatefulWidget {
  final String requestId;

  const VisitRequestDetailsPage({super.key, required this.requestId});

  @override
  State<VisitRequestDetailsPage> createState() => _VisitRequestDetailsPageState();
}

class _VisitRequestDetailsPageState extends State<VisitRequestDetailsPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            FamilyVisitRequestsHeader(onBackTap: Get.back),
            Expanded(
              child: Obx(() {
                final detail = _controller.state.value.data;

                if (detail == null && _controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
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
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                          ResponsiveHelper.getResponsiveHeight(context, 8),
                          ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
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
                        ],
                      ),
                    ),
                    if (detail.isCancellable)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                          0,
                          ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                          ResponsiveHelper.getResponsiveHeight(context, 14),
                        ),
                        // No backend action exists yet for cancelling a request - left as a
                        // no-op tap target, matching the convention used by other
                        // not-yet-wired actions in this app (e.g. the share icon on
                        // `IncidentDetailsPage`).
                        child: CancelRequestButton(onTap: () {}),
                      ),
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
