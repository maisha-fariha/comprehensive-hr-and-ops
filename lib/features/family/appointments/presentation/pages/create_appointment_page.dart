import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../controllers/appointment_request_controller.dart';
import '../widgets/appointment_form_fields.dart';

/// Family "Request a visit" form — matches the web Family Portal modal
/// (resident, preferred time, where, notes + Cancel / Send request).
class CreateAppointmentPage extends StatelessWidget {
  const CreateAppointmentPage({super.key});

  static const int _appointmentsTabIndex = 2;

  AppointmentRequestController _resolveController() {
    if (Get.isRegistered<AppointmentRequestController>()) {
      Get.delete<AppointmentRequestController>(force: true);
    }
    return Get.put(AppointmentRequestController());
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => FamilyShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final fieldGap =
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: FamilyBottomNavBar(
        currentIndex: _appointmentsTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final error = controller.formError.value;
          return Column(
            children: [
              const _RequestVisitHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null && error.isNotEmpty) ...[
                        AppointmentFormErrorBanner(message: error),
                        fieldGap,
                      ],
                      const AppointmentFieldLabel(
                        'Who would you like to visit',
                        required: true,
                      ),
                      AppointmentDropdownField(
                        value: controller.residentFieldValue,
                        isPlaceholder: controller.selectedResident == null,
                        trailingIcon: Icons.keyboard_arrow_down_rounded,
                        onTap: () => controller.pickResident(context),
                      ),
                      fieldGap,
                      const AppointmentFieldLabel('Preferred time'),
                      AppointmentDropdownField(
                        value: controller.preferredTimeLabel,
                        isPlaceholder: controller.preferredAt.value == null,
                        trailingIcon: Icons.calendar_today_outlined,
                        onTap: () => controller.pickPreferredTime(context),
                      ),
                      fieldGap,
                      const AppointmentFieldLabel('Where'),
                      AppointmentTextField(
                        controller: controller.locationController,
                        hint: 'Optional — e.g. the lounge, the garden',
                      ),
                      fieldGap,
                      const AppointmentFieldLabel(
                        'Anything the care home should know',
                      ),
                      AppointmentNoteField(
                        controller: controller.noteController,
                        hint:
                            'Optional — who is coming, how long you would like…',
                        showCounter: false,
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(
                          context,
                          24,
                        ),
                      ),
                      _RequestVisitActions(
                        isSubmitting: controller.isSubmitting.value,
                        onCancel: Get.back,
                        onSend: controller.submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RequestVisitHeader extends StatelessWidget {
  const _RequestVisitHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceWhite,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 44),
            height: ResponsiveHelper.getResponsiveSize(context, 44),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: ResponsiveHelper.getResponsiveSize(context, 22),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request a visit',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 18),
                    color: AppColors.primaryNavy,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Text(
                  'The care home will confirm the time with you.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Material(
            color: AppColors.filterButtonBackground,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: Get.back,
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveHelper.getResponsiveSize(context, 8),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 18),
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestVisitActions extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _RequestVisitActions({
    required this.isSubmitting,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textHeading,
              side: const BorderSide(color: AppColors.searchBorder),
              backgroundColor: AppColors.surfaceWhite,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: FilledButton(
            onPressed: isSubmitting ? null : onSend,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              disabledBackgroundColor:
                  AppColors.primaryNavy.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: Text(
              isSubmitting ? 'Sending…' : 'Send request',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
