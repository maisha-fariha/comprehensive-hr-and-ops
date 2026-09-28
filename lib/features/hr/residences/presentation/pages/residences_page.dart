import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../controllers/residences_controller.dart';
import '../widgets/residence_card.dart';
import 'residence_detail_page.dart';

/// Manager "Residences" screen: stats, search, status/type filters and the
/// list of homes the manager is scoped to.
class ResidencesPage extends StatelessWidget {
  const ResidencesPage({super.key});

  ResidencesController _resolveController() {
    try {
      return Get.find<ResidencesController>();
    } catch (_) {
      return Get.put(GetIt.instance<ResidencesController>());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final gap = ResponsiveHelper.getResponsiveHeight(context, 12);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, 'Residences'),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final all = controller.residences;
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
                _StatsGrid(controller: controller),
                SizedBox(height: gap),
                HrSearchField(
                  hint: 'Search by residence name or address',
                  onChanged: (v) => controller.query.value = v,
                ),
                SizedBox(height: gap),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HrFilterPill(
                      allLabel: 'All statuses',
                      value: controller.statusFilter.value,
                      options: controller.statuses,
                      labelOf: hrHumanize,
                      onChanged: (v) => controller.statusFilter.value = v,
                    ),
                    HrFilterPill(
                      allLabel: 'All types',
                      value: controller.typeFilter.value,
                      options: controller.types,
                      labelOf: hrHumanize,
                      onChanged: (v) => controller.typeFilter.value = v,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                if (items.isEmpty)
                  HrMessageView(
                    icon: Icons.home_work_outlined,
                    message: all.isEmpty
                        ? 'No residences are assigned to you yet.'
                        : 'No residences match your search or filters.',
                  )
                else
                  for (final residence in items) ...[
                    ResidenceCard(
                      residence: residence,
                      onTap: () => Get.to(
                        () => ResidenceDetailPage(residence: residence),
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

class _StatsGrid extends StatelessWidget {
  final ResidencesController controller;

  const _StatsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.getResponsiveWidth(context, 10);
    final tiles = [
      HrStatTile(
        label: 'Homes',
        value: '${controller.residences.length}',
        icon: Icons.home_work_outlined,
        iconColor: AppColors.infoBlue,
        iconBackground: AppColors.infoBackground,
      ),
      HrStatTile(
        label: 'Residents',
        value: '${controller.totalResidents}',
        icon: Icons.people_outline_rounded,
        iconColor: AppColors.activeGreen,
        iconBackground: AppColors.activeBackground,
      ),
      HrStatTile(
        label: 'Beds free',
        value: '${controller.totalBedsFree}',
        icon: Icons.bed_outlined,
        iconColor: AppColors.secondaryTeal,
        iconBackground: AppColors.quickActionCreateShiftBg,
      ),
      HrStatTile(
        label: 'At capacity',
        value: '${controller.atCapacityCount}',
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.urgentAmber,
        iconBackground: AppColors.urgentBackground,
      ),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            SizedBox(width: gap),
            Expanded(child: tiles[1]),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(child: tiles[2]),
            SizedBox(width: gap),
            Expanded(child: tiles[3]),
          ],
        ),
      ],
    );
  }
}
