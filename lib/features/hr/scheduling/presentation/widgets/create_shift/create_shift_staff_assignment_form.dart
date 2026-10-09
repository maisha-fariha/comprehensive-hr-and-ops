import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../domain/entities/create_shift_draft.dart';
import '../../../domain/entities/shift_staff_option.dart';
import 'create_shift_fields.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

const Color _avatarFill = Color(0xFFEAF0FE);
const Color _avatarText = Color(0xFF8E88B1);

/// "Staff Assignment" step — multi-select staff picker plus one expandable
/// task card (title, description, checklist, note) per assignee.
class CreateShiftStaffAssignmentForm extends StatelessWidget {
  final List<AssignedShiftStaff> assignedStaff;
  final String? expandedStaffId;
  final bool isLoadingStaff;
  final VoidCallback onAddStaff;
  final ValueChanged<String> onRemoveStaff;
  final ValueChanged<String> onToggleExpand;
  final VoidCallback onChanged;

  const CreateShiftStaffAssignmentForm({
    super.key,
    required this.assignedStaff,
    required this.expandedStaffId,
    required this.onAddStaff,
    required this.onRemoveStaff,
    required this.onToggleExpand,
    required this.onChanged,
    this.isLoadingStaff = false,
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
          const CreateShiftSectionHeader(
            title: 'Staff Assignment',
            description:
                "Assign staff members to this shift and configure each person's tasks, or leave it open for bidding.",
          ),
          const CreateShiftFieldLabel('Assigned Staff'),
          _StaffMultiSelectField(
            assignedStaff: assignedStaff,
            isLoading: isLoadingStaff,
            onTap: onAddStaff,
            onRemove: onRemoveStaff,
          ),
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
                expanded: expandedStaffId == staff.staffId,
                onToggleExpand: () => onToggleExpand(staff.staffId),
                onRemove: () => onRemoveStaff(staff.staffId),
                onChanged: onChanged,
              ),
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
            ],
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
        'No staff assigned yet. Select above to add someone, or leave this shift open in the next step.',
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

class _AssignedStaffCard extends StatefulWidget {
  final AssignedShiftStaff staff;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _AssignedStaffCard({
    super.key,
    required this.staff,
    required this.expanded,
    required this.onToggleExpand,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_AssignedStaffCard> createState() => _AssignedStaffCardState();
}

class _AssignedStaffCardState extends State<_AssignedStaffCard> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;
  late final TextEditingController _checklistController;

  AssignedShiftStaff get _staff => widget.staff;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _staff.taskTitle);
    _descriptionController =
        TextEditingController(text: _staff.taskDescription);
    _noteController = TextEditingController(text: _staff.note);
    _checklistController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    final label = _checklistController.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _staff.checklist.add(
        ShiftChecklistItem(
          id: 'chk-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
        ),
      );
      _checklistController.clear();
    });
    widget.onChanged();
  }

  void _removeChecklistItem(ShiftChecklistItem item) {
    setState(() => _staff.checklist.remove(item));
    widget.onChanged();
  }

  void _toggleChecklistItem(ShiftChecklistItem item, bool done) {
    setState(() => item.done = done);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _staff.checklist.length;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: ValueKey('assigned-staff-toggle-${_staff.staffId}'),
                    onTap: widget.onToggleExpand,
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
                            _staff.initials,
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
                                _staff.staffName,
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
                                _staff.subtitle,
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
                        if (steps > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.secondaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$steps step${steps == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  11,
                                ),
                                color: AppColors.secondaryTeal,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: widget.expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  tooltip: 'Remove ${_staff.staffName}',
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
          if (widget.expanded) _buildTaskBody(context),
        ],
      ),
    );
  }

  Widget _buildTaskBody(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14));
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        top: 14,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Assignment',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textHeading,
            ),
          ),
          gap,
          const CreateShiftFieldLabel('Task Title'),
          CreateShiftTextField(
            key: ValueKey('task-title-${_staff.staffId}'),
            controller: _titleController,
            hint: 'e.g. Morning medication round',
            onChanged: (value) {
              _staff.taskTitle = value;
              widget.onChanged();
            },
          ),
          const CreateShiftHelperText(
            'Leave empty to assign the shift without a task.',
          ),
          gap,
          const CreateShiftFieldLabel('Task Description'),
          CreateShiftTextField(
            key: ValueKey('task-description-${_staff.staffId}'),
            controller: _descriptionController,
            hint:
                'Describe what this staff member is responsible for during this shift…',
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            onChanged: (value) {
              _staff.taskDescription = value;
              widget.onChanged();
            },
          ),
          gap,
          const CreateShiftFieldLabel('Task Checklist'),
          for (final item in _staff.checklist) ...[
            _ChecklistRow(
              item: item,
              onToggle: (done) => _toggleChecklistItem(item, done),
              onRemove: () => _removeChecklistItem(item),
            ),
            const SizedBox(height: 8),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final input = CreateShiftTextField(
                key: ValueKey('checklist-input-${_staff.staffId}'),
                controller: _checklistController,
                hint: 'Add a checklist item…',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addChecklistItem(),
              );
              final button = _addChecklistButton(context);
              if (constraints.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [input, const SizedBox(height: 8), button],
                );
              }
              return Row(
                children: [
                  Expanded(child: input),
                  const SizedBox(width: 8),
                  button,
                ],
              );
            },
          ),
          gap,
          const CreateShiftFieldLabel('Note'),
          CreateShiftTextField(
            key: ValueKey('task-note-${_staff.staffId}'),
            controller: _noteController,
            hint: 'Any special instructions for this task…',
            onChanged: (value) {
              _staff.note = value;
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _addChecklistButton(BuildContext context) {
    return OutlinedButton.icon(
      key: ValueKey('checklist-add-${_staff.staffId}'),
      onPressed: _addChecklistItem,
      icon: const Icon(Icons.add_rounded, size: 16),
      label: const Text('Add checklist item'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondaryTeal,
        backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.05),
        side: BorderSide(
          color: AppColors.secondaryTeal.withValues(alpha: 0.4),
        ),
        textStyle: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final ShiftChecklistItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRemove;

  const _ChecklistRow({
    required this.item,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.done,
            onChanged: (value) => onToggle(value == true),
            activeColor: AppColors.secondaryTeal,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textHeading,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove checklist item',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ),
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
      onToggle: onToggle,
      errorMessage: errorMessage,
      onRetry: onRetry,
    ),
  );
}

class _StaffPickerSheet extends StatefulWidget {
  final List<ShiftStaffOption> options;
  final Set<String> selectedIds;
  final ValueChanged<ShiftStaffOption> onToggle;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const _StaffPickerSheet({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
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
                              return CheckboxListTile(
                                key: ValueKey('staff-option-${option.id}'),
                                value: selected,
                                activeColor: AppColors.secondaryTeal,
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                                title: Text(
                                  option.name,
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
