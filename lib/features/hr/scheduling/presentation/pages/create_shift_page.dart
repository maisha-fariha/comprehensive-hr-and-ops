import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../widgets/create_shift/create_shift_header.dart';
import '../widgets/create_shift/create_shift_info_form.dart';
import '../widgets/create_shift/create_shift_notifications_form.dart';
import '../widgets/create_shift/create_shift_open_shift_form.dart';
import '../widgets/create_shift/create_shift_recurring_form.dart';
import '../widgets/create_shift/create_shift_staff_assignment_form.dart';

/// UI-only "Add New Shift" screen matching the design reference.
///
/// No API / repository wiring — local field state only for layout preview.
class CreateShiftPage extends StatefulWidget {
  const CreateShiftPage({super.key});

  @override
  State<CreateShiftPage> createState() => _CreateShiftPageState();
}

class _CreateShiftPageState extends State<CreateShiftPage> {
  CreateShiftTab _tab = CreateShiftTab.shiftInformation;
  late final TextEditingController _peopleNeededController;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _peopleNeededController = TextEditingController(text: '1');
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _peopleNeededController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    CreateShiftHeader(onClose: Get.back),
                    CreateShiftStepTabs(
                      selected: _tab,
                      onSelected: (tab) => setState(() => _tab = tab),
                    ),
                    const CreateShiftCompletionBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _bodyForTab(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CreateShiftFooter(
              onCancel: Get.back,
              onCreate: () {
                // UI-only — create action not wired yet.
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyForTab() {
    switch (_tab) {
      case CreateShiftTab.shiftInformation:
        return CreateShiftInfoForm(
          peopleNeededController: _peopleNeededController,
          titleController: _titleController,
        );
      case CreateShiftTab.staffAssignment:
        return const CreateShiftStaffAssignmentForm();
      case CreateShiftTab.openShift:
        return const CreateShiftOpenShiftForm();
      case CreateShiftTab.recurring:
        return const CreateShiftRecurringForm();
      case CreateShiftTab.notifications:
        return const CreateShiftNotificationsForm();
    }
  }
}
