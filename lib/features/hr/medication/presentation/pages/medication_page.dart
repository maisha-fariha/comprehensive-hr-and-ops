import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/mar_administration.dart';
import '../../domain/entities/mar_medication.dart';
import '../controllers/medication_controller.dart';
import '../mar_row.dart';
import '../medication_labels.dart';
import '../widgets/mar_filters.dart';
import '../widgets/mar_given_tab.dart';
import '../widgets/mar_kpi_grid.dart';
import '../widgets/mar_medicine_form_sheet.dart';
import '../widgets/mar_record_administration_sheet.dart';
import '../widgets/mar_resident_chart_tab.dart';
import '../widgets/mar_row_card.dart';
import '../widgets/mar_side_panels.dart';
import '../widgets/medication_common.dart';

/// Manager "Medication Administration Record (MAR)" — mirrors web
/// `/dashboard/medication`.
class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  late final MedicationController _c;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<MedicationController>());
  }

  @override
  void dispose() {
    _search.dispose();
    Get.delete<MedicationController>();
    super.dispose();
  }

  Future<void> _record({List<MarRow> entries = const []}) => showMarRecordAdministrationSheet(
        context,
        controller: _c,
        entries: entries,
        prn: _c.tab.value == 'prn',
      );

  Future<void> _openForm({MarMedication? editing}) => showMarMedicineFormSheet(
        context,
        prn: editing?.isPrn ?? _c.tab.value == 'prn',
        editing: editing,
        residences: _c.residences.toList(),
        clients: _c.clients.toList(),
        loadChecks: _c.checksFor,
        onSubmit: (drafts) => _c.saveMedicines(drafts, editing: editing),
      );

  MarMedication? _lookup(MarRow row) {
    final m = _c.medicationFor(row);
    if (m == null) AppSnackbar.show(MedicationController.notInList, '');
    return m;
  }

  Future<void> _onAction(MarRow row, MarRowAction action) async {
    if (action == MarRowAction.view || action == MarRowAction.chart) {
      return _record(entries: [row]);
    }
    final m = _lookup(row);
    if (m == null) return;
    switch (action) {
      case MarRowAction.view:
      case MarRowAction.chart:
        break;
      case MarRowAction.edit:
        await _openForm(editing: m);
      case MarRowAction.discontinue:
        final ok = await showMarConfirm(
          context,
          title: 'Stop giving ${m.name}?',
          description:
              'It stops appearing here and cannot be charted again. The record and every dose already given are kept, though this list only shows medicines still in use.',
          confirmLabel: 'Discontinue',
        );
        if (ok) await _c.discontinue(m);
      case MarRowAction.delete:
        final ok = await showMarConfirm(
          context,
          title: 'Delete this prescription?',
          description:
              'It leaves the register. The prescription and the rounds already signed for are kept rather than destroyed, so it can be restored.',
          confirmLabel: 'Delete',
        );
        if (ok) await _c.delete(m);
    }
  }

  Future<void> _correct(MarAdministration a) => showMarCorrectDialog(
        context,
        administration: a,
        onSubmit: ({required reason, status, doseReason}) =>
            _c.amend(a, reason: reason, status: status, doseReason: doseReason),
      );

  void _clearFilters() {
    _search.clear();
    _c.search.value = '';
    _c.clearFilters();
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
                      child: Text('Medication', style: handoverText(context, 18, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.secondaryTeal,
              onRefresh: () async {
                if (_c.canRead) await _c.refreshAll();
              },
              child: Obx(
                () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: _c.canRead
                      ? [
                          _heading(context),
                          const SizedBox(height: 15),
                          if (_c.round.value case final r?) ...[
                            MarKpiGrid(summary: r.summary),
                            const SizedBox(height: 15),
                          ],
                          _tabs(context),
                          const SizedBox(height: 15),
                          ..._tabBody(context),
                          if (_c.tab.value == 'mar' || _c.tab.value == 'prn') ...[
                            const SizedBox(height: 15),
                            MarDueNowPanel(
                              items: _c.dueNow,
                              loading: _c.roundLoading.value,
                              onRecord: _c.canWrite
                                  ? (r) => _record(entries: [r, ..._c.companionsOf(r)])
                                  : null,
                              disabledReason: _c.administerDisabledReason,
                            ),
                            const SizedBox(height: 15),
                            MarAlertsPanel(
                              items: _c.alerts,
                              loading: _c.roundLoading.value,
                              onSelect: (r) => _onAction(r, MarRowAction.view),
                              onReviewAll: _c.reviewAll,
                            ),
                          ],
                        ]
                      : [
                          _heading(context),
                          const MarEmpty('You do not have permission to view the medication record.'),
                        ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context) {
    final reason = _c.administerDisabledReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medication Administration Record (MAR)',
          style: handoverText(context, 20, weight: FontWeight.w700, color: AppColors.primaryNavy),
        ),
        if (_c.canWrite || _c.canExport) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_c.canWrite)
                Tooltip(
                  message: reason ?? '',
                  child: HandoverButton(
                    key: const ValueKey('mar-record-administration'),
                    label: 'Record Administration',
                    icon: Icons.vaccines_outlined,
                    filled: true,
                    onPressed: reason == null ? () => _record() : null,
                  ),
                ),
              if (_c.canWrite)
                HandoverButton(
                  key: const ValueKey('mar-add-medicine'),
                  label: 'Add medicine',
                  icon: Icons.add_rounded,
                  onPressed: () => _openForm(),
                ),
              if (_c.canExport)
                HandoverButton(
                  key: const ValueKey('mar-export'),
                  label: _c.exporting.value ? 'Preparing…' : 'Export MAR',
                  icon: Icons.download_rounded,
                  foreground: AppColors.secondaryTeal,
                  onPressed: _c.exporting.value ? null : _c.export,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tabs(BuildContext context) {
    final tabs = [
      ('mar', 'MAR (${_c.filteredMar.length})'),
      ('prn', 'PRN (${_c.filteredPrn.length})'),
      ('given', 'Given (${_c.given.length})'),
      ('chart', 'Resident chart'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            for (final (id, label) in tabs)
              InkWell(
                key: ValueKey('mar-tab-$id'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _c.setTab(id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _c.tab.value == id ? AppColors.surfaceWhite : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: handoverText(
                      context,
                      13,
                      weight: _c.tab.value == id ? FontWeight.w600 : FontWeight.w500,
                      color: _c.tab.value == id ? AppColors.primaryNavy : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tabBody(BuildContext context) {
    switch (_c.tab.value) {
      case 'given':
        return [
          MarGivenTab(
            rows: _c.given.toList(),
            loading: _c.givenLoading.value,
            error: _c.givenError.value,
            canCorrect: _c.canCorrect,
            onCorrect: _correct,
          ),
        ];
      case 'chart':
        return [
          MarResidentChartTab(
            clientId: _c.chartClientId.value,
            clientOptions: [for (final c in _c.clients) (c.id, c.name)],
            chart: _c.chart.value,
            loading: _c.chartLoading.value,
            onClientChange: _c.loadChart,
          ),
        ];
      default:
        return [_registry(context)];
    }
  }

  Widget _registry(BuildContext context) {
    final prn = _c.tab.value == 'prn';
    final rows = _c.tabRows;
    final loading = prn ? _c.prnLoading.value : _c.roundLoading.value;
    final error = prn ? _c.prnError.value : _c.roundError.value;
    return HandoverPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prn ? 'PRN Medication Registry' : 'MAR Administration Registry',
                  style: handoverText(context, 16, weight: FontWeight.w600, color: AppColors.primaryNavy),
                ),
              ),
              MarPill(
                label: prn ? '${rows.length} available' : '${rows.length} scheduled today',
                tone: MarTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarFilters(
            search: _search,
            residenceId: _c.filterResidence.value,
            clientId: _c.filterClient.value,
            medication: _c.filterMedication.value,
            state: _c.filterState.value,
            residenceOptions: [for (final r in _c.residences) (r.id, r.label)],
            residentOptions: _c.residentOptions,
            medicationOptions: _c.medicationOptions,
            hasActive: _c.hasActiveFilters,
            onSearch: _c.setSearch,
            onChanged: _c.setFilter,
            onClear: _clearFilters,
          ),
          const SizedBox(height: 14),
          if (loading && rows.isEmpty)
            const MarEmpty('Loading…')
          else if (rows.isEmpty)
            MarEmpty(
              error ??
                  (prn
                      ? 'No PRN medicines under these filters.'
                      : 'No doses scheduled for today under these filters.'),
            )
          else ...[
            for (final r in _c.pagedRows) ...[
              MarRowCard(
                key: ValueKey('mar-row-${r.id}'),
                row: r,
                canChart: _c.canAdminister,
                canWrite: _c.canWrite,
                onAction: (action) => _onAction(r, action),
              ),
              const SizedBox(height: 12),
            ],
            AttendancePagination(
              page: _c.page.value,
              limit: _c.limit.value,
              total: rows.length,
              totalPages: _c.totalPages,
              limitOptions: MedicationController.pageSizes,
              onPage: _c.setPage,
              onLimit: _c.setLimit,
            ),
          ],
        ],
      ),
    );
  }
}
