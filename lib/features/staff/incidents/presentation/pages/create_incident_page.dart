import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../../domain/entities/staff_incident_options.dart';
import '../../domain/repositories/staff_incidents_repository.dart';
import '../controllers/incident_creation_controller.dart';
import '../widgets/create_incident/create_incident_form_fields.dart';
import '../widgets/create_incident/create_incident_investigation_section.dart';
import '../widgets/create_incident/create_incident_people_location_section.dart';
import '../widgets/create_incident/create_incident_report_form_section.dart';
import '../widgets/create_incident/numbered_section_header.dart';
import '../widgets/create_incident/severity_pill_selector.dart';
import '../widgets/staff_incidents_header.dart';

/// Staff "Create Incident" 5-step wizard (web parity).
///
/// Steps: Incident Details → Location & People → Investigation →
/// Evidence & Submission → Report Form.
///
/// Hosts [StaffBottomNavBar] with "More" selected so the pushed route still
/// matches reference frames that show the staff bottom nav.
class CreateIncidentPage extends StatefulWidget {
  const CreateIncidentPage({super.key});

  /// Index of the "More" slot in [StaffBottomNavBar.items].
  static const int moreTabIndex = 4;

  @override
  State<CreateIncidentPage> createState() => _CreateIncidentPageState();
}

class _CreateIncidentPageState extends State<CreateIncidentPage> {
  late final IncidentCreationController _controller;

  /// Always starts a fresh controller instance for a new draft rather than
  /// resolving the `get_it`-registered singleton — reusing the same
  /// instance across sessions would resurface a previous draft, and its
  /// `TextEditingController`s would already be disposed.
  ///
  /// Resolved once in [initState] (not [build]): keyboard/MediaQuery rebuilds
  /// after dialogs would otherwise delete the live controller mid-frame.
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<IncidentCreationController>()) {
      Get.delete<IncidentCreationController>(force: true);
    }
    _controller = Get.put(
      IncidentCreationController(
        repository: GetIt.instance<StaffIncidentsRepository>(),
      ),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<IncidentCreationController>() &&
        Get.find<IncidentCreationController>() == _controller) {
      Get.delete<IncidentCreationController>(force: true);
    }
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: CreateIncidentPage.moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.surfaceWhite,
              child: StaffIncidentsHeader(
                title: 'Add New Incident',
                subtitle:
                    'Report incident for safety, compliance & supervisor review',
                onBack: Get.back,
              ),
            ),
            Expanded(
              child: Obx(() {
                final step = _controller.wizardStep.value;
                final banner = _controller.formBannerMessage.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (banner != null && banner.isNotEmpty)
                      _FormBanner(
                        message: banner,
                        isError: _controller.formBannerIsError.value,
                        onDismiss: _controller.clearFormBanner,
                      ),
                    _WizardStepProgress(controller: _controller),
            Expanded(
              child: SingleChildScrollView(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: _buildStepContent(context, _controller, step),
                      ),
                    ),
                    _WizardFooter(controller: _controller),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    IncidentCreationController controller,
    int step,
  ) {
    final fieldGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 16),
    );
    final sectionGap = SizedBox(
      height: ResponsiveHelper.getResponsiveHeight(context, 18),
    );

    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NumberedSectionHeader(
              number: 1,
              title: 'INCIDENT DETAILS',
              filledBadge: true,
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
            Container(
              width: double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 16),
                ),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.05),
                    offset: Offset(
                      0,
                      ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    blurRadius:
                        ResponsiveHelper.getResponsiveHeight(context, 12),
                  ),
                ],
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const CreateIncidentFieldLabel(
                    'Incident Category',
                    required: true,
                  ),
                    Obx(
                      () => CreateIncidentDropdownField(
                      value: controller.incidentCategoryLabel,
                        placeholder: 'Select category...',
                      onTap: controller.pickCategory,
                      ),
                    ),
                    fieldGap,
                  const CreateIncidentFieldLabel(
                    'Incident Title',
                    required: true,
                  ),
                    CreateIncidentTextField(
                      controller: controller.incidentTitleController,
                    hint: 'e.g. Client refused morning medication',
                  ),
                  fieldGap,
                  const CreateIncidentFieldLabel(
                    'Category Details (optional)',
                  ),
                  CreateIncidentTextField(
                    key: const Key('staff-incident-category-details'),
                    controller: controller.categoryDetailsController,
                    hint: 'Add category-specific context…',
                    maxLines: 2,
                    ),
                    fieldGap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            const CreateIncidentFieldLabel(
                              'Incident Date',
                              required: true,
                            ),
                            GestureDetector(
                              onTap: () => controller.pickDate(context),
                              behavior: HitTestBehavior.opaque,
                              child: AbsorbPointer(
                                child: CreateIncidentDateField(
                                  controller:
                                      controller.incidentDateController,
                                ),
                              ),
                            ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveWidth(context, 12),
                      ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            const CreateIncidentFieldLabel(
                              'Incident Time',
                              required: true,
                            ),
                            GestureDetector(
                              onTap: () => controller.pickTime(context),
                              behavior: HitTestBehavior.opaque,
                              child: AbsorbPointer(
                                child: CreateIncidentTimeField(
                                  controller:
                                      controller.incidentTimeController,
                                ),
                              ),
                            ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    fieldGap,
                  const CreateIncidentFieldLabel('Time Ended (optional)'),
                  GestureDetector(
                    onTap: () => controller.pickEndTime(context),
                    behavior: HitTestBehavior.opaque,
                    child: AbsorbPointer(
                      child: CreateIncidentTextField(
                        key: const Key('staff-incident-end-time'),
                        controller: controller.endTimeController,
                        hint: 'e.g. 4:30 PM',
                      ),
                    ),
                  ),
                  fieldGap,
                  const CreateIncidentFieldLabel(
                    'Detected During (optional)',
                  ),
                    Obx(
                      () => CreateIncidentDropdownField(
                        value: controller.detectedDuring.value,
                      placeholder: 'Select context',
                      onTap: controller.pickDetectedDuring,
                    ),
                  ),
                ],
                      ),
                    ),
                    sectionGap,
            const CreateIncidentFieldLabel('Severity', required: true),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                    Obx(
                      () => SeverityPillSelector(
                        selected: controller.severity.value,
                        onChanged: controller.selectSeverity,
                      ),
                    ),
                    sectionGap,
            _DescriptionSection(
              controller: controller.descriptionController,
            ),
          ],
        );
      case 1:
        return CreateIncidentPeopleLocationSection(controller: controller);
      case 2:
        return CreateIncidentInvestigationSection(controller: controller);
      case 3:
        return _EvidenceSection(controller: controller);
      case 4:
      default:
        return CreateIncidentReportFormSection(controller: controller);
    }
  }
}

