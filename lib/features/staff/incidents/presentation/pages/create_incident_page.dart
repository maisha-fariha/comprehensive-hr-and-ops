import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../../domain/repositories/staff_incidents_repository.dart';
import '../controllers/incident_creation_controller.dart';
import '../widgets/create_incident/create_incident_form_fields.dart';
import '../widgets/create_incident/numbered_section_header.dart';
import '../widgets/create_incident/severity_pill_selector.dart';
import '../widgets/staff_incidents_header.dart';

/// The single-page "Create Incident" form, reached from the "+ Create
/// Incident" button on the Staff Incidents list screen.
///
/// Unlike the Manager Incidents feature's 4-step wizard, the Figma
/// "Create Incident - Incidents" screenshot shows a single scrollable form
/// (Incident Details / Severity / People & Location sections + a bottom
/// action bar), so this page mirrors that simpler shape.
///
/// Hosts [StaffBottomNavBar] with "More" selected so the pushed route still
/// matches reference frames that show the staff bottom nav.
class CreateIncidentPage extends StatelessWidget {
  const CreateIncidentPage({super.key});

  /// Index of the "More" slot in [StaffBottomNavBar.items].
  static const int _moreTabIndex = 4;

  /// Always starts a fresh controller instance for a new draft rather than
  /// resolving the `get_it`-registered singleton - reusing the same
  /// instance across multiple "Create Incident" sessions would resurface a
  /// previous draft's field values, and its `TextEditingController`s would
  /// already be disposed after the first time this page is closed (see the
  /// identical rationale on the Manager Incidents wizard's page).
  IncidentCreationController _resolveController() {
    if (Get.isRegistered<IncidentCreationController>()) {
      Get.delete<IncidentCreationController>(force: true);
    }
    return Get.put(
      IncidentCreationController(
        repository: GetIt.instance<StaffIncidentsRepository>(),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final sectionGap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 26));
    final fieldGap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.surfaceWhite,
              child: StaffIncidentsHeader(
                title: 'Create Incident',
                subtitle: 'Report incident for safety, compliance & supervisor review',
                onBack: Get.back,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, vertical: 20),
                child: Column(
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
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        all: 16,
                      ),
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
                            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CreateIncidentFieldLabel('Incident Category', required: true),
                          Obx(
                            () => CreateIncidentDropdownField(
                              value: controller.incidentCategoryLabel,
                              placeholder: 'Select category...',
                              onTap: controller.pickCategory,
                            ),
                          ),
                          Obx(() {
                            if (controller.cirTemplates.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldGap,
                                const CreateIncidentFieldLabel('CIR Template'),
                                CreateIncidentDropdownField(
                                  value: controller.cirTemplateLabel,
                                  placeholder: 'Select template...',
                                  onTap: controller.pickCirTemplate,
                                ),
                              ],
                            );
                          }),
                          fieldGap,
                          const CreateIncidentFieldLabel('Incident Title', required: true),
                          CreateIncidentTextField(
                            controller: controller.incidentTitleController,
                            hint: 'e.g. Fall – No Injury',
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
                                    const CreateIncidentFieldLabel('Date', required: true),
                                    GestureDetector(
                                      onTap: () => controller.pickDate(context),
                                      behavior: HitTestBehavior.opaque,
                                      child: AbsorbPointer(
                                        child: CreateIncidentDateField(
                                          controller: controller.incidentDateController,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CreateIncidentFieldLabel('Time', required: true),
                                    GestureDetector(
                                      onTap: () => controller.pickTime(context),
                                      behavior: HitTestBehavior.opaque,
                                      child: AbsorbPointer(
                                        child: CreateIncidentTimeField(
                                          controller: controller.incidentTimeController,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          fieldGap,
                          const CreateIncidentFieldLabel('Detected During', required: true),
                          Obx(
                            () => CreateIncidentDropdownField(
                              value: controller.detectedDuring.value,
                              placeholder: 'Select context...',
                              onTap: controller.pickDetectedDuring,
                            ),
                          ),
                        ],
                      ),
                    ),
                    sectionGap,
                    const NumberedSectionHeader(
                      number: 2,
                      title: 'SEVERITY',
                      required: true,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    Obx(
                      () => SeverityPillSelector(
                        selected: controller.severity.value,
                        onChanged: controller.selectSeverity,
                      ),
                    ),
                    sectionGap,
                    const NumberedSectionHeader(
                      number: 3,
                      title: 'PEOPLE & LOCATION',
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
                            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CreateIncidentFieldLabel('Resident / Client', required: true),
                          Obx(
                            () => CreateIncidentDropdownField(
                              value: controller.residentLabel,
                              placeholder: 'Select resident...',
                              onTap: controller.pickResident,
                            ),
                          ),
                          fieldGap,
                          const CreateIncidentFieldLabel('Location'),
                          CreateIncidentTextField(
                            controller: controller.locationController,
                            hint: 'e.g. Bathroom 2',
                          ),
                          fieldGap,
                          const CreateIncidentFieldLabel('Reported By'),
                          Obx(
                            () => _ReportedByField(
                              name: controller.reporterName.value,
                              meta: controller.reporterMeta.value,
                              initials: controller.reporterInitials.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                    sectionGap,
                    const NumberedSectionHeader(number: 4, title: 'DESCRIPTION'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    _DescriptionSection(
                      controller: controller.descriptionController,
                    ),
                    sectionGap,
                    const NumberedSectionHeader(
                      number: 5,
                      title: 'EVIDENCE',
                      trailingLabel: 'OPTIONAL',
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    _EvidenceSection(controller: controller),
                    sectionGap,
                    const NumberedSectionHeader(
                      number: 6,
                      title: 'FOLLOW-UP CHECKLIST',
                      trailingLabel: 'OPTIONAL',
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    _FollowUpChecklistSection(controller: controller),
                    sectionGap,
                    const NumberedSectionHeader(
                      number: 7,
                      title: 'CURRENT STATUS',
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    const _CurrentStatusSection(),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                    _CreateIncidentActions(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

/// Read-only "Reported By" row from `GET /mobile/me` / session (Auto).
class _ReportedByField extends StatelessWidget {
  final String name;
  final String meta;
  final String initials;

  const _ReportedByField({
    required this.name,
    required this.meta,
    required this.initials,
  });

  static const Color _fill = Color(0xFFF4F7F9);
  static const Color _avatarBg = Color(0xFFE8F0FE);
  static const Color _avatarFg = Color(0xFF2A5DA6);
  static const Color _autoBg = Color(0xFFE6F6EE);
  static const Color _autoFg = Color(0xFF2E8C58);
  static const Color _meta = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              color: _avatarBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: _avatarFg,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: _meta,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _autoBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Auto',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                color: _autoFg,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Evidence upload card — `POST /uploads?category=incidents`.
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
          GestureDetector(
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
                      child: const AppSvgIcon(_uploadAsset, size: 20, color: _teal),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    Text(
                      'Tap to upload photo or file',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                    Text(
                      'Images, PDF · uploaded as incidents',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
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
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
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
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                ],
              ],
            );
          }),
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


/// Optional follow-up checklist — tri-state null / true / false.
class _FollowUpChecklistSection extends StatelessWidget {
  final IncidentCreationController controller;

  const _FollowUpChecklistSection({required this.controller});

  static const Color _checkedGreen = Color(0xFF2E8C58);
  static const Color _falseAmber = Color(0xFFD97706);
  static const Color _checkedLabel = Color(0xFF94A3B8);
  static const Color _boxBorder = Color(0xFFCBD5E1);
  static const Color _divider = Color(0xFFEDF2F5);

  @override
  Widget build(BuildContext context) {
    final boxSize = ResponsiveHelper.getResponsiveSize(context, 22);
    final boxRadius = ResponsiveHelper.getResponsiveRadius(context, 6);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 4,
      ),
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
      child: Obx(() {
        final rows = <(String, bool?, VoidCallback)>[
          (
            'Resident checked & safe',
            controller.residentChecked.value,
            () => controller.cycleChecklist(controller.residentChecked),
          ),
          (
            'Supervisor notified',
            controller.supervisorNotified.value,
            () => controller.cycleChecklist(controller.supervisorNotified),
          ),
          (
            'Family / next of kin informed',
            controller.familyNotified.value,
            () => controller.cycleChecklist(controller.familyNotified),
          ),
          (
            'Care plan reviewed & updated',
            controller.carePlanReviewed.value,
            () => controller.cycleChecklist(controller.carePlanReviewed),
          ),
        ];

        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, thickness: 1, color: _divider),
              _ChecklistRow(
                label: rows[i].$1,
                value: rows[i].$2,
                onTap: rows[i].$3,
                boxSize: boxSize,
                boxRadius: boxRadius,
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final bool? value;
  final VoidCallback onTap;
  final double boxSize;
  final double boxRadius;

  const _ChecklistRow({
    required this.label,
    required this.value,
    required this.onTap,
    required this.boxSize,
    required this.boxRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isTrue = value == true;
    final isFalse = value == false;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: isTrue
                    ? _FollowUpChecklistSection._checkedGreen
                    : isFalse
                        ? _FollowUpChecklistSection._falseAmber
                            .withValues(alpha: 0.15)
                        : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(boxRadius),
                border: Border.all(
                  color: isTrue
                      ? _FollowUpChecklistSection._checkedGreen
                      : isFalse
                          ? _FollowUpChecklistSection._falseAmber
                          : _FollowUpChecklistSection._boxBorder,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isTrue
                  ? Icon(
                      Icons.check_rounded,
                      size: ResponsiveHelper.getResponsiveSize(context, 14),
                      color: Colors.white,
                    )
                  : isFalse
                      ? Icon(
                          Icons.close_rounded,
                          size: ResponsiveHelper.getResponsiveSize(context, 14),
                          color: _FollowUpChecklistSection._falseAmber,
                        )
                      : null,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: isTrue
                      ? _FollowUpChecklistSection._checkedLabel
                      : AppColors.textHeading,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Status options for the Create Incident "Current Status" chips.
enum _CreateIncidentFormStatus {
  draft('Draft'),
  submitted('Submitted'),
  underInvestigation('Under Investigation'),
  resolved('Resolved');

  final String label;
  const _CreateIncidentFormStatus(this.label);
}

/// White card with wrap-layout status chips (Draft selected by default).
class _CurrentStatusSection extends StatefulWidget {
  const _CurrentStatusSection();

  @override
  State<_CurrentStatusSection> createState() => _CurrentStatusSectionState();
}

class _CurrentStatusSectionState extends State<_CurrentStatusSection> {
  static const Color _teal = Color(0xFF0E7C7B);
  static const Color _selectedBg = Color(0xFFE6F4F3);
  static const Color _idleBg = Color(0xFFF4F7F9);
  static const Color _idleLabel = Color(0xFF94A3B8);

  _CreateIncidentFormStatus _selected = _CreateIncidentFormStatus.draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
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
      child: Wrap(
        spacing: ResponsiveHelper.getResponsiveWidth(context, 8),
        runSpacing: ResponsiveHelper.getResponsiveHeight(context, 8),
        children: [
          for (final status in _CreateIncidentFormStatus.values)
            GestureDetector(
              onTap: () => setState(() => _selected = status),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: status == _selected ? _selectedBg : _idleBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: status == _selected ? _teal : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: status == _selected ? _teal : _idleLabel,
                    height: 1.15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// Cancel + Submit Incident row. Submit → `POST /incidents` (status open).
class _CreateIncidentActions extends StatelessWidget {
  final IncidentCreationController controller;

  const _CreateIncidentActions({required this.controller});

  static const Color _submit = Color(0xFF0E7C7B);
  static const Color _cancelBorder = Color(0xFFE2E8F0);
  static const Color _cancelLabel = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Obx(() {
      final busy = controller.isSubmitting.value;
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: busy ? null : Get.back,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: ResponsiveHelper.getResponsiveHeight(context, 52),
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
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: _cancelLabel,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: busy ? null : controller.submit,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: ResponsiveHelper.getResponsiveHeight(context, 52),
                ),
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 12,
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
                        width: ResponsiveHelper.getResponsiveSize(context, 18),
                        height: ResponsiveHelper.getResponsiveSize(context, 18),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      SvgPicture.asset(
                        'assets/icons/staff_incidents/submit.svg',
                        width: ResponsiveHelper.getResponsiveSize(context, 18),
                      ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 8),
                    ),
                    Flexible(
                      child: Text(
                        busy ? 'Submitting…' : 'Submit Incident',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            14,
                          ),
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

