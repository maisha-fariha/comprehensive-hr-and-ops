import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../family_shell.dart';
import '../../../presentation/widgets/family_bottom_nav_bar.dart';
import '../controllers/appointment_request_controller.dart';
import '../widgets/appointment_form_fields.dart';

/// Family "Request a Visit" form — the web Family Portal modal (resident,
/// date of visit, preferred time slot, visiting area, number of visitors,
/// special notes + Cancel / Submit Visit Request).
///
/// On success it leaves the form (back to the list that opened it) and shows
/// the web's success toast; the lists are refetched by the controller.
class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({super.key});

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  static const int _appointmentsTabIndex = 2;

  late final AppointmentRequestController _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AppointmentRequestController>()) {
      Get.delete<AppointmentRequestController>(force: true);
    }
    _controller = Get.put(AppointmentRequestController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<AppointmentRequestController>() &&
        identical(Get.find<AppointmentRequestController>(), _controller)) {
      Get.delete<AppointmentRequestController>(force: true);
    }
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => FamilyShell(initialIndex: index));
  }

  void _close() => Navigator.of(context).maybePop();

  Future<void> _onSubmit() async {
    final sent = await _controller.submit();
    if (!sent || !mounted) return;
    Navigator.of(context).pop(true);
    AppSnackbar.show(AppointmentRequestController.successMessage, '', force: true);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _controller.visitDate.value;
    final date = await showDatePicker(
      context: context,
      initialDate: current == null || current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date != null) _controller.selectDate(date);
  }

  Future<void> _pickResident() async {
    final selected = await _pickOption(
      title: 'Resident',
      options: [
        for (final r in _controller.residents) VisitFormOption(r.id, r.name),
      ],
      selected: _controller.selectedResident?.id,
    );
    if (selected != null) _controller.selectResident(selected);
  }

  Future<void> _pickTimeSlot() async {
    final selected = await _pickOption(
      title: 'Preferred Time Slot',
      options: AppointmentRequestController.timeSlots,
      selected: _controller.timeSlot.value,
    );
    if (selected != null) _controller.timeSlot.value = selected;
  }

  Future<void> _pickVisitingArea() async {
    final selected = await _pickOption(
      title: 'Visiting Area',
      options: AppointmentRequestController.visitingAreas,
      selected: _controller.visitingArea.value,
    );
    if (selected != null) _controller.visitingArea.value = selected;
  }

  Future<String?> _pickOption({
    required String title,
    required List<VisitFormOption> options,
    String? selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF14263B),
                  ),
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(
                  option.label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                trailing: option.value == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.secondaryTeal)
                    : null,
                onTap: () => Navigator.pop(ctx, option.value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
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
          final resident = controller.selectedResident;
          return Column(
            children: [
              _RequestVisitHeader(onClose: _close),
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
                      if (controller.residents.length > 1) ...[
                        const AppointmentFieldLabel('Resident'),
                        AppointmentDropdownField(
                          key: const ValueKey('visit-form-resident'),
                          value: resident?.name ?? 'Select an option',
                          isPlaceholder: resident == null,
                          trailingIcon: Icons.keyboard_arrow_down_rounded,
                          onTap: _pickResident,
                        ),
                        fieldGap,
                      ],
                      const AppointmentFieldLabel('Date of Visit', required: true),
                      AppointmentDropdownField(
                        key: const ValueKey('visit-form-date'),
                        value: controller.visitDateLabel,
                        isPlaceholder: controller.visitDate.value == null,
                        trailingIcon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                      fieldGap,
                      const AppointmentFieldLabel('Preferred Time Slot'),
                      AppointmentDropdownField(
                        key: const ValueKey('visit-form-time-slot'),
                        value: controller.timeSlotLabel,
                        trailingIcon: Icons.keyboard_arrow_down_rounded,
                        onTap: _pickTimeSlot,
                      ),
                      fieldGap,
                      const AppointmentFieldLabel('Visiting Area'),
                      AppointmentDropdownField(
                        key: const ValueKey('visit-form-area'),
                        value: controller.visitingAreaLabel,
                        trailingIcon: Icons.keyboard_arrow_down_rounded,
                        onTap: _pickVisitingArea,
                      ),
                      fieldGap,
                      const AppointmentFieldLabel('Number of Visitors'),
                      AppointmentTextField(
                        controller: controller.visitorsController,
                        hint: '2',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const AppointmentFieldHelper(
                        'Max 6 per party in private rooms',
                      ),
                      fieldGap,
                      const AppointmentFieldLabel(
                        'Special Notes or Requests (Optional)',
                      ),
                      AppointmentNoteField(
                        controller: controller.noteController,
                        hint:
                            'e.g. Bringing birthday flowers, wheelchair assistance needed, outdoor walk if sunny',
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
                        onCancel: _close,
                        onSend: _onSubmit,
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
  final VoidCallback onClose;

  const _RequestVisitHeader({required this.onClose});

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
                  'Request a Visit',
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
                  'Choose a date and preferred time. The care home will confirm your visit.',
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
              onTap: onClose,
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
            key: const ValueKey('visit-form-submit'),
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
              isSubmitting ? 'Sending Request...' : 'Submit Visit Request',
              textAlign: TextAlign.center,
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