/// Inline validation / submit feedback under the page header.
class _FormBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  static const Color _errorBg = Color(0xFFFEF2F2);
  static const Color _errorBorder = Color(0xFFFECACA);
  static const Color _errorFg = Color(0xFFB91C1C);
  static const Color _infoBg = Color(0xFFECFDF5);
  static const Color _infoBorder = Color(0xFFA7F3D0);
  static const Color _infoFg = Color(0xFF047857);

  const _FormBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isError ? _errorBg : _infoBg;
    final border = isError ? _errorBorder : _infoBorder;
    final fg = isError ? _errorFg : _infoFg;

    return Material(
      color: bg,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 20),
              color: fg,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: fg,
                  height: 1.35,
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.close_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress label + tappable step chips for the 5-step wizard.
class _WizardStepProgress extends StatelessWidget {
  final IncidentCreationController controller;

  const _WizardStepProgress({required this.controller});

  static const Color _teal = Color(0xFF0E7C7B);
  static const Color _idleBg = Color(0xFFF4F7F9);
  static const Color _idleLabel = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final step = controller.wizardStep.value;
    final titles = IncidentCreationController.stepTitles;
    final complete = step; // steps before current count as complete

    return Container(
      width: double.infinity,
      color: AppColors.surfaceWhite,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 12,
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP ${step + 1} OF ${titles.length}',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              letterSpacing: 0.6,
              color: _teal,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            titles[step],
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            '$complete of ${titles.length} steps complete',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < titles.length; i++) ...[
                  if (i > 0)
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 8),
                    ),
                  GestureDetector(
                    onTap: () => controller.goToStep(i),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: i == step ? const Color(0xFFE6F4F3) : _idleBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: i == step ? _teal : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${i + 1}. ${titles[i]}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            11.5,
                          ),
                          color: i == step ? _teal : _idleLabel,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer: Cancel | Save Draft | Back (step>0) | Next / Submit.
