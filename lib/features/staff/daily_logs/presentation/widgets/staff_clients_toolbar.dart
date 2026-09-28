import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Search bar + residence filter for Daily Logs My Clients (web has no Add Client).
class StaffClientsToolbar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? selectedResidenceId;
  final List<({String id, String name})> residenceOptions;
  final ValueChanged<String?> onResidenceChanged;

  const StaffClientsToolbar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedResidenceId,
    required this.residenceOptions,
    required this.onResidenceChanged,
  });

  @override
  State<StaffClientsToolbar> createState() => _StaffClientsToolbarState();
}

class _StaffClientsToolbarState extends State<StaffClientsToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant StaffClientsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text &&
        widget.searchQuery != oldWidget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('staff-clients-search'),
          controller: _searchController,
          onChanged: widget.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search clients',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: AppSvgIcon(
                AppAssets.search,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 14),
              ),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 14),
              ),
              borderSide: const BorderSide(color: AppColors.searchBorder),
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        Container(
          key: const Key('staff-clients-residence-dropdown'),
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 14),
            ),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: widget.selectedResidenceId,
              hint: const Text('All residences'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All residences'),
                ),
                for (final option in widget.residenceOptions)
                  DropdownMenuItem<String?>(
                    value: option.id,
                    child: Text(option.name),
                  ),
              ],
              onChanged: widget.onResidenceChanged,
            ),
          ),
        ),
      ],
    );
  }
}
