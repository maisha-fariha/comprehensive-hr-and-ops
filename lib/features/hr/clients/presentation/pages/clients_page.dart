import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/client_summary.dart';
import '../clients_labels.dart';
import '../controllers/clients_controller.dart';
import '../widgets/add_client_sheet.dart';
import '../widgets/client_card.dart';
import '../widgets/clients_common.dart';
import '../widgets/deleted_clients_sheet.dart';
import '../widgets/move_client_sheet.dart';
import 'client_detail_page.dart';

/// Web `/dashboard/clients` ("Client Directory").
class ClientsPage extends StatefulWidget {
  /// Pre-selects the residence filter (e.g. from a residence detail page).
  final String? initialResidenceId;

  const ClientsPage({super.key, this.initialResidenceId});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late final ClientsController _controller;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<ClientsController>();
    } catch (_) {
      _controller = Get.put(GetIt.instance<ClientsController>());
    }
    _controller.openWith(residenceId: widget.initialResidenceId);
  }

  void _clearFilters() {
    setState(() => _searchGeneration++);
    _controller.clearFilters();
  }

  Future<void> _open(ClientSummary client, {bool editing = false}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ClientDetailPage(client: client, editing: editing)),
    );
    if (changed == true) await _controller.loadClients();
  }

  Future<void> _onAction(ClientSummary client, ClientRowAction action) async {
    switch (action) {
      case ClientRowAction.view:
        await _open(client);
      case ClientRowAction.edit:
        await _open(client, editing: true);
      case ClientRowAction.move:
        await showMoveClientSheet(context, _controller, client);
      case ClientRowAction.delete:
        final reason = TextEditingController();
        final ok = await confirmClientAction(
          context,
          title: 'Delete ${client.firstName} ${client.lastName}?',
          description: 'They leave the directory. The record is kept on the deleted log, '
              'with who deleted it and why, and can be restored from there.',
          confirmLabel: 'Delete Client',
          confirmKey: const ValueKey('client-delete-confirm'),
          extra: ClientInput(
            key: const ValueKey('client-delete-reason'),
            label: 'Reason (optional)',
            placeholder: 'e.g. Duplicate record',
            controller: reason,
            lines: 2,
          ),
        );
        if (ok) await _controller.deleteClient(client, reason: reason.text);
    }
  }

  Future<void> _openDeleted() => showClientSheet<void>(
        context,
        DeletedClientsSheet(controller: _controller),
      );

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final gap = ResponsiveHelper.getResponsiveHeight(context, 12);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, 'Client Directory'),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final items = controller.clients.toList();
          final loading = controller.isLoading.value;
          final error = controller.loadError.value;
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
                _actions(context),
                SizedBox(height: gap),
                HrSearchField(
                  key: ValueKey('clients-search-$_searchGeneration'),
                  hint: 'Search clients...',
                  onChanged: controller.setSearch,
                ),
                SizedBox(height: gap),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    HrFilterPill(
                      allLabel: 'All Residences',
                      value: controller.residenceFilter.value,
                      options: controller.residenceOptions,
                      labelOf: controller.residenceLabel,
                      onChanged: controller.setResidence,
                    ),
                    if (controller.hasFilters)
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(
                          'Clear filters',
                          style: handoverText(context, 13, color: AppColors.infoBlue),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: gap),
                if (items.isEmpty && loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.secondaryTeal),
                    ),
                  )
                else if (items.isEmpty && error != null)
                  HrMessageView(
                    icon: Icons.error_outline_rounded,
                    message: error,
                    onRetry: controller.refresh,
                  )
                else if (items.isEmpty)
                  _empty(context)
                else ...[
                  for (final client in items) ...[
                    ClientCard(
                      client: client,
                      residenceName: client.residenceName ??
                          (client.residenceId == null
                              ? null
                              : controller.residenceLabel(client.residenceId!)),
                      canUpdate: controller.canUpdate,
                      canDelete: controller.canDelete,
                      onTap: () => _open(client),
                      onAction: (a) => _onAction(client, a),
                    ),
                    SizedBox(height: gap),
                  ],
                  AttendancePagination(
                    page: controller.page.value,
                    limit: controller.limit.value,
                    total: controller.total.value,
                    totalPages: controller.totalPages.value,
                    limitOptions: ClientsLabels.pageSizes,
                    onPage: controller.setPage,
                    onLimit: controller.setLimit,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final c = _controller;
    final limited = c.isLimitReached;
    final cap = c.clientLimit.value;
    final exporting = c.isExporting.value;
    final add = HandoverButton(
      key: const ValueKey('clients-add'),
      label: limited ? 'Limit Exceeded' : 'Add Client',
      icon: Icons.add_rounded,
      filled: true,
      onPressed: limited ? null : () => showAddClientSheet(context, c),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (c.canCreate)
          limited && cap != null
              ? Tooltip(
                  message: ClientsLabels.planLimitTooltip(c.limitCount, cap),
                  child: add,
                )
              : add,
        if (c.canDelete)
          HandoverButton(
            key: const ValueKey('clients-deleted'),
            label: 'Deleted residents',
            icon: Icons.history_rounded,
            onPressed: _openDeleted,
          ),
        if (c.canExport)
          HandoverButton(
            key: const ValueKey('clients-export'),
            label: exporting ? 'Preparing…' : 'Export List',
            icon: Icons.download_rounded,
            onPressed: exporting ? null : c.exportList,
          ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text('No clients found', style: handoverText(context, 15, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            _controller.hasFilters
                ? 'No client matches these filters.'
                : 'Clients you add will appear here.',
            textAlign: TextAlign.center,
            style: handoverText(context, 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