class _WizardFooter extends StatelessWidget {
  final IncidentCreationController controller;

  const _WizardFooter({required this.controller});

  static const Color _submit = Color(0xFF0E7C7B);
  static const Color _cancelBorder = Color(0xFFE2E8F0);
  static const Color _cancelLabel = Color(0xFF64748B);
  static const Color _draftBg = Color(0xFFF4F7F9);

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final step = controller.wizardStep.value;
    final titles = IncidentCreationController.stepTitles;
    final isLast = step >= titles.length - 1;
    final nextTitle = isLast ? null : titles[step + 1];

    return Obx(() {
      final busy = controller.isSubmitting.value;
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 20,
          top: 12,
          bottom: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (step > 0) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('staff-incident-wizard-back'),
                  onPressed: busy ? null : controller.previousStep,
                  child: const Text('Back'),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: busy ? null : Get.back,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight:
                            ResponsiveHelper.getResponsiveHeight(context, 48),
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: _cancelBorder),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13.5,
                          ),
                          color: _cancelLabel,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: ResponsiveHelper.getResponsiveWidth(context, 8),
                ),
                Expanded(
                  child: GestureDetector(
                    key: const Key('staff-incident-save-draft'),
                    onTap: busy ? null : controller.saveDraft,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight:
                            ResponsiveHelper.getResponsiveHeight(context, 48),
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _draftBg,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: _cancelBorder),
                      ),
                      child: Text(
                        'Save Draft',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13.5,
                          ),
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: ResponsiveHelper.getResponsiveWidth(context, 8),
                ),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    key: isLast
                        ? const Key('staff-incident-submit')
                        : const Key('staff-incident-wizard-next'),
                    onTap: busy
                        ? null
                        : (isLast
                            ? controller.submit
                            : () => controller.nextStep()),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight:
                            ResponsiveHelper.getResponsiveHeight(context, 48),
                      ),
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _submit.withValues(alpha: busy ? 0.7 : 1),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (busy)
                            SizedBox(
                              width: ResponsiveHelper.getResponsiveSize(
                                context,
                                18,
                              ),
                              height: ResponsiveHelper.getResponsiveSize(
                                context,
                                18,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else if (isLast)
                            SvgPicture.asset(
                              'assets/icons/staff_incidents/submit.svg',
                              width: ResponsiveHelper.getResponsiveSize(
                                context,
                                18,
                              ),
                            )
                          else
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: ResponsiveHelper.getResponsiveSize(
                                context,
                                18,
                              ),
                              color: Colors.white,
                            ),
                          SizedBox(
                            width:
                                ResponsiveHelper.getResponsiveWidth(context, 8),
                          ),
                          Flexible(
                            child: Text(
                              busy
                                  ? 'Submitting…'
                                  : isLast
                                      ? 'Submit Incident'
                                      : 'Next: $nextTitle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  13.5,
                                ),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Description section card: required label + multiline field with 600 cap.
class _DescriptionSection extends StatefulWidget {
  final TextEditingController controller;

  const _DescriptionSection({required this.controller});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  static const int _maxChars = 600;
  static const Color _fill = Color(0xFFF0F2F5);
  static const Color _placeholder = Color(0xFFB0B7C3);
  static const Color _counter = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fieldHeight = ResponsiveHelper.getResponsiveHeight(context, 148);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreateIncidentFieldLabel('Incident Description', required: true),
          Container(
            width: double.infinity,
            height: fieldHeight,
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    maxLength: _maxChars,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textHeading,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      counterText: '',
                      hintText:
                          'Describe what happened, who was involved, and any immediate action taken...',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                        color: _placeholder,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${widget.controller.text.length}/$_maxChars',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: _counter,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Evidence section with Files / Notes tabs (BUG_Report016).
class _EvidenceSection extends StatelessWidget {
  final IncidentCreationController controller;

  const _EvidenceSection({required this.controller});

  static const String _uploadAsset = 'assets/icons/staff_incidents/upload.svg';
  static const Color _teal = Color(0xFF0E7C7B);
  static const Color _mint = Color(0xFFDFF3F1);
  static const Color _dash = Color(0xFF94A3B8);
  static const Color _meta = Color(0xFF94A3B8);
  static const Color _rowFill = Color(0xFFF4F7F9);

  @override
  Widget build(BuildContext context) {
    final cardRadius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final dashRadius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 44);

    return Container(
      key: const Key('staff-incident-evidence'),
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Attach evidence, add final notes, and confirm who\'s been notified.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const CreateIncidentFieldLabel('Evidence (photos, documents)'),
          GestureDetector(
            key: const Key('staff-incident-evidence-upload'),
            onTap: controller.pickEvidence,
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: _dash,
                radius: dashRadius,
                strokeWidth: 1.4,
                dashWidth: 5,
                dashGap: 4,
              ),
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  vertical: 22,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: _mint,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon(
                        _uploadAsset,
                        size: 20,
                        color: _teal,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 12),
                    ),
                    Text(
                      'Tap to upload photo or file',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13.5,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Text(
                      'Image, PDF or document · up to 15MB each',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          11.5,
                        ),
                        color: _meta,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            final files = controller.evidenceFiles;
            if (files.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 12),
                ),
                for (final file in files) ...[
                  _EvidenceFileRow(
                    extension: file.extensionLabel,
                    name: file.fileName,
                    sizeLabel: file.sizeLabel,
                    badgeColor: file.extensionLabel == 'PDF'
                        ? const Color(0xFFE5484D)
                        : const Color(0xFF2A5DA6),
                    onRemove: () => controller.removeEvidence(file),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 8),
                  ),
                ],
              ],
            );
          }),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          const CreateIncidentFieldLabel('Transcription / Additional Notes'),
          CreateIncidentTextField(
            key: const Key('staff-incident-additional-notes'),
            controller: controller.transcriptionController,
            hint: 'Transcription / additional notes will appear here…',
            maxLines: 4,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          _PartiesNotifiedCard(controller: controller),
        ],
      ),
    );
  }
}

