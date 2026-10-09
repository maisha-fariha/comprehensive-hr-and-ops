import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document_row.dart';
import '../controllers/hr_documents_controller.dart';
import '../widgets/hr_document_detail_sheet.dart';
import '../widgets/hr_document_form_sheet.dart';
import '../widgets/hr_document_insights.dart';
import '../widgets/hr_document_row_card.dart';
import '../widgets/hr_document_types_sheet.dart';
import '../widgets/hr_documents_common.dart';
import '../widgets/hr_documents_kpi_grid.dart';
import '../widgets/hr_documents_registry.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Manager "Documents" — mirrors web `/dashboard/documents`.
class HrDocumentsPage extends StatefulWidget {
  const HrDocumentsPage({super.key});

  @override
  State<HrDocumentsPage> createState() => _HrDocumentsPageState();
}

class _HrDocumentsPageState extends State<HrDocumentsPage> {
  late final HrDocumentsController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<HrDocumentsController>());
  }

  @override
  void dispose() {
    Get.delete<HrDocumentsController>();
    super.dispose();
  }

  void _upload() => showHrDocumentFormSheet(context, controller: _c);

  void _edit(HrDocumentRow row) =>
      showHrDocumentFormSheet(context, controller: _c, editing: row);

  void _types() => showHrSheet<void>(context, (_) => HrDocumentTypesSheet(controller: _c));

  void _missing() {
    final summary = _c.summary.value;
    if (summary == null) return;
    showHrSheet<void>(context, (_) => HrMissingDocumentsSheet(rows: summary.missingByType));
  }

  void _view(HrDocumentRow row) => showHrSheet<void>(
        context,
        (sheetContext) => HrDocumentDetailSheet(
          row: row,
          canWrite: _c.canWrite,
          onDownload: () => _c.download(row.fileUrl!, row.name),
          onEdit: () {
            Navigator.of(sheetContext).pop();
            _edit(row);
          },
        ),
      );

  Future<void> _confirmWithdraw(HrDocumentRow row) async {
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Withdraw this document?',
          style: handoverText(dialogContext, 17, weight: FontWeight.w700),
        ),
        content: Text(
          '"${row.name}" leaves the registry but is kept — a filed document is evidence '
          'of what was held, so it can be restored.',
          style: handoverText(dialogContext, 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          HandoverButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          Material(
            color: AppColors.criticalRed,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              key: const ValueKey('document-withdraw-confirm'),
              borderRadius: BorderRadius.circular(9),
              onTap: () => Navigator.of(dialogContext).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Withdraw',
                  style: handoverText(
                    dialogContext,
                    13.5,
                    weight: FontWeight.w600,
                    color: AppColors.surfaceWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _c.withdraw(row);
  }

  void _onAction(HrDocumentRow row, HrDocumentAction action) {
    switch (action) {
      case HrDocumentAction.view:
        _view(row);
      case HrDocumentAction.download:
        _c.download(row.fileUrl!, row.name);
      case HrDocumentAction.edit:
        _edit(row);
      case HrDocumentAction.restore:
        _c.restore(row);
      case HrDocumentAction.withdraw:
        _confirmWithdraw(row);
    }
  }

  void _onAlert(HrComplianceAlert alert) {
    if (alert.filter == null) {
      _missing();
    } else {
      _c.applyAlert(alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveHelper.getResponsiveWidth(context, 16);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHeading),
                    ),
                    Expanded(
                      child: Text(
                        'Documents',
                        style: handoverText(context, 18, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: _c.refreshAll,
              child: Obx(() {
                final summary = _c.summary.value;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: [
                    Text(
                      'Every certificate, care plan and policy on file, and what is missing',
                      style: handoverText(context, 13.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    _actions(),
                    const SizedBox(height: 15),
                    if (summary != null) ...[
                      HrDocumentsKpiGrid(summary: summary),
                      const SizedBox(height: 15),
                    ],
                    HrDocumentsRegistry(controller: _c, onAction: _onAction),
                    const SizedBox(height: 15),
                    HrDocumentCategoriesCard(
                      categories: summary == null ? const [] : HrCategoryShare.from(summary.byType),
                      total: summary?.documents ?? 0,
                      onViewAll: _c.canWrite ? _types : null,
                    ),
                    const SizedBox(height: 15),
                    HrComplianceAlertsCard(
                      alerts: summary == null ? const [] : HrComplianceAlert.from(summary),
                      onSelect: _onAlert,
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    final withdrawn = _c.filters.value.includeDeleted;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        HandoverButton(
          key: const ValueKey('documents-toggle-withdrawn'),
          label: withdrawn ? 'Withdrawn shown' : 'Show withdrawn',
          filled: withdrawn,
          onPressed: _c.toggleWithdrawn,
        ),
        if (_c.canExport)
          HandoverButton(
            key: const ValueKey('documents-export'),
            label: 'Export Report',
            icon: Icons.download_rounded,
            onPressed: _c.exportReport,
          ),
        if (_c.canWrite) ...[
          HandoverButton(
            key: const ValueKey('documents-types'),
            label: 'Document types',
            icon: Icons.sell_outlined,
            onPressed: _types,
          ),
          HandoverButton(
            key: const ValueKey('documents-upload'),
            label: 'Upload Document',
            icon: Icons.add_rounded,
            filled: true,
            onPressed: _upload,
          ),
        ],
      ],
    );
  }
}
