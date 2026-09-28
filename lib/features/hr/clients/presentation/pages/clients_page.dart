import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../controllers/clients_controller.dart';
import '../widgets/client_card.dart';
import 'client_detail_page.dart';

/// Manager "Client Directory": search by name/ID, residence and status
/// filters, and the list of residents in the manager's scope.
class ClientsPage extends StatefulWidget {
  /// Pre-selects the residence filter (e.g. from a residence detail page).
  final String? initialResidenceId;

  const ClientsPage({super.key, this.initialResidenceId});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late final ClientsController _controller;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<ClientsController>();
    } catch (_) {
      _controller = Get.put(GetIt.instance<ClientsController>());
    }
    if (widget.initialResidenceId != null) {
      _controller.residenceFilter.value = widget.initialResidenceId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final gap = ResponsiveHelper.getResponsiveHeight(context, 12);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, 'Clients'),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final all = controller.clients;
          if (all.isEmpty && controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
          }
          if (all.isEmpty && controller.errorMessage.value.isNotEmpty) {
            return Center(
              child: HrMessageView(
                icon: Icons.error_outline_rounded,
                message: controller.errorMessage.value,
                onRetry: controller.refresh,
              ),
            );
          }

          final items = controller.filtered;
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
                HrSearchField(
                  hint: 'Search by client name or ID',
                  onChanged: (v) => controller.query.value = v,
                ),
                SizedBox(height: gap),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HrFilterPill(
                      allLabel: 'All residences',
                      value: controller.residenceFilter.value,
                      options: controller.residenceOptions,
                      labelOf: controller.residenceLabel,
                      onChanged: (v) => controller.residenceFilter.value = v,
                    ),
                    HrFilterPill(
                      allLabel: 'All statuses',
                      value: controller.statusFilter.value,
                      options: controller.statuses,
                      labelOf: hrHumanize,
                      onChanged: (v) => controller.statusFilter.value = v,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                Text(
                  '${items.length} of ${all.length} clients',
                  style: AppTextStyles.base(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    fontWeight: AppFontWeight.medium,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                if (items.isEmpty)
                  HrMessageView(
                    icon: Icons.people_outline_rounded,
                    message: all.isEmpty
                        ? 'No clients in your residences yet.'
                        : 'No clients match your search or filters.',
                  )
                else
                  for (final client in items) ...[
                    ClientCard(
                      client: client,
                      residenceName: client.residenceId == null
                          ? client.residenceName
                          : controller.residenceLabel(client.residenceId!),
                      onTap: () => Get.to(
                        () => ClientDetailPage(client: client),
                      ),
                    ),
                    SizedBox(height: gap),
                  ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
