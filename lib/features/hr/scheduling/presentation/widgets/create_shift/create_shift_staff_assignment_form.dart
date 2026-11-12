import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../domain/entities/create_shift_draft.dart';
import '../../../domain/entities/shift_staff_conflict.dart';
import '../../../domain/entities/shift_staff_option.dart';
import 'create_shift_fields.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

const Color _avatarFill = Color(0xFFEAF0FE);
const Color _avatarText = Color(0xFF8E88B1);

/// "Staff Assignment" step — web staffing method (Assign Staff | Open Shift)
/// side-by-side, then either assignees or open-shift bidding fields.
class CreateShiftStaffAssignmentForm extends StatelessWidget {
  final List<AssignedShiftStaff> assignedStaff;
  final List<PendingShiftBid> pendingBids;
  final bool isLoadingStaff;
  final bool isOpenShift;
  final ValueChanged<bool> onOpenShiftChanged;
  final Widget? openShiftFields;
  final VoidCallback onAddStaff;
  final ValueChanged<String> onRemoveStaff;
  final Future<void> Function(PendingShiftBid bid)? onAcceptBid;
  final List<ShiftScheduleConflict> scheduleConflicts;
  final List<ShiftLeaveConflict> leaveConflicts;
  final List<ShiftRestConflict> restConflicts;
  final int? minimumRestHours;
  final TextEditingController? restOverrideReasonController;
  final String? restOverrideReasonError;
  final ValueChanged<String>? onRestOverrideReasonChanged;
  final String? residenceName;

  const CreateShiftStaffAssignmentForm({
    super.key,
    required this.assignedStaff,
    required this.isOpenShift,
    required this.onOpenShiftChanged,
    required this.onAddStaff,
    required this.onRemoveStaff,
    this.pendingBids = const [],
    this.onAcceptBid,
    this.openShiftFields,
    this.isLoadingStaff = false,
    this.scheduleConflicts = const [],
    this.leaveConflicts = const [],
    this.restConflicts = const [],
    this.minimumRestHours,
    this.restOverrideReasonController,
    this.restOverrideReasonError,
    this.onRestOverrideReasonChanged,
    this.residenceName,
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
          CreateShiftSectionHeader(
            title: isOpenShift
                ? 'Staffing · Open Shift'
                : 'Staffing · Staff Assignment',
            description: isOpenShift
                ? 'Configure bidding rules, deadlines, and broadcast to qualified staff.'
                : 'Assign qualified team members directly to this shift, or publish as an open shift.',
          ),
          const CreateShiftFieldLabel('Staffing Method'),
          _StaffingMethodToggle(
            isOpenShift: isOpenShift,
            onChanged: onOpenShiftChanged,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          if (isOpenShift) ...[
            _OpenShiftBroadcast(residenceName: residenceName),
            if (pendingBids.isNotEmpty && onAcceptBid != null) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
              _PendingBidsSection(
                bids: pendingBids,
                onAccept: onAcceptBid!,
              ),
            ],
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            ?openShiftFields,
          ] else ...[
            const CreateShiftFieldLabel('Assigned Staff'),
            _StaffMultiSelectField(
              assignedStaff: assignedStaff,
              isLoading: isLoadingStaff,
              onTap: onAddStaff,
              onRemove: onRemoveStaff,
            ),
            // Web order: rest → leave → overlap (`data-testid` shift-rest / leave / conflicts).
            if (restConflicts.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              _ShiftConflictBanner(
                key: const ValueKey('shift-rest'),
                title:
                    "Less than ${minimumRestHours ?? "the minimum"} hours' rest",
                lines: [
                  for (final row in restConflicts)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize:
                              ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: AppColors.textHeading,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: row.staffName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                ' would have only ${row.restHoursLabel} hours between this shift and ${row.label}.',
                          ),
                        ],
                      ),
                    ),
                ],
                footer: restOverrideReasonController == null
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const CreateShiftFieldLabel(
                            'Reason to roster anyway',
                            required: true,
                          ),
                          CreateShiftTextField(
                            key: const ValueKey('shift-rest-override-reason'),
                            controller: restOverrideReasonController!,
                            hint:
                                'e.g. Emergency cover — two carers off sick, no one else available',
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                            hasError: restOverrideReasonError != null,
                            onChanged: onRestOverrideReasonChanged,
                          ),
                          if (restOverrideReasonError != null)
                            CreateShiftErrorText(restOverrideReasonError!)
                          else
                            const CreateShiftHelperText(
                              'Saved with the shift and kept in the audit log. Or choose someone else.',
                            ),
                        ],
                      ),
              ),
            ],
            if (leaveConflicts.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              _ShiftConflictBanner(
                key: const ValueKey('shift-leave'),
                title: 'On approved time off',
                lines: [
                  for (final row in leaveConflicts)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize:
                              ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: AppColors.textHeading,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: row.staffName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                ' is off ${row.label}. Remove them or choose another day to continue.',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (scheduleConflicts.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              _ShiftConflictBanner(
                key: const ValueKey('shift-conflicts'),
                title: 'Already rostered at these hours',
                lines: [
                  for (final row in scheduleConflicts)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize:
                              ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: AppColors.textHeading,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: row.staffName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                ' is on ${row.label}${row.residenceName == null || row.residenceName!.isEmpty ? '' : ' at ${row.residenceName}'}. Remove them or change the shift\'s hours to continue.',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
            Text(
              'Assigned Staff (${assignedStaff.length})',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textHeading,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            if (assignedStaff.isEmpty)
              const _EmptyAssignedStaff()
            else
              for (final staff in assignedStaff) ...[
                _AssignedStaffCard(
                  key: ValueKey('assigned-staff-${staff.staffId}'),
                  staff: staff,
                  onRemove: () => onRemoveStaff(staff.staffId),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 12),
                ),
              ],
          ],
        ],
      ),
    );
  }
}

