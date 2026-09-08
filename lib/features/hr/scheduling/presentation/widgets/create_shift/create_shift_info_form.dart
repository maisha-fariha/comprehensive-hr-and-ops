import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import 'create_shift_fields.dart';

/// "Shift Information" body — timing, residence, and role coverage fields
/// matching the Add New Shift reference.
class CreateShiftInfoForm extends StatelessWidget {
  final TextEditingController peopleNeededController;
  final TextEditingController titleController;
  final String? residenceValue;
  final bool isLoadingResidences;
  final VoidCallback? onResidenceTap;
  final String? shiftTypeValue;
  final VoidCallback? onShiftTypeTap;
  final String shiftDateValue;
  final VoidCallback? onShiftDateTap;
  final String startTimeValue;
  final VoidCallback? onStartTimeTap;
  final String endTimeValue;
  final VoidCallback? onEndTimeTap;
  final String? qualificationValue;
  final bool isLoadingQualifications;
  final VoidCallback? onQualificationTap;
  final String? breakDurationValue;
  final VoidCallback? onBreakDurationTap;
  final String? coverageLevelValue;
  final VoidCallback? onCoverageLevelTap;

  const CreateShiftInfoForm({
    super.key,
    required this.peopleNeededController,
    required this.titleController,
    this.residenceValue,
    this.isLoadingResidences = false,
    this.onResidenceTap,
    this.shiftTypeValue,
    this.onShiftTypeTap,
    required this.shiftDateValue,
    this.onShiftDateTap,
    required this.startTimeValue,
    this.onStartTimeTap,
    required this.endTimeValue,
    this.onEndTimeTap,
    this.qualificationValue,
    this.isLoadingQualifications = false,
    this.onQualificationTap,
    this.breakDurationValue,
    this.onBreakDurationTap,
    this.coverageLevelValue,
    this.onCoverageLevelTap,
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
          Text(
            'Shift Information',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            'Set the timing, residence, and role coverage for this shift.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Residence', required: true),
                CreateShiftDropdownField(
                  value: residenceValue,
                  placeholder: isLoadingResidences
                      ? 'Loading residences…'
                      : 'Select residence',
                  onTap: onResidenceTap,
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Shift Type', required: true),
                CreateShiftDropdownField(
                  value: shiftTypeValue,
                  placeholder: 'Select shift type',
                  onTap: onShiftTypeTap,
                ),
              ],
            ),
          ),
          gap,
          CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Shift Date', required: true),
                CreateShiftDateField(
                  value: shiftDateValue,
                  onTap: onShiftDateTap,
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Required Qualification'),
                CreateShiftDropdownField(
                  value: qualificationValue,
                  placeholder: isLoadingQualifications
                      ? 'Loading qualifications…'
                      : 'Select qualification',
                  onTap: onQualificationTap,
                ),
                const CreateShiftHelperText(
                  'Only staff in this category can be assigned or bid.',
                ),
              ],
            ),
          ),
          gap,
          CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Start Time', required: true),
                CreateShiftTimeField(
                  value: startTimeValue,
                  onTap: onStartTimeTap,
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('End Time', required: true),
                CreateShiftTimeField(
                  value: endTimeValue,
                  onTap: onEndTimeTap,
                ),
                const CreateShiftHelperText(
                  'Earlier than the start means it runs overnight.',
                ),
              ],
            ),
          ),
          gap,
          CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Break Duration'),
                CreateShiftDropdownField(
                  value: breakDurationValue,
                  placeholder: 'Select break',
                  onTap: onBreakDurationTap,
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Coverage Level'),
                CreateShiftDropdownField(
                  value: coverageLevelValue,
                  placeholder: 'Select coverage',
                  onTap: onCoverageLevelTap,
                ),
              ],
            ),
          ),
          gap,
          CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('People needed'),
                CreateShiftTextField(
                  controller: peopleNeededController,
                  hint: '1',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CreateShiftFieldLabel('Title'),
                CreateShiftTextField(
                  controller: titleController,
                  hint: 'Optional — e.g. Weekend cover',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateShiftPlaceholderSection extends StatelessWidget {
  final String title;
  final String subtitle;

  const CreateShiftPlaceholderSection({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 14),
          ),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateShiftFooter extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onCreate;
  final bool isSubmitting;

  const CreateShiftFooter({
    super.key,
    this.onCancel,
    this.onCreate,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;
    final createEnabled = onCreate != null && !isSubmitting;
    final cancelEnabled = onCancel != null && !isSubmitting;
    final requiredHint = RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          color: AppColors.textSecondary,
        ),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: AppColors.criticalRed),
          ),
          TextSpan(text: ' Required fields'),
        ],
      ),
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FooterButton(
          label: 'Cancel',
          filled: false,
          onTap: cancelEnabled ? onCancel : null,
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        _FooterButton(
          label: isSubmitting ? 'Creating…' : 'Create shift',
          filled: true,
          isLoading: isSubmitting,
          onTap: createEnabled ? onCreate : null,
        ),
      ],
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 20,
            top: 12,
            bottom: 12,
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    requiredHint,
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 12),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _FooterButton(
                            label: 'Cancel',
                            filled: false,
                            onTap: cancelEnabled ? onCancel : null,
                            expanded: true,
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(context, 10),
                        ),
                        Expanded(
                          child: _FooterButton(
                            label: isSubmitting ? 'Creating…' : 'Create shift',
                            filled: true,
                            isLoading: isSubmitting,
                            onTap: createEnabled ? onCreate : null,
                            expanded: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    requiredHint,
                    const Spacer(),
                    actions,
                  ],
                ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool expanded;
  final bool isLoading;
  final VoidCallback? onTap;

  const _FooterButton({
    required this.label,
    required this.filled,
    this.onTap,
    this.expanded = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = filled
        ? (enabled
            ? AppColors.primaryNavy
            : AppColors.primaryNavy.withValues(alpha: 0.55))
        : AppColors.surfaceWhite;
    final foreground = filled
        ? Colors.white
        : (enabled
            ? AppColors.textHeading
            : AppColors.textHeading.withValues(alpha: 0.45));

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: Container(
          width: expanded ? double.infinity : null,
          alignment: Alignment.center,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
            border: filled ? null : Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: ResponsiveHelper.getResponsiveSize(context, 16),
                  height: ResponsiveHelper.getResponsiveSize(context, 16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
