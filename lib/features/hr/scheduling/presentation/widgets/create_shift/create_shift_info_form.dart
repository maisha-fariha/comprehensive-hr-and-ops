import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import 'create_shift_fields.dart';

/// "Shift Information" body — timing, residence, and role coverage fields
/// matching the Add New Shift reference.
class CreateShiftInfoForm extends StatelessWidget {
  final TextEditingController peopleNeededController;
  final TextEditingController titleController;

  const CreateShiftInfoForm({
    super.key,
    required this.peopleNeededController,
    required this.titleController,
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
            left: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateShiftFieldLabel('Residence', required: true),
                CreateShiftDropdownField(placeholder: 'Select residence'),
              ],
            ),
            right: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateShiftFieldLabel('Shift Type', required: true),
                CreateShiftDropdownField(
                  value: 'Morning (07:00 – 15:00)',
                  placeholder: 'Select shift type',
                ),
              ],
            ),
          ),
          gap,
          CreateShiftFieldRow(
            left: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateShiftFieldLabel('Shift Date', required: true),
                CreateShiftDateField(value: 'Aug 31, 2026'),
              ],
            ),
            right: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateShiftFieldLabel('Required Qualification'),
                CreateShiftDropdownField(
                  value: 'Anyone can cover this',
                  placeholder: 'Select qualification',
                ),
                CreateShiftHelperText(
                  'Only staff in this category can be assigned or bid.',
                ),
              ],
            ),
          ),
          gap,
          CreateShiftFieldRow(
            left: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateShiftFieldLabel('Start Time', required: true),
                CreateShiftTimeField(value: '07:00 AM'),
              ],
            ),
            right: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateShiftFieldLabel('End Time', required: true),
                CreateShiftTimeField(value: '03:00 PM'),
                CreateShiftHelperText(
                  'Earlier than the start means it runs overnight.',
                ),
              ],
            ),
          ),
          gap,
          const CreateShiftFieldRow(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateShiftFieldLabel('Break Duration'),
                CreateShiftDropdownField(
                  value: '30 minutes',
                  placeholder: 'Select break',
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateShiftFieldLabel('Coverage Level'),
                CreateShiftDropdownField(
                  value: 'Standard',
                  placeholder: 'Select coverage',
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

  const CreateShiftFooter({
    super.key,
    this.onCancel,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;
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
          onTap: onCancel,
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        _FooterButton(
          label: 'Create shift',
          filled: true,
          onTap: onCreate,
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
                            onTap: onCancel,
                            expanded: true,
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveHelper.getResponsiveWidth(context, 10),
                        ),
                        Expanded(
                          child: _FooterButton(
                            label: 'Create shift',
                            filled: true,
                            onTap: onCreate,
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
  final VoidCallback? onTap;

  const _FooterButton({
    required this.label,
    required this.filled,
    this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primaryNavy : AppColors.surfaceWhite,
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
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: filled ? Colors.white : AppColors.textHeading,
            ),
          ),
        ),
      ),
    );
  }
}
