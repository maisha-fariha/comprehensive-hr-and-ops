import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/residence_summary.dart';
import '../controllers/residences_controller.dart';
import '../residences_labels.dart';
import '../widgets/residence_card.dart';
import '../widgets/residences_common.dart';
import 'residence_detail_page.dart';
import 'residence_form_page.dart';

/// Manager "Residences Management" — mirrors web `/dashboard/residences`.
class ResidencesPage extends StatefulWidget {
  const ResidencesPage({super.key});

  @override
  State<ResidencesPage> createState() => _ResidencesPageState();
}

class _ResidencesPageState extends State<ResidencesPage> {
  late final ResidencesController controller = _resolveController();
  int _searchEpoch = 0;

  ResidencesController _resolveController() {
    try {
      return Get.find<ResidencesController>();
    } catch (_) {
      return Get.put(GetIt.instance<ResidencesController>());
    }
  }

  void _clearFilters() {
    setState(() => _searchEpoch++);
    controller.query.value = '';
    controller.statusFilter.value = null;
    controller.typeFilter.value = null;
    controller.page.value = 1;
    controller.loadResidences();
  }

  void _view(ResidenceSummary r) =>
      Get.to(() => ResidenceDetailPage(residence: r));

  void _openForm({ResidenceSummary? editing}) => Get.to(
        () => ResidenceFormPage(controller: controller, editing: editing),
      );

  Future<void> _onAction(ResidenceSummary r, ResidenceRowAction action) async {
    switch (action) {
      case ResidenceRowAction.view:
        _view(r);
      case ResidenceRowAction.edit:
        final row = controller.rowById(r.id);
        if (row != null) _openForm(editing: row);
      case ResidenceRowAction.toggleStatus:
        await controller.setResidenceStatus(r, r.isActive ? 'inactive' : 'active');
      case ResidenceRowAction.delete:
        if (await confirmResidenceDelete(context)) {
          await controller.deleteResidence(r);
        }
    }
  }

  List<ResidenceRowAction> get _actions => [
        ResidenceRowAction.view,
        if (controller.canUpdate) ...[
          ResidenceRowAction.edit,
          ResidenceRowAction.toggleStatus,
        ],
        if (controller.canDelete) ResidenceRowAction.delete,
      ];

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveHeight(context, 12);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, 'Residences Management'),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final items = controller.residences;
          return RefreshIndicator(
            color: AppColors.secondaryTeal,
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: AppDimens.screenPaddingHorizontal,
                vertical: 16,
              ),
              children: [
                _headerActions(context),
                SizedBox(height: gap),
                _kpis(),
                SizedBox(height: gap),
                HrSearchField(
                  key: ValueKey('residence-search-$_searchEpoch'),
                  hint: 'Search by residence name or manager....',
                  onChanged: (v) => controller.query.value = v,
                ),
                SizedBox(height: gap),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    HrFilterPill(
                      key: const ValueKey('residence-status-filter'),
                      allLabel: 'All statuses',
                      value: controller.statusFilter.value,
                      options: [for (final (v, _) in ResidencesLabels.statusFilters) v],
                      labelOf: (v) => ResidencesLabels.statusFilters
                          .firstWhere((o) => o.$1 == v, orElse: () => (v, hrHumanize(v)))
                          .$2,
                      onChanged: controller.setStatusFilter,
                    ),
                    HrFilterPill(
                      key: const ValueKey('residence-type-filter'),
                      allLabel: 'All types',
                      value: controller.typeFilter.value,
                      options: controller.types,
                      labelOf: hrHumanize,
                      onChanged: controller.setTypeFilter,
                    ),
                    if (controller.hasFilters)
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(
                          'Clear filters',
                          style: handoverText(
                            context,
                            12.5,
                            weight: FontWeight.w600,
                            color: AppColors.secondaryTeal,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: gap),
                ..._body(context, items, gap),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _headerActions(BuildContext context) {
    final limitReached = controller.limitReached;
    final add = HandoverButton(
      key: const ValueKey('residence-add'),
      label: limitReached ? 'Limit Exceeded' : 'Add Residence',
      icon: Icons.add_rounded,
      filled: true,
      onPressed: limitReached ? null : () => _openForm(),
    );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (controller.canCreate)
          limitReached
              ? Tooltip(message: controller.limitTooltip, child: add)
              : add,
        if (controller.canExport)
          HandoverButton(
            key: const ValueKey('residence-export'),
            label: controller.exporting.value ? 'Preparing…' : 'Export List',
            icon: Icons.cloud_download_outlined,
            foreground: AppColors.secondaryTeal,
            onPressed: controller.exporting.value ? null : controller.exportList,
          ),
      ],
    );
  }

  Widget _kpis() {
    final s = controller.kpis.value;
    return ResidenceTileGrid(
      children: [
        ResidenceKpiTile(
          label: 'Homes',
          value: '${s?.residences ?? 0}',
          bottom: s == null ? '—' : '${s.active} active',
        ),
        ResidenceKpiTile(
          label: 'Residents',
          value: '${s?.residents ?? 0}',
          bottom: 'Living in them today',
        ),
        ResidenceKpiTile(
          label: 'Beds free',
          value: '${s?.bedsFree ?? 0}',
          bottom: s == null ? '—' : 'Of ${s.beds} licensed',
        ),
        ResidenceKpiTile(
          label: 'At capacity',
          value: '${s?.atCapacity ?? 0}',
          bottom: 'Homes that cannot take anyone',
          danger: (s?.atCapacity ?? 0) > 0,
        ),
      ],
    );
  }

  List<Widget> _body(
    BuildContext context,
    List<ResidenceSummary> items,
    double gap,
  ) {
    if (items.isEmpty && controller.isLoading.value) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          ),
        ),
      ];
    }
    if (items.isEmpty && controller.errorMessage.value.isNotEmpty) {
      return [
        HrMessageView(
          icon: Icons.error_outline_rounded,
          message: controller.errorMessage.value,
          onRetry: controller.refresh,
        ),
      ];
    }
    if (items.isEmpty) {
      return [
        HandoverPanel(
          child: ResidenceMutedMessage(
            title: 'No residences found',
            message: controller.hasFilters
                ? 'No residence matches these filters.'
                : 'Residences you add will appear here.',
          ),
        ),
      ];
    }
    final actions = _actions;
    return [
      for (final residence in items) ...[
        ResidenceCard(
          key: ValueKey('residence-${residence.id}'),
          residence: residence,
          busy: controller.busyId.value == residence.id,
          actions: actions,
          onAction: (a) => _onAction(residence, a),
          onTap: () => _view(residence),
        ),
        SizedBox(height: gap),
      ],
      if (controller.total.value > 0)
        AttendancePagination(
          page: controller.page.value,
          limit: controller.limit.value,
          total: controller.total.value,
          totalPages: controller.totalPages.value,
          limitOptions: ResidencesController.pageSizes,
          onPage: controller.setPage,
          onLimit: controller.setLimit,
        ),
    ];
  }
}
