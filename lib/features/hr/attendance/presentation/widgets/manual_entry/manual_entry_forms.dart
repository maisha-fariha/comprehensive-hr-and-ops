import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/manual_entry_options.dart';
import 'manual_entry_fields.dart';

/// Step 1 — residence, staff, optional rostered shift.
class ManualEntryDetailsForm extends StatelessWidget {
  final String? residenceValue;
  final bool isLoadingResidences;
  final VoidCallback? onResidenceTap;
  final TextEditingController staffSearchController;
  final ValueChanged<String>? onStaffSearchChanged;
  final List<ManualEntryStaffOption> staffResults;
  final bool isLoadingStaff;
  final ManualEntryStaffOption? selectedStaff;
  final ValueChanged<ManualEntryStaffOption>? onStaffSelected;
  final String? rosteredShiftValue;
  final bool isLoadingShifts;
  final VoidCallback? onRosteredShiftTap;
  final bool canPickShift;

  const ManualEntryDetailsForm({
    super.key,
    this.residenceValue,
    this.isLoadingResidences = false,
    this.onResidenceTap,
    required this.staffSearchController,
    this.onStaffSearchChanged,
    this.staffResults = const [],
    this.isLoadingStaff = false,
    this.selectedStaff,
    this.onStaffSelected,
    this.rosteredShiftValue,
    this.isLoadingShifts = false,
    this.onRosteredShiftTap,
    this.canPickShift = false,
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 8,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ManualEntrySectionIntro(
            title: 'Attendance Details',
            subtitle:
                'Choose the staff member, the home, and the shift this entry corrects.',
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          const ManualEntryFieldLabel('Residence', required: true),
          ManualEntryDropdownField(
            value: isLoadingResidences
                ? 'Loading residences…'
                : residenceValue,
            placeholder: 'Select residence',
            onTap: isLoadingResidences ? null : onResidenceTap,
            enabled: !isLoadingResidences,
          ),
          gap,
          const ManualEntryFieldLabel('Staff Member', required: true),
          ManualEntrySearchField(
            controller: staffSearchController,
            hint: 'Search staff by name...',
            onChanged: onStaffSearchChanged,
          ),
          if (selectedStaff != null) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            _SelectedStaffChip(staff: selectedStaff!),
          ],
          if (isLoadingStaff) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ),
          ] else if (staffResults.isNotEmpty && selectedStaff == null) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            for (final staff in staffResults)
              _StaffResultTile(
                staff: staff,
                onTap: onStaffSelected == null
                    ? null
                    : () => onStaffSelected!(staff),
              ),
          ],
          gap,
          const ManualEntryFieldLabel('Rostered Shift'),
          ManualEntryDropdownField(
            value: isLoadingShifts
                ? 'Loading shifts…'
                : rosteredShiftValue,
            placeholder: canPickShift
                ? 'Select rostered shift'
                : 'Choose a staff member first',
            onTap: canPickShift && !isLoadingShifts ? onRosteredShiftTap : null,
            enabled: canPickShift && !isLoadingShifts,
          ),
          const ManualEntryHelperText(
            'Optional. A correction with no rostered shift behind it is normal.',
          ),
        ],
      ),
    );
  }
}

class _SelectedStaffChip extends StatelessWidget {
  final ManualEntryStaffOption staff;

  const _SelectedStaffChip({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.activeBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
      ),
      child: Text(
        '${staff.name}${staff.detail.isEmpty ? '' : ' · ${staff.detail}'}',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: AppColors.activeGreen,
        ),
      ),
    );
  }
}

class _StaffResultTile extends StatelessWidget {
  final ManualEntryStaffOption staff;
  final VoidCallback? onTap;

