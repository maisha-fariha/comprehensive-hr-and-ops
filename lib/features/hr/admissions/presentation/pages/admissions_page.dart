import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_pagination.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import '../admissions_labels.dart';
import '../controllers/admissions_controller.dart';
import '../widgets/admissions_common.dart';
import '../widgets/admissions_kpi_grid.dart';
import '../widgets/admit_referral_sheet.dart';
import '../widgets/decline_referral_sheet.dart';
import '../widgets/intake_forms_tab.dart';
import '../widgets/referral_card.dart';
import '../widgets/referral_detail_sheet.dart';
import '../widgets/referral_form_sheet.dart';

/// Manager "Admissions" — mirrors web `/dashboard/admissions`.
class AdmissionsPage extends StatefulWidget {
  const AdmissionsPage({super.key});

  @override
  State<AdmissionsPage> createState() => _AdmissionsPageState();
}

class _AdmissionsPageState extends State<AdmissionsPage> {
  late final AdmissionsController _c;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<AdmissionsController>());
    _search = TextEditingController(text: _c.search.value);
  }

  @override
  void dispose() {
    _search.dispose();
    Get.delete<AdmissionsController>();
    super.dispose();
  }

  Future<void> _confirmDelete(Referral r) async {
    final confirmed = await confirmAdmissionAction(
      context,
      title: 'Delete this referral?',
      description:
          '${[r.firstName, r.lastName].where((p) => p.isNotEmpty).join(' ')} '
          'leaves the pipeline. The referral and its history are kept rather '
          'than destroyed, so it can be restored.',
      confirmLabel: 'Delete',
      tone: AppColors.criticalRed,
      confirmKey: const ValueKey('referral-delete-confirm'),
    );
    if (confirmed) await _c.deleteReferral(r);
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
                child: Obx(
                  () => Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textHeading,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Admissions',
                          style:
                              handoverText(context, 18, weight: FontWeight.w700),
                        ),
                      ),
                      if (_c.tab.value == AdmissionsTab.referrals && _c.canWrite)
                        HandoverButton(
                          key: const ValueKey('referral-new'),
                          label: 'New referral',
                          icon: Icons.add_rounded,
                          filled: true,
                          compact: true,
                          onPressed: () =>
                              showReferralFormSheet(context, controller: _c),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: !_c.canRead
                ? _noAccess(context)
                : RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: _c.refreshAll,
                    child: Obx(
                      () => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                        children: [
                          if (_c.tab.value == AdmissionsTab.referrals) ...[
                            _filters(context),
                            const SizedBox(height: 15),
                          ],
                          if (_c.board.value case final board?) ...[
                            AdmissionsKpiGrid(board: board),
                            const SizedBox(height: 15),
                          ],
                          _tabs(context),
                          const SizedBox(height: 15),
                          if (_c.tab.value == AdmissionsTab.forms)
                            IntakeFormsTab(controller: _c)
                          else
                            ..._list(context),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _noAccess(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'You do not have access to this page.',
            textAlign: TextAlign.center,
            style: handoverText(context, 14, color: AppColors.textMuted),
          ),
        ),
      );

  Widget _filters(BuildContext context) {
    final options = [('', 'Any stage'), ...AdmissionsLabels.stages];
    final current = _c.status.value ?? '';
    final label = options.firstWhere((o) => o.$1 == current).$2;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              key: const ValueKey('admissions-search'),
              controller: _search,
              onChanged: _c.setSearch,
              style: handoverText(context, 13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search referrals…',
                hintStyle:
                    handoverText(context, 13.5, color: AppColors.textMuted),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.surfaceWhite,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            key: const ValueKey('admissions-stage-filter'),
            borderRadius: BorderRadius.circular(9),
            onTap: () async {
              final picked = await pickHandoverOption(
                context,
                title: 'Stage',
                options: options,
                selected: current,
              );
              if (picked != null) _c.setStatus(picked.isEmpty ? null : picked);
            },
            child: Container(
              constraints: const BoxConstraints(minWidth: 130),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.searchBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: handoverText(context, 13.5, weight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabs(BuildContext context) {
    Widget tab(AdmissionsTab id, String label) {
      final selected = _c.tab.value == id;
      return InkWell(
        key: ValueKey('admissions-tab-${id.name}'),
        onTap: () => _c.setTab(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.secondaryTeal : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: handoverText(
              context,
              13.5,
              weight: FontWeight.w500,
              color: selected ? AppColors.secondaryTeal : AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          tab(AdmissionsTab.referrals, 'Referrals'),
          tab(AdmissionsTab.forms, 'Intake forms'),
        ],
      ),
    );
  }

  List<Widget> _list(BuildContext context) {
    if (_c.loading.value && _c.referrals.isEmpty) {
      return [
        for (var i = 0; i < 3; i++)
          Container(
            height: 130,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ];
    }
    if (_c.referrals.isEmpty) {
      final failed = _c.loadError.value != null;
      return [
        HandoverPanel(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 19,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                failed ? 'Referrals could not be loaded' : 'No referrals',
                textAlign: TextAlign.center,
                style: handoverText(context, 15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                failed
                    ? _c.loadError.value!
                    : 'Someone enquiring about a place starts here and ends as a resident record.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final r in _c.referrals) ...[
        ReferralCard(
          key: ValueKey('referral-${r.id}'),
          referral: r,
          preferredName: _c.residenceName(r.preferredResidenceId),
          canWrite: _c.canWrite,
          busy: _c.busyId.value == r.id,
          onOpen: () => showReferralDetailSheet(
            context,
            controller: _c,
            referralId: r.id,
          ),
          onEdit: () =>
              showReferralFormSheet(context, controller: _c, referral: r),
          onAdmit: () => showAdmitReferralSheet(
            context,
            controller: _c,
            referralId: r.id,
          ),
          onDecline: () => showDeclineReferralSheet(
            context,
            controller: _c,
            referralId: r.id,
          ),
          onDelete: () => _confirmDelete(r),
        ),
        const SizedBox(height: 12),
      ],
      AttendancePagination(
        page: _c.page.value,
        limit: _c.limit.value,
        total: _c.total.value,
        totalPages: _c.totalPages,
        limitOptions: AdmissionsController.pageSizes,
        onPage: _c.setPage,
        onLimit: _c.setLimit,
      ),
    ];
  }
}
