import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_document.dart';

class StaffDocumentsFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final String ownerType;
  final String documentTypeId;
  final String status;
  final String visibility;
  final List<StaffDocumentType> types;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final void Function({
    String? ownerType,
    String? documentTypeId,
    String? status,
    String? visibility,
  }) onFilterChanged;
  final VoidCallback onClear;

  const StaffDocumentsFiltersBar({
    super.key,
    required this.searchController,
    required this.ownerType,
    required this.documentTypeId,
    required this.status,
    required this.visibility,
    required this.types,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: AppColors.textHeading,
          ),
          decoration: InputDecoration(
            hintText: 'Search documents...',
            hintStyle: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondaryTeal),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: _ownerLabel(ownerType),
              onTap: () => _pick(
                context,
                title: 'Owner',
                current: ownerType,
                options: const [
                  ('', 'All owners'),
                  ('client', 'Resident'),
                  ('staff', 'Staff'),
                  ('residence', 'Residence'),
                  ('tenant', 'Organisation'),
                  ('referral', 'Referral'),
                ],
                onPicked: (v) => onFilterChanged(ownerType: v),
              ),
            ),
            _FilterChip(
              label: _categoryLabel(documentTypeId, types),
              onTap: () => _pick(
                context,
                title: 'Category',
                current: documentTypeId,
                options: [
                  ('', 'All categories'),
                  ...types
                      .where((t) => t.isActive)
                      .map((t) => (t.id, t.name)),
                ],
                onPicked: (v) => onFilterChanged(documentTypeId: v),
              ),
            ),
            _FilterChip(
              label: _statusLabel(status),
              onTap: () => _pick(
                context,
                title: 'Status',
                current: status,
                options: const [
                  ('', 'Any status'),
                  ('valid', 'In date'),
                  ('expiring', 'Expiring soon'),
                  ('expired', 'Expired'),
                ],
                onPicked: (v) => onFilterChanged(status: v),
              ),
            ),
            _FilterChip(
              label: _visibilityLabel(visibility),
              onTap: () => _pick(
                context,
                title: 'Visibility',
                current: visibility,
                options: const [
                  ('', 'Any visibility'),
                  ('all', 'Everyone'),
                  ('staff_only', 'Staff only'),
                  ('management_only', 'Management only'),
                  ('family', 'Family'),
                ],
                onPicked: (v) => onFilterChanged(visibility: v),
              ),
            ),
            if (hasActiveFilters)
              TextButton(
                onPressed: onClear,
                child: const Text(
                  'Clear filters',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _ownerLabel(String v) {
    switch (v) {
      case 'client':
        return 'Resident';
      case 'staff':
        return 'Staff';
      case 'residence':
        return 'Residence';
      case 'tenant':
        return 'Organisation';
      case 'referral':
        return 'Referral';
      default:
        return 'All owners';
    }
  }

  static String _categoryLabel(String id, List<StaffDocumentType> types) {
    if (id.isEmpty) return 'All categories';
    return types
            .where((t) => t.id == id)
            .map((t) => t.name)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null) ??
        'Category';
  }

  static String _statusLabel(String v) {
    switch (v) {
      case 'valid':
        return 'In date';
      case 'expiring':
        return 'Expiring soon';
      case 'expired':
        return 'Expired';
      default:
        return 'Any status';
    }
  }

  static String _visibilityLabel(String v) {
    switch (v) {
      case 'all':
        return 'Everyone';
      case 'staff_only':
        return 'Staff only';
      case 'management_only':
        return 'Management only';
      case 'family':
        return 'Family';
      default:
        return 'Any visibility';
    }
  }

  Future<void> _pick(
    BuildContext context, {
    required String title,
    required String current,
    required List<(String, String)> options,
    required ValueChanged<String> onPicked,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(ctx, 16),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              for (final opt in options)
                ListTile(
                  title: Text(
                    opt.$2,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight:
                          opt.$1 == current ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textHeading,
                    ),
                  ),
                  trailing: opt.$1 == current
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.secondaryTeal,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, opt.$1),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) onPicked(selected);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.filterButtonBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
