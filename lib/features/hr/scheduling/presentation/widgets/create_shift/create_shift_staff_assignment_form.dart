import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import 'create_shift_fields.dart';

/// Mock staff row for the UI-only Staff Assignment tab.
class CreateShiftStaffOption {
  final String id;
  final String name;
  final String detail;
  final String initials;

  const CreateShiftStaffOption({
    required this.id,
    required this.name,
    required this.detail,
    required this.initials,
  });
}

/// Sample roster matching the Staff Assignment reference layout.
const kCreateShiftStaffPreview = <CreateShiftStaffOption>[
  CreateShiftStaffOption(
    id: '1',
    name: 'bilai Manager',
    detail: 'new test',
    initials: 'BM',
  ),
  CreateShiftStaffOption(
    id: '2',
    name: 'Sarah Kuk',
    detail: 'Mala Box',
    initials: 'SK',
  ),
  CreateShiftStaffOption(
    id: '3',
    name: 'notun bilai',
    detail: 'Dhaka',
    initials: 'NB',
  ),
  CreateShiftStaffOption(
    id: '4',
    name: 'notun bilai',
    detail: 'Child and Youth Caregiver · Dhaka',
    initials: 'NB',
  ),
  CreateShiftStaffOption(
    id: '5',
    name: 'billkiss Preston',
    detail: 'Dhaka',
    initials: 'BP',
  ),
  CreateShiftStaffOption(
    id: '6',
    name: 'Lallu mama',
    detail: 'Child and Youth Caregiver · Dhaka',
    initials: 'LM',
  ),
  CreateShiftStaffOption(
    id: '7',
    name: 'Amina Rahman',
    detail: 'Support Worker · Dhaka',
    initials: 'AR',
  ),
  CreateShiftStaffOption(
    id: '8',
    name: 'James Okonkwo',
    detail: 'Night Care · Mala Box',
    initials: 'JO',
  ),
];

/// Soft lavender used for staff initials avatars in the reference.
const Color _avatarFill = Color(0xFFE8E4F5);
const Color _avatarText = Color(0xFF5B4B8A);

/// Staff Assignment tab body — search + selectable staff list (UI-only).
class CreateShiftStaffAssignmentForm extends StatefulWidget {
  final List<CreateShiftStaffOption> staff;

  const CreateShiftStaffAssignmentForm({
    super.key,
    this.staff = kCreateShiftStaffPreview,
  });

  @override
  State<CreateShiftStaffAssignmentForm> createState() =>
      _CreateShiftStaffAssignmentFormState();
}

class _CreateShiftStaffAssignmentFormState
    extends State<CreateShiftStaffAssignmentForm> {
  late final TextEditingController _searchController;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CreateShiftStaffOption> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.staff;
    return widget.staff
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.detail.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

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
            'Staff Assignment',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            'Assign staff members to this shift and configure each person\'s tasks, or leave it open for bidding.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          const CreateShiftFieldLabel('Assign Staff'),
          _StaffSearchField(controller: _searchController),
          const CreateShiftHelperText(
            'Set a required qualification on the previous step to narrow this list.',
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _StaffListCard(
            staff: filtered,
            selectedIds: _selectedIds,
            onToggle: (id) {
              setState(() {
                if (_selectedIds.contains(id)) {
                  _selectedIds.remove(id);
                } else {
                  _selectedIds.add(id);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

class _StaffSearchField extends StatelessWidget {
  final TextEditingController controller;

  const _StaffSearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Row(
        children: [
          const AppSvgIcon(
            AppAssets.search,
            size: 17,
            color: AppColors.textFaint,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: AppColors.textHeading,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search staff by name...',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: AppColors.textFaint,
                ),
                contentPadding: ResponsiveHelper.getResponsivePadding(
                  context,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffListCard extends StatelessWidget {
  final List<CreateShiftStaffOption> staff;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _StaffListCard({
    required this.staff,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: staff.isEmpty
          ? Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
              child: Text(
                'No staff match your search.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < staff.length; i++) ...[
                  _StaffListTile(
                    option: staff[i],
                    selected: selectedIds.contains(staff[i].id),
                    onTap: () => onToggle(staff[i].id),
                  ),
                  if (i < staff.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.dividerLight,
                    ),
                ],
              ],
            ),
    );
  }
}

class _StaffListTile extends StatelessWidget {
  final CreateShiftStaffOption option;
  final bool selected;
  final VoidCallback onTap;

  const _StaffListTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF3F8F7) : AppColors.surfaceWhite,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 40),
                height: ResponsiveHelper.getResponsiveSize(context, 40),
                decoration: const BoxDecoration(
                  color: _avatarFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  option.initials,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: _avatarText,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 2),
                    ),
                    Text(
                      option.detail,
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
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 20),
                  color: AppColors.secondaryTeal,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
