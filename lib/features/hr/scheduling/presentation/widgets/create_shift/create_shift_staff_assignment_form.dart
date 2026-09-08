import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../domain/entities/shift_staff_option.dart';
import 'create_shift_fields.dart';

/// Soft lavender used for staff initials avatars in the reference.
const Color _avatarFill = Color(0xFFE8E4F5);
const Color _avatarText = Color(0xFF5B4B8A);

/// Staff Assignment tab body — search + selectable staff list from `GET /staff`.
class CreateShiftStaffAssignmentForm extends StatelessWidget {
  final TextEditingController searchController;
  final List<ShiftStaffOption> staff;
  final Set<String> selectedIds;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onToggleStaff;
  final VoidCallback? onRetry;

  const CreateShiftStaffAssignmentForm({
    super.key,
    required this.searchController,
    required this.staff,
    required this.selectedIds,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onToggleStaff,
    this.errorMessage,
    this.onRetry,
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
          _StaffSearchField(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const CreateShiftHelperText(
            'Set a required qualification on the previous step to narrow this list.',
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _StaffListCard(
            staff: staff,
            selectedIds: selectedIds,
            isLoading: isLoading,
            errorMessage: errorMessage,
            onToggle: onToggleStaff,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _StaffSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _StaffSearchField({
    required this.controller,
    required this.onChanged,
  });

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
              onChanged: onChanged,
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
  final List<ShiftStaffOption> staff;
  final Set<String> selectedIds;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onToggle;
  final VoidCallback? onRetry;

  const _StaffListCard({
    required this.staff,
    required this.selectedIds,
    required this.isLoading,
    required this.onToggle,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: ResponsiveHelper.getResponsiveHeight(context, 120),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading && staff.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.secondaryTeal,
            ),
          ),
        ),
      );
    }

    final error = errorMessage?.trim() ?? '';
    if (error.isNotEmpty && staff.isEmpty) {
      return Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      );
    }

    if (staff.isEmpty) {
      return Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Text(
          'No staff match your search.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
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
    );
  }
}

class _StaffListTile extends StatelessWidget {
  final ShiftStaffOption option;
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
