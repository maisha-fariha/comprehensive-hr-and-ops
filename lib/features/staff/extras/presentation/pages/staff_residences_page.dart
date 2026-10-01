import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_residence.dart';
import '../../domain/repositories/staff_extras_repository.dart';
import '../widgets/staff_residence_list_card.dart';
import '../widgets/staff_residences_summary_row.dart';
import 'staff_residence_detail_page.dart';
import 'staff_residence_edit_page.dart';

/// Staff Residences list — layout mirrors web Residences Management
/// (summary cards + rich residence rows + actions). BUG_Report002.
class StaffResidencesPage extends StatefulWidget {
  const StaffResidencesPage({super.key});

  @override
  State<StaffResidencesPage> createState() => _StaffResidencesPageState();
}

class _StaffResidencesPageState extends State<StaffResidencesPage> {
  late final StaffExtrasRepository _repository;
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<StaffResidence> _items = const [];
  int _activeResidentCount = 0;
  String _query = '';

  bool get _canUpdate => Get.find<UserSession>().can('residences:update');

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffExtrasRepository>();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final residencesFuture = _repository.getResidences();
    final residentsFuture = _repository.getActiveResidentCount();
    final residencesResult = await residencesFuture;
    final residentsResult = await residentsFuture;
    if (!mounted) return;

    String? error;
    var items = <StaffResidence>[];
    var residentCount = 0;

    residencesResult.when(
      success: (value) => items = value,
      failure: (err) => error = err.message,
    );
    residentsResult.when(
      success: (value) => residentCount = value,
      failure: (_) {
        // Fall back so the list still renders if clients KPI fails.
        residentCount = items.fold<int>(
          0,
          (sum, r) => sum + (r.occupiedBeds ?? 0),
        );
      },
    );

    setState(() {
      _items = items;
      _activeResidentCount = residentCount;
      _error = error;
      _loading = false;
    });
  }

  List<StaffResidence> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((item) {
      final haystack = [
        item.name,
        item.listAddress,
        item.typeLabel,
        item.primaryManager?.name ?? '',
        item.status,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
  }

  void _openDetail(StaffResidence item) {
    final id = item.id.trim();
    if (id.isEmpty) return;
    Get.to(
      () => StaffResidenceDetailPage(
        residenceId: id,
        fallbackName: item.name,
      ),
    );
  }

  Future<void> _openEdit(StaffResidence item) async {
    final updated = await Get.to<bool>(
      () => StaffResidenceEditPage(residence: item),
    );
    if (updated == true) await _load();
  }

  Future<void> _confirmDeactivate(StaffResidence item) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Deactivate residence?'),
        content: Text(
          'Archive “${item.name.trim()}”? It will no longer show as Active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('staff-residence-deactivate-confirm'),
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.criticalRed),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _repository.deactivateResidence(item.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        Get.snackbar(
          'Residence deactivated',
          '${item.name.trim()} was archived.',
          snackPosition: SnackPosition.BOTTOM,
        );
        _load();
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not deactivate residence',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      key: const Key('staff-residences-page'),
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Residences Management'),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            )
          : _error != null && _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 16,
                      bottom: 28,
                    ),
                    children: [
                      StaffResidencesSummaryRow(
                        residences: _items,
                        activeResidentCount: _activeResidentCount,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      _SearchField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              'No residences match your search.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      else
                        ...[
                          for (var i = 0; i < filtered.length; i++) ...[
                            if (i > 0)
                              SizedBox(
                                height: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  10,
                                ),
                              ),
                            StaffResidenceListCard(
                              residence: filtered[i],
                              onView: () => _openDetail(filtered[i]),
                              onEdit: _canUpdate
                                  ? () => _openEdit(filtered[i])
                                  : null,
                              onDeactivate: _canUpdate
                                  ? () => _confirmDeactivate(filtered[i])
                                  : null,
                            ),
                          ],
                        ],
                    ],
                  ),
                ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('staff-residences-search'),
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.textHeading,
      ),
      decoration: InputDecoration(
        hintText: 'Search by residence name or manager…',
        hintStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.textPlaceholder,
          fontSize: 13.5,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.searchBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.searchBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondaryTeal),
        ),
      ),
    );
  }
}
