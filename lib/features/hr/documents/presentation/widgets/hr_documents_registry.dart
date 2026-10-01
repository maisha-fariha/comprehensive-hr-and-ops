import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document_row.dart';
import '../controllers/hr_documents_controller.dart';
import 'hr_document_row_card.dart';
import 'hr_documents_common.dart';

/// "Document Registry": search, the four filters, rows and paging.
class HrDocumentsRegistry extends StatefulWidget {
  final HrDocumentsController controller;
  final void Function(HrDocumentRow row, HrDocumentAction action) onAction;

  const HrDocumentsRegistry({super.key, required this.controller, required this.onAction});

  @override
  State<HrDocumentsRegistry> createState() => _HrDocumentsRegistryState();
}

class _HrDocumentsRegistryState extends State<HrDocumentsRegistry> {
  late final TextEditingController _search =
      TextEditingController(text: widget.controller.searchInput.value);
  late final Worker _sync;

  HrDocumentsController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _sync = ever<String>(_c.searchInput, (value) {
      if (_search.text != value) _search.text = value;
    });
  }

  @override
  void dispose() {
    _sync.dispose();
    _search.dispose();
    super.dispose();
  }

  Widget _filter({
    required String key,
    required String title,
    required String anyLabel,
    required List<(String, String)> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final all = [('', anyLabel), ...options];
    final label = all.firstWhere((o) => o.$1 == value, orElse: () => all.first).$2;
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        key: ValueKey(key),
        borderRadius: BorderRadius.circular(9),
        onTap: () async {
          final picked = await pickHandoverOption(
            context,
            title: title,
            options: all,
            selected: value,
          );
          if (picked != null && picked != value) onChanged(picked);
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: handoverText(context, 13, weight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final f = _c.filters.value;
      final total = _c.total.value;
      final rows = _c.rows;
      return HandoverPanel(
        key: const ValueKey('documents-registry'),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Document Registry', style: handoverText(context, 15, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              '${hrCount(total)} ${total == 1 ? 'document' : 'documents'} matching these filters',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('documents-search'),
              controller: _search,
              onChanged: _c.setSearch,
              style: handoverText(context, 13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search documents...',
                hintStyle: handoverText(context, 13.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.infoBlue),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppColors.searchBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppColors.searchBorder),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _filter(
                  key: 'documents-filter-owner',
                  title: 'Owner Type',
                  anyLabel: 'All owners',
                  options: HrDocumentOptions.ownerTypes,
                  value: f.ownerType,
                  onChanged: _c.setOwnerType,
                ),
                _filter(
                  key: 'documents-filter-category',
                  title: 'Category',
                  anyLabel: 'All categories',
                  options: [for (final t in _c.types) (t.id, t.name)],
                  value: f.documentTypeId,
                  onChanged: _c.setDocumentType,
                ),
                _filter(
                  key: 'documents-filter-status',
                  title: 'Status',
                  anyLabel: 'Any status',
                  options: HrDocumentOptions.statuses,
                  value: f.status,
                  onChanged: _c.setStatus,
                ),
                _filter(
                  key: 'documents-filter-visibility',
                  title: 'Visibility',
                  anyLabel: 'Any visibility',
                  options: HrDocumentOptions.visibilities,
                  value: f.visibility,
                  onChanged: _c.setVisibility,
                ),
                TextButton(
                  key: const ValueKey('documents-clear-filters'),
                  onPressed: _c.clearFilters,
                  child: Text(
                    'Clear filters',
                    style: handoverText(context, 13, weight: FontWeight.w500, color: AppColors.infoBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._body(context, rows),
          ],
        ),
      );
    });
  }

  List<Widget> _body(BuildContext context, List<HrDocumentRow> rows) {
    if (_c.loading.value && rows.isEmpty) {
      return [
        for (var i = 0; i < 3; i++)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ];
    }
    if (rows.isEmpty) {
      final error = _c.loadError.value;
      return [
        Padding(
          key: const ValueKey('documents-empty'),
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.file_copy_outlined, size: 19, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                error != null ? 'Documents could not be loaded' : 'No documents match',
                textAlign: TextAlign.center,
                style: handoverText(context, 15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                error ?? 'Certificates, care plans and policies you upload are filed here.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final row in rows) ...[
        HrDocumentRowCard(
          key: ValueKey('document-${row.id}'),
          row: row,
          canWrite: _c.canWrite,
          busy: _c.busyId.value == row.id,
          onAction: (action) => widget.onAction(row, action),
        ),
        const SizedBox(height: 10),
      ],
      AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: _c.total.value,
        totalPages: _c.totalPages.value < 1 ? 1 : _c.totalPages.value,
        limitOptions: HrDocumentsController.pageSizes,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      ),
    ];
  }
}
