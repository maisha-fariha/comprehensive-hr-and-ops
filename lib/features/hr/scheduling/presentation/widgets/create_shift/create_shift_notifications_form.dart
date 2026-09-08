import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/shift_reminder_option.dart';
import 'create_shift_fields.dart';

/// Notifications tab body — assignee notify toggle, reminder, custom message.
class CreateShiftNotificationsForm extends StatelessWidget {
  final bool notifyAssignedStaff;
  final ValueChanged<bool> onNotifyAssignedStaffChanged;
  final ShiftReminderOption selectedReminder;
  final VoidCallback onReminderTap;
  final TextEditingController messageController;

  const CreateShiftNotificationsForm({
    super.key,
    required this.notifyAssignedStaff,
    required this.onNotifyAssignedStaffChanged,
    required this.selectedReminder,
    required this.onReminderTap,
    required this.messageController,
  });

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18));

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
            'Notifications',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            'Choose whether the people on this shift are told, and when they are reminded.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          _NotifyToggleCard(
            value: notifyAssignedStaff,
            onChanged: onNotifyAssignedStaffChanged,
          ),
          gap,
          const CreateShiftFieldLabel('Reminder'),
          CreateShiftDropdownField(
            value: selectedReminder.label,
            placeholder: 'Select an option',
            onTap: onReminderTap,
          ),
          const CreateShiftHelperText(
            'A second notification this long before the shift starts.',
          ),
          gap,
          const CreateShiftFieldLabel('Custom Message'),
          CreateShiftTextField(
            controller: messageController,
            hint:
                'Add a note included in the notification instead of the shift time...',
            maxLines: 4,
            keyboardType: TextInputType.multiline,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          const _TenantSettingsNote(),
        ],
      ),
    );
  }
}

class _NotifyToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifyToggleCard({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        side: const BorderSide(color: AppColors.searchBorder),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notify assigned staff',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          14.5,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                    ),
                    Text(
                      'Send each assignee a notification as soon as the shift is saved. Turn off while drafting a rota.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Switch(
                value: value,
                onChanged: onChanged,
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
        ),
      ),
    );
  }
}

class _TenantSettingsNote extends StatelessWidget {
  const _TenantSettingsNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F8),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          children: const [
            TextSpan(
              text:
                  'Quiet hours, digests and which channels each notification uses are set once for the whole tenant, under ',
            ),
            TextSpan(
              text: 'Settings → Notifications',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