class _PartiesNotifiedCard extends StatelessWidget {
  final IncidentCreationController controller;

  const _PartiesNotifiedCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('staff-incident-parties-notified'),
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parties Notified',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            'Track who has been informed of this incident and when.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Obx(() {
            final parties = controller.partyNotifications;
            return Column(
              children: [
                for (var i = 0; i < parties.length; i++) ...[
                  _PartyNotificationRow(
                    index: i,
                    party: parties[i],
                    controller: controller,
                  ),
                  if (i < parties.length - 1)
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 10),
                    ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _PartyNotificationRow extends StatelessWidget {
  final int index;
  final StaffIncidentPartyNotification party;
  final IncidentCreationController controller;

  const _PartyNotificationRow({
    required this.index,
    required this.party,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  party.party,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Switch(
                value: party.notified,
                onChanged: (value) => controller.updatePartyNotification(
                  index,
                  notified: value,
                ),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.secondaryTeal,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.cardBorder,
                trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (party.notified) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            TextFormField(
              initialValue: party.contactName,
              decoration: const InputDecoration(
                hintText: 'Contact name (optional)',
                isDense: true,
              ),
              onChanged: (value) => controller.updatePartyNotification(
                index,
                contactName: value,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            TextFormField(
              initialValue: party.dateNotified,
              decoration: const InputDecoration(
                hintText: 'Date notified (yyyy-mm-dd)',
                isDense: true,
              ),
              onChanged: (value) => controller.updatePartyNotification(
                index,
                dateNotified: value,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceFileRow extends StatelessWidget {
  final String extension;
  final String name;
  final String sizeLabel;
  final Color badgeColor;
  final VoidCallback onRemove;

  const _EvidenceFileRow({
    required this.extension,
    required this.name,
    required this.sizeLabel,
    required this.badgeColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: _EvidenceSection._rowFill,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              extension,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                color: badgeColor,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  sizeLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: _EvidenceSection._meta,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: _EvidenceSection._meta,
            ),
          ),
        ],
      ),
    );
  }
}


class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}