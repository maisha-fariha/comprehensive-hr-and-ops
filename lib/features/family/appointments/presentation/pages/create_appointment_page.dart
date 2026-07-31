import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../controllers/appointment_request_controller.dart';
import '../widgets/appointment_form_fields.dart';
import '../widgets/family_appointments_header.dart';
import '../widgets/family_primary_button.dart';
import '../widgets/request_type_toggle.dart';

/// The single-page "Request Visit" / "Request Appointment" create form,
/// reached from the "+ Create Appointment" button on the Family
/// Appointments list screen.
///
/// One page backs both states of the Figma "Request Visit - Appointments"
/// and "Request Appointment - Appointments" screenshots - the "Request
/// Type" segmented toggle at the top switches the AppBar title plus a
/// handful of field labels/values, matching the reference structure of the
/// Staff Incidents feature's single-page "Create Incident" form.
class CreateAppointmentPage extends StatelessWidget {
  const CreateAppointmentPage({super.key});

  /// Always starts a fresh controller instance for a new draft rather than
  /// resolving the `get_it`-registered singleton - reusing the same
  /// instance across multiple "Create Appointment" sessions would resurface
  /// a previous draft's field values, and its `TextEditingController` would
  /// already be disposed after the first time this page is closed (see the
  /// identical rationale on the Staff Incidents feature's create-form page).
  AppointmentRequestController _resolveController() {
    if (Get.isRegistered<AppointmentRequestController>()) {
      Get.delete<AppointmentRequestController>(force: true);
    }
    return Get.put(AppointmentRequestController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final fieldGap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
          return Column(
            children: [
              Container(
                color: AppColors.surfaceWhite,
                child: FamilyAppointmentsHeader(title: controller.pageTitle, onBack: Get.back),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppointmentFieldLabel('Request Type'),
                      RequestTypeToggle(selected: controller.requestType.value, onSelected: controller.selectRequestType),
                      fieldGap,
                      const AppointmentFieldLabel('Preferred Date'),
                      AppointmentDropdownField(value: controller.preferredDate, leadingIcon: AppAssets.navCalendar),
                      fieldGap,
                      const AppointmentFieldLabel('Preferred Time'),
                      AppointmentDropdownField(value: controller.preferredTime, leadingIcon: AppAssets.clock),
                      fieldGap,
                      AppointmentFieldLabel(controller.thirdFieldLabel),
                      AppointmentDropdownField(value: controller.thirdFieldValue),
                      fieldGap,
                      const AppointmentFieldLabel('Location / Mode'),
                      AppointmentDropdownField(value: controller.locationModeValue),
                      fieldGap,
                      const AppointmentFieldLabel('Add a Note', suffix: '(Optional)'),
                      AppointmentNoteField(
                        controller: controller.noteController,
                        hint: controller.notePlaceholder,
                        length: controller.noteLength.value,
                      ),
                      fieldGap,
                      AppointmentInfoBanner(message: controller.bannerMessage),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 12, bottom: 12),
                  child: FamilyPrimaryButton(
                    label: 'Submit Request',
                    icon: Icons.send_rounded,
                    onTap: Get.back,
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
