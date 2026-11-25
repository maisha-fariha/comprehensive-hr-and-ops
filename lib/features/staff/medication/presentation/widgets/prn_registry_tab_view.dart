import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../hr/medication/presentation/medication_labels.dart';
import '../../domain/entities/staff_client_medication_item.dart';
import 'administered_tab_view.dart';

/// Web PRN tab — `GET /prn-medications` registry (same card chrome as MAR).
class PrnRegistryTabView extends StatelessWidget {
  final List<StaffClientMedicationItem> items;
  final ValueChanged<StaffClientMedicationItem>? onGive;
  final ValueChanged<StaffClientMedicationItem>? onOpenChart;
  final ValueChanged<StaffClientMedicationItem>? onEdit;
  final ValueChanged<StaffClientMedicationItem>? onDelete;
  final ValueChanged<StaffClientMedicationItem>? onDiscontinue;
  final bool canGive;

  /// The registry search + filters shared with the MAR tab.
  final Widget? filters;

  const PrnRegistryTabView({
    super.key,
    required this.items,
    this.onGive,
    this.onOpenChart,
    this.onEdit,
    this.onDelete,
    this.onDiscontinue,
    this.canGive = true,
    this.filters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Row(
          children: [
            const Expanded(
              child: Text(
                'PRN Medication Registry',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            StaffMedicationCountLabel(
              text: '${items.length} available',
              background: const Color(0xFFE7F0FF),
              foreground: const Color(0xFF2A5DA6),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        if (filters != null) ...[
          filters!,
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        ],
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'No PRN medicines available under these filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            _PrnCard(
              item: items[i],
              canGive: canGive,
              onGive: onGive == null ? null : () => onGive!(items[i]),
              onOpenChart:
                  onOpenChart == null ? null : () => onOpenChart!(items[i]),
              onEdit: onEdit == null ? null : () => onEdit!(items[i]),
              onDelete: onDelete == null ? null : () => onDelete!(items[i]),
              onDiscontinue: onDiscontinue == null
                  ? null
                  : () => onDiscontinue!(items[i]),
            ),
            if (i != items.length - 1)
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
          ],
      ],
    );
  }
}

/// Same stacked registry layout as the MAR [DueDoseCard].
class _PrnCard extends StatelessWidget {
  final StaffClientMedicationItem item;
  final bool canGive;
  final VoidCallback? onGive;
  final VoidCallback? onOpenChart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDiscontinue;

  const _PrnCard({
    required this.item,
    required this.canGive,
    this.onGive,
    this.onOpenChart,
    this.onEdit,
    this.onDelete,
    this.onDiscontinue,
  });

  String get _resident {
    if (item.clientName.trim().isEmpty) return 'Outside your access';
    return item.clientName.trim();
  }

  String get _initials {
    if (_resident == 'Outside your access') return '?';
    final parts = _resident
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  String get _schedule {
    final bits = <String>['As needed'];
    final instructions = item.instructions?.trim() ?? '';
    if (instructions.isNotEmpty) bits.add(instructions);
    if (item.minIntervalMinutes != null && item.minIntervalMinutes! > 0) {
      final m = item.minIntervalMinutes!;
      bits.add(m >= 60 ? 'min ${m ~/ 60}h' : 'min ${m}m');
    }
    return bits.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final statusTone =
        item.isActive ? MarTone.info : MarTone.neutral;
    final statusLabel = item.isActive ? 'AVAILABLE' : 'INACTIVE';
    final avatarBg = const Color(0xFFE7F0FF);
    final avatarFg = const Color(0xFF2A5DA6);

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenChart ?? onGive,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: avatarFg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _resident,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusTone.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        color: statusTone.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: avatarFg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name.isEmpty ? 'Medication' : item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _metaGrid([
                (
                  'Residence',
                  item.residenceName.isEmpty ? '—' : item.residenceName,
                ),
                ('Dosage', item.dose.isEmpty ? '—' : item.dose),
                ('Schedule', _schedule),
                (
                  'Given',
                  item.scheduleLabel?.trim().isNotEmpty == true
                      ? item.scheduleLabel!.trim()
                      : '—',
                ),
              ]),
              const SizedBox(height: 6),
              const Divider(height: 1, color: AppColors.cardBorder),
              // Web order: View · Give · Delete · Edit · Discontinue.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Action(
                    key: ValueKey('staff-prn-view-${item.id}'),
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    onTap: onOpenChart ?? onGive ?? () {},
                  ),
                  if (canGive && onGive != null)
                    _Action(
                      key: ValueKey('staff-prn-give-${item.id}'),
                      icon: Icons.vaccines_outlined,
                      label: 'Give PRN',
                      onTap: onGive!,
                    ),
                  if (onDelete != null)
                    _Action(
                      key: ValueKey('staff-prn-delete-${item.id}'),
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete prescription',
                      danger: true,
                      onTap: onDelete!,
                    ),
                  if (onEdit != null)
                    _Action(
                      key: ValueKey('staff-prn-edit-${item.id}'),
                      icon: Icons.edit_outlined,
                      label: 'Edit prescription',
                      onTap: onEdit!,
                    ),
                  if (onDiscontinue != null)
                    _Action(
                      key: ValueKey('staff-prn-discontinue-${item.id}'),
                      icon: Icons.block_rounded,
                      label: 'Discontinue',
                      onTap: onDiscontinue!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaGrid(List<(String, String)> cells) {
    return Column(
      children: [
        for (var i = 0; i < cells.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < cells.length ? 8 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _metaCell(cells[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < cells.length
                      ? _metaCell(cells[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _metaCell((String, String) cell) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cell.$1.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 10.5,
            letterSpacing: 0.3,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          cell.$2,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: AppColors.textHeading,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: Icon(
          icon,
          size: 18,
          color: danger ? AppColors.criticalRed : AppColors.textSecondary,
        ),
      ),
    );
  }
}
