import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../domain/entities/shift_handover.dart';
import '../controllers/handovers_controller.dart';
import '../handover_labels.dart';
import '../widgets/handover_card.dart';
import '../widgets/handover_common.dart';
import '../widgets/handover_detail_sheet.dart';
import '../widgets/record_handover_sheet.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Manager "Shift Handovers" — mirrors web `/dashboard/handovers`.
class HandoversPage extends StatefulWidget {
  const HandoversPage({super.key});

  @override
  State<HandoversPage> createState() => _HandoversPageState();
}

class _HandoversPageState extends State<HandoversPage> {
  late final HandoversController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(GetIt.instance<HandoversController>());
  }

  @override
  void dispose() {
    Get.delete<HandoversController>();
    super.dispose();
  }

  Future<void> _confirmDelete(ShiftHandover h) async {
    final confirmed = await showAppPopup<bool>(
      context: context,
      builder: (dialogContext) => AppSheetDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Delete this handover?',
          style: handoverText(dialogContext, 17, weight: FontWeight.w700),
        ),
        content: Text(
          'It leaves the list. What it recorded, and who acknowledged it, are '
          'kept rather than destroyed, so it can be restored.',
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
              key: const ValueKey('handover-delete-confirm'),
              borderRadius: BorderRadius.circular(9),
              onTap: () => Navigator.of(dialogContext).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Delete',
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
    if (confirmed == true) await _c.delete(h);
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime?> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) onPicked(picked);
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
                        'Shift Handovers',
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
              onRefresh: _c.load,
              child: Obx(
                () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 24),
                  children: [
                    ..._filters(context),
                    const SizedBox(height: 15),
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

  List<Widget> _filters(BuildContext context) {
    final statusOptions = [('', 'Any status'), ...HandoverLabels.statuses];
    final staffOptions = [
      ('', 'Anyone'),
      for (final s in _c.staff) (s.id, s.label),
    ];
    final residenceOptions = [
      ('', 'All Residences'),
      for (final r in _c.residences) (r.id, r.label),
    ];
    String labelOf(List<(String, String)> options, String? id) =>
        options.firstWhere((o) => o.$1 == (id ?? ''), orElse: () => options.first).$2;

    Widget select(
      String key,
      String title,
      List<(String, String)> options,
      String? value,
      ValueChanged<String?> onChanged,
    ) =>
        _FilterButton(
          key: ValueKey(key),
          icon: Icons.unfold_more_rounded,
          label: labelOf(options, value),
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: title,
              options: options,
              selected: value ?? '',
            );
            if (picked != null) onChanged(picked.isEmpty ? null : picked);
          },
        );

    Widget date(String key, String label, DateTime? value, ValueChanged<DateTime?> set) =>
        _FilterButton(
          key: ValueKey(key),
          icon: Icons.calendar_today_outlined,
          label: value == null ? label : WebFormat.date(value),
          muted: value == null,
          onTap: () => _pickDate(value, set),
          onClear: value == null ? null : () => set(null),
        );

    return [
      Row(
        children: [
          Expanded(
            child: select('handovers-status-filter', 'Status', statusOptions,
                _c.status.value, _c.setStatus),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: select('handovers-staff-filter', 'Staff', staffOptions,
                _c.staffId.value, _c.setStaff),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: date('handovers-from', 'Handovers from', _c.from.value, _c.setFrom),
          ),
          const SizedBox(width: 10),
          Expanded(child: date('handovers-to', 'Handovers to', _c.to.value, _c.setTo)),
        ],
      ),
      const SizedBox(height: 10),
      select('handovers-residence-filter', 'Residence', residenceOptions,
          _c.residenceId.value, _c.setResidence),
      if (_c.canWrite) ...[
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: HandoverButton(
            key: const ValueKey('handovers-record'),
            label: 'Record Handover',
            icon: Icons.add_rounded,
            filled: true,
            onPressed: () => showRecordHandoverSheet(context, controller: _c),
          ),
        ),
      ],
    ];
  }

  List<Widget> _list(BuildContext context) {
    if (_c.loading.value && _c.handovers.isEmpty) {
      return [
        for (var i = 0; i < 3; i++)
          Container(
            height: 110,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.filterButtonBackground,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ];
    }
    if (_c.handovers.isEmpty) {
      final failed = _c.loadError.value != null;
      return [
        HandoverPanel(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Text(
                failed ? 'Handovers could not be loaded' : 'No handovers yet',
                textAlign: TextAlign.center,
                style: handoverText(context, 15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                failed
                    ? _c.loadError.value!
                    : 'What one shift tells the next will appear here.',
                textAlign: TextAlign.center,
                style: handoverText(context, 13.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final h in _c.handovers) ...[
        HandoverCard(
          key: ValueKey('handover-${h.id}'),
          handover: h,
          busy: _c.busyId.value == h.id,
          canSubmit: _c.canSubmit(h),
          canTake: _c.canTake(h),
          canDelete: _c.canWrite,
          onOpen: () =>
              showHandoverDetailSheet(context, controller: _c, handoverId: h.id),
          onSubmit: () => _c.submit(h),
          onTake: () => _c.take(h),
          onDelete: () => _confirmDelete(h),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.muted = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: ResponsiveHelper.getResponsiveHeight(context, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: handoverText(
                    context,
                    13.5,
                    weight: FontWeight.w500,
                    color: muted ? AppColors.textMuted : AppColors.textHeading,
                  ),
                ),
              ),
              if (onClear != null)
                InkWell(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
