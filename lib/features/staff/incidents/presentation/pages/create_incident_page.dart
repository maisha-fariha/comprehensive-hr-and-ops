import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
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
    return Get.put(IncidentCreationController());
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
                              value: controller.incidentCategory.value,
                              placeholder: 'Select category...',
                            ),
                          ),
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
                                    CreateIncidentDateField(
                                      controller: controller.incidentDateController,
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
                                    CreateIncidentTimeField(
                                      controller: controller.incidentTimeController,
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
                              value: controller.resident.value,
                              placeholder: 'Select resident...',
                            ),
                          ),
                          fieldGap,
                          const CreateIncidentFieldLabel('Location'),
                          Obx(
                            () => CreateIncidentDropdownField(
                              value: controller.location.value,
                              placeholder: 'Select location...',
                            ),
                          ),
                          fieldGap,
                          const CreateIncidentFieldLabel('Reported By'),
                          const _ReportedByField(),
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
                    const _EvidenceSection(),
                    sectionGap,
                    const NumberedSectionHeader(
                      number: 6,
                      title: 'FOLLOW-UP CHECKLIST',
                      trailingLabel: 'OPTIONAL',
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    const _FollowUpChecklistSection(),
                    sectionGap,
                    const NumberedSectionHeader(
                      number: 7,
                      title: 'CURRENT STATUS',
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    const _CurrentStatusSection(),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                    const _CreateIncidentActions(),
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

/// Read-only "Reported By" row (UI-hardcoded David L. + Auto badge).
class _ReportedByField extends StatelessWidget {
  const _ReportedByField();

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
              'DL',
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
                  'David L.',
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
                  'Care Staff · Sunrise Home',
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

class _EvidenceFile {
  final String extension;
  final String name;
  final String sizeLabel;
  final Color badgeColor;

  const _EvidenceFile({
    required this.extension,
    required this.name,
    required this.sizeLabel,
    required this.badgeColor,
  });
}

/// Evidence upload card with dashed drop zone + UI-hardcoded sample files.
class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection();

  static const String _uploadAsset = 'assets/icons/staff_incidents/upload.svg';
  static const Color _teal = Color(0xFF0E7C7B);
  static const Color _mint = Color(0xFFDFF3F1);
  static const Color _dash = Color(0xFF94A3B8);
  static const Color _meta = Color(0xFF94A3B8);
  static const Color _rowFill = Color(0xFFF4F7F9);

  static const List<_EvidenceFile> _files = [
    _EvidenceFile(
      extension: 'JPG',
      name: 'hallway-photo.jpg',
      sizeLabel: '1.8 MB',
      badgeColor: Color(0xFF2A5DA6),
    ),
    _EvidenceFile(
      extension: 'PDF',
      name: 'witness-statement.pdf',
      sizeLabel: '240 KB',
      badgeColor: Color(0xFFE5484D),
    ),
  ];

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
          CustomPaint(
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
                    'Upload files',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textHeading,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Text(
                    'PDF, JPG or PNG • multiple allowed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: _meta,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          for (var i = 0; i < _files.length; i++) ...[
            if (i > 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            _EvidenceFileRow(file: _files[i]),
          ],
        ],
      ),
    );
  }
}

class _EvidenceFileRow extends StatelessWidget {
  final _EvidenceFile file;

  const _EvidenceFileRow({required this.file});

  @override
  Widget build(BuildContext context) {
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Container(
      width: double.infinity,
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
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: file.badgeColor,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 10),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              file.extension,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                color: Colors.white,
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
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  file.sizeLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: _EvidenceSection._meta,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.close_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 18),
            color: _EvidenceSection._meta,
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

class _ChecklistItem {
  final String label;
  bool checked;

  _ChecklistItem({required this.label, required this.checked});
}

/// Optional follow-up checklist card; first two items start checked.
class _FollowUpChecklistSection extends StatefulWidget {
  const _FollowUpChecklistSection();

  @override
  State<_FollowUpChecklistSection> createState() => _FollowUpChecklistSectionState();
}

class _FollowUpChecklistSectionState extends State<_FollowUpChecklistSection> {
  static const Color _checkedGreen = Color(0xFF2E8C58);
  static const Color _checkedLabel = Color(0xFF94A3B8);
  static const Color _boxBorder = Color(0xFFCBD5E1);
  static const Color _divider = Color(0xFFEDF2F5);

  late final List<_ChecklistItem> _items = [
    _ChecklistItem(label: 'Resident checked & safe', checked: true),
    _ChecklistItem(label: 'Supervisor notified', checked: true),
    _ChecklistItem(label: 'Family / next of kin informed', checked: false),
    _ChecklistItem(label: 'Care plan reviewed & updated', checked: false),
  ];

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
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: Divider(height: 1, thickness: 1, color: _divider),
              ),
            GestureDetector(
              onTap: () => setState(() => _items[i].checked = !_items[i].checked),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        color: _items[i].checked ? _checkedGreen : AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(boxRadius),
                        border: Border.all(
                          color: _items[i].checked ? _checkedGreen : _boxBorder,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _items[i].checked
                          ? Icon(
                              Icons.check_rounded,
                              size: ResponsiveHelper.getResponsiveSize(context, 14),
                              color: Colors.white,
                            )
                          : null,
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                    Expanded(
                      child: Text(
                        _items[i].label,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                          color: _items[i].checked
                              ? _checkedLabel
                              : AppColors.textHeading,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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

/// Cancel + Submit Incident row matching the Create Incident footer reference.
class _CreateIncidentActions extends StatelessWidget {
  const _CreateIncidentActions();

  static const Color _submit = Color(0xFF0E7C7B);
  static const Color _cancelBorder = Color(0xFFE2E8F0);
  static const Color _cancelLabel = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: Get.back,
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
            onTap: Get.back,
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
                color: _submit,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/staff_incidents/submit.svg',
                    width: ResponsiveHelper.getResponsiveSize(context, 18),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                  Flexible(
                    child: Text(
                      'Submit Incident',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
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
  }
}