class _StaffingMethodToggle extends StatelessWidget {
  final bool isOpenShift;
  final ValueChanged<bool> onChanged;

  const _StaffingMethodToggle({
    required this.isOpenShift,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('create-shift-staffing-method'),
      children: [
        _MethodChip(
          key: const ValueKey('create-shift-method-assign'),
          label: 'Assign Specific Staff',
          subtitle: 'Pick team members to staff this shift directly.',
          icon: Icons.person_outline_rounded,
          selected: !isOpenShift,
          onTap: () => onChanged(false),
        ),
        const SizedBox(height: 8),
        _MethodChip(
          key: const ValueKey('create-shift-method-open'),
          label: 'Publish as Open Shift',
          subtitle: 'Broadcast to qualified staff to claim or submit bids.',
          icon: Icons.campaign_outlined,
          selected: isOpenShift,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceWhite : AppColors.filterButtonBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.secondaryTeal : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.textHeading : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          14,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        color: AppColors.textSecondary,
                        height: 1.3,
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

class _PendingBidsSection extends StatefulWidget {
  final List<PendingShiftBid> bids;
  final Future<void> Function(PendingShiftBid bid) onAccept;

  const _PendingBidsSection({
    required this.bids,
    required this.onAccept,
  });

  @override
  State<_PendingBidsSection> createState() => _PendingBidsSectionState();
}

class _PendingBidsSectionState extends State<_PendingBidsSection> {
  String? _busyBidId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateShiftFieldLabel('Pending bids'),
        Text(
          '${widget.bids.length} staff ${widget.bids.length == 1 ? 'has' : 'have'} bid for this shift',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        for (final bid in widget.bids) ...[
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              bottom: ResponsiveHelper.getResponsiveHeight(context, 8),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.staffName,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textHeading,
                        ),
                      ),
                      if (bid.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          bid.note.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _busyBidId != null
                      ? null
                      : () async {
                          setState(() => _busyBidId = bid.bidId);
                          await widget.onAccept(bid);
                          if (mounted) setState(() => _busyBidId = null);
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryTeal,
                  ),
                  child: _busyBidId == bid.bidId
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accept'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OpenShiftBroadcast extends StatelessWidget {
  final String? residenceName;

  const _OpenShiftBroadcast({this.residenceName});

  @override
  Widget build(BuildContext context) {
    final home = residenceName?.trim();
    final where = home == null || home.isEmpty
        ? 'all eligible staff'
        : 'all eligible staff assigned to $home';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Open Shift Broadcast',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This shift will be published for bidding and broadcast to $where. '
            'Qualified team members can submit bids until the deadline according to the rules below.',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffMultiSelectField extends StatelessWidget {
  final List<AssignedShiftStaff> assignedStaff;
  final bool isLoading;
  final VoidCallback onTap;
  final ValueChanged<String> onRemove;

  const _StaffMultiSelectField({
    required this.assignedStaff,
    required this.isLoading,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        side: const BorderSide(color: AppColors.searchBorder),
      ),
      child: InkWell(
        key: const ValueKey('create-shift-add-staff'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 10,
            vertical: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final staff in assignedStaff)
                      _StaffChip(
                        name: staff.staffName,
                        onRemove: () => onRemove(staff.staffId),
                      ),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Text(
                        'Add staff…',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize:
                              ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                          color: AppColors.textFaint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondaryTeal,
                  ),
                )
              else
                const AppSvgIcon(
                  AppAssets.chevronDown,
                  size: 14,
                  color: AppColors.textFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _StaffChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Semantics(
              label: 'Remove $name',
              button: true,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssignedStaff extends StatelessWidget {
  const _EmptyAssignedStaff();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Text(
        'No staff assigned yet. Select above to add someone, or choose Publish as Open Shift above to let staff bid.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Web staffing cards list name + residence only — no per-staff Task Assignment.
class _AssignedStaffCard extends StatelessWidget {
  final AssignedShiftStaff staff;
  final VoidCallback onRemove;

  const _AssignedStaffCard({
    super.key,
    required this.staff,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveSize(context, 36),
              height: ResponsiveHelper.getResponsiveSize(context, 36),
              decoration: const BoxDecoration(
                color: _avatarFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                staff.initials,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: _avatarText,
                ),
              ),
            ),
            SizedBox(
              width: ResponsiveHelper.getResponsiveWidth(context, 12),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.staffName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        14,
                      ),
                      color: AppColors.textHeading,
                    ),
                  ),
                  Text(
                    staff.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        12,
                      ),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove ${staff.staffName}',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftConflictBanner extends StatelessWidget {
  final String title;
  final List<Widget> lines;
  final Widget? footer;

  const _ShiftConflictBanner({
    super.key,
    required this.title,
    required this.lines,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.urgentAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.urgentAmber.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: AppColors.urgentAmber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.urgentAmber,
                  ),
                ),
              ),
            ],
          ),
          for (final line in lines) ...[
            const SizedBox(height: 6),
            line,
          ],
          ?footer,
        ],
      ),
    );
  }
}

/// Searchable checkbox list of tenant staff ("Search staff…"). Toggling a
/// row adds or removes that person from the shift immediately.
Future<void> showCreateShiftStaffPicker({
  required BuildContext context,
  required List<ShiftStaffOption> options,
  required Set<String> selectedIds,
  required ValueChanged<ShiftStaffOption> onToggle,
  Set<String> hasShiftIds = const {},
  String? errorMessage,
  VoidCallback? onRetry,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _StaffPickerSheet(
      options: options,
      selectedIds: {...selectedIds},
      hasShiftIds: hasShiftIds,
      onToggle: onToggle,
      errorMessage: errorMessage,
      onRetry: onRetry,
    ),
  );
}

class _StaffPickerSheet extends StatefulWidget {
  final List<ShiftStaffOption> options;
  final Set<String> selectedIds;
  final Set<String> hasShiftIds;
  final ValueChanged<ShiftStaffOption> onToggle;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const _StaffPickerSheet({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
    this.hasShiftIds = const {},
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<_StaffPickerSheet> createState() => _StaffPickerSheetState();
}

class _StaffPickerSheetState extends State<_StaffPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.name.toLowerCase().contains(query))
            .toList();
    final error = widget.errorMessage?.trim() ?? '';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Assigned Staff',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  key: const ValueKey('create-shift-staff-search'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search staff…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.searchBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.searchBorder),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: error.isNotEmpty && widget.options.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (widget.onRetry != null)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onRetry!();
                                },
                                child: const Text('Try again'),
                              ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No results found.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              final selected =
                                  widget.selectedIds.contains(option.id);
                              final hasShift =
                                  widget.hasShiftIds.contains(option.id);
                              return CheckboxListTile(
                                key: ValueKey('staff-option-${option.id}'),
                                value: selected,
                                activeColor: AppColors.secondaryTeal,
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                                title: Text(
                                  hasShift
                                      ? '${option.name} • (Has Shift)'
                                      : option.name,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                onChanged: (_) {
                                  setState(() {
                                    if (!widget.selectedIds.remove(option.id)) {
                                      widget.selectedIds.add(option.id);
                                    }
                                  });
                                  widget.onToggle(option);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