  const _StaffResultTile({required this.staff, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 4,
            vertical: 10,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: ResponsiveHelper.getResponsiveSize(context, 16),
                backgroundColor: AppColors.infoBackground,
                child: Text(
                  staff.initials,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: AppColors.infoBlue,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13.5,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (staff.detail.isNotEmpty)
                      Text(
                        staff.detail,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            11.5,
                          ),
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2 — original clock times vs corrected times (reference layout).
class ManualEntryTimeCorrectionForm extends StatelessWidget {
  static const String dateTimePlaceholder = 'mm/dd/yyyy --:-- --';

  final String? originalCheckInValue;
  final VoidCallback? onOriginalCheckInTap;
  final String? originalCheckOutValue;
  final VoidCallback? onOriginalCheckOutTap;
  final String? correctedCheckInValue;
  final VoidCallback? onCorrectedCheckInTap;
  final String? correctedCheckOutValue;
  final VoidCallback? onCorrectedCheckOutTap;
  final String unpaidBreakValue;
  final VoidCallback? onUnpaidBreakTap;
  final String? paySummaryText;

  const ManualEntryTimeCorrectionForm({
    super.key,
    this.originalCheckInValue,
    this.onOriginalCheckInTap,
    this.originalCheckOutValue,
    this.onOriginalCheckOutTap,
    this.correctedCheckInValue,
    this.onCorrectedCheckInTap,
    this.correctedCheckOutValue,
    this.onCorrectedCheckOutTap,
    this.unpaidBreakValue = 'None',
    this.onUnpaidBreakTap,
    this.paySummaryText,
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 8,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ManualEntrySectionIntro(
            title: 'Time Correction',
            subtitle:
                'State what the clock recorded, and what it should have been.',
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          _OriginalClockGroup(
            originalCheckInValue: originalCheckInValue,
            onOriginalCheckInTap: onOriginalCheckInTap,
            originalCheckOutValue: originalCheckOutValue,
            onOriginalCheckOutTap: onOriginalCheckOutTap,
          ),
          gap,
          const ManualEntryFieldLabel('Corrected clock-in', required: true),
          ManualEntryDateTimeField(
            value: correctedCheckInValue,
            placeholder: dateTimePlaceholder,
            onTap: onCorrectedCheckInTap,
          ),
          gap,
          const ManualEntryFieldLabel('Corrected clock-out'),
          ManualEntryDateTimeField(
            value: correctedCheckOutValue,
            placeholder: dateTimePlaceholder,
            onTap: onCorrectedCheckOutTap,
          ),
          const ManualEntryHelperText(
            'Leave empty for a shift still in progress.',
          ),
          gap,
          const ManualEntryFieldLabel('Unpaid break'),
          ManualEntryDropdownField(
            value: unpaidBreakValue,
            placeholder: 'None',
            onTap: onUnpaidBreakTap,
          ),
          const ManualEntryHelperText('Subtracted from worked time.'),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          _PaySummaryBanner(
            text: paySummaryText ??
                'Enter both times to see what this entry will pay.',
            emphasized: paySummaryText != null,
          ),
        ],
      ),
    );
  }
}

class _OriginalClockGroup extends StatelessWidget {
  final String? originalCheckInValue;
  final VoidCallback? onOriginalCheckInTap;
  final String? originalCheckOutValue;
  final VoidCallback? onOriginalCheckOutTap;

  const _OriginalClockGroup({
    this.originalCheckInValue,
    this.onOriginalCheckInTap,
    this.originalCheckOutValue,
    this.onOriginalCheckOutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What the clock recorded',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const ManualEntryFieldLabel('Original clock-in'),
          ManualEntryDateTimeField(
            value: originalCheckInValue,
            placeholder: ManualEntryTimeCorrectionForm.dateTimePlaceholder,
            onTap: onOriginalCheckInTap,
          ),
          const ManualEntryHelperText(
            'Leave empty if there was no clock record at all.',
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          const ManualEntryFieldLabel('Original clock-out'),
          ManualEntryDateTimeField(
            value: originalCheckOutValue,
            placeholder: ManualEntryTimeCorrectionForm.dateTimePlaceholder,
            onTap: onOriginalCheckOutTap,
          ),
        ],
      ),
    );
  }
}

class _PaySummaryBanner extends StatelessWidget {
  final String text;
  final bool emphasized;

  const _PaySummaryBanner({
    required this.text,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: emphasized ? AppColors.infoBlue : AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Step 3 — reason dropdown, notes, and evidence upload (reference layout).
class ManualEntryEvidenceForm extends StatelessWidget {
  final String? reasonValue;
  final VoidCallback? onReasonTap;
  final TextEditingController notesController;
  final List<ManualEntryEvidenceFile> evidenceFiles;
  final VoidCallback? onAddEvidenceTap;
  final ValueChanged<ManualEntryEvidenceFile>? onRemoveEvidence;

  const ManualEntryEvidenceForm({
    super.key,
    this.reasonValue,
    this.onReasonTap,
    required this.notesController,
    this.evidenceFiles = const [],
    this.onAddEvidenceTap,
    this.onRemoveEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 8,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ManualEntrySectionIntro(
            title: 'Reason & Evidence',
            subtitle:
                'A pay claim that does not say why is indistinguishable from an error.',
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          const ManualEntryFieldLabel('Reason', required: true),
          ManualEntryDropdownField(
            value: reasonValue,
            placeholder: 'Why is this being entered by hand?',
            onTap: onReasonTap,
          ),
          gap,
          const ManualEntryFieldLabel('Notes'),
          ManualEntryTextField(
            controller: notesController,
            hint: "What happened, in the claimant's own words...",
            maxLines: 5,
          ),
          gap,
          const ManualEntryFieldLabel('Evidence'),
          _EvidenceUploadZone(onTap: onAddEvidenceTap),
          if (evidenceFiles.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            for (final file in evidenceFiles) ...[
              _EvidenceFileChip(
                file: file,
                onRemove: onRemoveEvidence == null
                    ? null
                    : () => onRemoveEvidence!(file),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            ],
          ],
        ],
      ),
    );
  }
}

class _EvidenceUploadZone extends StatelessWidget {
  final VoidCallback? onTap;

  const _EvidenceUploadZone({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: AppColors.searchBorder,
          radius: ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 22,
          ),
          child: Column(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 40),
                height: ResponsiveHelper.getResponsiveSize(context, 40),
                decoration: BoxDecoration(
                  color: AppColors.infoBackground,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 10),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: ResponsiveHelper.getResponsiveSize(context, 22),
                  color: AppColors.infoBlue,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textSecondary,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Click to upload',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                    TextSpan(text: ' or drag & drop'),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
              Text(
                'A rota screenshot, a signed sheet. PDF, DOCX, PNG - up to 15MB each',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenceFileChip extends StatelessWidget {
  final ManualEntryEvidenceFile file;
  final VoidCallback? onRemove;

  const _EvidenceFileChip({
    required this.file,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = file.uploadError != null
        ? AppColors.criticalRed
        : file.isReady
            ? AppColors.activeGreen
            : AppColors.textMuted;
    final statusText = file.uploadError ??
        (file.isUploading
            ? 'Uploading…'
            : file.isReady
                ? 'Uploaded'
                : 'Pending upload');

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Row(
        children: [
          if (file.isUploading)
            SizedBox(
              width: ResponsiveHelper.getResponsiveSize(context, 18),
              height: ResponsiveHelper.getResponsiveSize(context, 18),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.secondaryTeal,
              ),
            )
          else
            Icon(
              Icons.insert_drive_file_outlined,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: AppColors.infoBlue,
            ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.close_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  static const double _strokeWidth = 1.5;
  static const double _dashWidth = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

/// Step 4 — approval summary + status + note (reference layout).
class ManualEntryApprovalForm extends StatelessWidget {
  final String reasonLabel;
  final String evidenceLabel;
  final String correctedClockInLabel;
  final String correctedClockOutLabel;
  final String wasRecordedAsLabel;
  final String unpaidBreakLabel;
  final String statusValue;
  final VoidCallback? onStatusTap;
  final TextEditingController noteController;

  const ManualEntryApprovalForm({
    super.key,
    required this.reasonLabel,
    required this.evidenceLabel,
    required this.correctedClockInLabel,
    required this.correctedClockOutLabel,
    required this.wasRecordedAsLabel,
    required this.unpaidBreakLabel,
    required this.statusValue,
    this.onStatusTap,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 8,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ManualEntrySectionIntro(
            title: 'Approval',
            subtitle:
                'Manual entries feed payroll once approved, so the decision is recorded with a reason.',
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          _ApprovalSummaryCard(
            rows: [
              _ApprovalSummaryRow(label: 'REASON', value: reasonLabel),
              _ApprovalSummaryRow(label: 'EVIDENCE', value: evidenceLabel),
              _ApprovalSummaryRow(
                label: 'CORRECTED CLOCK-IN',
                value: correctedClockInLabel,
              ),
              _ApprovalSummaryRow(
                label: 'CORRECTED CLOCK-OUT',
                value: correctedClockOutLabel,
              ),
              _ApprovalSummaryRow(
                label: 'WAS RECORDED AS',
                value: wasRecordedAsLabel,
              ),
              _ApprovalSummaryRow(
                label: 'UNPAID BREAK',
                value: unpaidBreakLabel,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          const ManualEntryFieldLabel('Status', required: true),
          ManualEntryDropdownField(
            value: statusValue,
            placeholder: 'Select status',
            onTap: onStatusTap,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          const ManualEntryFieldLabel('Note'),
          ManualEntryTextField(
            controller: noteController,
            hint: 'Add a note for this approval decision…',
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _ApprovalSummaryCard extends StatelessWidget {
  final List<_ApprovalSummaryRow> rows;

  const _ApprovalSummaryCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          ],
        ],
      ),
    );
  }
}

class _ApprovalSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _ApprovalSummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: AppColors.textHeading,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
